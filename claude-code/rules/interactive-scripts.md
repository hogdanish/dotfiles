---
paths:
  - "**/*.fish"
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
  - "**/Makefile"
  - "**/package.json"
---

# Interactive scripts use gum

Applies to every script, function, abbreviation, or command wrapper a human will run, in any
directory — gum is not a dotfiles-repo convention. **Before writing or editing anything that
prompts, asks, lists, waits, or prints for a human — a menu, yes/no, text prompt, file picker,
spinner, banner, table, rendered document, or status/error output — Read
`~/.config/claude-code/skills/gum/SKILL.md`.** Read its `references/commands.md` for any gum
command you have not written before, and `references/recipes.md` before composing more than one
call. Do not skip it because the script "only has one prompt" — the defaults are the trap.

| Instead of | Use |
| --- | --- |
| `read -p` (bash) / `read -P` (fish) | `gum input` (`gum write` for multi-line) |
| `read -n1` y/n, `select` | `gum confirm`, `gum choose` |
| `select` over a long list | `gum filter` |
| `echo`/`printf` status, warnings, errors | `gum log --level <lvl>` |
| ANSI escapes, `tput`, manual box-drawing | `gum style` (+ `gum join`) |
| `column -t`, hand-aligned output | `gum table --print` |
| `cat` a markdown file | `gum format` (→ `gum pager` if long) |
| A bare `sleep`/silent long command | `gum spin --title …` |

Plain `echo`/`printf` stays correct for machine-readable output and for a script whose stdout is
meant to be piped. Style the human-facing stream, not the data stream.

## Non-negotiable

1. Guard it: `type -q gum` (fish) / `command -v gum` (bash, zsh) before the first gum call, with a
   working fallback or clean error. Guard the tty too (`isatty stdin` / `[[ -t 0 ]]`) if the script
   can run non-interactively.
2. **`gum confirm --default` is `true`.** Every destructive confirmation passes `--default=false`.
3. Propagate aborts: `130` (ctrl+c) and `124` (timeout) must stop the script. Fish: capture
   `$status` on the very next line. Bash: `gum confirm … || <handler>`, never `set -e`.
4. Never `gum input --password` for a credential 1Password holds — `op run` / `op://` first. A
   passphrase that must be typed pipes into the consumer, never a variable.
5. fish splits multi-line gum output in command substitution — `(gum style … | string collect)`.

⚠ gum's TUI is on **stderr**, its result on **stdout**, so `$(gum choose …)` is safe. ⚠ Bash tool
calls have no tty: interactive gum commands exit 1 there — test them under
`script -q /dev/null gum …`. ⚠ gum inherits the laramie theme only from a fish-launched process
(`conf.d/gum.fish`); cron, launchd, and bare `zsh -c` get stock colours — accept that rather than
hardcoding the palette.
