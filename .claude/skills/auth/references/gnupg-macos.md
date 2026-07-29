# GnuPG on macOS

Scoped to what this machine needs: the agent, the pinentry chain, the keychain contract, and OpenPGP
commit signing. Verified against **GnuPG 2.5.21** (Homebrew) on 2026-07-28. This is not a general
GPG tutorial — assume the standard command surface and read this for the macOS-specific seams.

## 1. Current state

**`~/.gnupg` does not exist.** No keys, no `gpg-agent.conf`, no keychain entry. `gnupg`,
`pinentry-mac` (1.3.1.1) and `pinentry-touchid` (0.0.3) are installed but nothing is wired up.
Commit signing runs entirely through SSH + 1Password, so GPG is currently unused — the reason to set
it up would be OpenPGP-specific work (encrypting files, signing releases/tags for a project that
requires OpenPGP, verifying upstream signatures).

⚠ **1Password cannot serve GPG keys.** Its agent speaks the SSH agent protocol only. A GPG private
key must live in `~/.gnupg/private-keys-v1.d/` (encrypted by its passphrase). The best available
posture is therefore: strong passphrase → stored in the macOS login keychain → keychain access
guarded by Touch ID via `pinentry-touchid`. 1Password can hold a *backup* of the exported key as a
document, but not serve it.

## 2. Home directory and XDG

```sh
gpgconf --list-dirs homedir      # → /Users/ethan/.gnupg
```

GnuPG does **not** honour `XDG_CONFIG_HOME`. The only lever is `GNUPGHOME`:

```fish
set -gx GNUPGHOME $XDG_DATA_HOME/gnupg    # only if you accept the consequences
```

⚠ Moving it is a real commitment: every tool that shells out to `gpg` inherits the variable from
fish only. Bash tool calls, launchd agents, GUI apps and cron do **not** see it and will silently
create and use a second, empty `~/.gnupg`. Given that `~/.gnupg` holds keys and sockets rather than
hand-authored config, leaving it at the default is the defensible choice — note it as a deliberate
exception to the XDG convention rather than an oversight.

Socket paths (`S.gpg-agent`, `S.gpg-agent.ssh`, …) also live in the homedir; `gpgconf --list-dirs`
prints all of them.

## 3. `gpg-agent.conf`

`~/.gnupg/gpg-agent.conf`, one `option value` per line, no leading `--`. Apply changes with:

```sh
gpg-connect-agent reloadagent /bye     # reload
gpgconf --kill gpg-agent               # hard restart (also required after some changes)
```

Options that matter here:

| Option | Default | Notes |
| --- | --- | --- |
| `pinentry-program <path>` | compiled-in `pinentry` | the whole Touch ID story hangs off this |
| `default-cache-ttl <n>` | 600 s | idle timeout of a cached passphrase; resets on each use |
| `max-cache-ttl <n>` | 7200 s | absolute ceiling regardless of use |
| `default-cache-ttl-ssh <n>` | 1800 s | same, for keys served over `enable-ssh-support` |
| `max-cache-ttl-ssh <n>` | 7200 s | |
| `no-allow-external-cache` | *unset* | ⚠ **do not set** — it disables the pinentry keychain path that `pinentry-touchid` depends on |
| `ignore-cache-for-signing` | off | forces a prompt for every signature; the opposite of what we want |
| `enable-ssh-support` | off | ⚠ leave off — 1Password owns SSH here; enabling it fights for `SSH_AUTH_SOCK` |
| `allow-preset-passphrase` | off | needed only for `gpg-preset-passphrase` |

A reasonable starting file for this machine:

```
# use touch id, falling back to pinentry-mac
pinentry-program /opt/homebrew/bin/pinentry-touchid

# cache generously — the keychain entry is the real gate, and it is touch-id guarded
default-cache-ttl 3600
max-cache-ttl 28800
```

⚠ Longer TTLs are not a security downgrade *here*: the passphrase is already recoverable from the
keychain behind Touch ID, so cache length only trades a Touch ID tap for wall-clock time.

## 4. The pinentry chain

```
gpg / git  →  gpg-agent  →  $pinentry-program  →  (pinentry-touchid)  →  pinentry-mac  →  GUI dialog
                                                          ↓
                                              macOS login keychain
```

`gpgconf --list-components | grep pinentry` reports the path gpg-agent will launch when
`pinentry-program` is unset. On this machine:

```
pinentry:Passphrase Entry:/opt/homebrew/opt/pinentry/bin/pinentry
```

⚠ **That path is a symlink to `pinentry-curses`** — verified 2026-07-28 with
`pinentry-touchid -check`, which reports:

```
❌ /opt/homebrew/opt/pinentry/bin/pinentry is a symlink that resolves to
   /opt/homebrew/Cellar/pinentry/1.3.3/bin/pinentry-curses not to pinentry-mac
```

`/opt/homebrew/opt/pinentry/bin/` contains only `pinentry -> pinentry-curses`, `pinentry-curses`
and `pinentry-tty`. **There is no `pinentry-mac` in that directory** — it is a separate keg reached
via `/opt/homebrew/bin/pinentry-mac`.

