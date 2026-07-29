# 1Password for SSH & Git

Distilled from www.1password.dev/ssh (2026-07-28) and verified against this machine's
`~/.ssh/config`, `~/.config/1Password/ssh/agent.toml` and `~/.config/git/.gitconfig`.

## 1. What the agent is

The 1Password SSH agent is an agent-protocol socket served by the desktop app. It replaces
`ssh-agent`: instead of `ssh-add`-ing keys into a process that then serves any caller, **every
request is authorized individually**, and the private key never leaves the app.

Socket on macOS:

```
~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

Turn it on: 1Password → Settings → Developer → *Use the SSH Agent*. Also enable Settings → General →
*Keep 1Password in the menu bar* and *Start at login*, or the agent dies with the window.

When 1Password is locked the agent keeps running and can still prompt; it just cannot reach private
keys until unlocked.

## 2. Eligible keys

A key is offered by the agent only if it is:

- an **`SSH Key` item** (Ed25519, or RSA 2048/3072/4096) — not a note, not an attachment;
- in a vault the agent is configured to use (default: `Personal`/`Private`/`Employee`);
- active (not archived, not deleted).

List what the agent actually offers:

```sh
SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l
```

## 3. `agent.toml` — which keys, in what order

```
$XDG_CONFIG_HOME/1Password/ssh/agent.toml     # checked first when XDG_CONFIG_HOME is set
~/.config/1Password/ssh/agent.toml            # macOS/Linux default
```

⚠ **Creating the file at all overrides the default configuration, even if it is empty** — an empty
`agent.toml` means *no keys*. This machine has:

```toml
[[ssh-keys]]
vault = "Development"
```

so only keys in the `Development` vault are offered; anything in `Private` is invisible to SSH until
this file says otherwise.

Syntax: an array of `[[ssh-keys]]` tables, each with one or more of `item`, `vault`, `account`
(name, sign-in address, or ID). The keys behave like `WHERE`/`AND` clauses — more pairs, narrower
match. **Header and keys must be lowercase**; values must be quoted; values themselves are
case-insensitive. UTF-8, `#` comments.

```toml
# most specific first — this is also the offer order
[[ssh-keys]]
item = "Git Signing Key"
vault = "Development"

[[ssh-keys]]
vault = "Private"
account = "my.1password.com"
```

- **Section order = the order keys are offered to servers.** This is the lever against the six-key
  limit (§6).
- Multiple matches inside one section are ordered by item creation date, oldest first.
- Edits apply immediately; no agent restart. (Creating the file the first time may need a
  lock/unlock.)
- Use **IDs instead of names** when you don't want item/vault names sitting unencrypted on disk, or
  when names change. Copy a UUID via Settings → Advanced → *Show debugging tools* → ⋮ → Copy UUID,
  or via `op item get X --format json | jq .id`.
- A typo produces no error — entries that match nothing are silently ignored. A *syntax* error stops
  the agent and reports in Settings → Developer.
- The file is local-only, never synced; version it yourself if you want it shared.

## 4. Client configuration

### `IdentityAgent` (preferred)

```
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

Already present in `~/.ssh/config` on this machine.

### `SSH_AUTH_SOCK` (fallback)

More clients honour the env var than honour `ssh_config`. For clients that read both,
`IdentityAgent` wins.

```fish
set -gx SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

To make it apply to GUI apps launched from Finder, 1Password documents a LaunchAgent that symlinks
the socket over `$SSH_AUTH_SOCK`. ⚠ That overrides Apple's launchd agent globally — only do it for a
specific client that needs it.

### Config file location and XDG

OpenSSH (10.4 here) has **no XDG support**; `~/.ssh/config` is hardcoded. But `Include` accepts `~`
and environment variables, so the config body can live in `~/.config` with no symlink:

```
# ~/.ssh/config — stub only
Include ~/.config/ssh/config
Include ~/.ssh/1Password/config
```

⚠ **First obtained value wins** in `ssh_config`. `Include` lines and host-specific blocks go at the
*top*; `Host *` defaults go at the bottom. An `Include` placed after a `Host *` block cannot override
what that block already set.

