# Touch ID & system authentication on macOS

Every place this machine can ask "prove it's you", what each one actually protects, and how to get
to *one tap, rarely* without pretending something is secure when it isn't. Verified 2026-07-28 on
macOS 27.0, Apple Silicon.

## 1. The surfaces

| Surface | Gate | Configured here? |
| --- | --- | --- |
| 1Password app unlock | Touch ID / Apple Watch / account password | app setting — **verify** |
| `op` CLI command | 1Password authorization prompt | yes (desktop-app integration) |
| Shell plugin (`gh`, `aws`, …) | same prompt as `op` | no plugin configured |
| SSH / Git over the 1Password agent | 1Password authorization prompt | yes |
| Git commit signature (`op-ssh-sign`) | same | yes |
| GPG passphrase | keychain ACL + Touch ID via `pinentry-touchid` | no (`~/.gnupg` absent) |
| `sudo` | PAM: password, or `pam_tid.so` | **no** — password only |
| `sudo` inside tmux/screen | needs `pam_reattach` before `pam_tid` | n/a (`pam-reattach` not installed) |
| Keychain item access | per-item ACL | implicit |
| macOS login / screen unlock | Touch ID | system default |

Everything in the top half funnels through one thing: **whether 1Password itself is unlocked with
Touch ID**. Fix that first — it is the difference between "tap" and "type your account password"
across the entire CLI, SSH and signing surface.

## 2. Making the 1Password surfaces quiet

Three independent settings, all in the 1Password app:

1. **Security → unlock with Touch ID.** Without it, every `op` command and every SSH authorization
   prompt asks for the account password. This is the single highest-leverage setting.
2. **Security → auto-lock.** Approvals are wiped on lock (unless a fixed duration is chosen, §3),
   so an aggressive auto-lock multiplies prompts. Lock on screensaver / after some idle period, not
   after minutes.
3. **Developer → SSH agent → approval scope and memory.** See
   [1password-ssh-git.md](1password-ssh-git.md) §5. Recommended balance: *For each new application*
   + remember *for 4–12 hours*. Prompts then collapse to about one per app per work session, while
   each key still requires an explicit human approval the first time an app asks for it.

`op` CLI sessions are separate and not configurable: per terminal window, ending at lock, 10 minutes
idle, 12 hours, or `op signout`.

⚠ *Approve for all applications* (the checkbox on a prompt) removes per-process consent for that key
until the session ends — after that, only socket file permissions stand between any process running
as you and that key. Reasonable for a short batch of work; not a default.

## 3. Touch ID for `sudo`

macOS 14+ provides a drop-in that survives OS updates. `/etc/pam.d/sudo` already contains
`auth include sudo_local` as its first line; only the template exists here:

```sh
sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
sudo micro /etc/pam.d/sudo_local        # uncomment the pam_tid.so line
```

Target contents:

```
auth       sufficient     pam_tid.so
```

`sufficient` means Touch ID satisfies auth if it succeeds and falls through to the password prompt if
it fails or is unavailable (SSH sessions, lid closed, no finger enrolled) — so there is no lockout
risk. It takes effect on the next `sudo`.

⚠ Editing `/etc/pam.d/sudo` itself instead of `sudo_local` is the old advice; the file is replaced by
OS updates and a syntax error there can make `sudo` unusable. Always use `sudo_local`, keep a root
shell open while editing, and test in a second terminal before closing it.

### Inside tmux/screen

`pam_tid.so` fails in a re-parented session. `pam-reattach` fixes it by reattaching to the user's
GUI session:

```
auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
auth       sufficient     pam_tid.so
```

`pam-reattach` **is installed** (1.3; `/opt/homebrew/lib/pam/pam_reattach.so`, verified 2026-07-28),
so this line can go in immediately. It is a PAM module, not a CLI — `command -v pam-reattach` finds
nothing and that is not evidence of absence. Check `ls /opt/homebrew/lib/pam/` or
`brew list --versions pam-reattach` instead.

⚠ The module path is architecture-specific (`/opt/homebrew/lib/pam/…` on Apple Silicon,
`/usr/local/lib/pam/…` on Intel). `optional` means a missing or broken module does not block auth,
so the line is safe even if the formula is later removed. tmux is not in use here, so it is
future-proofing rather than a current need.

## 4. Keychain ACLs

macOS gates each keychain item by which binaries may read it:

- The binary that **creates** an item owns it and reads without extra prompts.
- Any other binary triggers a login-password prompt with *Deny / Allow / Always Allow*. **Always
  Allow** adds it to the item's ACL permanently.
- Ownership is per-binary path and per-signature — reinstalling or upgrading a tool can re-trigger
  the prompt once.

This is exactly the dance `pinentry-touchid` documents: let it create the entry (via
`DisableKeychain` on `pinentry-mac`) and there is no password prompt at all.

Inspect with Keychain Access, or:

```sh
security find-generic-password -s 'GnuPG'      # metadata only
```

⚠ Never add `-w` — it prints the secret.

## 5. What Touch ID here does *not* do

- **It is not encryption.** Touch ID authorizes access to a secret protected by the login keychain or
  by 1Password; it does not itself encrypt anything.
- **`pinentry-touchid` does not use the Secure Enclave.** Its own README says so: the passphrase is a
  normal keychain item, guarded by an ACL plus a biometric check.
- **It is biometrics-only in `pinentry-touchid`** (`LAPolicyDeviceOwnerAuthenticationWithBiometrics`)
  — no Apple Watch, no password fallback inside that program. 1Password's own prompts are more
  flexible.
- **It does not bound a process.** Once a session is authorized, every process in it can use the
  credential; consent is per-app-session, not per-command.

## 6. Verification

```sh
bioutil -r                                    # touch id enrolment state for this user
ls -l /etc/pam.d/sudo_local                   # does the drop-in exist yet
sudo -k && sudo true                          # re-auth: does touch id appear
op whoami                                     # does the cli prompt, and with what
security find-generic-password -s 'GnuPG'     # gpg passphrase entry present
```

## 7. If prompts feel excessive, check in this order

1. Is 1Password set to unlock with Touch ID at all?
2. How aggressively does 1Password auto-lock?
3. SSH agent approval scope — is it set to *per terminal session* rather than *per application*?
4. Is an IDE running background `git fetch`? (Menu-bar dot → *SSH request waiting*.)
5. Is the work spread across many short-lived terminals? Each new terminal costs one `op` prompt.
6. For GPG: does the keychain entry exist and is it owned by `pinentry-touchid`? An entry owned by
   `pinentry-mac` costs a login-password prompt every time until *Always Allow*.
