# 1Password CLI (`op`)

Distilled from www.1password.dev/cli (2026-07-28), verified against `op` 2.38.1-beta.01 on this
machine. Command structure is noun-verb: `op <command> [subcommand] <flags>`.

## 1. Authentication

Three ways `op` can authenticate. Only the first is set up here.

| Method | How | Use for |
| --- | --- | --- |
| **Desktop app integration** | 1Password → Settings → Developer → *Integrate with 1Password CLI* | everything interactive; unlocks with Touch ID |
| **Service account** | `OP_SERVICE_ACCOUNT_TOKEN` env var | CI, headless, scripts that must not prompt |
| **Manual sign-in** | `op signin` with account details in the config file | legacy; avoid |

With the app integration on, *any* `op` command triggers an authorization prompt (Touch ID, Apple
Watch, or account password) and establishes a **session bound to the terminal window/tab**.

**Session lifetime** — the session ends when any of these happen:

- 1Password locks
- 10 minutes of inactivity
- 12 hours elapse
- `op signout` in that terminal, or `op signout --all` anywhere

Within a live session, every subsequent `op` call *and* every shell-plugin invocation runs without
re-prompting. That is the whole trick to a low-friction setup: keep 1Password unlocked, and the
prompts collapse to roughly one per terminal.

`OP_BIOMETRIC_UNLOCK_ENABLED=true|false` toggles the app integration for a shell without changing
app settings. `op account use --account <addr>` (beta) sets a default account for the session.

⚠ `op` is Touch-ID-gated but **not** process-gated: anything running in an authorized terminal can
read every vault the account can reach. Scope with a service account when that matters.

## 2. Config directories

Defaults to `${XDG_CONFIG_HOME}/op`, else `~/.config/op`. Detection order of precedence:

1. `--config <dir>`
2. `OP_CONFIG_DIR`
3. `~/.op`
4. `${XDG_CONFIG_HOME}/.op`
5. `~/.config/op`
6. `${XDG_CONFIG_HOME}/op`

This machine: `XDG_CONFIG_HOME=$HOME/.config` (set in `conf.d/_init.fish`), so `~/.config/op`,
containing `config` and `op-daemon.sock`. Nothing to configure.

## 3. Secret references (`op://`)

```
op://<vault>/<item>/[<section>/]<field>
op://<vault>/<item>/[<section>/]<file-name>        # file attachment
```

- **Case-insensitive.** Allowed characters: `a-z A-Z 0-9 - _ .` and space. Quote any reference
  containing a space. Any component with an unsupported character must be referenced by its **ID**.
- **IDs are more stable than names** — an item ID changes only when the item moves vaults, and ID
  lookups are faster. Names are more readable; pick per situation.
- **Variables interpolate**: `op://$APP_ENV/mysql/password` resolves `$APP_ENV` from the environment,
  which is how one `.env` template serves dev and prod.

### Query parameters

```
op://<vault>/<item>/<field>?attribute=<attr>
op://<vault>/<item>/<field>?ssh-format=openssh
```

Field attributes: `type`, `value`, `title`, `id`, `purpose`, `otp`.
File attributes: `content`, `size`, `id`, `name`, `type`.

`?attribute=otp` on a one-time-password field prints a live TOTP code — the clean way to script MFA.
`?ssh-format=openssh` prints a private key in OpenSSH format; ⚠ that defeats the point of keeping
keys in 1Password, so only for a key that must be handed to a client that cannot use the agent.

### Getting a reference

```sh
op item get GitHub --format json --fields password | jq .reference   # one field
op item get GitHub --format json | jq '.fields[].reference'          # every field
```

The desktop app also offers *Copy Secret Reference* on any field's ⌄ menu (requires the CLI
integration to be on).

## 4. Resolving references at runtime

### `op read` — one secret to stdout

```sh
op read "op://Development/GitHub/credentials/personal_token"
op read --out-file token.txt "op://…"        # write to a file instead
```

⚠ Never run bare `op read` in an agent session: the plaintext lands in the transcript. Pipe it into
the consumer, or use `op run`.

### `op run` — secrets as env vars for one process

```sh
op run -- <command>
op run --env-file=./node.env -- node app.js
op run --environment <environmentID> -- ./script.sh      # beta, 1Password Environments
op run --no-masking -- printenv DB_PASSWORD              # unmask (avoid)
```

