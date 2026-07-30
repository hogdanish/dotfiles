# CLAUDE.md

Guidance for Claude Code in this repository.

⚠ Every `SKILL.md` links docs in an adjacent `references/`. Read **all** that could plausibly bear
on the task — floors, not menus.

## Read this first: the repo IS `~/.config`

**Edit `~/.config` directly — and that is the repository.** Since 2026-07-29 `~/.config` is a git
repo tracked in place. There is no manager, no mirror, no templating, and no deploy step: editing
`~/.config/fish/conf.d/git.fish` *is* editing the repo. Do not create a `config/` subdirectory, do
not copy files "into the repo", and do not treat any path here as a staging copy.

⚠ **Nothing is tracked unless `.gitignore` names it.** The allowlist opens with an anchored `/*`
and re-includes explicitly, so the default for anything new is *ignored*. Adding a config means
adding one `!` line; `git check-ignore -v <path>` says which rule decided. Two traps that have
already cost a cycle:

- A bare `*` instead of `/*` matches directory entries at every depth, and git never descends into
  an excluded directory — so every `!foo/**` beneath it silently never fires.
- **`.gitignore` has no trailing comments.** `#` opens a comment only at the start of a line, so
  `/fish/fish_variables  # note` is one literal pattern matching nothing.

Untracked on purpose: `raycast/`, `op/`, `homebrew/`, `yt-dlp/cookies.txt`, `fish/fish_variables`,
and all of `claude/` except `CLAUDE.md`, `settings.json` and `rules/`. `README.md` explains each.

`scripts/` holds `bootstrap.sh` (POSIX sh — fish and gum may not exist when it runs),
`link-home.fish`, and `audit-config.fish`. **Run the audit after anything installs a new tool**; it
names every top-level entry that is neither tracked nor known junk.

`home/` holds the files that cannot live under `~/.config` because their consumer hardcodes a
`$HOME` path — `zshrc`, `zprofile`, `ssh/config`, `gnupg/gpg-agent.conf` — symlinked into place.
⚠ Edit them at `~/.config/home/…`; the `$HOME` paths are symlinks.

The `Brewfile` is **hand-maintained**, not generated, and doubles as this machine's **software
inventory** — each entry says why it is installed. **Read it before configuring any tool,
recommending one, or diagnosing a missing command.** ⚠ Never run `brew bundle dump --force` over it;
that destroys every comment and category. The `brewfile` skill owns it;
`.claude/rules/machine-inventory.md` has the protocol and the ⚠ that it records *declared intent*,
not verified state — confirm a binary with `type -q` before depending on it.

**Commits are gated** by `lefthook.yml`: `betterleaks` on staged content, a force-add guard, `fish -n`
+ `fish_indent --check`, and `ruby -c` on the Brewfile. ⚠ `.git/hooks` is never version-controlled —
`lefthook install` is required once per clone or none of that exists.

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
`shellenv` plus two lines of *state relocation* — `HISTFILE` → `$XDG_STATE_HOME/zsh/history` and
`SHELL_SESSIONS_DISABLE=1` — and nothing else. That is deliberately not configuration: it stops zsh
scattering `~/.zsh_history` and `~/.zsh_sessions` through `$HOME`, and changes no behaviour.
⚠ `HISTFILE` must stay in `~/.zshrc` (`/etc/zshrc` sets it and runs first) and
`SHELL_SESSIONS_DISABLE` must stay in `~/.zprofile` (`/etc/zshrc` sources
`/etc/zshrc_Apple_Terminal` and runs *after* it). All real shell configuration lives in fish. Ghostty launches fish explicitly
(`command = /opt/homebrew/bin/fish --login --interactive`), which is why the login shell was
never changed. Do not "helpfully" port fish config to zsh, and remember that Bash tool commands
here run under **zsh**, so fish abbreviations and functions are not available to you.

## How the fish config loads

**Writing or editing any `.fish` file? The `fish` skill is the source of truth** — the mandatory house
style guide, the language and builtin references, load order, theming, and a bash→fish translation
table. Load it before you start, not after, and read **every** reference in its Required-reading row —
those rows are floors, not menus. `.claude/rules/fish.md` carries the always-on subset;
`.claude/hooks/fish-validate.sh` checks every `.fish` write.

⚠ **The fish skill is expected to grow.** When a fish behaviour surprises you or costs a debugging
cycle, append it to `.claude/skills/fish/references/caveats.md` in the same turn and fix whichever
reference was wrong. Rediscovering a caveat is a documentation defect, not bad luck. Verify against
fish 4.8.1 first — never correct a reference from memory.

`~/.config/fish/config.fish` is intentionally empty (documentation only). Everything lives in
`conf.d/`, which fish sources **before** `config.fish`, sorted `digits` → `_` → `letters`. Fifteen
snippets, one concern each, in load order:

