# CLAUDE.md

Guidance for Claude Code and Codex in this repository.

⚠ Every `SKILL.md` links docs in an adjacent `references/`. Read **all** that could plausibly bear
on the task — floors, not menus.

## Read this first: the repo IS `~/.config`

**Edit `~/.config` directly — that is the repository**, a git repo tracked in place since
2026-07-29. No manager, no mirror, no deploy step. Do not create a `config/` subdirectory, copy
files "into the repo", or treat any path here as a staging copy.

⚠ **Nothing is tracked unless `.gitignore` names it.** The allowlist opens with an anchored `/*`
and re-includes explicitly, so anything new defaults to *ignored*. Adding a config means adding one
`!` line; `git check-ignore -v <path>` says which rule decided. Two traps that have cost a cycle:

- A bare `*` instead of `/*` matches at every depth, and git never descends into an excluded
  directory — every `!foo/**` beneath it silently never fires.
- **`.gitignore` has no trailing comments.** `#` opens a comment only at line start, so
  `/fish/fish_variables  # note` is one literal pattern matching nothing.

Untracked on purpose: `raycast/`, `op/`, `homebrew/`, `yt-dlp/cookies.txt`, `fish/fish_variables`,
`claude/`. `README.md` explains each.

⚠ **`$CLAUDE_CONFIG_DIR` is `$XDG_STATE_HOME/claude`, not `~/.config/claude`.** Transcripts,
history, and vendored plugins are state, deliberately outside this repo. The authored config lives
in `claude-code/` and is symlinked back from the state directory by `scripts/link-claude.fish`;
`~/.config/claude` is only a compatibility symlink. ⚠ If Claude Code ever *rewrites*
`settings.json` (via `/config`) it can replace that symlink with a real file and silently detach it
from version control — `scripts/audit-config.fish` checks for exactly this.

## The claude-code/ layout

**`rules/`** — user-level rules, loaded in every project on this machine. Path-scoped (cost
nothing until a matching file is touched): `gdscript.md` (`**/*.gd`), `fish.md` (`**/*.fish`),
`interactive-scripts.md` (script files — the gum trigger, scoped 2026-08-16). Unscoped
(always loaded, kept lean on purpose): `toolbox.md` (the CLI-toolbox core: the manifest comment
`brewfile-audit.sh` checks, the better-defaults table, the Context7 mandate, traps, not-installed
list; per-domain depth moved to the `toolbox` skill 2026-08-16), `context-architecture.md` (the
CLAUDE.md/rules/skills/references doctrine for any repo), `notify.md` (`cc-notify`). ⚠ Adding or
removing a CLI formula means updating the `toolbox.md` manifest *and* the `toolbox` skill in the
same change. ⚠ Unlike skills, `rules/` is symlinked **as a directory** — a new rule needs no
`link-claude.fish` run.

**`hooks/`** — user-level hooks. `fish-validate.sh` is the only one, wired from
`claude-code/settings.json` by absolute path, so it fires on every `.fish` write anywhere. ⚠ It is
not symlinked and must not be. `brewfile-validate.sh` and `toolbox-nudge.sh` stay project-scoped in
`.claude/hooks/`.

**`skills/`** — user-level skills, loaded everywhere on this machine (unlike `.claude/skills/`,
which loads only inside this repo): `godot`, `toolbox` (split out of the toolbox rule 2026-08-16),
`fish`, `gum`, `linode-cli`, `orbstack`. The `prose` skill and rule were deleted 2026-08-16.
⚠ **Five of these set `disable-model-invocation: true`** (all but `godot`), so they never appear in
the skill listing: the always-on CLAUDE.md/rule pointers instruct a direct Read of
`claude-code/skills/<name>/SKILL.md` instead. Keep that scheme — it is the context-cost design, not
an accident. `fish` and `gum` are user-level because neither is repo-specific, even though their
references document `~/.config/fish` in depth.
Skills are symlinked into `$CLAUDE_CONFIG_DIR/skills/` **one directory at a time**, because that
namespace is one any installer may write into — linking it wholesale would drag foreign output into
a public repo. ⚠ Symlinked skills **do** load (verified against Claude Code 2.1.220); if one fails
to appear the link is broken, not unsupported. `audit-config.fish` fails on a dangling skill link.

