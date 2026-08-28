# CLAUDE.md

Guidance for Claude Code and Codex in this repository.

⚠ Every `SKILL.md` links docs in an adjacent `references/`. Read **all** that could plausibly bear
on the task — floors, not menus.

## Read this first: the repo IS `~/.config`

**Edit `~/.config` directly — that is the repository**, tracked in place since 2026-07-29, public at
**github.com/hogdanish/dotfiles**. No manager, no mirror, no deploy step. Never create a `config/`
subdirectory, copy files "into the repo", or treat any path here as a staging copy.

⚠ **`.gitignore` is an allowlist** — an anchored `/*` then explicit `!` re-includes, so anything new
defaults to *ignored*. Adding a config means adding one `!` line; `git check-ignore -v <path>` says
which rule decided. Two traps that have each cost a cycle:

- A bare `*` instead of `/*` matches at every depth, and git never descends into an excluded
  directory — every `!foo/**` beneath it silently never fires.
- **No trailing comments.** `#` opens a comment only at line start, so `/fish/fish_variables  # note`
  is one literal pattern matching nothing.

Untracked on purpose (`README.md` explains each): `raycast/`, `op/`, `homebrew/`,
`yt-dlp/cookies.txt`, `fish/fish_variables`, `claude/`.

⚠ **`$CLAUDE_CONFIG_DIR` is `$XDG_STATE_HOME/claude`, not `~/.config/claude`** — transcripts,
history and vendored plugins are state, deliberately outside this repo. Authored config lives in
`claude-code/` and is symlinked back by `scripts/link-claude.fish`; `~/.config/claude` is only a
compatibility symlink. ⚠ A `/config` rewrite of `settings.json` can replace that symlink with a real
file and silently detach it from version control — `scripts/audit-config.fish` checks for this.

## The claude-code/ layout

**`rules/`** — user-level, loaded in every project on this machine. Path-scoped (free until a
matching file is touched): `gdscript.md` (`**/*.gd`), `fish.md` (`**/*.fish`),
`interactive-scripts.md` (script files — the gum trigger, scoped 2026-08-16). Unscoped and kept lean
on purpose: `notify.md` (when to reach Ethan via `PushNotification`). ⚠ Unlike skills, `rules/` is
symlinked **as a directory** — a new rule needs no `link-claude.fish` run.

**`hooks/`** — user-level, wired from `claude-code/settings.json` by absolute path, so they fire in
every project. `fish-validate.sh` fires on every `.fish` write anywhere. ⚠ It is not symlinked and
must not be. `brewfile-validate.sh` stays project-scoped in `.claude/hooks/`. ⚠ A `caffeinate.sh`
`SessionStart`/`SessionEnd` keep-awake hook was **deleted 2026-08-27** — do not reintroduce it.

**`skills/`** — user-level, loaded everywhere (unlike `.claude/skills/`, which loads only inside
this repo): `godot`, `fish`, `gum`, `linode-cli`, `orbstack`. `fish` and `gum` live here rather than
in `.claude/` because neither is repo-specific. All five are listed and model-invocable —
`disable-model-invocation: true` was dropped **2026-08-27**, because hiding them meant relying on
always-on CLAUDE.md pointers to get them read at all. Deleted: `prose` (2026-08-16) and `toolbox`
(2026-08-17), skill and rule each.

- ⚠ Symlinked **one directory at a time**: `$CLAUDE_CONFIG_DIR/skills/` is a namespace any installer
  may write into, and linking it wholesale would drag foreign output into a public repo.
- ⚠ Symlinked skills **do** load (verified against Claude Code 2.1.220); one that fails to appear
  has a broken link. `audit-config.fish` fails on a dangling skill link.
- ⚠ **Vendor skills belong in a plugin, not here** — a third party's skills are its to version. The
  payload sits in `$CLAUDE_CONFIG_DIR/plugins/` (untracked state) and only the enable flag lands in
  the tracked `settings.json`, which `claude plugin install` writes through the symlink, so the
  declaration version-controls itself. A hand-authored copy goes stale (the brief `firecrawl` one
  proved it).

