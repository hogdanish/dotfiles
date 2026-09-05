---
name: auth
description: "Credentials on this machine: 1Password and op, op:// references, Environments, shell plugins, SSH agent and commit signing, GnuPG, Touch ID, sudo, and PAM. Load for any secret, token, .env, SSH/GPG config, or config that consumes a credential."
user-invocable: false
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(op*), Bash(gpg*), Bash(gpgconf*), Bash(ssh*), Bash(ssh-add*), Bash(ssh-keygen*), Bash(security find-generic-password*), Bash(defaults read*), Bash(git config*), Bash(ls*), Bash(type*), Bash(command -v*)
---

# Authentication, secrets & credential management

**1Password is the root of trust on this machine.** Private keys and tokens live in the 1Password
app; nothing on disk holds a usable secret. Everything else here is a way to get a credential *out*
of 1Password at the moment of use, or a way to make the human half of that transaction a Touch ID
tap instead of a typed password.

Three independent chains, in descending order of how much of the machine they carry:

1. **1Password app → `op` CLI / SSH agent.** Desktop-app integration means `op` and the SSH agent
   authenticate exactly the way you unlock 1Password (Touch ID). Secrets are referenced by
   `op://vault/item/field` URIs and resolved at runtime; SSH private keys never leave the app.
2. **1Password Environments (beta) → `.env`.** Project env vars stored in 1Password, exposed either
   as a locally *mounted* `.env` (a FIFO, never written to disk) or via `op run --environment`.
3. **gpg-agent → pinentry-touchid → pinentry-mac → macOS keychain.** The OpenPGP path. 1Password
   **cannot** hold GPG keys for gpg-agent, so a GPG passphrase lives in the login keychain and
   Touch ID guards access to it. Currently **entirely unconfigured** (see below).

## Reference material

- [1password-cli.md](references/1password-cli.md) — the `op` CLI: authentication model and session
  lifetime, config-directory detection, `op://` secret-reference syntax with query parameters,
  `read`/`run`/`inject`, `--env-file` and template variables, `op environment read`, shell plugins,
  service accounts, every `OP_*` environment variable, and troubleshooting. Read before writing any
  command or config that resolves a secret.
- [1password-ssh-git.md](references/1password-ssh-git.md) — the SSH agent: eligible keys, the
  `agent.toml` config file, the authorization model and every prompt-frequency setting, the
  `IdentityAgent`/`SSH_AUTH_SOCK` split, the six-key limit, multiple Git identities, SSH bookmarks
  and the generated `~/.ssh/1Password/config`, SSH commit signing with `op-ssh-sign`, allowed
  signers, and key import/export rules. Read before editing `~/.ssh/*` or any signing config.
- [1password-environments.md](references/1password-environments.md) — Environments (beta): creating
  them, mounted `.env` files and their Git interaction, the Claude Code validation hook and
  `.1password/environments.toml`, programmatic reads, variable precedence, and the `op run`
  wrapper pattern for MCP server configs. Read when a project needs a `.env` or an MCP server needs
  a token.
- [gnupg-macos.md](references/gnupg-macos.md) — GnuPG 2.5.21 on this machine: homedir and why
  `GNUPGHOME` is the only XDG lever, `gpg-agent.conf` options that matter (pinentry program, cache
  TTLs, `allow-external-cache`), key generation, OpenPGP commit signing, and the pinentry-mac
  keychain contract (`org.gpgtools.common` defaults, keychain item shape). Read before creating
  `~/.gnupg` or debugging a passphrase prompt.
- [pinentry-touchid.md](references/pinentry-touchid.md) — upstream README reproduced verbatim, plus
  source-verified behaviour the README omits (keychain label format, log path, fallback conditions)
  and the ⚠ Homebrew hazard in `-fix`. Read before installing or debugging Touch ID for GPG.
- [touchid-system-auth.md](references/touchid-system-auth.md) — every Touch ID surface on macOS and
  how to reduce prompt fatigue without weakening anything: 1Password's four unlock/authorization
  settings, `pam_tid.so` via `/etc/pam.d/sudo_local`, `pam-reattach` for tmux, keychain ACLs, and
  what Touch ID does *not* protect. Read when the goal is "stop asking me for my password".

## Verified state of this machine (2026-08-08)

