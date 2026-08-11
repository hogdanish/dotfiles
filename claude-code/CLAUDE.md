# Global system-wide instructions

## Behaviour

### General rules
- Always follow best practices and assume strict linting/warnings in any given language.
- Consistently follow standards such as conventional commits / SemVer / Keep a Changelog / XDG Base Directory / etc.
- If faced with gaps in your knowledge or understanding and are required to make assumptions to continue, be transparent and disclose them to the user. 
- After any compaction (i.e `/compact`) while working on an active plan, ALWAYS re-read the active PLAN.md before continuing
- When prompting the user with options in planning mode (i.e `/plan`), try to indicate which option you personally reccomend and why in the most concise manner possible within the prompt. 
- Practice radical candor by actively looking for opportunities to directly challenge my instructions if you think it will lead to a better outcome. I am capable of making mistakes and handling criticism, so don't be afraid to speak up if you think I'm guiding you in the wrong direction. Don't blindly take my prompts at face value.

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
- **JS/TS runtime**: bun (or node for compatibility)
- **IDE**: VS Code Insiders
- **Auth**: 1Password / `op` CLI for all secrets and credentials
- **Version control**: git + GitHub CLI (via 1Password shell plugin)

### Preferences
- Fish shell for local interactive use; bash when more appropriate; zsh as last resort
- Global installs: `brew` → `mas` → `bun`/`uv`/language-specific → manual. Avoid `pip` for global Python packages.
- Local credentials: use `op://` references with `op run` — never hardcode secrets

### Resources

- `~/.config/Brewfile` — the full software inventory including GUI apps, one line of *why* per entry.
  Read it when you need something the `toolbox` rule does not cover, or before recommending a new tool.
- Fish is the shell for interactive use and for scripts a human runs. Load the `fish` skill before
  writing or editing any `.fish` file, in any directory, and before porting bash or zsh to fish; it
  owns the house style guide and the language references. The `fish` rule is the always-on subset.
- `gum` is the house toolkit for anything a script shows or asks a human, in fish and bash alike.
  Load the `gum` skill before writing a prompt, confirmation, menu, spinner, banner, table or status
  output — never hand-roll `read`, `select`, `tput` or raw ANSI. The `interactive-scripts` rule is the
  always-on trigger.
- `$JAVA_HOME` is set in `~/.config/fish/conf.d/java.fish`
- Linode is a paid control plane. Never create, clone, resize, rebuild, or enable paid services for
  a Linode or any other billable Akamai Cloud resource without Ethan's explicit permission in the
  current request. Read-only inspection is allowed. Load the `linode-cli` skill before using the
  official CLI; it owns the full command surface and safety workflow.

**Notable system paths:**
- `/Users/ethan/.config/`: system dotfiles — **and the dotfiles git repo itself**, tracked in place
  since 2026-07-29. `$DOTFILES` and `$XDG_CONFIG_HOME` are deliberately the same path. ⚠ Nothing is
  tracked unless `.gitignore` (an allowlist) names it; adding a config means adding one `!` line.
  Full guidance — the fish layout, user-level skills, brew autoupdate, and every trap that has cost
  a cycle — is `~/.config/.claude/CLAUDE.md`, which loads when working there. Read it before
  changing anything under that path.
- `/Users/ethan/.config/home/`: files that cannot live under `~/.config` because their consumer
  hardcodes a `$HOME` path — `zshrc`, `zprofile`, `ssh/config`, `gnupg/gpg-agent.conf`. They are
  symlinked into `$HOME`, so ⚠ edit them here, not at the `$HOME` path.
- `/Users/ethan/Projects/`: git repositories