**`codex/`** — Codex-specific TOML only. Codex does not separate config from state, so live
`~/.codex/` stays untracked and links back here: `config.toml` and `*.config.toml` profiles into
`codex/`, `AGENTS.md` into `claude-code/CLAUDE.md`, and each `~/.agents/skills/<name>` into
`claude-code/skills/`. Run `scripts/link-codex.fish` after adding a global skill. Codex's base
config exposes Context7 and the Godot LSP/editor MCP in every session (editor calls still need an
open project). Symmetrically, Claude Code owns this repo's project instructions and skills: root
`AGENTS.md` symlinks to `.claude/CLAUDE.md`, `.agents/skills/<name>` to each `.claude/skills/` dir.

**Cloudflare tooling: on by default for Claude Code, still `--infra`-gated for Codex.** It was gated
for both agents 2026-08-16 and **ungated for Claude Code 2026-08-28** — `settings.json` sets
`cloudflare@cloudflare: true`, so the skills and the `cloudflare-api` MCP server load in every
project, `~/Projects/commongrounds` included (nothing there overrides `enabledPlugins`). ⚠ The
context weight is trimmed by `deniedMcpServers`, which blocks the plugin's other four servers
(`cloudflare-docs`, `-bindings`, `-builds`, `-observability`) — remove an entry there to gain one
back. `functions/wrappers/claude.fish` still swallows `--infra` as a no-op so the flag never reaches
claude as an unknown option; `functions/wrappers/codex.fish` keeps the real gate, since Codex's base
config still disables the plugin and its `cloudflare-api` server. There is deliberately **no** Linode
MCP or infrastructure profile; agents use `linode-cli` and SSH. In every session the wrapper resolves
infrastructure credentials once and a session-scoped broker holds the Linode and Cloudflare CLI
tokens in memory for the agent's lifetime.

**Firecrawl: on by default for Claude Code as of 2026-08-28.** `settings.json` sets
`firecrawl@claude-plugins-official: true`, so its ten skills and the `/skill-gen` command load in
every project, `~/Projects/commongrounds` included (nothing there overrides `enabledPlugins`).
⚠ It ships **no MCP server** — the skills are wrappers over the `firecrawl` CLI (`npm
"firecrawl-cli"`, in the Brewfile), which is why the deferred-tool pin below buys it nothing: the
standing cost is ten skill descriptions in every system prompt, not tool schemas. ⚠ Auth reaches it
through the *process environment*, not `functions/wrappers/firecrawl.fish` — that function is fish's
and never reaches an agent (Bash tool calls are non-interactive zsh). `FIRECRAWL_API_KEY` lives in
the `Claude Code` 1Password Environment that `wrappers/claude.fish` mounts, and the Bash tool
inherits it; launch claude any other way and every firecrawl skill fails on a missing key. ⚠ The
skills advertise themselves over the built-in `WebFetch`/`WebSearch` ("use this instead of
WebFetch"), and the Firecrawl API is metered — enabling it globally moves routine web reads onto
paid credits.

**Deferred tools are pinned on** — `wrappers/claude.fish` exports `ENABLE_TOOL_SEARCH=true`, so tool
*names* go into context up front and a schema is fetched only when it is first needed, rather than
every MCP and plugin schema being inlined every turn. ⚠ This is already Claude Code's default (unset
=> mode `tst` in 2.1.250); the pin exists so the default cannot flip under us. `false`/`0`/`no`/`off`
turns it off, as does `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`. It is process-wide and endpoint-wide,
not per-project — there is no per-repo setting and none is needed. Skills are separate and already
lazy by construction: only each `SKILL.md`'s name and description sit in context until the skill is
invoked.

**`scripts/`** — `bootstrap.sh` (POSIX sh; fish and gum may not exist when it runs),
`link-home.fish`, `link-claude.fish`, `link-codex.fish`, `audit-config.fish`, and the agent session
credential broker with its private `agent-bin/` shims. **Run the audit after anything installs a new
tool**; it names every top-level entry that is neither tracked nor known junk.

**`home/`** — files whose consumers hardcode a `$HOME` path (`zshenv`, `zshrc`, `zprofile`,
`ssh/config`, `gnupg/gpg-agent.conf`), symlinked into place. ⚠ Edit them at `~/.config/home/…`.

## Brewfile and Homebrew

`Brewfile` is the **hand-maintained** software inventory, one terse line of *why* per entry.
**Read it before configuring, recommending, or diagnosing a missing command.** ⚠ Never run
`brew bundle dump --force` over it. The `brewfile` skill owns the file, the comment rules and
Homebrew's own runtime config. **It is kept current in both directions** — installs and removals
update it in the same change, and `brewfile-audit.sh` proves nothing is installed-but-undeclared or
declared-but-gone — so trust it for what exists rather than surveying `brew list`.
`.claude/rules/machine-inventory.md` has the protocol and the ⚠ that being *declared* still is not
proof a given binary resolves today.