`op run` scans the environment (and any `--env-file`) for `op://` references, resolves them, and
runs the command in a subprocess with the real values present only for its lifetime. Secrets the
subprocess prints to stdout/stderr are masked as `<concealed by 1Password>` unless `--no-masking`.

**Precedence when a variable comes from several places** (highest first):

1. `--environment` (1Password Environments)
2. `--env-file`
3. inherited shell environment

Last `--env-file` wins among env files; last `--environment` wins among Environments.

⚠ **The expansion race.** In `MY_VAR=op://… op run -- echo "$MY_VAR"`, the shell expands `$MY_VAR`
before `op` ever runs. Either export the reference on a previous line, or force expansion inside the
subprocess:

```sh
MY_VAR=op://vault/item/field op run --no-masking -- sh -c 'echo "$MY_VAR"'
```

In fish, export with `set -x NAME "op://vault/item/field"` (no `=`).

### `op inject` — fill a template file

```sh
op inject --in-file config.yml.tpl --out-file config.yml
echo "token: op://dev/GitHub/token" | op inject
```

Reads stdin / `-i`, writes stdout / `-o`, replacing every `op://` reference found. The `.tpl` file is
safe to commit; the output is not — treat it as generated and gitignore it.

## 5. Shell plugins

Biometric authentication for third-party CLIs, so their credentials live in 1Password instead of
`~/.config/gh/hosts.yml`, `~/.aws/credentials` and friends. Bash, Zsh and fish are supported;
60+ CLIs including `gh`, `aws`, `brew`, `stripe`, `terraform`, `vercel`, OpenAI, and Claude Code.

```sh
op plugin list                    # available plugins
op plugin init gh                 # configure credentials + scope for one CLI
op plugin inspect gh              # what is configured, and where
op plugin run -- gh <args>        # run without the alias
op plugin clear gh [--all]        # remove a configuration
```

### ⚠ `plugins.sh` is POSIX shell and **cannot be sourced from fish**

Verified 2026-07-28 after initializing `gh`, `brew` and `claude`. `op plugin init` writes
`<op-config-dir>/plugins.sh` — here `~/.config/op/plugins.sh` — containing **POSIX shell function
definitions**, regardless of which shell invoked it:

```sh
export OP_PLUGIN_ALIASES_SOURCED=1
brew() {
    op plugin run -- brew "$@"
}
gh() {
    op plugin run -- gh "$@"
}
```

`fish -n` on that file fails: `command substitutions not allowed in command position`. So the
`source` line `op plugin init` prints — and which its `--help` suggests adding to
`~/.config/fish/config.fish` — **would error on every fish start.** Upstream's fish support means
`op plugin run` works under fish, not that `plugins.sh` is fish.

**The fish path is one autoloaded function per CLI**, mirroring what `plugins.sh` would have defined:

```fish
# ~/.config/fish/functions/gh.fish
function gh --wraps gh --description 'gh with a github pat supplied by the 1password shell plugin'
    op plugin run -- gh $argv
end
```

No recursion: `op plugin run` resolves the real binary from `$PATH` in a fresh process, where the
fish function does not exist. Plugin *state* lives in `~/.config/op/plugins/*.json` and needs no
shell wiring at all.

⚠ **A `brew` function is visible to `conf.d/*.fish`**, because autoloaded functions resolve during
`conf.d` sourcing. Any startup snippet that calls `brew` (e.g. a cached `brew shellenv`) must use
`command brew`, or every shell start becomes a 1Password authorization prompt.

⚠ **Aliases and functions from `plugins.sh` can never serve Claude Code.** Its Bash tool runs a
*non-interactive login* zsh: `~/.zprofile` is read, `~/.zshrc` is not, and aliases do not expand.
Claude Code gets its credentials from the process environment instead — see
[1password-environments.md](1password-environments.md) §6.

### ⚠ The `claude` plugin switches Claude Code to API billing

`op plugin list` offers a `claude` plugin under vendor **Anthropic**, supplying an `api_key`
credential (`credential_type: api_key` in `~/.config/op/plugins/claude.json`). Claude Code on this
machine authenticates with an **OAuth subscription** — `oauthAccount` in `.claude.json`, tokens in
the login keychain as `Claude Code-credentials`. Injecting `ANTHROPIC_API_KEY` moves usage to
pay-per-token API billing. Do not initialize it; `op plugin clear claude` removes it.