`~/.ssh` still has to exist for `known_hosts`, `authorized_keys`, downloaded public keys and the
1Password-generated bookmark directory.

### Gradual migration / per-host agents

`IdentityAgent none` opts a host out; `IdentityFile none` opts out of a key file. So the 1Password
agent can serve `Host *` while one legacy host keeps a local `.pem`:

```
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

Host legacy-box
  HostName 203.0.113.10
  IdentityFile ~/.ssh/legacy.pem
  IdentityAgent none
```

## 5. Authorization model

A request prompts once, then establishes a session between **that key** and **the requesting
process**. Subsequent commands in the same process are silent — authorize `git pull`, and `git push`
follows without a prompt.

Two settings in Settings → Developer control friction:

**What is being approved:**
- *For each new application* (default) — per key, per app, including subprocesses.
- *For each new application and terminal session* — additionally per terminal tab. Strictest.
- *Approve for all applications* — a per-prompt checkbox; authorizes every process of the current OS
  user for that key, for the session. Only file permissions on the socket restrict it after that.

**How long approval is remembered:**
- *Until 1Password locks* (default)
- *Until 1Password quits*
- *For 4 / 12 / 24 hours* — approvals survive locking; you still get an unlock prompt, because the
  agent never keeps private keys in memory while locked.

**Least-annoying combination that stays honest:** *For each new application* + a fixed 4–12 hours,
with 1Password's own auto-lock set long and Touch ID unlock on. Prompts then collapse to roughly one
per app per workday.

**Background `git fetch`** from IDEs is the usual source of surprise prompts. 1Password suppresses
prompts from non-foreground windows and shows a dot on the menu-bar icon — click it, then *SSH
request waiting*. Turning off IDE autofetch removes the cause.

**Local storage:** enabling the agent writes an unencrypted copy of your **public** keys to disk (so
prompts can render while locked). Enabling *Display key names when authorizing connections* also
writes **item titles**; leave it off if titles are sensitive — prompts then show a truncated
fingerprint.

## 6. The six-key limit

OpenSSH servers default to `MaxAuthTries 6`. The agent offers keys one at a time; the seventh
attempt gets `Too many authentication failures`. Three fixes, in order of preference:

1. **SSH Bookmarks** (§7) — 1Password generates the host↔key mapping for you.
2. **`agent.toml` ordering** — put the keys you use most first.
3. **Manual `IdentityFile`** — download the *public* key from the item and point a `Host` block at
   it. The private key stays in 1Password.

```
Host github.com
  IdentityFile ~/.ssh/github.pub
  IdentitiesOnly yes
```

⚠ Some clients reject a `.pub` file in `IdentityFile`; check compatibility first.

## 7. SSH Bookmarks (beta)

Add an `ssh://` URL as a custom field on an SSH Key item (`ssh://user@host`, `ssh://192.0.2.10`,
`ssh://my-alias`) and it appears under Developer → View SSH agent → Bookmarks, with a *Connect*
button that launches your terminal. The quickest way to create one is the **Bookmark** button beside
an entry in the SSH activity log.

Settings → Developer → Advanced → *Generate SSH config files from 1Password SSH bookmarks* makes
1Password write:

```
~/.ssh/1Password/config     # Match Host blocks mapping hosts → keys
~/.ssh/1Password/*.pub      # public keys, named by fingerprint
```

**This machine already has that directory**, containing a header comment and a bare `Match all`, but
`~/.ssh/config` never includes it — so it does nothing today. Add
`Include ~/.ssh/1Password/config` at the top of `~/.ssh/config` to activate it, or turn the setting
off to have 1Password remove the directory.

⚠ Never hand-edit files under `~/.ssh/1Password/` — 1Password rewrites them. To override a rule,
copy its `Match Host` block into `~/.ssh/config` *above* the `Include`.

⚠ Generating these files puts host URLs and public keys on disk unencrypted. Private keys stay in
1Password.

## 8. Git commit signing with SSH

Git ≥ 2.34 signs with SSH keys — no GPG needed. Current state of this machine (already configured):

```ini
[user]
    name = hogdanish
    email = 121070110+hogdanish@users.noreply.github.com
    signingkey = ssh-ed25519 AAAA…            # the public key, inline
[commit]
    gpgsign = true
[gpg]
    format = ssh
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```