**Homebrew updates itself unattended** — the `domt4/autoupdate` tap on a launchd timer, every 12 h,
AC power only, notifying only on failure (`brew autoupdate logs`). ⚠ It runs **without `--sudo`**,
so the `pkg` casks `temurin@25` and `font-sf-pro` must be upgraded by hand. ⚠ **The agent does not
touch the App Store** — `functions/brewup.fish` owns `mas`, and a `NOPASSWD` sudoers rule for it
would be a trivial root escalation. ⚠ Brew's own environment is **not** re-derivable from this repo:
the autoupdate plist, `brew.env` and `/opt/homebrew/etc/npmrc` all live outside it, and only
`brew config` proves what brew actually has set. Every rule and trap, including the two
"only fish exports it" failures and the `HOMEBREW_*` boolean trap:
`brewfile` skill → `references/homebrew-runtime.md`.

**Commits are gated** by `lefthook.yml`: `betterleaks` on staged content, a force-add guard,
`fish -n` + `fish_indent --check`, `ruby -c` on the Brewfile. ⚠ `.git/hooks` is never
version-controlled — `lefthook install` once per clone or none of that exists.

## System facts

⚠ Homebrew auto-updates, so never pin a claim to a patch version — check the live one when it
matters.

| | |
|---|---|
| macOS | 27.x Golden Gate (public beta), Apple Silicon (arm64) |
| Homebrew prefix | `/opt/homebrew` |
| Login shell | `/bin/zsh` — but see below |
| Interactive shell | **fish 4.8.x** (`/opt/homebrew/bin/fish`) |
| Terminal | **Ghostty 1.3.x-main** (channel `tip`) — the `ghostty` skill |
| Editor | VS Code Insiders (`code-insiders`); `micro` for terminal edits |
| Git identity | `hogdanish`, commits SSH-signed via the 1Password agent |

**zsh is not configured and is not meant to be.** `~/.zshrc` and `~/.zprofile` hold Homebrew's
`shellenv` plus state relocation — `HISTFILE` → `$XDG_STATE_HOME/zsh/history` and
`SHELL_SESSIONS_DISABLE=1`. The one conditional exception is `~/.zshenv`: while an agent broker
socket exists it defines `linode-cli` and `cf` functions reaching the session-local shims.
⚠ `HISTFILE` must stay in `~/.zshrc` (`/etc/zshrc` sets it and runs first); `SHELL_SESSIONS_DISABLE`
must stay in `~/.zprofile` (runs after `/etc/zshrc_Apple_Terminal`). All real shell configuration
lives in fish; Ghostty launches fish explicitly, which is why the login shell was never changed. Do
not port fish config to zsh. ⚠ Bash tool calls run under **zsh** — fish abbreviations and functions
are not available to you.

## The fish config

**Editing any `.fish` file? Invoke the `fish` skill first** — house style, load order, theming, the
bash→fish table, startup-cost budget and every caveat, in full. Its Required-reading rows are
floors, not menus. The `fish` rule is the always-on subset, and
`claude-code/hooks/fish-validate.sh` checks every write. ⚠ A fish behaviour that surprises you or
costs a debugging cycle goes into the skill's `references/caveats.md` in the same turn, verified
against the installed fish — never corrected from memory.

`config.fish` is intentionally **empty**. Everything is eighteen one-concern snippets in `conf.d/`,
sourced before it, sorted digits → `_` → letters:

`_init` · `_shell` · `abbrs` · `brew` · `bun` · `cloudflare` · `colours` · `fzf` · `ghostty` ·
`git` · `gum` · `java` · `keybindings` · `op` · `rust` · `tools` · `uv` · `xdg-apps`

New tool config goes in its own `conf.d/<tool>.fish`, never `config.fish`. `functions/` is filed
**by caller**: top level for commands a human types (`brewup` `cls` `extract` `fishprof` `funcfresh`
`mcpkill` `reload` `up`), `wrappers/` shadows real binaries (`claude` `codex` `firecrawl` `gh`
`linode-cli`), `internal/` for conf.d-called helpers, `grc/`. ⚠ No `alias/` — `alias` is banned in
fish. Decision table: fish skill `config-layout.md` §7.

