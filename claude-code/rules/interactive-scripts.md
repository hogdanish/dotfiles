# Interactive scripts use gum

Applies on this machine to every script, function, abbreviation or command wrapper a human will run —
`.fish`, `.sh`, `.bash`, `.zsh`, a `Makefile` recipe, a `package.json` script, and one-off commands you
hand the user. The **`gum` skill is authoritative**; this is the always-on trigger.

## Load the skill

**Before writing or editing anything that prompts, asks, lists, waits, or prints for a human, load the
`gum` skill.** That means: a menu, a yes/no question, a text prompt, a file picker, a progress
indicator, a spinner, a banner, a table, a rendered document, or status/error output.

This holds in **fish and bash alike**, and in any directory — gum is not a dotfiles-repo convention.
Read `references/commands.md` for any gum command you have not written before, and `references/recipes.md`
before composing more than one call; it carries both a fish and a bash skeleton.

Do **not** skip the skill because the script "only has one prompt". The defaults are the trap — see
`--default` below.

## Prefer gum over the primitives

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

Plain `echo`/`printf` remains correct for machine-readable output, and for a script whose stdout is
meant to be piped. Style the human-facing stream, not the data stream.

## Non-negotiable

1. **Guard it**: `type -q gum` (fish) / `command -v gum` (bash, zsh) before the first gum call, with a
   working fallback or a clean error. Guard the tty too (`isatty stdin` / `[[ -t 0 ]]`) if the script
   can run non-interactively.
2. **`gum confirm --default` is `true`.** Every destructive confirmation passes `--default=false`.
3. **Propagate aborts.** `130` (ctrl+c) and `124` (timeout) must stop the script. In fish capture
   `$status` on the very next line; in bash write `gum confirm … || <handler>`, never rely on `set -e`.
4. **Never `gum input --password` for a credential 1Password holds** — `op run` / `op://` first (the
   `security` rule and `auth` skill). If a passphrase must be typed, pipe it into the consumer, never
   a variable.
5. **fish splits multi-line gum output** in command substitution — `(gum style … | string collect)`.

⚠ gum's TUI is on **stderr** and its result on **stdout**, so `$(gum choose …)` is safe. ⚠ Bash tool
calls have no tty: interactive gum commands exit 1 there. Test them under `script -q /dev/null gum …`.

⚠ gum is themed by `~/.config/fish/conf.d/gum.fish`, so it inherits laramie only in a fish-launched
process. A script run from cron, launchd or a bare `zsh -c` gets stock colours — accept that rather
than hardcoding the palette.
