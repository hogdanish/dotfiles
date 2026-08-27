# dotfiles

My simple macOS config.  No GNU Stow, chezmoi, or anything else. This repo is `~/.config`.

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
- `claude-code/` and `codex/` are custom global system agent configs and are symlinked via `scripts/link-claude.fish` & `link-codex.fish`
- All secrets are managed via 1Password and resolved at use time via `op run`, never stored on disk.

## New machine

```sh
curl -fsSL https://raw.githubusercontent.com/hogdanish/dotfiles/main/scripts/bootstrap.sh | sh
```