`_init` · `_shell` · `abbrs` · `brew` · `bun` · `colours` · `fzf` · `ghostty` · `git` · `gum` ·
`java` · `keybindings` · `op` · `tools` · `xdg-apps`

⚠ Five orderings are **load-bearing** and the skill explains each: `brew` first to touch `$PATH` ·
`bun` after `brew` (which resets `fish_user_paths`) · `colours` before `fzf` · `fzf` before `tools` ·
atuin last inside `tools.fish`. ⚠ **One concern per
file** — a bare `return` ends the whole file. ⚠ **Startup cost is maintained, not accidental**:
**10.0 ms** interactive and 3.7 ms non-interactive (was 63.1 → 16.4 → 10.0), every tool init cached by
`functions/cachecmd.fish`. Measure with `fishprof` before and after any `conf.d` change — ⚠ it reports
a *single* run, and startups vary by a few ms with occasional 3× outliers, so compare medians.
⚠ `java.fish` hardcodes the JDK path rather than calling `/usr/libexec/java_home` — that fork alone
measured **5.7 ms**. ⚠ `tools.fish` seeds `ATUIN_SESSION` with builtins to preempt the `atuin uuid`
fork inside atuin's own init (4.5 ms, formerly 31% of startup); the skill's `caveats.md` explains why
that is safe and what to re-check after an atuin upgrade. The largest line left is fish's own
`fish_config theme choose`, which has no opt-out.

New tool config goes in its own `conf.d/<tool>.fish`, not into `config.fish`.

## The terminal (Ghostty)

**The `ghostty` skill is the source of truth** — the full 206-option reference, the keybind system and
all 85 actions, the CLI, shell integration, terminfo/SSH, themes, AppleScript, and the VT API. Load it
before touching `~/.config/ghostty/` or answering anything about terminal appearance, keys, fonts or
`$TERM`.

⚠ The config is `~/.config/ghostty/**config.ghostty**`, not `config` (renamed in 1.2.3). Two paths
under `~/Library/Application Support/com.mitchellh.ghostty/` load **after** the XDG ones and would
silently win; one exists and is empty — keep it that way.

⚠ The **`tip`** channel with `auto-update = download`, so options appear between releases. Never
assert one exists from memory: `ghostty +explain-config <key>`. After an upgrade run
`.claude/skills/ghostty/scripts/ghostty-audit.sh`, which fails on binary/skill drift.

`conf.d/ghostty.fish` sources the integration manually and `test -r`-guarded — the manual source is
what gives *nested* fish shells the integration. The seam is documented in the `ghostty` skill;
edits to the `.fish` side are the `fish` skill's job.

## Interactive scripts and terminal output (gum)

**The `gum` skill is the source of truth** for every script or function a human runs — all 13 commands
with every flag and `GUM_*` variable, the contract (TUI on **stderr**, result on **stdout**, exit codes
`0`/`1`/`124`/`130`), `style`+`join` layout, glamour markdown, and the fish idioms where command
substitution shreds multi-line gum output. **Load it before writing anything that prompts, asks, lists,
waits, or prints for a human.** `.claude/rules/interactive-scripts.md` carries the always-on subset and
the primitive→gum table (`read`→`gum input`, `echo`→`gum log`, `tput`→`gum style`, …).

gum **0.17.0** (Brewfile line 36) is a hard dependency here — still guard it with `type -q gum`.
`conf.d/gum.fish` carries the laramie palette (~24 `GUM_*` variables; gum has no config file), so a
plain `gum choose` is already themed — pass colours only for semantic meaning. ⚠ It is deliberately
**not** interactive-guarded: scripts are exactly what needs it.

⚠ `gum confirm --default` is **`true`**: destructive confirmations need `--default=false`. ⚠ There is
no `glow`, and **gum does not read `GLAMOUR_STYLE`** — `gh` uses that one, gum uses
`GUM_FORMAT_THEME`; both point at `~/.config/glamour/laramie.json` and both must move together.

## Secrets, keys and authentication

**The `auth` skill is the source of truth** for anything credential-shaped — 1Password (`op` CLI,
`op://` secret references, Environments, shell plugins), the 1Password SSH agent and `op-ssh-sign`
commit signing, the GnuPG/pinentry-touchid/keychain chain, and every Touch ID surface including
`sudo`. Load it before writing any config that stores or consumes a secret.
`.claude/rules/security.md` carries the always-on subset.

**No plaintext secrets in any *config* file** — verified. `conf.d/secrets.fish` is gone and the
tokens live in the `Claude Code` 1Password Environment; **never recreate it**. Never read, print or
copy `~/.config/yt-dlp/cookies.txt`, and never run a command whose output would be a resolved secret.