| Piece | State |
| --- | --- |
| 1Password app | `1password@beta` cask; one account, `my.1password.com` |
| `op` | 2.38.1-beta.01, `/opt/homebrew/bin/op`; config at `~/.config/op` |
| `op` sign-in | ✅ working interactively. ⚠ `op whoami` **always fails from a Claude Code Bash call** — see below; that is not a misconfiguration |
| 1Password MCP | ✅ on (2026-09-04). Claude Code **user scope**, so every project; `/Applications/1Password.app/Contents/MacOS/1password-mcp`. ⚠ Environments only — eight tools, none of which returns a secret *value*. Not a vault client |
| Shell plugins | `gh` and `linode-cli`, as fish functions under `functions/wrappers/` — **not** `plugins.sh`. ⚠ The `brew` wrapper was **removed 2026-07-30**: `HOMEBREW_GITHUB_API_TOKEN` buys nothing since Homebrew 4 moved metadata to the JSON API, and it cost a 1Password prompt on the most-used command here. `~/.config/op/plugins/brew.json` is orphaned state; `op plugin clear brew` |
| SSH agent | on; `~/.ssh/config` sets `IdentityAgent`, and `conf.d/op.fish` exports `SSH_AUTH_SOCK` |
| Keys served | **six** — DigitalOcean, UniFi, Proxmox, Git, Home Assistant, Linode. ⚠ exactly at the common `MaxAuthTries 6` limit |
| `agent.toml` | `~/.config/1Password/ssh/agent.toml` → `vault = "Development"` only. ⚠ A 2026-08-08 named-item ordering attempt served only its first item in this app build, so do not repeat it without a fail-safe `ssh-add -l` check |
| SSH bookmarks | `~/.ssh/1Password/config` generated but holds only `Match all`; not yet included |
| Commit signing | `gpg.format=ssh`, `op-ssh-sign`, `commit.gpgsign=true`, `tag.gpgsign=true`; key fingerprint matches the agent's *Git SSH* entry |
| Local verification | `gpg.ssh.allowedSignersFile = ~/.config/git/allowed_signers` ✅ (file created) |
| GnuPG | 2.5.21; `~/.gnupg` created (0700) with `gpg-agent.conf` → `pinentry-touchid`, agent running. **No key exists**, so the Touch ID path is untested |
| pinentry | ⚠ `gpgconf` resolves to `/opt/homebrew/opt/pinentry/bin/pinentry`, a **symlink to `pinentry-curses`** — a TTY prompt. Bypassed by the explicit `pinentry-program` |
| Touch ID for sudo | ✅ **on** (2026-07-30). `/etc/pam.d/sudo_local` = `pam_reattach` optional, then `pam_tid.so` sufficient. ⚠ Interactive `sudo` only — see `touchid-system-auth.md` §3.1 |
| `pam-reattach` | **installed** (1.3, `/opt/homebrew/lib/pam/pam_reattach.so`) — it is a PAM module, so `command -v` finds nothing |
| Plaintext secrets | ✅ `conf.d/secrets.fish` was retired; development tokens come from the 1Password Environment or direct `op://` references at agent launch. The plaintext token written by `linode-cli` browser setup was removed from `~/.config/linode-cli` on 2026-08-08 |

⏳ = outstanding. Re-verify before relying on any row — this table is a snapshot, not a live check.

## Agent development credentials

⚠ **Per-MCP-server `op run` wrapping is impossible for plugin-bundled servers.** The `github` plugin
ships an **HTTP** MCP server whose config interpolates `Authorization: Bearer
${GITHUB_PERSONAL_ACCESS_TOKEN}` from the *Claude process environment*. Codex's direct Context7 MCP
server reads `CONTEXT7_API_KEY` from the Codex process environment. Claude's Context7 connector is
authenticated server-side and needs no local token. The agent process must carry any locally consumed
values because the relevant server config is not ours to wrap.

The mechanism is a **1Password Environment** resolved at launch by a fish wrapper:

```fish
# ~/.config/fish/functions/wrappers/claude.fish
op run --no-masking --environment $__op_claude_env -- \
    /opt/homebrew/bin/bun "$XDG_CONFIG_HOME/scripts/internal/agent-credential-broker.mjs" \
    supervise claude $argv
```

One authorization prompt per session; nothing on disk; variables edited in the 1Password GUI. The
Environment ID is an opaque identifier, not a secret, and lives in `conf.d/op.fish`.

Codex uses the same Environment for tools it launches, while retaining its own ChatGPT OAuth login:

```fish
# ~/.config/fish/functions/wrappers/codex.fish
op run --no-masking --environment $__op_codex_env -- \
    /opt/homebrew/bin/bun "$XDG_CONFIG_HOME/scripts/internal/agent-credential-broker.mjs" \
    supervise codex $argv
```

