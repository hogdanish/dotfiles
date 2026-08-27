# Global instructions

## Behaviour

- Follow best practices; assume strict linting and warnings in every language.
- Follow the usual standards: conventional commits, SemVer, Keep a Changelog, XDG base directories.
- Disclose any assumption you make to fill a knowledge gap.
- After any compaction during an active plan, re-read the active PLAN.md before you continue.
- When you present options in plan mode, mark the option you recommend and say why, briefly.
- Challenge my instructions when you think they are wrong. I make mistakes and can handle
  criticism — do not take my prompts at face value.

## System

Ethan, 24, developer and artist, Wichita KS. MacBook Pro 14″ M5 2025 (24 GB / 1 TB), macOS Golden
Gate 27.x public beta. Interactive shell fish, in Ghostty. Homebrew 6.x; bun (node also present);
VS Code Insiders; git + GitHub CLI through the 1Password shell plugin.

- Secrets: 1Password / `op` for every credential — `op://` references with `op run`, never
  hardcoded.
- Global installs: `brew` → `mas` → `bun`/`uv`/language-specific → manual. Never `pip` for global
  Python packages.
- Scripts a human runs are fish; bash when more appropriate; zsh as last resort.
- `$JAVA_HOME` is set in `~/.config/fish/conf.d/java.fish`.

## Global skills

`fish`, `gum`, `godot`, `linode-cli`, and `orbstack` are user-level skills, listed and invokable in
every project on this machine. Invoke the one that applies — the descriptions carry the triggers.
Two guardrails that hold whether or not the skill is loaded:

- **gum** is the house toolkit for anything a script shows or asks a human, fish and bash alike —
  never hand-roll `read`, `select`, `tput`, or raw ANSI.
- ⚠ **Linode is a paid control plane**: never create, clone, resize, rebuild, or enable a billable
  Akamai Cloud resource without Ethan's explicit permission in the current request. Read-only
  inspection is allowed.

## Paths

- `/Users/ethan/.config/` — system dotfiles **and the dotfiles git repo itself**, tracked in place;
  `$DOTFILES` and `$XDG_CONFIG_HOME` are deliberately the same path. ⚠ `.gitignore` is an
  allowlist: nothing is tracked until a `!` line names it. `~/.config/.claude/CLAUDE.md` (loads
  when working there) carries the full guidance — read it before changing anything under that path.
- `~/.config/Brewfile` — the full software inventory, GUI apps included, one line of *why* per
  entry. Read it before recommending a new tool.
- `/Users/ethan/.config/home/` — files whose consumers hardcode a `$HOME` path (`zshenv`, `zshrc`,
  `zprofile`, `ssh/config`, `gnupg/gpg-agent.conf`), symlinked into `$HOME`. ⚠ Edit them here, not
  at the `$HOME` path.
- `/Users/ethan/Projects/` — git repositories.