Two consequences:

1. **Unconfigured GPG prompts on the TTY, not in a GUI.** No Touch ID, no dialog — which is why
   `pinentry-program` must be set explicitly even before any key exists.
2. `pinentry-touchid -fix` would `os.Remove` that symlink (which belongs to the `pinentry` formula)
   and replace it with one to `pinentry-mac`, leaving a modified Homebrew install. The hazard stands;
   see [pinentry-touchid.md](pinentry-touchid.md) §Hazards. Setting `pinentry-program` achieves the
   same result with no filesystem surgery.

⚠ **`gpgconf --list-options gpg-agent` does not list `pinentry-program`** on 2.5.21 — it is not a
gpgconf-managed option, so its absence there is not evidence the setting was ignored. Confirm the
conf file is being read by checking an option that *is* listed (`default-cache-ttl`,
`max-cache-ttl` appear in field 10 of the output).

Test that a GUI pinentry answers at all:

```sh
echo GETPIN | pinentry           # should raise a dialog, not a TTY prompt
```

### pinentry-mac defaults (source-verified)

`pinentry-mac` reads `NSUserDefaults` from its own domain **plus** the shared suite
`org.gpgtools.common` (`AppDelegate.m` calls `addSuiteNamed:`). Keys it actually reads:

| Key | Type | Effect |
| --- | --- | --- |
| `UseKeychain` | bool | tick *Save in Keychain* by default. **Registered default is `YES`** |
| `DisableKeychain` | bool | hard-off: hides/ignores the keychain entirely, overriding `UseKeychain` |
| `ShowPassphrase` | bool | reveal typed characters by default |
| `KeychainPath` | string | use a non-default keychain file |

```sh
defaults write org.gpgtools.common UseKeychain -bool yes
defaults write org.gpgtools.common DisableKeychain -bool yes    # recommended once touch id works
defaults read org.gpgtools.common                               # inspect
```

Bundle identifier: `org.gpgtools.pinentry-mac`.

### The keychain item

Written as a **generic password**:

- service (`kSecAttrService`) = `GnuPG`
- account (`kSecAttrAccount`) = the key's cache ID / fingerprint
- label = free text; `pinentry-touchid` writes `Name <email> (keyID)`

Inspect (metadata only — never pass `-w`, which prints the passphrase):

```sh
security find-generic-password -s 'GnuPG'
```

`security: SecKeychainSearchCopyNext: The specified item could not be found` means no entry exists
yet.

## 5. Keys

```sh
gpg --quick-generate-key "Name <email>" ed25519 sign,cert 2y   # modern, small, fast
gpg --list-secret-keys --keyid-format=long
gpg --edit-key <keyid>                                          # expire, adduid, addkey
gpg --export --armor <keyid>                                    # public key, safe to publish
gpg --list-keys --with-keygrip                                  # keygrips, for agent-level ops
```

⚠ Never run `gpg --export-secret-keys` in an agent session — it prints private key material to the
transcript. If a backup is needed, have the user run it and store the result in 1Password.

Passphrase-change and key-generation prompts **bypass** `pinentry-touchid` and fall through to
`pinentry-mac`, because the Assuan `REPEAT`/error settings disable the keychain path. That is
expected, not a fault.

## 6. OpenPGP commit signing

Only relevant if a project requires OpenPGP specifically; SSH signing via 1Password is the default
here.

```ini
[user]
    signingkey = <LONG-KEY-ID-OR-FINGERPRINT>
[gpg]
    format = openpgp
[commit]
    gpgsign = true
```

To mix — SSH signing globally, GPG for one subtree:

```ini
# ~/.config/git/.gitconfig
[includeIf "gitdir:~/Projects/needs-openpgp/"]
    path = ~/Projects/needs-openpgp/.gitconfig
```

```ini
# ~/Projects/needs-openpgp/.gitconfig
[user]
    signingkey = 6A40D13BBB936F443084E8C9292E4F983136B860
[gpg]
    format = openpgp
```

⚠ `includeIf` paths in git are **not** environment-expanded — use `~/` or a path relative to the
including file. (Same trap that currently breaks `themes.gitconfig`.)

Register the public key at github.com/settings/keys for `Verified` badges.

## 7. Terminal/TTY issues

If a prompt appears in the wrong place, or gpg fails non-interactively with `Inappropriate ioctl for
device`, the agent needs to know the TTY. With a GUI pinentry (`pinentry-mac`) this rarely matters;
with `pinentry-curses`/`pinentry-tty` it always does:

```fish
set -gx GPG_TTY (tty)
gpg-connect-agent updatestartuptty /bye
```

Keep `GPG_TTY` out of the config until GPG is actually in use — an unused export is noise.

## 8. Verification

```sh
gpg --version | head -1                       # 2.5.21
gpgconf --list-dirs homedir                   # where keys will land
gpgconf --list-components | grep pinentry     # which pinentry gets launched
gpg-connect-agent 'getinfo version' /bye      # agent is alive
echo test | gpg --clearsign > /dev/null       # end-to-end signing works
gpg-connect-agent reloadagent /bye            # apply gpg-agent.conf edits
```