⚠ **Vendor skills belong in a plugin, not here.** A third party's skills are its to version: the
plugin payload sits in `$CLAUDE_CONFIG_DIR/plugins/` (state, untracked) and only the enable flag
lands in the tracked `claude-code/settings.json` — `claude plugin install` writes that flag through
the symlink, so the declaration version-controls itself. Hand-authoring a copy of a vendor skill
goes stale (the brief `firecrawl` copy proved it). The one thing a plugin cannot carry is
machine-specific contradiction of its own docs — those overrides live in the `toolbox` skill.

**`codex/`** holds only Codex-specific TOML. Codex does not separate config from state, so live
`~/.codex/` stays untracked; its `config.toml` and `*.config.toml` profiles link back into
`codex/`, its `AGENTS.md` links to `claude-code/CLAUDE.md`, and each global skill under
`~/.agents/skills/` links directly to `claude-code/skills/`. This sharing is local to this repo.
Run `scripts/link-codex.fish` after adding a global skill.

Codex's base `config.toml` exposes Context7, Godot LSP, and Godot editor MCP in every session
(editor-backed calls still need an open Godot project). **Cloudflare tooling is gated behind
`--infra`** (2026-08-16, both agents): the launch wrappers intercept the flag and re-enable the
cloudflare plugin — Claude Code via a `--settings` overlay on `enabledPlugins`, Codex via `-c`
overrides — while the base configs keep it disabled to spare ordinary sessions the context weight.
There is deliberately no Linode MCP or infrastructure profile; agents use the official `linode-cli`
and SSH. The launch wrapper resolves infrastructure credentials once, then a session-scoped broker
keeps Linode and Cloudflare CLI tokens in memory for the agent's lifetime — in every session,
`--infra` or not.

Claude Code is the canonical owner of this repository's project instructions and skills. Root
`AGENTS.md` symlinks to `.claude/CLAUDE.md`, and `.agents/skills/<name>` links each directory from
`.claude/skills/` individually.

**`scripts/`** holds `bootstrap.sh` (POSIX sh — fish and gum may not exist when it runs),
`link-home.fish`, `link-claude.fish`, `link-codex.fish`, `audit-config.fish`, and the agent session
credential broker with its private `agent-bin/` shims. **Run the audit after anything installs a
new tool**; it names every top-level entry that is neither tracked nor known junk.

**`home/`** holds files whose consumers hardcode a `$HOME` path — `zshenv`, `zshrc`, `zprofile`,
`ssh/config`, `gnupg/gpg-agent.conf` — symlinked into place. ⚠ Edit them at `~/.config/home/…`.

## Brewfile and unattended updates

The `Brewfile` is **hand-maintained**, the machine's software inventory — each entry says why it is
installed. **Read it before configuring, recommending, or diagnosing a missing command.** ⚠ Never
run `brew bundle dump --force` over it. The `brewfile` skill owns it;
`.claude/rules/machine-inventory.md` has the protocol and the ⚠ that it records *declared intent*,
not verified state.

**Homebrew updates itself unattended.** The `domt4/autoupdate` tap is declared with
**command-scoped** trust (`trusted: {command: "autoupdate"}`, not `trusted: true`). A launchd agent
runs update/upgrade/cleanup every 12 h, AC power only, notifying only on failure. Logs:
`brew autoupdate logs`.

⚠ It runs **without `--sudo` on purpose** — that flag raises a pinentry password dialog with no
Touch ID path at unpredictable times. The price: the `pkg` casks **`temurin@25`** and
**`font-sf-pro`** cannot upgrade in the background; upgrade them by hand
(`brew upgrade --cask temurin@25`), where Touch ID covers `sudo`.

