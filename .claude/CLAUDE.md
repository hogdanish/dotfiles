# CLAUDE.md

Guidance for Claude Code and Codex in this repository.

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
and `claude/`. `README.md` explains each.

⚠ **`$CLAUDE_CONFIG_DIR` is `$XDG_STATE_HOME/claude`, not `~/.config/claude`.** Transcripts, prompt
history and vendored plugins are state, not config, and are deliberately outside this repo's working
tree. The authored config lives in `claude-code/` and is symlinked back from the state directory by
`scripts/link-claude.fish`; `~/.config/claude` is only a compatibility symlink. ⚠ If Claude Code ever
*rewrites* `settings.json` (via `/config`) it can replace that symlink with a real file and silently
detach it from version control — `scripts/audit-config.fish` checks for exactly this.

`claude-code/rules/` holds the **user-level** rules, which load in every project on this machine, not
just here: `gdscript.md` (scoped to `**/*.gd`), `fish.md` (scoped to `**/*.fish`, moved out of
`.claude/rules/` on 2026-08-11), `toolbox.md` (unscoped — the always-in-context digest of this
machine's CLI toolbox, verified by `brewfile-audit.sh`; the `brewfile` skill owns it),
`interactive-scripts.md` (unscoped — the always-on trigger for the `gum` skill, moved 2026-08-11), and
`context-architecture.md` (unscoped — the doctrine for CLAUDE.md/rules/skills/references/memory in
*any* repo; it replaced the project-scoped `claude-framework` skill on 2026-07-30, whose skill map
described a Godot project this machine does not contain). ⚠ Adding or removing a CLI formula means
updating `toolbox.md` in the same change. ⚠ Unlike skills, `rules/` is symlinked **as a directory**,
so a new rule needs no `link-claude.fish` run.

`claude-code/hooks/` holds the **user-level** hooks. `fish-validate.sh` is the only one, wired from
`claude-code/settings.json` by absolute path (`$HOME/.config/claude-code/hooks/…`), so it fires on
every `.fish` write anywhere on this machine. ⚠ It is not symlinked and must not be — settings.json
names the repo path directly, so there is no link to drift. `brewfile-validate.sh` and
`toolbox-nudge.sh` stay project-scoped in `.claude/hooks/`.

`claude-code/skills/` holds the **user-level** skills — `godot`, `orbstack`, `prose`, `linode-cli`
(the official Akamai Cloud control plane and its paid-resource guardrails; 2026-08-08), and, since
2026-08-11, `fish` and `gum`. ⚠ `fish` and `gum` moved out of `.claude/skills/` because neither is
repo-specific: fish is the shell for every script on this machine and gum is the house toolkit for
every interactive one. Their references still document `~/.config/fish` in depth — that is machine
fact, reachable from any directory, not repo scope.
⚠ Do not confuse them with `.claude/skills/`, which loads only inside this repo; these load
everywhere on this machine. They are symlinked in **one directory at a time**, because
`$CLAUDE_CONFIG_DIR/skills/` is a namespace any installer may write into and linking it wholesale
would either drag that output into a public repo or bury it. ⚠ Symlinked skills **do** load — that
was verified against Claude Code 2.1.220 with a probe skill pointed at `/tmp`, so if one fails to
appear the link is broken, not unsupported. `audit-config.fish` fails on a dangling skill link.

⚠ **Vendor skills belong in a plugin, not here.** The rule that fell out of the Firecrawl work: a
third party's skills are *its* to version, so take them through the plugin system, where the payload
sits in `$CLAUDE_CONFIG_DIR/plugins/` (state, untracked, outside this repo) and only the one-line
enable flag lands in the tracked `claude-code/settings.json`. `claude plugin install` writes that
flag **through the symlink** into the repo, so the declaration version-controls itself and a fresh
clone re-fetches the plugin. Hand-authoring a copy of a vendor's skill — which is what
`claude-code/skills/firecrawl/` briefly was — buys nothing and goes stale. ⚠ The one thing a plugin
cannot carry is machine-specific contradiction of its own docs: Firecrawl's bundled `install.md`
tells the agent to run `firecrawl init` / `setup skills` / `login`, all three of which are wrong
here, so that override lives in `claude-code/CLAUDE.md` instead.

`codex/` holds only **Codex-specific** TOML configuration. Codex does not separate config from state,
so the live `~/.codex/` directory remains untracked. Its `config.toml` and each `*.config.toml`
profile link back into `codex/`; its `AGENTS.md` links to `claude-code/CLAUDE.md`, and each global
skill under `~/.agents/skills/` links directly to `claude-code/skills/`. This sharing is local to
this dotfiles repo. Other projects may use Claude-only skill frontmatter. Vendor skills still belong
in plugins. Run `scripts/link-codex.fish` after adding a global skill, and keep
`scripts/audit-config.fish` able to detect detached or dangling links.

Claude Code remains the canonical owner of this repository's project instructions and skills.
Root `AGENTS.md` symlinks to `.claude/CLAUDE.md`, and `.agents/skills/<name>` links each directory
from `.claude/skills/` individually. That gives Codex the same project-specific guidance without
duplicating it or turning either shared skill namespace into a wholesale directory link.

`scripts/` holds `bootstrap.sh` (POSIX sh — fish and gum may not exist when it runs),
`link-home.fish`, `link-claude.fish`, `link-codex.fish`, and `audit-config.fish`. **Run the audit
after anything installs a new tool**; it names every top-level entry that is neither tracked nor
known junk.

`home/` holds the files that cannot live under `~/.config` because their consumer hardcodes a
`$HOME` path — `zshrc`, `zprofile`, `ssh/config`, `gnupg/gpg-agent.conf` — symlinked into place.
⚠ Edit them at `~/.config/home/…`; the `$HOME` paths are symlinks.

The `Brewfile` is **hand-maintained**, not generated, and doubles as this machine's **software
inventory** — each entry says why it is installed. **Read it before configuring any tool,
recommending one, or diagnosing a missing command.** ⚠ Never run `brew bundle dump --force` over it;
that destroys every comment and category. The `brewfile` skill owns it;
`.claude/rules/machine-inventory.md` has the protocol and the ⚠ that it records *declared intent*,
not verified state — confirm a binary with `type -q` before depending on it.

**Homebrew updates itself unattended.** The `domt4/autoupdate` tap is declared in the Brewfile with
**command-scoped** trust (`trusted: {command: "autoupdate"}`, *not* `trusted: true` — Homebrew 6's tap
gate; this permits only `brew autoupdate`). A launchd agent runs `brew update && brew upgrade
--formula && brew upgrade --cask && brew cleanup` every 12 h, **AC power only**, notifying only on
failure. Logs: `brew autoupdate logs`.

⚠ It is started **without `--sudo` on purpose.** That flag writes a `SUDO_ASKPASS` helper that raises a
pinentry-mac password dialog at unpredictable times, and that dialog has **no Touch ID path** — it is
precisely the intrusion this setup exists to avoid. The price is that the two casks with a `pkg`
artifact, **`temurin@25`** and **`font-sf-pro`**, cannot be upgraded in the background; when a new
version lands that one cask fails and you get an error notification. Upgrade those by hand
(`brew upgrade --cask temurin@25`), where Touch ID covers the `sudo`. Every other cask either
self-updates (`auto_updates true`, skipped because there is no `--greedy`) or needs no root.

⚠ **The agent does not touch the App Store.** `mas update` **requires root** (`mas help update` says
so), so putting it in the launchd job would reintroduce exactly the unattended password prompt this
design removes — and `mas` is additionally known to hang without a GUI session. App Store apps are
therefore updated by **`functions/brewup.fish`**, which is also where the two `pkg` casks get done:
`brew update`/`upgrade` → `sudo mas upgrade` *only when `mas outdated` is non-empty* → `brew cleanup`.
⚠ It replaced the `brewup` abbreviation, because an abbr cannot hold that conditional. ⚠ Do not
"fix" this with a `NOPASSWD` sudoers rule for `mas`: it lives in `/opt/homebrew/bin`, which is
user-writable, so that is a trivial root escalation.

⚠ **Only fish exports `XDG_CONFIG_HOME`, and brew resolves its user config from it.** A brew launched
by launchd, cron or a GUI app therefore looked in `~/.homebrew`, found no `trust.json`, and **silently
treated every third-party tap as untrusted** — the first autoupdate run logged
`Warning: Skipping pinentry-touchid: tap formula is not trusted`. This is the same failure class as
the `GNUPGHOME` decision below, and the fix is `/opt/homebrew/etc/homebrew/brew.env` holding
`HOMEBREW_XDG_CONFIG_HOME=/Users/ethan/.config`, written by `bootstrap.sh` step 2 (it must run before
`brew bundle`, which is what applies the Brewfile's `trusted:` options). ⚠ That file accepts only
`HOMEBREW_*`, `SUDO_ASKPASS` and the proxy variables — a plain `XDG_CONFIG_HOME=` line is dropped
silently, and `HOMEBREW_USER_CONFIG_HOME` is on brew's forbidden-override list. Verify with
`env -u XDG_CONFIG_HOME brew trust`, never with a plain `brew trust`.

⚠ **npm has the identical failure, closed 2026-07-30.** Only fish exports `NPM_CONFIG_USERCONFIG`, so
an npm launched by launchd, a GUI app or Claude Code's zsh never reads `npm/npmrc` **at all** — that
variable is the only thing that says where to look. It fell back to `~/.npmrc`, found nothing, and
cached into `~/.npm`. The floor is the **global** config `/opt/homebrew/etc/npmrc` holding `cache=`,
written by `bootstrap.sh` step 4 and read regardless of launch context. ⚠ Precedence is
cli > env > project > user > global > builtin, so it can only ever be the fallback, never an
override. ⚠ `logs-dir` defaults to `{cache}/_logs`, so pinning the cache moves the logs with it.
⚠ The path is not owned by the `node` formula, so `brew upgrade node` does not clobber it.

⚠ **`brew autoupdate` state is not re-derivable from this repo** — the plist and the generated script
live in `~/Library`. To change a flag you must `brew autoupdate delete` **then** `start`; a bare
`start` silently reuses the existing script and your new flags are ignored. ⚠ `start` bakes a snapshot
of `PATH`, `HOMEBREW_CACHE`, `HOMEBREW_LOGS`, `HOMEBREW_DEVELOPER`, `HOMEBREW_NO_ANALYTICS`,
`HOMEBREW_CASK_OPTS` and `SUDO_ASKPASS` into that script, so run it from a shell whose environment you
actually want — nothing else is inherited, and no other `HOMEBREW_*` reaches the background job.

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
those rows are floors, not menus. `claude-code/rules/fish.md` carries the always-on subset;
`claude-code/hooks/fish-validate.sh` checks every `.fish` write.

⚠ **The fish skill is expected to grow.** When a fish behaviour surprises you or costs a debugging
cycle, append it to `claude-code/skills/fish/references/caveats.md` in the same turn and fix whichever
reference was wrong. Rediscovering a caveat is a documentation defect, not bad luck. Verify against
fish 4.8.1 first — never correct a reference from memory.

`~/.config/fish/config.fish` is intentionally empty (documentation only). Everything lives in
`conf.d/`, which fish sources **before** `config.fish`, sorted `digits` → `_` → `letters`. Eighteen
snippets, one concern each, in load order:

`_init` · `_shell` · `abbrs` · `brew` · `bun` · `cloudflare` · `colours` · `fzf` · `ghostty` · `git` ·
`gum` · `java` · `keybindings` · `op` · `rust` · `tools` · `uv` · `xdg-apps`

⚠ Six orderings are **load-bearing** and the skill explains each: `brew` first to touch `$PATH` ·
`bun` and `uv` after `brew` (which resets `fish_user_paths`) · `colours` before `fzf` · `fzf` before `tools` ·
atuin last inside `tools.fish`. ⚠ **One concern per
file** — a bare `return` ends the whole file. ⚠ **Startup cost is maintained, not accidental**:
**10.0 ms** interactive and 3.7 ms non-interactive (was 63.1 → 16.4 → 10.0), every tool init cached by
`functions/internal/cachecmd.fish`. Measure with `fishprof` before and after any `conf.d` change — ⚠ it reports
a *single* run, and startups vary by a few ms with occasional 3× outliers, so compare medians.
⚠ `java.fish` hardcodes the JDK path rather than calling `/usr/libexec/java_home` — that fork alone
measured **5.7 ms**. ⚠ `tools.fish` seeds `ATUIN_SESSION` with builtins to preempt the `atuin uuid`
fork inside atuin's own init (4.5 ms, formerly 31% of startup); the skill's `caveats.md` explains why
that is safe and what to re-check after an atuin upgrade. The largest line left is fish's own
`fish_config theme choose`, which has no opt-out.

New tool config goes in its own `conf.d/<tool>.fish`, not into `config.fish`.

`functions/` is filed **by caller**, reorganised 2026-07-30. The top level is reserved for commands a
human types (`brewup` `cls` `extract` `fishprof` `funcfresh` `mcpkill` `reload` `up`); everything else
goes to `wrappers/` (shadows a real binary — `claude` `codex` `firecrawl` `gh` `linode-cli`), `internal/` (only `conf.d`,
fish itself or another function calls it — `cachecmd` `fish_should_add_to_history`
`__abbr_last_history_item`), or `grc/`. ⚠ There is no `alias/` and there should not be: `alias` means
a specific banned thing in fish. ⚠ All four subdirectories are *prepended* to `$fish_function_path`,
so each shadows the top level **and** the others — a basename may appear in exactly one. ⚠ A new
subdirectory is invisible until `exec fish`, because `_init.fish`'s `functions/*/` glob runs once at
startup. The decision table is in the fish skill's `config-layout.md` §7.

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
waits, or prints for a human.** `claude-code/rules/interactive-scripts.md` carries the always-on subset and
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
scoped to the `Development` vault, `op-ssh-sign` signing with a working `allowedSignersFile`, the
`gh` and `linode-cli` shell plugins as fish wrappers,
`functions/wrappers/{claude,codex,firecrawl}.fish` for `op run`, and `gpg-agent.conf` →
`pinentry-touchid`.

⚠ **There is no `functions/brew.fish` any more** (removed 2026-07-30) and it should not come back.
It wrapped every `brew` in `op plugin run --` to supply `HOMEBREW_GITHUB_API_TOKEN`, costing a
1Password authorization on the most-used command here. Since Homebrew 4 all formula and cask metadata
comes from the JSON API and `api.github.com` is not touched at all: the token only raises the
unauthenticated rate limit for `brew search --desc`, `brew bump` and the developer commands.
⚠ The one thing that *would* justify a token is `HOMEBREW_VERIFY_ATTESTATIONS` (Sigstore build
provenance for core bottles) — it is **not** set here, and enabling it would break the autoupdate job,
whose launchd script forwards no token. `~/.config/op/plugins/brew.json` is now orphaned machine
state; `op plugin clear brew` removes it.

⚠ **`op whoami` always fails from a Bash tool call** — no tty means no biometric prompt. That is not
evidence 1Password is misconfigured; ask the user to check in their own terminal.
⚠ **`op run` needs `--no-masking` for any TUI child** — masking pipes stdout, and Claude Code then
drops to `--print` mode and errors. `op run -- /usr/bin/tty` will not reveal this (it tests stdin).

⚠ **Never source `~/.config/op/plugins.sh` from fish** — it is POSIX shell and fails `fish -n`.
⚠ **`GNUPGHOME` deliberately stays at `~/.gnupg`**, not XDG: only fish would export it, so launchd,
GUI apps, cron and Claude Code's zsh would each create a second, empty homedir.

## Git: two layers, on purpose

`git/.gitconfig` carries **aliases** (`lg` `lga` `ll` `branches` `staged` `unstage` `amend` `undo`
`last` `root` `aliases`) and `conf.d/abbrs.fish` carries ~40 **abbreviations**. They overlap, and the
split is deliberate: an alias works from zsh, from a script and from a Bash tool call, while an abbr
only ever expands in fish's line editor. So the abbrs expand to *raw git* — the buffer and the history
end up holding something portable — and only reach for an alias where the payload is a format string
that has nowhere shorter to live (`glg` → `git lg`).

⚠ Three traps, all hit while writing this: **git word-splits an alias body with shell rules**, so a
`--format=…` containing spaces needs inner single quotes or it arrives as five arguments;
**`%(color:auto)` is a `log` placeholder and is rejected by `for-each-ref`** formats like
`branch --format`, which need a real colour name; and the `[pretty] lg` format uses **ANSI colour
names, not laramie hexes**, precisely so it inherits the terminal palette instead of becoming a
fifteenth place the theme has to be hand-duplicated.

⚠ `gs` and `gcp` are deliberately **not** abbreviations — they are ghostscript and GNU coreutils' `cp`,
both installed, and an abbr at command position would shadow them in the buffer.

## Two non-obvious environment overrides

Both are set in `~/.config/fish/conf.d/git.fish` and change how git behaves everywhere:

- `GIT_CONFIG_GLOBAL=$XDG_CONFIG_HOME/git/.gitconfig` — this is why the global config is at the
  unusual path `git/.gitconfig` (git's own default would be `git/config`).
- `GIT_CONFIG_SYSTEM=/dev/null` — the system config is deliberately disabled.

⚠ **`git/config` is a tracked symlink to `.gitconfig`, and it is load-bearing** (added 2026-07-30).
`GIT_CONFIG_GLOBAL` is a **git-CLI** variable; **libgit2 ignores it entirely** and looks only at
`$XDG_CONFIG_HOME/git/config` or `~/.gitconfig`. Neither existed, so every libgit2-backed tool saw
*no global config at all*. That is why `delta` silently rendered its built-in colours and the whole
`[delta "laramie"]` block had never once applied — discovered while rebuilding the theme, and the
symlink is the fix. ⚠ Anything else libgit2-backed (`git-delta`, `git-filter-repo`'s libgit2 paths,
GUI clients, Rust/Go git bindings) depends on that symlink. Do not "tidy" it away.

⚠ **Both *are* set in Bash tool calls** — `claude` is launched from fish, so its whole environment is
inherited. The Bash tool's zsh is a *non-interactive login* shell: `~/.zprofile` is read, `~/.zshrc`
is not, and aliases never expand — so fish functions and `op plugin` aliases can never serve Claude
Code, though exported variables can. Set them explicitly when correctness must not depend on how the
session was launched:

```sh
GIT_CONFIG_GLOBAL=~/.config/git/.gitconfig GIT_CONFIG_SYSTEM=/dev/null git config --list --show-origin
```

## The `laramie` theme

**The `laramie` skill is the source of truth** — the 32-token OKLCH spec, the per-tool binding tables
for all fifteen files that carry a hex, the ANSI-16 contract, and the three-colour syntax doctrine.
Load it before touching any file with a colour in it, or answering anything about contrast, syntax
highlighting or terminal palettes. Rebuilt from the ground up 2026-07-30; ⚠ the old "core hexes" list
that used to live here is **retired** — every one of those values changed.

Two things worth knowing without loading it: ⚠ **`bat cache --build` after editing the tmTheme**, or
bat falls back silently and `delta.syntax-theme = laramie` breaks with it. ⚠ **If a tool accepts ANSI
colour *names*, use them** — `starship.toml`, `LS_COLORS`, `EZA_COLORS`, `LESS_TERMCAP_*` and git's log
formats all do, and they inherit laramie for free from `ghostty/themes/laramie`. Do not hex-code them.

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

New-config spot checks, none of which have a `--validate` of their own:

```sh
fd . /tmp --type=file                             # honours ~/.config/fd/ignore (no node_modules)
curl -sso /dev/null https://example.com/nope; echo $?   # 22, i.e. curlrc's `fail` is live
uv run --no-project python -c 'import sys; print(sys.executable)'  # a uv-managed python, not brew's
script -q /dev/null btop                          # theme loads; ⚠ btop needs a tty, `q` to quit
duti -x json                                      # what actually handles .json right now
fish -lc 'printf "# hi\n" | CLICOLOR_FORCE=1 gum format' | rg -q '73;235;240'  # laramie markdown
```

⚠ **Every hex in every theme file must appear in the `laramie` skill's `references/spec.md`.** Any
other value is drift, by definition — that check is the closest thing to a validator the theme has:

```sh
rg -o '`#[0-9a-f]{6}`' .claude/skills/laramie/references/spec.md | tr -d '`' | sort -u > /tmp/spec
rg -o '#[0-9a-fA-F]{6}' <theme file> | tr 'A-F' 'a-f' | sort -u | comm -23 - /tmp/spec  # must be empty
```

⚠ `ghostty +validate-config` silently ignores a nonexistent `--config-file` path, so a typo'd path
looks like success. ⚠ `brew bundle check` only proves the *declared* set is installed — it passes on
a near-empty Brewfile; the audit script is what proves the file is complete.

Ghostty reloads with `cmd+r`; fish with the `refresh` abbreviation (`exec fish`).

## Known gaps

1. ~~Touch ID for `sudo`~~ — **closed 2026-07-30.** `/etc/pam.d/sudo_local` now holds
   `pam_reattach` (optional) then `pam_tid.so` (sufficient); verified with `sudo -k && sudo true`.
   ⚠ It does **not** help an unattended launchd job — see the `auth` skill's
   `touchid-system-auth.md` §3.1, which is why `brew autoupdate` runs without `--sudo`.
2. ~~**`act` cannot run**~~ — **closed 2026-08-06** by the OrbStack install, which supplies the
   container runtime it was waiting on. `~/.config/act/actrc` was already written and correct.
3. **fzf has no preview.** `FZF_DEFAULT_OPTS` is themed, but `FZF_CTRL_T_OPTS`/`FZF_ALT_C_OPTS` are
   unset, so `ctrl-t` and `alt-c` show bare filenames while `bat` and `eza` sit installed and themed.
4. No completions for `claude`, `code-insiders`, `ffmpeg`, `fswatch`, `scons`, `woff2` —
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

**Closed 2026-07-29** by publishing — do not re-report "the repo is local-only". `origin` is
**github.com/hogdanish/dotfiles**, public, `main` tracking `origin/main`. ⚠ The remote was added as
the HTTPS URL but `git remote -v` shows `git@github.com:` — that is the `url.git@github.com:.insteadof`
rewrite in `git/.gitconfig`, not a mistake; pushes authenticate over SSH through the 1Password agent.
Being public is what makes GitHub push protection apply, so it is a guardrail layer, not just a
default — see `README.md`.

⚠ Traps that would undo earlier fixes: **never** reintroduce a bare `fish_add_path` (it writes a
universal `fish_user_paths`); **never** put an environment variable in a git `include.path`; **never**
source `/opt/homebrew/etc/grc.fish` (it writes a universal and `eval`s arguments); **never** write
`set -gx HOMEBREW_<X> 0` (every `HOMEBREW_*` here is `boolean: :set`, so `0` *enables* it — that is how
`HOMEBREW_DEVELOPER 0` silently ran this machine in developer mode until 2026-07-30; the only way to
spell "off" is to omit the line, and `brew config` is what proves it); **never** restore
`functions/brew.fish` without making `conf.d/brew.fish` use `command brew`. Details and reproduction
live in `fish/references/caveats.md` and the `auth` skill — not here.

## Handle with care in `~/.config`

- `yt-dlp/cookies.txt` — live session cookies. Never read it into context, print it, or copy it
  anywhere in this repo.
- `fish/conf.d/secrets.fish` — **retired 2026-07-28**; do not recreate it (`auth` skill).
- `fish_variables` — fish-managed state, never hand-edited. It is **empty**, and must stay that way:
  anything that lands there is machine state escaping version control.
- `raycast/` — machine-managed extension bundles; nothing there is user-authored.