⚠ **The stronger claim "no plaintext secrets on this machine" was false and has been corrected.**
On 2026-07-29 an audit found the full contents of the retired `secrets.fish` — a GitHub
fine-grained PAT, the Firecrawl key and the Context7 key — captured verbatim in Claude Code
transcripts under `$CLAUDE_CONFIG_DIR/projects/`. Those four credentials were rotated. The lesson
is structural, not incidental: **transcripts are append-only and hostile.** Anything `cat`-ed into a
session persists in plaintext long after the file is deleted. Never design a guardrail that assumes
that directory is clean — which is why it is untracked, and why `betterleaks` runs on content rather
than trusting paths.

⚠ The 412 built-in betterleaks rules do **not** cover `fc-` (Firecrawl), `ctx7sk-` (Context7) or
`ya29.`. `.betterleaks.toml` adds them; re-verify after `brew upgrade betterleaks`.

Configured: the SSH agent (`IdentityAgent` + `SSH_AUTH_SOCK` from `conf.d/op.fish`), `agent.toml`
scoped to `Development`, `op-ssh-sign` signing with a working `allowedSignersFile`, the `gh`/`brew`
shell plugins as `functions/{gh,brew}.fish`, `functions/{claude,firecrawl}.fish` for `op run`, and
`gpg-agent.conf` → `pinentry-touchid`. Not yet: Touch ID for `sudo`.

⚠ **`op whoami` always fails from a Bash tool call** — no tty means no biometric prompt. That is not
evidence 1Password is misconfigured; ask the user to check in their own terminal.
⚠ **`op run` needs `--no-masking` for any TUI child** — masking pipes stdout, and Claude Code then
drops to `--print` mode and errors. `op run -- /usr/bin/tty` will not reveal this (it tests stdin).

⚠ **Never source `~/.config/op/plugins.sh` from fish** — it is POSIX shell and fails `fish -n`.
⚠ **`GNUPGHOME` deliberately stays at `~/.gnupg`**, not XDG: only fish would export it, so launchd,
GUI apps, cron and Claude Code's zsh would each create a second, empty homedir.

## Two non-obvious environment overrides

Both are set in `~/.config/fish/conf.d/git.fish` and change how git behaves everywhere:

- `GIT_CONFIG_GLOBAL=$XDG_CONFIG_HOME/git/.gitconfig` — this is why the global config is at the
  unusual path `git/.gitconfig` (git's own default would be `git/config`).
- `GIT_CONFIG_SYSTEM=/dev/null` — the system config is deliberately disabled.

⚠ **Both *are* set in Bash tool calls** — `claude` is launched from fish, so its whole environment is
inherited. The Bash tool's zsh is a *non-interactive login* shell: `~/.zprofile` is read, `~/.zshrc`
is not, and aliases never expand — so fish functions and `op plugin` aliases can never serve Claude
Code, though exported variables can. Set them explicitly when correctness must not depend on how the
session was launched:

```sh
GIT_CONFIG_GLOBAL=~/.config/git/.gitconfig GIT_CONFIG_SYSTEM=/dev/null git config --list --show-origin
```

## The `laramie` theme

A custom Tokyo Night-derived palette, duplicated by hand across every tool because none share a
format. Changing one colour means changing all of these:

- `~/.config/ghostty/themes/laramie` — 16-color palette + bg/fg/cursor/selection
- `~/.config/git/themes.gitconfig` — `[delta "laramie"]` feature block
- `~/.config/micro/colorschemes/laramie-tc.micro`
- `~/.config/bat/themes/laramie.tmTheme` — ⚠ **re-run `bat cache --build` after editing**, or bat
  falls back silently and `delta.syntax-theme = laramie` breaks with it
- `~/.config/atuin/themes/laramie.toml`
- `~/.config/fish/themes/laramie.fish` (hex **with** `#`) + the generated `laramie.theme` (bare hex —
  a `.theme` file is tokenised, so `#` starts a comment). Regenerate with
  `.claude/skills/fish/scripts/gen-fish-theme.fish`
- `~/.config/glamour/laramie.json` — markdown, read by **two** renderers via two variables:
  `GUM_FORMAT_THEME` (`conf.d/gum.fish`) and `GLAMOUR_STYLE` (`conf.d/xdg-apps.fish`, for `gh`)
- `~/.config/fish/conf.d/gum.fish` — ~24 `GUM_*` accent variables; gum has no config file (`gum` skill)
- `~/.config/btop/themes/laramie.theme` — ⚠ `theme[main_bg]` is deliberately **empty**, not
  `#1f2335`; that plus `theme_background = False` in `btop.conf` is what lets Ghostty's
  `background-opacity`/`background-blur` show through instead of an opaque rectangle
- `~/.config/macchina/themes/laramie.toml` — hex, not the named colours macchina also accepts

Core hexes: bg `#1f2335`, fg `#a9b1d6`, red `#f7768e`, green `#9ece6a`, yellow `#e0af68`, blue
`#7aa2f7`, magenta `#bb9af7`, cyan `#7dcfff`, bright-white `#c0caf5`, comment/dim `#414868`.

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
macchina --doctor                                         # every declared readout still resolves
brew bundle check --file=Brewfile                         # everything declared is installed
.claude/skills/brewfile/scripts/brewfile-audit.sh         # ...and everything installed is declared
```

New-config spot checks, none of which have a `--validate` of their own:

```sh
fd . /tmp --type=file                             # honours ~/.config/fd/ignore (no node_modules)
curl -sso /dev/null https://example.com/nope; echo $?   # 22, i.e. curlrc's `fail` is live
uv run --no-project python -c 'import sys; print(sys.executable)'  # a uv-managed python, not brew's
script -q /dev/null btop                          # theme loads; ⚠ btop needs a tty, `q` to quit
duti -x json                                      # what actually handles .json right now
fish -lc 'printf "# hi\n" | CLICOLOR_FORCE=1 gum format' | rg -q '187;154;247'  # laramie markdown
```

⚠ `ghostty +validate-config` silently ignores a nonexistent `--config-file` path, so a typo'd path
looks like success. ⚠ `brew bundle check` only proves the *declared* set is installed — it passes on
a near-empty Brewfile; the audit script is what proves the file is complete.

Ghostty reloads with `cmd+r`; fish with the `refresh` abbreviation (`exec fish`).

## Known gaps

1. **The repo is local-only.** `~/.config` is under git with a full history, but there is no remote
   yet and nothing has been pushed. A disk failure still loses everything — publishing is the
   remaining step.
2. Touch ID for `sudo` is still not configured (`auth` skill). ⚠ `pam-reattach` is installed
   *specifically* for this and currently does nothing; `/etc/pam.d/sudo_local` does not exist.
3. **`act` cannot run** — it needs a container runtime and neither docker nor podman is installed.
   `~/.config/act/actrc` is written and correct, waiting on that dependency.
4. **fzf has no preview.** `FZF_DEFAULT_OPTS` is themed, but `FZF_CTRL_T_OPTS`/`FZF_ALT_C_OPTS` are
   unset, so `ctrl-t` and `alt-c` show bare filenames while `bat` and `eza` sit installed and themed.
5. No completions for `macchina`, `claude`, `code-insiders`, `ffmpeg`, `fswatch`, `scons`, `woff2` —
   none of them ship one and none has a manpage for `fish_update_completions` to derive one from.
   Everything else is covered; re-run `fish_update_completions` after installing a new tool.

**Closed 2026-07-29** by the fish overhaul — do not re-report: dead `cls`/`tre`/`z` abbreviations ·
`starship`/`atuin`/`zoxide`/`fzf` initialisation · `grc` unwired · the missing `laramie` bat theme
(which also broke `delta.syntax-theme`) · `fish_indent --check` failures · the last universal
variable · empty `completions/`.

**Closed 2026-07-29** by the system-wide config audit — do not re-report: `JAVA_HOME` unset ·
zoxide's database outside XDG · `GLAMOUR_STYLE`/`GUM_FORMAT_THEME` unset (glamour themes now
consumed — ⚠ the old note that `GLAMOUR_STYLE` is "a dead end" was **wrong**, gh reads it) · gum
unthemed · btop/macchina/fd/curl/npm/uv/xh/shellcheck/act unconfigured · `LESSKEY` pointing at a
source-format path · stale `~/.npm`, `~/.cache/.bun`, `~/.local/share/lesshst`, `~/.zsh_sessions` ·
zsh history in `$HOME` · `fish_update_completions` covering only system man pages (804 → 1371).

⚠ Traps that would undo earlier fixes: **never** reintroduce a bare `fish_add_path` (it writes a
universal `fish_user_paths`); **never** put an environment variable in a git `include.path`; **never**
source `/opt/homebrew/etc/grc.fish` (it writes a universal and `eval`s arguments). Details and
reproduction live in `fish/references/caveats.md` and the `auth` skill — not here.

## Handle with care in `~/.config`

- `yt-dlp/cookies.txt` — live session cookies. Never read it into context, print it, or copy it
  anywhere in this repo.
- `fish/conf.d/secrets.fish` — **retired 2026-07-28**; do not recreate it (`auth` skill).
- `fish_variables` — fish-managed state, never hand-edited. It is **empty**, and must stay that way:
  anything that lands there is machine state escaping version control.
- `raycast/` — machine-managed extension bundles; nothing there is user-authored.