⚠ **The agent does not touch the App Store.** `mas update` requires root and hangs without a GUI
session. `functions/brewup.fish` covers it: `brew update`/`upgrade` → `sudo mas upgrade` only when
`mas outdated` is non-empty → `brew cleanup`. It replaced the `brewup` abbreviation (an abbr cannot
hold the conditional). ⚠ Never "fix" this with a `NOPASSWD` sudoers rule for `mas` — it lives in
user-writable `/opt/homebrew/bin`, so that is a trivial root escalation.

⚠ **Only fish exports `XDG_CONFIG_HOME`, and brew resolves user config from it.** A brew launched
by launchd, cron, or a GUI app looked in `~/.homebrew`, found no `trust.json`, and silently treated
every third-party tap as untrusted. Fix: `/opt/homebrew/etc/homebrew/brew.env` holds
`HOMEBREW_XDG_CONFIG_HOME=/Users/ethan/.config`, written by `bootstrap.sh` step 2 (must run before
`brew bundle`). ⚠ That file accepts only `HOMEBREW_*`, `SUDO_ASKPASS`, and proxy variables — a
plain `XDG_CONFIG_HOME=` line is dropped silently, and `HOMEBREW_USER_CONFIG_HOME` is on brew's
forbidden list. Verify with `env -u XDG_CONFIG_HOME brew trust`, never plain `brew trust`.

⚠ **npm had the identical failure, closed 2026-07-30.** Only fish exports
`NPM_CONFIG_USERCONFIG`, so npm outside fish never reads `npm/npmrc` and fell back to `~/.npm`. The
floor is the global config `/opt/homebrew/etc/npmrc` holding `cache=` (bootstrap step 4), read
regardless of launch context. Precedence means it can only be the fallback. `logs-dir` follows the
cache. The path is not owned by the `node` formula, so upgrades keep it.

⚠ **`brew autoupdate` state is not re-derivable from this repo** — plist and script live in
`~/Library`. To change a flag: `brew autoupdate delete` **then** `start` (a bare `start` silently
reuses the old script). ⚠ `start` bakes a snapshot of `PATH`, `HOMEBREW_CACHE`, `HOMEBREW_LOGS`,
`HOMEBREW_DEVELOPER`, `HOMEBREW_NO_ANALYTICS`, `HOMEBREW_CASK_OPTS`, and `SUDO_ASKPASS` into that
script — run it from a shell whose environment you want; nothing else is inherited.

**Commits are gated** by `lefthook.yml`: `betterleaks` on staged content, a force-add guard,
`fish -n` + `fish_indent --check`, `ruby -c` on the Brewfile. ⚠ `.git/hooks` is never
version-controlled — `lefthook install` once per clone or none of that exists.

## System facts

| | |
|---|---|
| macOS | 27.0 (build 26A5388g), Apple Silicon (arm64) |
| Homebrew prefix | `/opt/homebrew` |
| Login shell | `/bin/zsh` — but see below |
| Interactive shell | **fish 4.8** (`/opt/homebrew/bin/fish`) |
| Terminal | **Ghostty 1.3.2-main** (channel `tip`) — the `ghostty` skill |
| Editor | VS Code Insiders (`code-insiders`); `micro` for terminal edits |
| Git identity | `hogdanish`, commits SSH-signed via the 1Password agent |

**zsh is not configured and is not meant to be.** `~/.zshrc` and `~/.zprofile` hold Homebrew's
`shellenv` plus state relocation — `HISTFILE` → `$XDG_STATE_HOME/zsh/history` and
`SHELL_SESSIONS_DISABLE=1`. The one conditional exception is `~/.zshenv`: while an agent broker
socket exists, it defines `linode-cli` and `cf` functions that reach the session-local shims.
⚠ `HISTFILE` must stay in `~/.zshrc` (`/etc/zshrc` sets it and runs first);
`SHELL_SESSIONS_DISABLE` must stay in `~/.zprofile` (runs after `/etc/zshrc_Apple_Terminal`). All
real shell configuration lives in fish; Ghostty launches fish explicitly, which is why the login
shell was never changed. Do not port fish config to zsh. Bash tool calls run under **zsh** — fish
abbreviations and functions are not available to you.