`op-ssh-sign` talks to the agent directly, so `SSH_AUTH_SOCK` need not be set for signing. The app
can write this block for you: open the SSH Key item → ⋮ → *Configure Commit Signing* → *Edit
Automatically* (or *Copy Snippet* to paste into a repo's `.git/config` for per-repo signing).

**Register the public key for verification.** On GitHub the same key must be added a second time
with type **Signing key** — an authentication key alone leaves commits `Unverified`. GitLab uses
`Authentication & Signing`.

**Local verification** needs an allowed-signers file, which is currently **missing** here:

```sh
touch ~/.ssh/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
printf '%s %s\n' you@example.com "ssh-ed25519 AAAA…" >> ~/.ssh/allowed_signers
```

Without it, `git log --show-signature` prints
`error: gpg.ssh.allowedSignersFile needs to be configured…`. It blocks local verification only, not
committing. The file is shareable and can be committed like `CODEOWNERS`.

**Mixed setups** — `includeIf "gitdir:~/work/acme/"` can point a subtree at a GPG configuration while
SSH signing stays the default. See [gnupg-macos.md](gnupg-macos.md).

### Signing failures, in order of likelihood

| Symptom | Cause |
| --- | --- |
| `unsupported value for gpg.format: ssh` | Git < 2.34 |
| `failed to write commit object`, `could not deserialize public key` | `user.signingkey` is not a valid SSH public key |
| commits show `Unverified` on GitHub | key not registered as a **signing** key, or author email ≠ registered email (case-sensitive on GitLab/Bitbucket) |
| local values differ from `~/.gitconfig` | repo-level override — `git config --local --unset gpg.format` etc. |

Diagnose with `git config --show-origin --get-regexp '^(gpg|commit|user\.signing)'`.

## 9. Managing keys

- **Generate**: app → New Item → SSH Key → *Add Private Key* → *Generate a New Key* (Ed25519
  default), or `op item create --category ssh --title "My SSH Key"`.
- **Import**: New Item → SSH Key → *Import a Key File* (drag-drop or paste). An encrypted key asks
  for its passphrase once, then is stored under 1Password's own encryption.
- **Supported**: Ed25519, RSA 2048/3072/4096 (public exponent ≥ 65537); formats PKCS#1, PKCS#8,
  OpenSSH. **Not** supported: DSA, ECDSA, PuTTY `.ppk`, RC4-encrypted keys.
- **Export**: item → private key field → choose OpenSSH or PKCS#8, with or without a passphrase.
  ⚠ Only when a client genuinely cannot use an agent; delete the export afterwards.
- **Public key**: copy, download, or autofill into a web form with the browser extension.

## 10. Developer Watchtower

1Password → Developer → View Developer Watchtower → *Check for developer credentials on disk* scans
`~/.ssh` (3 levels deep, no symlinks, files ≤ 1 MiB) and flags:

- **Insecure key type** — DSA, or RSA < 2048. Remove from every `authorized_keys` first, then
  regenerate and delete.
- **Unencrypted key** — plaintext private key. Import into 1Password and delete, or
  `ssh-keygen -pf <key>` to add a passphrase.
- **Already exists in 1Password** — fingerprint matches an item; delete the disk copy.
- **Unsupported key** — cannot be imported; regenerate if it should live in 1Password.

`~/.ssh/.ignore` (glob patterns, one per line) exempts files. Turning this on is the fastest audit of
"is there a plaintext key anywhere on this machine".

## 11. Client compatibility

Most CLI tools (`ssh`, `git`, `scp`, `rsync`) honour `IdentityAgent`. GUI clients vary: some read
only `SSH_AUTH_SOCK`, some read neither, some reject public keys in `IdentityFile`. Upstream keeps a
per-client table at `1password.dev/ssh/agent/compatibility` covering Cyberduck, DataGrip, FileZilla,
Fork, GitKraken, GitHub Desktop, Nova, Sequel Ace, Sourcetree, Sublime Merge, TablePlus, Termius,
Tower, Transmit, Xcode and more — consult it before concluding the agent is broken.