**Credential scope**, chosen during `init` (most specific wins):

1. terminal-session default (`Prompt me for each new terminal session`)
2. directory default (`Use automatically when in this directory or subdirectories`)
3. global default (`Use as global default on my system`)

Directory scope is how you switch between work/personal or dev/prod credentials by `cd`-ing —
group projects by environment and set a default at each environment root.

**Field naming matters.** A plugin injects specific env vars from specific field names; e.g. the
GitHub plugin maps field `Token` → `GH_TOKEN` and optional `Host` → `GH_HOST`. If the item was
created by hand, the field labels must match or `op` prompts to rename them.

⚠ Only run plugins shipped with `op` or written yourself — never drop binaries in
`~/.op/plugins/local`. Shipped plugins are reviewed by 1Password; local ones are not.

After adopting a plugin, delete the credential file it replaces (`rm ~/.config/gh/hosts.yml`).

## 6. Service accounts

A token-scoped identity for non-interactive use. Create at
`start.1password.com/developer-tools/infrastructure-secrets/serviceaccount`, then:

```fish
set -x OP_SERVICE_ACCOUNT_TOKEN <token>    # itself an op:// reference in practice
```

Scope each to the minimum vaults or Environments needed. Use for CI, cron, containers, and any
script that must not raise a Touch ID prompt. ⚠ The token *is* a bearer credential — it must come
from 1Password (`op run`), never from a dotfile.

## 7. Environment variables

| Variable | Effect |
| --- | --- |
| `OP_ACCOUNT` | default account (shorthand, sign-in address, account ID, user ID) |
| `OP_SERVICE_ACCOUNT_TOKEN` | authenticate as a service account |
| `OP_BIOMETRIC_UNLOCK_ENABLED` | `true`/`false` — toggle the desktop app integration |
| `OP_CONFIG_DIR` | override config directory |
| `OP_FORMAT` | `human-readable` (default) or `json` |
| `OP_CACHE` | `false` disables the daemon's encrypted in-memory cache (on by default on UNIX) |
| `OP_DEBUG` | `true` enables debug output |
| `OP_ISO_TIMESTAMPS` | ISO 8601 / RFC 3339 timestamps |

Global flags mirror these: `--account`, `--cache`, `--config`, `--debug`, `--format`, `--session`,
`--no-color`, `--encoding` (`gbk`, `shift-jis`).

## 8. Command surface

`account` · `completion` · `connect` · `document` · `environment` (beta) · `events-api` · `group` ·
`inject` · `item` · `plugin` · `read` · `run` · `service-account` · `signin` · `signout` · `update` ·
`user` · `vault` · `whoami`

Frequently useful:

```sh
op whoami                                   # who am I authenticated as
op vault list                               # vaults + IDs
op item get "work email"                    # item detail
op item get X --fields label=username,label=password
op item create --category ssh --title "My SSH Key"   # generates an Ed25519 key
op environment read <environmentID>         # beta: env vars as KEY=VALUE
op update                                   # check for CLI updates
```

`op item create` with sensitive values should use a JSON template rather than command-line
arguments — arguments land in shell history and process listings.

**Shell completion for fish:**

```fish
op completion fish | source
```

## 9. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `connectionreset`, "couldn't connect to the app" | System Settings → General → Login Items → *Allow in background* for 1Password; restart the app |
| `LostConnectionToApp` | enable *Keep 1Password in the menu bar* |
| `op signin` doesn't list an account | the account isn't added to the desktop app |
| Prompted for account password instead of Touch ID | Touch ID isn't enabled for unlocking 1Password itself |
| A plugin doesn't fire | `plugins.sh` isn't sourced in this shell; check `op plugin inspect <cli>` |

The 1Password app keeps an encrypted CLI activity log: Developer → View CLI. Turn it off with
*Record and display activity* if unwanted.

## 10. Related

- 1Password for VS Code (`1Password.op-vscode`) detects plaintext secrets in open files, saves them
  to 1Password, and replaces them with `op://` references — a practical migration tool for
  `secrets.fish`. Requires the CLI + app integration. Not installed here.
- Everything Environments-specific lives in
  [1password-environments.md](1password-environments.md); everything SSH/Git in
  [1password-ssh-git.md](1password-ssh-git.md).