## The fish config

**Writing or editing any `.fish` file? Read `claude-code/skills/fish/SKILL.md` first** — the house
style guide, references, load order, theming, and the bash→fish table. Its Required-reading rows
are floors, not menus. The `fish` rule carries the always-on subset;
`claude-code/hooks/fish-validate.sh` checks every `.fish` write.

⚠ **The fish skill is expected to grow.** A fish behaviour that surprises you or costs a debugging
cycle goes into `claude-code/skills/fish/references/caveats.md` in the same turn, verified against
fish 4.8.1 — never corrected from memory.

`fish/config.fish` is intentionally empty. Everything lives in `conf.d/`, sourced **before**
`config.fish`, sorted digits → `_` → letters. Eighteen snippets, one concern each:

`_init` · `_shell` · `abbrs` · `brew` · `bun` · `cloudflare` · `colours` · `fzf` · `ghostty` ·
`git` · `gum` · `java` · `keybindings` · `op` · `rust` · `tools` · `uv` · `xdg-apps`

⚠ Six orderings are **load-bearing** (the skill explains each): `brew` first · `bun` and `uv` after
`brew` · `colours` before `fzf` · `fzf` before `tools` · atuin last inside `tools.fish`. ⚠ One
concern per file — a bare `return` ends the whole file. ⚠ **Startup cost is maintained**: 10.0 ms
interactive, every tool init cached by `functions/internal/cachecmd.fish`. Measure with `fishprof`
before and after any `conf.d` change — compare medians, single runs vary. ⚠ `java.fish` hardcodes
the JDK path (the `/usr/libexec/java_home` fork alone cost 5.7 ms). ⚠ `tools.fish` seeds
`ATUIN_SESSION` with builtins to preempt the `atuin uuid` fork (4.5 ms); the skill's `caveats.md`
explains why that is safe and what to re-check after an atuin upgrade.

New tool config goes in its own `conf.d/<tool>.fish`, never `config.fish`.