Three invariants the skill explains and `fishprof`/`set -U --names` prove: **six `conf.d` orderings
are load-bearing** · **startup cost is maintained** (10.0 ms interactive, every tool init cached by
`functions/internal/cachecmd.fish` — measure medians before and after any `conf.d` change) ·
**zero universal variables**.

## Ghostty, gum, laramie

Three skills own these outright — load the relevant one before touching a terminal setting, a
human-facing script, or any file with a colour in it. What is worth knowing *unloaded*:

- **`ghostty`** — ⚠ the config is `ghostty/**config.ghostty**`, not `config` (renamed in 1.2.3).
  ⚠ Channel `tip` with `auto-update = download`: never assert an option exists from memory
  (`ghostty +explain-config <key>`), and run `.claude/skills/ghostty/scripts/ghostty-audit.sh`
  after an upgrade.
- **`gum`** — the source of truth for every script a human runs; the path-scoped
  `interactive-scripts` rule is the trigger and carries the non-negotiables. A hard dependency here,
  but still guard with `type -q gum`.
- **`laramie`** — owns the 32-token OKLCH spec, per-tool bindings, the ANSI-16 contract and syntax
  doctrine. ⚠ Run `bat cache --build` after editing the tmTheme or bat falls back silently and
  `delta.syntax-theme = laramie` breaks with it. ⚠ Where a tool takes ANSI colour *names*
  (`starship.toml`, `LS_COLORS`, `EZA_COLORS`, `LESS_TERMCAP_*`, git log formats), use them — they
  inherit laramie for free. Do not hex-code them.

## Secrets, keys and authentication

**The `auth` skill is the source of truth** for anything credential-shaped — 1Password, `op://`
references, Environments, shell plugins, the SSH agent and `op-ssh-sign` signing, the
GnuPG/pinentry-touchid chain, every Touch ID surface. Load it before writing any config that stores
or consumes a secret; `.claude/rules/security.md` is the always-on subset. Everything configured
here (agent socket, `agent.toml` vault scoping, `allowedSignersFile`, the `gh`/`linode-cli` shell
plugins, the `op run` wrappers) is documented there, along with the traps `op whoami` fails from a
Bash tool call · `op run` needs `--no-masking` for a TUI child · never source `op/plugins.sh` from
fish · `GNUPGHOME` stays at `~/.gnupg`, not XDG.

**No plaintext secrets in any config file** — verified. `conf.d/secrets.fish` is gone, the tokens
live in the `Claude Code` 1Password Environment, and it must **never** be recreated.

⚠ **"No plaintext secrets on this machine" was false and was corrected.** A 2026-07-29 audit found
the retired `secrets.fish` contents captured verbatim in transcripts under
`$CLAUDE_CONFIG_DIR/projects/`; four credentials were rotated. The lesson is structural:
**transcripts are append-only and hostile** — anything `cat`-ed into a session persists after the
file is deleted. Never design a guardrail that assumes that directory is clean; that is why it is
untracked and why `betterleaks` runs on content, not paths. ⚠ Its built-in rules do **not** cover
`fc-`, `ctx7sk-` or `ya29.` — `.betterleaks.toml` adds them; re-verify after
`brew upgrade betterleaks`.

⚠ **There is no `functions/brew.fish` and it must not come back** (removed 2026-07-30). It wrapped
every `brew` in `op plugin run --` for `HOMEBREW_GITHUB_API_TOKEN`, costing a 1Password prompt on
the most-used command — but since Homebrew 4 all metadata comes from the JSON API and the token only
raises rate limits for `brew search --desc` and developer commands. The one thing that would justify
a token, `HOMEBREW_VERIFY_ATTESTATIONS`, is not set and would break the autoupdate job.
`op/plugins/brew.json` is orphaned state; `op plugin clear brew` removes it.

## Git: two layers, on purpose

`git/.gitconfig` carries **aliases** (`lg` `lga` `ll` `branches` `staged` `unstage` `amend` `undo`
`last` `root` `aliases`); `conf.d/abbrs.fish` carries ~40 **abbreviations**. The overlap is
deliberate: an alias works from zsh, scripts and Bash tool calls; an abbr only expands in fish's line
editor — so abbrs expand to *raw git* (portable buffer/history) and aliases exist only where the
payload is a format string (`glg` → `git lg`). ⚠ `gs` and `gcp` are deliberately **not**
abbreviations — they are ghostscript and coreutils' `cp`.

