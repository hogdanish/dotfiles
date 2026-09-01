# dotfiles

My simple macOS config. No GNU Stow, chezmoi, or anything else. This repo is `~/.config`.

- **OS**: macOS Golden Gate 27.x
- **Hardware**: MacBook Pro (M5, 14-inch, 24 GB)
- **Shell**: fish
- **Terminal**: Ghostty
- **Package manager**: Homebrew
- **Credential manager**: 1Password

## How it works

- `.gitignore` is the allowlist, everything is ignored by default
- `Brewfile` acts as an automatically updated software inventory for everything (CLI tools, GUI apps, NPM packages, app store apps, etc)
- `home/` holds files that have to be in `$HOME`, symlinked via `scripts/link-home.fish`.
- `claude-code/` owns shared agent instructions, skills and hooks; `codex/` contains only thin
  Codex adapters linked by `scripts/link-codex.fish`
- Codex keeps Cloudflare behind `codex --infra`; project MCPs stay in each project's tracked
  `.codex/config.toml`
- The Website Spec MCP is declared globally for both agents but switched on per project
  (`hogdot`, `commongrounds`); the `website-spec` skill vendors the whole checklist so audits work without it
- All secrets are managed via 1Password and resolved at use time via `op run`, never stored on disk.

## New machine

```sh
curl -fsSL https://raw.githubusercontent.com/hogdanish/dotfiles/main/scripts/bootstrap.sh | sh
```
