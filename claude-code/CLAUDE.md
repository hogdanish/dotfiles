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
  - **Godot**: load the `godot` skill for Godot/GDScript/scene/shader work. Two MCP servers back it — `godot-mcp` (editor + running-game control, deterministic playtesting, runtime state) and `godot-lsp` (static GDScript diagnostics + the game console). Neither authors content: writing `.gd`/`.tscn`/`.tres` is normal filesystem work.
  - **Docs / API lookup**: Context7 first, then built-in search/fetch, then Firecrawl.
  - **JS-heavy / multi-page web extraction**: Firecrawl, via the official **`firecrawl` plugin**
    (`firecrawl@claude-plugins-official`) — 11 `firecrawl:*` skills driving the `firecrawl` CLI.
    ⚠ The plugin ships **no MCP server** (`claude plugin details` confirms 0), and none is wanted:
    the CLI does the same work with nothing to keep alive. ⚠ `FIRECRAWL_API_KEY` is already on the
    process environment when `claude` is launched from fish, and Bash tool calls inherit it — so a
    bare `firecrawl …` is authenticated. Do not wrap it in `op run` and do not pass `--api-key`.
    ⚠ **Never run `firecrawl init`, `firecrawl setup skills|workflows`, or `firecrawl login`,** even
    though the plugin's own `install.md` recommends all three: on this machine they write 31 bundles
    to `~/.agents/` linked with a prefix that only resolves under `~/.claude/skills` (so every link
    dangles), spray copies into every other agent/IDE they detect, and open a second credential store
    under `~/Library/Application Support/firecrawl-cli`. The CLI is installed and authenticated;
    `firecrawl --status` is the check.
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
- Preferred CLI alternatives: the full table is in the always-loaded toolbox digest below

### Resources

**Installed system tools** — two files, and deliberately no third copy:

- `~/.config/claude-code/rules/toolbox.md` — the **digest**, loaded into every session in every
  project as a user-level rule, so it is already in context. It names the tools worth reaching for,
  what each replaces, the macOS/BSD traps, and what is deliberately *not* installed. **Act on it
  directly: do not re-verify a command it names, and do not offer to install one.**
- `~/.config/Brewfile` — the full inventory including GUI apps, one line of *why* per entry. Read it
  when you need something the digest does not cover, or before recommending a new tool.
- Use `gum` for interactive prompts in shell scripts
- `$JAVA_HOME` is set in `~/.config/fish/conf.d/java.fish`

**Notable system paths:**
- `/Users/ethan/.config/`: system dotfiles — **and the dotfiles git repo itself**, tracked in place
  since 2026-07-29. `$DOTFILES` and `$XDG_CONFIG_HOME` are deliberately the same path. ⚠ Nothing is
  tracked unless `.gitignore` (an allowlist) names it; adding a config means adding one `!` line.
  Its own guidance is `~/.config/.claude/CLAUDE.md`.
- `/Users/ethan/.config/home/`: files that cannot live under `~/.config` because their consumer
  hardcodes a `$HOME` path — `zshrc`, `zprofile`, `ssh/config`, `gnupg/gpg-agent.conf`. They are
  symlinked into `$HOME`, so ⚠ edit them here, not at the `$HOME` path.
- `/Users/ethan/.config/claude-code/skills/`: the **hand-authored, version-controlled** user-level
  skills — currently just `godot` — symlinked one by one into `$CLAUDE_CONFIG_DIR/skills/`. Adding a
  global skill means writing it here and re-running `~/.config/scripts/link-claude.fish`.
  ⚠ **Vendor skills do not go here.** They arrive as *plugins*, whose payload lives in
  `$CLAUDE_CONFIG_DIR/plugins/` (state, untracked) while only the enable flag lands in the tracked
  `claude-code/settings.json`. That is what keeps this directory a clean list of things Ethan wrote.
  ⚠ `~/.agents/` is **gone** (deleted 2026-07-30) and must not come back.
- `/Users/ethan/.config/fish/conf.d/`: shell config — 15 snippets, one concern each, in load order:
  `_init` · `_shell` · `abbrs` · `brew` · `bun` · `colours` · `fzf` · `ghostty` · `git` · `gum` ·
  `java` · `keybindings` · `op` · `tools` · `xdg-apps`. ⚠ No `fisher.fish` (no plugin manager) and
  no `theme.fish` (renamed to `colours.fish`); `secrets.fish` was retired and must never return.
- `/Users/ethan/.config/fish/functions/`: custom shell functions, filed **by caller** since
  2026-07-30. The top level holds only commands a human types (`brewup` `cls` `extract` `fishprof`
  `funcfresh` `mcpkill` `reload` `up`); ⚠ the three subdirectories are `wrappers/` (shadow a real
  binary — `claude` `firecrawl` `gh`), `internal/` (only conf.d/fish/another function calls it —
  `cachecmd` `fish_should_add_to_history` `__abbr_last_history_item`) and `grc/` (one colouriser per
  command). There is no `alias/`. There is exactly **one** 1Password shell-plugin wrapper,
  `wrappers/gh.fish` (`op plugin run -- gh $argv`); ⚠ the matching `brew.fish` was **removed
  2026-07-30** and must not come back — plain `brew` is not wrapped. `brewup.fish` is the full update
  command (homebrew + mac app store); Homebrew also updates itself on a 12 h launchd timer via
  `brew autoupdate`.
- `/Users/ethan/Projects/`: git repositories