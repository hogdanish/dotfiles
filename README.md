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
- `Brewfile` acts as an automatically updated software inventory for everything (CLI tools, GUI
  apps, NPM packages, app store apps, etc)
- `home/` holds files that have to be in `$HOME`, symlinked via `scripts/link-home.fish`.
- `claude-code/` owns shared agent instructions, skills and hooks; `codex/` contains only thin
  Codex adapters linked by `scripts/link-codex.fish`
- Codex and Claude Code both load Cloudflare skills and the `cloudflare-api` MCP by default;
  project-only MCPs stay in each project's tracked `.codex/config.toml`
- The Website Spec MCP is declared globally for both agents but switched on per project (`hogdot`,
  `commongrounds`); the `website-spec` skill vendors the whole checklist so audits work without it
- The `simple-english` skill and output style are vendored from
  [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish) rather than installed as its
  plugin, whose hooks would apply the register to every session; both agents load the skill only
  when it is asked for by name
- Claude Code's config dir is `$XDG_STATE_HOME/claude`, reached through a `~/.claude` symlink;
  `$CLAUDE_CONFIG_DIR` is deliberately **not** exported, because `clauth` and every other Claude
  account manager hardcode `~/.claude`, and Claude Code namespaces its macOS Keychain item by that
  variable's hash. `~/.claude/settings.json` is deliberately absent too — `clauth` would rewrite it
  on every account switch — so the tracked file is passed per session with `claude --settings`
- `clauth` manages the Claude Code accounts: switching, live 5h/7d usage, and an auto-switch
  fallback chain run by a launchd daemon. No Homebrew formula, and installed from git rather than
  crates.io — the released version corrupts the macOS Keychain login item on every switch
- `rumdl` formats every markdown file, at three points that all fix rather than complain: VS Code
  on save, a `PostToolUse` hook on anything an agent writes, and a `lefthook` job that reformats and
  re-stages instead of rejecting the commit. The style is `rumdl/rumdl.toml`, which doubles as the
  machine-wide fallback for markdown outside this repo
- All secrets are managed via 1Password and resolved at use time via `op run`, never stored on disk.

## New machine

```sh
curl -fsSL https://raw.githubusercontent.com/hogdanish/dotfiles/main/scripts/bootstrap.sh | sh
```
