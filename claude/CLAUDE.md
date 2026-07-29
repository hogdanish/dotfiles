# Global system-wide instructions

## Behaviour

### General rules
- Generally prefer modern, efficient & performant tools and libraries over more stable ones within reason.
- Always follow best practices and assume strict linting/warnings in any given language.
- Keep comments concise, relevant, and written in all-lowercase. 
- Consistently follow standards such as conventional commits / SemVer / Keep a Changelog / XDG Base Directory / etc.
- If faced with gaps in your knowledge or understanding and are required to make assumptions to continue, be transparent and disclose them to the user. 
- After any compaction (i.e `/compact`) while working on an active plan, ALWAYS re-read the active PLAN.md before continuing
- When prompting the user with options in planning mode (i.e `/plan`), try to indicate which option you personally reccomend and why in the most concise manner possible within the prompt. 

### Style
- Use Canadian English spelling and grammar conventions
- Don't sacrifice clarity for brevity, but avoid unnecessary verbosity—practice excellent word economy.
- If you disagree with my approach, say so and explain why.
- Practice radical candor by actively looking for opportunities to directly challenge my instructions if you think it will lead to a better outcome. I am capable of making mistakes and handling criticism, so don't be afraid to speak up if you think I'm guiding you in the wrong direction. Don't blindly take my prompts at face value.

### Tools
- Proactively research using tools whenever you're unsure about something, the topic may have changed recently, or a library/API version matters.
- Don't solely rely on your knowledge and prefer fetching actual up-to-date documentation for anything that is version-sensitive or particularly obscure.
- Use any tools at your disposal without asking permission when they are clearly appropriate and low-risk.
- Preferred tool selection:
  - **GitHub**: GitHub MCP server first, then `gh` CLI or manual action as fallback.
  - **Godot**: consider the `godot` skill for Godot/GDScript/scene/shader work unless direct filesystem edits/other methods are more appropriate/faster
  - **Docs / API lookup**: Context7 first, then built-in search/fetch, then Firecrawl.
  - **JS-heavy / multi-page web extraction**: Firecrawl.
  - **Local / execution work**: terminal commands and filesystem tools.

## Coding Guidelines

### 1. Think Before Coding
*Don't assume. Don't hide confusion. Surface tradeoffs.*
- State assumptions explicitly before implementing. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First
*Minimum code that solves the problem. Nothing speculative.*
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes
*Touch only what you must. Clean up only your own mess.*
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused; leave pre-existing dead code alone.
- The test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution
*Define success criteria. Loop until verified.*
- Transform tasks into verifiable goals:
  - "Add validation" → "Write tests for invalid inputs, then make them pass"
  - "Fix the bug" → "Write a test that reproduces it, then make it pass"
  - "Refactor X" → "Ensure tests pass before and after"
- For multi-step tasks, state a brief plan:
  ```
  1. [Step] → verify: [check]
  2. [Step] → verify: [check]
  3. [Step] → verify: [check]
  ```
- Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## System context

### Overview
- **User**: Ethan
- **Role**: 24yo developer, artist
- **Location**: Wichita, KS
- **System**: MacBook Pro (14-inch, M5, 2025, 24 GB RAM, 1 TB SSD)
- **OS**: macOS Golden Gate 27.x (Public Beta)
- **Shell**: Fish (interactive)
- **Terminal emulator**: Ghostty
- **Package manager**: Homebrew 6.x 
- **JS/TS runtime**: node
- **IDE**: VS Code Insiders
- **Auth**: 1Password / `op` CLI for all secrets and credentials
- **Version control**: git + GitHub CLI (via 1Password shell plugin)

### Preferences
- Fish shell for local interactive use; bash when more appropriate; zsh as last resort
- Global installs: `brew` → `mas` → `bun`/`uv`/language-specific → manual. Avoid `pip` for global Python packages.
- Local credentials: use `op://` references with `op run` — never hardcode secrets
- Preferred CLI alternatives (use when appropriate):
  - `trash` → `rm` · `bat` → `cat` · `fd` → `find` · `eza` → `ls` · `ripgrep` → `grep`
  - `zoxide` → `cd` · `delta` → `git diff` · `xh` → `curl` · `doge` → `dig`
  - `bun` → `node`/`npm` · `uv` → `pip`

### Resources

**Installed system tools** — ⚠ do not maintain a list here. `~/Projects/dotfiles/Brewfile` is the
machine's inventory: every entry carries a one-line comment saying *why* it is installed, and it is
the only copy that gets updated when something is added. Read it before recommending, configuring or
diagnosing any tool. A hand-kept duplicate in this file drifted badly enough that config was written
against tools that were never installed — corrected 2026-07-29.

⚠ Verify before depending on a binary, because the Brewfile records *declared intent*:
`type -q <cmd>` in fish, `command -v <cmd>` in bash/zsh, `brew list --versions <formula>` for
formulae that ship no same-named binary (`pam-reattach`, keg-only `curl`, `make` → `gmake`).

Not from Homebrew, and easy to mistake for it: `jq` (`/usr/bin/jq`, `jq-1.7.1-apple`) and `trash`
(`/usr/bin/trash`) are **macOS 27 system binaries**. `java` is the `/usr/bin/java` stub dispatching
to the `temurin@25` cask; `$JAVA_HOME` is set in `~/.config/fish/conf.d/java.fish`.

**Not installed** despite once being listed here — do not write config or examples against them:
`tre`, `yq`, `docker`, `docker-compose`, `rustup`/`cargo`, `maven`, `gradle`, `shfmt`, `prettier`,
`eslint`, `atomicparsley`, `chafa`, `macos-defaults`. ⚠ `act` is installed but **cannot run**: it
needs a container runtime, and neither docker nor podman is present.

- Use `gum` for interactive prompts in shell scripts
- `code-insiders .` opens VS Code Insiders

**Notable system paths:**
- `/Users/ethan/.config/`: system dotfiles
- `/Users/ethan/.config/fish/conf.d/`: shell config — 15 snippets, one concern each, in load order:
  `_init` · `_shell` · `abbrs` · `brew` · `bun` · `colours` · `fzf` · `ghostty` · `git` · `gum` ·
  `java` · `keybindings` · `op` · `tools` · `xdg-apps`. ⚠ No `fisher.fish` (no plugin manager) and
  no `theme.fish` (renamed to `colours.fish`); `secrets.fish` was retired and must never return.
- `/Users/ethan/.config/fish/functions/`: custom shell functions. ⚠ The subdirectory is `grc/`
  (one wrapper per grc-colourised command), not `alias/`. The 1Password shell-plugin wrappers are
  top-level: `gh.fish` and `brew.fish`, each `op plugin run -- <cli> $argv`.
- `/Users/ethan/Projects/`: git repositories