⚠ Three traps: **git word-splits an alias body with shell rules** (a `--format=…` with spaces needs
inner single quotes); **`%(color:auto)` is a `log` placeholder rejected by `for-each-ref`** formats
like `branch --format` (use a real colour name); the `[pretty] lg` format uses **ANSI colour names,
not laramie hexes**, precisely so it inherits the terminal palette.

Two environment overrides in `conf.d/git.fish` change git everywhere:
`GIT_CONFIG_GLOBAL=$XDG_CONFIG_HOME/git/.gitconfig` (why the global config sits at that unusual
path) and `GIT_CONFIG_SYSTEM=/dev/null` (the system config is deliberately disabled).

⚠ **`git/config` is a tracked symlink to `.gitconfig`, and it is load-bearing.** `GIT_CONFIG_GLOBAL`
is a git-CLI variable; **libgit2 ignores it** and looks only at `$XDG_CONFIG_HOME/git/config` or
`~/.gitconfig`. Without the symlink every libgit2-backed tool (`delta`, GUI clients, Rust/Go
bindings) saw no global config at all — that is why the `[delta "laramie"]` block silently never
applied. Do not "tidy" it away.

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

⚠ **Every hex in every theme file must appear in the `laramie` skill's `references/spec.md`** — any
other value is drift, by definition:

```sh
rg -o '`#[0-9a-f]{6}`' .claude/skills/laramie/references/spec.md | tr -d '`' | sort -u > /tmp/spec
rg -o '#[0-9a-fA-F]{6}' <theme file> | tr 'A-F' 'a-f' | sort -u | comm -23 - /tmp/spec  # must be empty
```

⚠ `ghostty +validate-config` silently ignores a nonexistent `--config-file` path, so a typo'd path
looks like success. ⚠ `brew bundle check` only proves the *declared* set is installed — the audit
script proves the file is complete. Ghostty reloads with `cmd+r`; fish with `refresh` (`exec fish`).

## Known gaps and closed items

Open gaps:

1. **fzf has no preview** — `FZF_CTRL_T_OPTS`/`FZF_ALT_C_OPTS` are unset, so `ctrl-t` and `alt-c`
   show bare filenames while `bat` and `eza` sit installed and themed.
2. No completions for `claude`, `code-insiders`, `ffmpeg`, `fswatch`, `scons`, `woff2` — none ships
   one and none has a manpage to derive one from. Re-run `fish_update_completions` after installing
   a new tool.

Closed — **do not re-report**: Touch ID for `sudo` (2026-07-30: `/etc/pam.d/sudo_local` holds
`pam_reattach` optional then `pam_tid.so` sufficient; it does **not** help unattended launchd jobs —
see the `auth` skill's `touchid-system-auth.md` §3.1) · `act` runnable (2026-08-06: OrbStack
supplies the runtime) · the 2026-07-29 fish overhaul (dead abbreviations, tool inits, the laramie
bat theme, universal variables, completions) · the 2026-07-29 system-wide config audit (`JAVA_HOME`,
zoxide XDG, glamour/gum theming, btop/fd/curl/npm/uv/xh configs, stale caches; ⚠ the old note that
`GLAMOUR_STYLE` is "a dead end" was wrong — gh reads it) · "the repo is local-only" (it is public;
`git remote -v` showing `git@github.com:` is the `insteadof` rewrite, not a mistake — pushes
authenticate over SSH through the 1Password agent, and being public is what makes GitHub push
protection a guardrail layer).

⚠ Traps that would undo earlier fixes — **never**: a bare `fish_add_path` (writes a universal
`fish_user_paths`) · an environment variable in a git `include.path` · sourcing
`/opt/homebrew/etc/grc.fish` (writes a universal and `eval`s arguments) · `set -gx HOMEBREW_<X> 0`
(every `HOMEBREW_*` here is `boolean: :set`, so `0` *enables* it) · restoring `functions/brew.fish`
without making `conf.d/brew.fish` use `command brew`. Details: fish skill `caveats.md`, the `auth`
skill, and `brewfile` skill `homebrew-runtime.md`.

## Handle with care in `~/.config`

- `yt-dlp/cookies.txt` — live session cookies. Never read, print or copy it.
- `fish/conf.d/secrets.fish` — retired 2026-07-28; do not recreate it (`auth` skill).
- `fish_variables` — fish-managed state, never hand-edited. It is **empty** and must stay that way.
- `raycast/` — machine-managed extension bundles; nothing there is user-authored.