The Linode PAT remains one 1Password item rather than being copied into that Environment.
`conf.d/op.fish` stores only its `op://` reference. Both launch wrappers export it as
`LINODE_CLI_TOKEN`. Humans use `functions/wrappers/linode-cli.fish`, which delegates to the installed
1Password shell plugin.

⚠ **Agent CLI authentication, verified with Codex CLI 0.147.0 and Claude Code 2.1.232 on
2026-08-14.** The launch wrappers start `scripts/internal/agent-credential-broker.mjs` inside the
initial `op run`. The broker keeps the resolved Linode and scoped Cloudflare tokens in memory,
removes them from the agent environment, and exposes only a mode-0600 Unix socket. Session-local
`linode-cli` and `cf` shims forward arguments to the official binaries through that socket.

```sh
linode-cli linodes view 102470771 --json
cf zones list --name hogdani.sh
```

The one launch-time `op run` may request Touch ID. Neither CLI calls `op` again during that agent
session, so 1Password's ten-minute CLI idle expiry does not interrupt long work. The socket and
broker disappear when the agent exits; no resolved credential is written to disk or exposed to the
agent environment. The third-party Linode MCP and its `LINODE_API_TOKEN` path were removed.

The two `cg-test-ord-01` SSH hosts use a mode-0600 OpenSSH control socket under
`$XDG_CACHE_HOME/ssh/control` with `ControlPersist 12h`. The first connection may need 1Password SSH
approval; later connections reuse that authenticated transport without another key-signing request.

The Cloudflare MCP uses its own OAuth login. Inside a wrapped agent session, bare `cf` uses the
in-memory broker. Outside one, inject the scoped DNS token from 1Password for one command only:

```sh
env CLOUDFLARE_API_TOKEN='op://Development/cloudflare commongrounds acme/credential' \
  op run -- cf zones list --name hogdani.sh
```

Do not export the resolved token into shell state. With `cf` 0.6.0, `cf auth whoami` reports
`tokenValid: false` for this scoped token even though token verification and an authenticated zone
read succeed. Test the intended read operation instead of treating `whoami` as authoritative.

⚠ **`GH_TOKEN` and `GITHUB_PERSONAL_ACCESS_TOKEN` are both required** and must hold the same value:
`gh` reads the former, the GitHub MCP plugin interpolates the latter. That is not a duplication bug.

⚠ Fish functions and `plugins.sh` aliases **cannot** reach Claude Code — its Bash tool is a
non-interactive login zsh (`~/.zprofile` yes, `~/.zshrc` no, aliases never expand). Conversely,
`GIT_CONFIG_GLOBAL`/`CLAUDE_CONFIG_DIR` *are* visible there, inherited from the fish process that
launched `claude`.

### ⚠ Two traps that both look like a broken 1Password setup

**`op whoami` fails from any agent Bash call, always.** Desktop-app integration authenticates by
raising a biometric prompt; a Claude Code Bash call has **no tty on fd 0, 1 or 2**, so `op` cannot
prompt and reports `[ERROR] account is not signed in`. This is indistinguishable from *Integrate with
1Password CLI* being disabled, and it cost a wrong diagnosis on 2026-07-28. **Never conclude `op` is
unconfigured from an agent-side check** — ask the user to run `op whoami` in their own terminal.

**`op run` masking breaks any TUI child, including `claude` and `codex`.** Masking scans the child's
stdout/stderr for secret values, which means replacing those fds with pipes. Claude Code probes for a
tty to decide whether it can draw a TUI; with a piped stdout it silently switches to `--print` mode
and exits with:

```text
Error: Input must be provided either through stdin or as a prompt argument when using --print
```

⚠ **`op run -- /usr/bin/tty` does not detect this** — `tty` reports on *stdin*, which `op run` leaves
alone, so the test passes while stdout is still a pipe. Use `--no-masking` for any interactive or
full-screen child. Masking is still worth keeping for ordinary CLIs (`firecrawl`), where output could
plausibly contain a secret.

## Where does a secret go?

| Kind of secret | Storage | Consumption |
| --- | --- | --- |
| SSH private key | 1Password `SSH Key` item | SSH agent socket; never exported to disk |
| Git commit signature | same SSH key | `op-ssh-sign` (`gpg.format = ssh`) |
| Project env var (`.env`) | 1Password **Environment** | mounted `.env`, or `op run --environment` |
| One-off API token for a script | 1Password item | `op read op://…` or `op run` with `op://` refs |
| Token an interactive shell needs | 1Password item | `op run --` wrapper, **not** a `-gx` export |
| Credential for a supported CLI | 1Password item | shell plugin (`op plugin init <cli>`) |
| GPG passphrase | macOS login keychain | pinentry-touchid, guarded by Touch ID |
| Anything at all | — | **never** a literal in a dotfile, script or config |