`functions/` is filed **by caller**: top level for commands a human types (`brewup` `cls` `extract`
`fishprof` `funcfresh` `mcpkill` `reload` `up`); `wrappers/` shadows real binaries (`claude`
`codex` `firecrawl` `gh` `linode-cli`); `internal/` for conf.d/fish-called helpers; `grc/`. ⚠ No
`alias/` — `alias` is banned in fish. ⚠ All four subdirectories are *prepended* to
`$fish_function_path`, so a basename may appear in exactly one. ⚠ A new subdirectory is invisible
until `exec fish` (`_init.fish`'s glob runs once). Decision table: fish skill `config-layout.md`
§7.

## Ghostty, gum, laramie

**Ghostty** — the `ghostty` skill is the source of truth; load it before touching
`~/.config/ghostty/` or answering anything about terminal appearance, keys, fonts, or `$TERM`.
⚠ The config is `ghostty/**config.ghostty**`, not `config` (renamed 1.2.3). Two paths under
`~/Library/Application Support/com.mitchellh.ghostty/` load **after** the XDG ones and would
silently win; one exists and is empty — keep it that way. ⚠ Channel `tip` with
`auto-update = download`: never assert an option exists from memory — `ghostty +explain-config
<key>`; after an upgrade run `.claude/skills/ghostty/scripts/ghostty-audit.sh`.
`conf.d/ghostty.fish` sources the shell integration manually (`test -r`-guarded) — that is what
gives nested fish shells the integration.

**gum** — `claude-code/skills/gum/SKILL.md` is the source of truth for every script a human runs;
the path-scoped `interactive-scripts` rule is the trigger and carries the non-negotiables. gum
**0.17.0** is a
hard dependency here — still guard with `type -q gum`. `conf.d/gum.fish` carries the laramie
palette (~24 `GUM_*` variables; gum has no config file) and is deliberately **not**
interactive-guarded. ⚠ There is no `glow`, and gum does not read `GLAMOUR_STYLE` — `gh` uses that
one, gum uses `GUM_FORMAT_THEME`; both point at `~/.config/glamour/laramie.json` and move together.

**laramie** — the `laramie` skill owns the 32-token OKLCH spec, per-tool binding tables, ANSI-16
contract, and syntax doctrine. Load it before touching any file with a colour in it. Two facts
worth knowing unloaded: ⚠ `bat cache --build` after editing the tmTheme, or bat falls back
silently and `delta.syntax-theme = laramie` breaks with it. ⚠ Where a tool accepts ANSI colour
*names* (`starship.toml`, `LS_COLORS`, `EZA_COLORS`, `LESS_TERMCAP_*`, git log formats), use them —
they inherit laramie for free. Do not hex-code them.

## Secrets, keys and authentication

**The `auth` skill is the source of truth** for anything credential-shaped — 1Password (`op`,
`op://` references, Environments, shell plugins), the SSH agent and `op-ssh-sign` signing, the
GnuPG/pinentry-touchid chain, every Touch ID surface. Load it before writing any config that
stores or consumes a secret. `.claude/rules/security.md` is the always-on subset.

**No plaintext secrets in any config file** — verified. `conf.d/secrets.fish` is gone; the tokens
live in the `Claude Code` 1Password Environment; **never recreate it**. Never read, print, or copy
`~/.config/yt-dlp/cookies.txt`; never run a command whose output would be a resolved secret.

⚠ **"No plaintext secrets on this machine" was false and was corrected.** A 2026-07-29 audit found
the retired `secrets.fish` contents captured verbatim in Claude Code transcripts under
`$CLAUDE_CONFIG_DIR/projects/`; four credentials were rotated. The lesson is structural:
**transcripts are append-only and hostile** — anything `cat`-ed into a session persists after the
file is deleted. Never design a guardrail that assumes that directory is clean; that is why it is
untracked and why `betterleaks` runs on content, not paths.

⚠ The built-in betterleaks rules do **not** cover `fc-`, `ctx7sk-`, or `ya29.` —
`.betterleaks.toml` adds them; re-verify after `brew upgrade betterleaks`.

Configured: the SSH agent (`IdentityAgent` + `SSH_AUTH_SOCK` from `conf.d/op.fish`), `agent.toml`
scoped to the `Development` vault, `op-ssh-sign` with a working `allowedSignersFile`, the `gh` and
`linode-cli` shell plugins as fish wrappers, `functions/wrappers/{claude,codex,firecrawl}.fish` for
`op run`, `gpg-agent.conf` → `pinentry-touchid`.

⚠ **There is no `functions/brew.fish` and it must not come back** (removed 2026-07-30). It wrapped
every `brew` in `op plugin run --` for `HOMEBREW_GITHUB_API_TOKEN`, costing a 1Password prompt on
the most-used command — but since Homebrew 4 all metadata comes from the JSON API and the token
only raises rate limits for `brew search --desc` and developer commands. The one thing that would
justify a token, `HOMEBREW_VERIFY_ATTESTATIONS`, is not set and would break the autoupdate job.
`op/plugins/brew.json` is orphaned state; `op plugin clear brew` removes it.

⚠ `op whoami` **always fails from a Bash tool call** — no tty, no biometric prompt; that is not
misconfiguration, ask the user to check in their terminal. ⚠ `op run` needs `--no-masking` for any
TUI child — masking pipes stdout and Claude Code drops to `--print` mode. ⚠ Never source
`~/.config/op/plugins.sh` from fish — it is POSIX shell. ⚠ **`GNUPGHOME` stays at `~/.gnupg`**,
not XDG: only fish would export it, so launchd, GUI apps, cron, and zsh would each create a second
empty homedir.

## Git: two layers, on purpose

`git/.gitconfig` carries **aliases** (`lg` `lga` `ll` `branches` `staged` `unstage` `amend` `undo`
`last` `root` `aliases`); `conf.d/abbrs.fish` carries ~40 **abbreviations**. The overlap is
deliberate: an alias works from zsh, scripts, and Bash tool calls; an abbr only expands in fish's
line editor — so abbrs expand to *raw git* (portable buffer/history) and aliases exist only where
the payload is a format string (`glg` → `git lg`).

⚠ Three traps: **git word-splits an alias body with shell rules** (a `--format=…` with spaces needs
inner single quotes); **`%(color:auto)` is a `log` placeholder rejected by `for-each-ref`** formats
like `branch --format` (use a real colour name); the `[pretty] lg` format uses **ANSI colour names,
not laramie hexes**, precisely so it inherits the terminal palette.

⚠ `gs` and `gcp` are deliberately **not** abbreviations — they are ghostscript and coreutils' `cp`.

Two environment overrides in `conf.d/git.fish` change git everywhere:

- `GIT_CONFIG_GLOBAL=$XDG_CONFIG_HOME/git/.gitconfig` — why the global config sits at the unusual
  path `git/.gitconfig`.
- `GIT_CONFIG_SYSTEM=/dev/null` — the system config is deliberately disabled.

⚠ **`git/config` is a tracked symlink to `.gitconfig`, and it is load-bearing.**
`GIT_CONFIG_GLOBAL` is a git-CLI variable; **libgit2 ignores it** and looks only at
`$XDG_CONFIG_HOME/git/config` or `~/.gitconfig`. Without the symlink every libgit2-backed tool
(`delta`, GUI clients, Rust/Go bindings) saw no global config at all — that is why the
`[delta "laramie"]` block silently never applied. Do not "tidy" it away.

⚠ Both *are* set in Bash tool calls (`claude` is launched from fish, inheriting its environment).
Agent tools use non-interactive zsh: `~/.zshenv` is read, `~/.zshrc` is not, aliases never expand —
fish functions and `op plugin` aliases cannot serve Claude Code, though exported variables and the
conditional agent functions in `~/.zshenv` can. When correctness must not depend on launch context:

```sh
GIT_CONFIG_GLOBAL=~/.config/git/.gitconfig GIT_CONFIG_SYSTEM=/dev/null git config --list --show-origin
```

## Verifying a change

```sh
fish -n <f>.fish; fish_indent --check <f>.fish            # parses, and is canonically formatted
fish -c 'set -U --names'                                  # must print nothing — zero universals
script -q /dev/null fish --login --interactive -c exit    # a real startup, on a tty
fish -c fishprof                                          # startup cost, attributed line by line
git config --file ~/.config/git/.gitconfig --list         # gitconfig parses
ghostty +validate-config                                  # ghostty config is valid
.claude/skills/ghostty/scripts/ghostty-audit.sh           # ...and the ghostty skill matches the build
python3 -m json.tool ~/.config/micro/settings.json        # micro configs are JSON
python3 -m json.tool ~/.config/xh/config.json             # ...so is xh's
fastfetch --list-config-paths                             # ⚠ confirms which single config is read
brew bundle check --file=Brewfile                         # everything declared is installed
.claude/skills/brewfile/scripts/brewfile-audit.sh         # ...and everything installed is declared
scripts/link-claude.fish --dry-run                        # authored claude config is linked in
brew config | rg HOMEBREW_                                # ⚠ what brew ACTUALLY has set, not the file
env -u XDG_CONFIG_HOME brew trust                         # taps resolve outside fish (launchd, cron)
brew autoupdate status                                    # the unattended-update agent is running
```

New-config spot checks (none has a `--validate` of its own):

```sh
fd . /tmp --type=file                             # honours ~/.config/fd/ignore (no node_modules)
curl -sso /dev/null https://example.com/nope; echo $?   # 22, i.e. curlrc's `fail` is live
uv run --no-project python -c 'import sys; print(sys.executable)'  # a uv-managed python, not brew's
script -q /dev/null btop                          # theme loads; ⚠ btop needs a tty, `q` to quit
duti -x json                                      # what actually handles .json right now
fish -lc 'printf "# hi\n" | CLICOLOR_FORCE=1 gum format' | rg -q '73;235;240'  # laramie markdown
```

⚠ **Every hex in every theme file must appear in the `laramie` skill's `references/spec.md`** —
any other value is drift, by definition:

```sh
rg -o '`#[0-9a-f]{6}`' .claude/skills/laramie/references/spec.md | tr -d '`' | sort -u > /tmp/spec
rg -o '#[0-9a-fA-F]{6}' <theme file> | tr 'A-F' 'a-f' | sort -u | comm -23 - /tmp/spec  # must be empty
```

⚠ `ghostty +validate-config` silently ignores a nonexistent `--config-file` path, so a typo'd path
looks like success. ⚠ `brew bundle check` only proves the *declared* set is installed — the audit
script proves the file is complete. Ghostty reloads with `cmd+r`; fish with `refresh` (`exec
fish`).

## Known gaps and closed items

Open gaps:

1. **fzf has no preview** — `FZF_CTRL_T_OPTS`/`FZF_ALT_C_OPTS` are unset, so `ctrl-t` and `alt-c`
   show bare filenames while `bat` and `eza` sit installed and themed.
2. No completions for `claude`, `code-insiders`, `ffmpeg`, `fswatch`, `scons`, `woff2` — none
   ships one and none has a manpage to derive one from. Re-run `fish_update_completions` after
   installing a new tool.

Closed — do not re-report: Touch ID for `sudo` (2026-07-30: `/etc/pam.d/sudo_local` holds
`pam_reattach` optional then `pam_tid.so` sufficient; it does **not** help unattended launchd jobs
— see the `auth` skill's `touchid-system-auth.md` §3.1) · `act` runnable (2026-08-06: OrbStack
supplies the runtime) · the 2026-07-29 fish overhaul items (dead abbreviations, tool inits, the
laramie bat theme, universal variables, completions) · the 2026-07-29 system-wide config audit
items (`JAVA_HOME`, zoxide XDG, glamour/gum theming, btop/fd/curl/npm/uv/xh configs, stale caches;
⚠ the old note that `GLAMOUR_STYLE` is "a dead end" was wrong — gh reads it) · "the repo is
local-only" (public at **github.com/hogdanish/dotfiles**; `git remote -v` showing `git@github.com:`
is the `insteadof` rewrite, not a mistake — pushes authenticate over SSH through the 1Password
agent, and being public is what makes GitHub push protection a guardrail layer).

⚠ Traps that would undo earlier fixes: **never** a bare `fish_add_path` (writes a universal
`fish_user_paths`) · **never** an environment variable in a git `include.path` · **never** source
`/opt/homebrew/etc/grc.fish` (writes a universal and `eval`s arguments) · **never**
`set -gx HOMEBREW_<X> 0` — every `HOMEBREW_*` here is `boolean: :set`, so `0` *enables* it (that is
how `HOMEBREW_DEVELOPER 0` silently ran developer mode until 2026-07-30); the only "off" is
omitting the line, and `brew config` proves it · **never** restore `functions/brew.fish` without
making `conf.d/brew.fish` use `command brew`. Details: fish skill `caveats.md` and the `auth`
skill.

## Handle with care in `~/.config`

- `yt-dlp/cookies.txt` — live session cookies. Never read, print, or copy it.
- `fish/conf.d/secrets.fish` — retired 2026-07-28; do not recreate it (`auth` skill).
- `fish_variables` — fish-managed state, never hand-edited. It is **empty** and must stay that way.
- `raycast/` — machine-managed extension bundles; nothing there is user-authored.