Prefer the option higher in that table when two would work: a mounted Environment beats `op run`
beats `op read` in a subshell, because each step down widens the window in which the plaintext
exists.

## Non-negotiables

`.claude/skills/auth/SKILL.md` carries the always-on subset. The short version:

1. **Never write a credential literal** into any file — use an `op://` reference, `op run`, or a
   mounted Environment. This includes "temporary" values and test fixtures.
2. **Never read, print, copy or `cat`** `~/.config/fish/conf.d/secrets.fish` or
   `~/.config/yt-dlp/cookies.txt`. Their *existence* and *names* are in scope; their contents are not.
3. **Never run a command that prints a resolved secret to the terminal** (`op read`, `op run
   --no-masking`, `gpg --export-secret-keys`, `security find-generic-password -w`) — the output lands
   in the transcript. Redirect to a consumer, or ask the user to run it.
4. **Never export a private key** from 1Password to disk to "make something work". Fix the client
   config instead — [1password-ssh-git.md](references/1password-ssh-git.md) lists what each client
   supports.
5. **Ask before changing an auth path that could lock the user out** — `~/.ssh/config`, PAM files,
   `gpg-agent.conf`, the agent config. Show the diff first.

## Verifying a change

```sh
op whoami                                            # cli auth works
op account list                                      # accounts known to the app
SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l
                                                     # keys the agent actually offers
ssh -T git@github.com                                # agent auth end-to-end
ssh -G github.com | grep -i identityagent            # what ssh_config resolves to
git config --get-regexp '^(gpg|commit|user\.signing)' # signing config as git sees it
gpgconf --list-dirs homedir                          # where gpg will look
gpgconf --list-components | grep pinentry            # which pinentry gpg-agent will launch
gpg-connect-agent reloadagent /bye                   # apply gpg-agent.conf changes
security find-generic-password -s 'GnuPG'            # keychain entry exists (prints metadata only)
```

⚠ `git config` from a Bash tool call needs `GIT_CONFIG_GLOBAL=~/.config/git/.gitconfig
GIT_CONFIG_SYSTEM=/dev/null` — those are exported by fish, and Bash tool calls run under zsh.

## Gotchas that cost time

- ⚠ **`op run` loses the race with the shell.** `MY_VAR=op://… op run -- echo $MY_VAR` expands
  `$MY_VAR` before `op` substitutes. Export the reference first, or run the consumer in a subshell.
- ⚠ **`IdentityAgent` beats `SSH_AUTH_SOCK`** for clients that read `ssh_config`, and many GUI
  clients read neither. Check the compatibility notes before blaming the agent.
- ⚠ **First obtained value wins in `ssh_config`.** `Include` lines and specific `Host` blocks belong
  at the *top* of `~/.ssh/config`; `Host *` defaults belong at the bottom.
- ⚠ **`agent.toml`'s mere existence overrides the default**, even when empty. This machine's file
  limits the agent to the `Development` vault — a key in any other vault is silently unavailable.
- ⚠ **`pinentry-touchid -fix` is dangerous here.** It `rm`s whatever path `gpgconf` reports for
  pinentry and symlinks it to pinentry-mac. On this machine that path is
  `/opt/homebrew/opt/pinentry/bin/pinentry` — the **real binary inside the Cellar**, not a symlink.
  Set `pinentry-program` in `gpg-agent.conf` instead; never run `-fix`.
- ⚠ **OpenSSH has no XDG support.** `~/.ssh/config` is hardcoded, but `Include` accepts `~` and
  environment variables — so a two-line stub that includes `~/.config/ssh/config` gets the config
  into `~/.config` with no symlink. `~/.ssh` still has to exist for keys and `known_hosts`.
- ⚠ **A mounted Environment `.env` is a FIFO, not a file.** It reads once per open, is never on
  disk, and confuses tools that stat or re-read it. Git shows it as modified until the previously
  tracked `.env` is deleted *and committed*.
- ⚠ **Environments and the `--environment` flag are beta** and need `op` ≥ 2.33.0-beta.02. The
  installed beta CLI qualifies; a switch back to the stable cask would break every such call.

---

*Source of truth for authentication, secrets and credential management on this machine — update it
when the stack changes, and add newly discovered behaviour to the matching reference in the same turn.*
