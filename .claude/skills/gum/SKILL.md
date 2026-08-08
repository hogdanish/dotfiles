---
name: gum
description: "Gum 0.17.0 for interactive and formatted shell scripts: all commands and flags, GUM variables, stdout/stderr and exit-code contracts, TTY behavior, layout, glamour Markdown, laramie styling, and fish piping traps. Load before writing any prompt, confirmation, menu, progress display, banner, table, or formatted terminal output, and for gum theming or pipeline failures. Owns gum usage and styling; fish owns syntax, brewfile installation, and auth credentials."
user-invocable: false
---

# gum — glamorous shell scripts

**gum 0.17.0** (`/opt/homebrew/bin/gum`, Brewfile line 36, current upstream release) is the house
toolkit for interaction and terminal formatting. It is a hard dependency of this dotfiles setup, not a
nicety: `.claude/rules/interactive-scripts.md` makes it the default for anything a human reads or
answers.

**Reading floor.** Writing a gum command you haven't written before → read
[commands.md](references/commands.md). Composing more than one gum call into a script or layout → read
[recipes.md](references/recipes.md) too. Both are floors, not menus.

⚠ **Bash tool calls have no tty.** Every interactive gum command (`choose`, `filter`, `confirm`,
`input`, `write`, `file`, `table` without `--print`, `pager`) fails with `could not open a new TTY`,
exit 1. You can still exercise the non-interactive ones — `style`, `join`, `format`, `log`,
`table --print`, `spin`, `version-check` — and drive an interactive one under
`script -q /dev/null gum …` when you must see it render.

## The contract, in six lines

1. The **TUI draws on stderr**, the **result prints on stdout**. `$(gum choose …)` is safe and still
   shows the picker. `gum log` is stderr-only, so it never pollutes a capture.
2. Exit codes: `0` ok · `1` negative/nothing-selected/no-tty · `124` `--timeout` elapsed · `130`
   aborted · `gum spin` returns the wrapped command's code.
3. Colour is profiled from **stderr**, so capturing stdout keeps colour but piping stderr away loses
   it. `CLICOLOR_FORCE=1` forces it back; `NO_COLOR=1` beats that; `FORCE_COLOR` does nothing.
4. Every flag has a `GUM_<COMMAND>_<FLAG>` env var and flags win. `gum style` is the exception —
   its style flags are **unprefixed** globals (`$BORDER`, `$FOREGROUND`, `$PADDING`).
5. `--` separates gum's flags from a wrapped command or from arguments starting with `-`.
6. `gum format` is the whole glamour surface here. glamour v0.10.0 is vendored into gum; there is no
   `glow` binary on this machine and `GLAMOUR_STYLE` is not read.

## Command map

| Need | Command |
| --- | --- |
| Pick 1 of a handful | `choose` |
| Pick from a long/generated list | `filter` |
| Multi-select | `choose --no-limit`, `filter --no-limit` |
| Yes/no gate | `confirm` |
| One-line answer / paragraph | `input` / `write` |
| A path | `file` |
| Tabular data, or a row from it | `table` (`--print` to just render) |
| Show a long document | `format` → `pager` |
| Wait on a slow command | `spin` |
| Box, banner, coloured span | `style`, composed with `join` |
| Status and progress messages | `log` |
| Markdown, templates, code, emoji | `format` |
| Guard against an old gum | `version-check` |

## Caveats — the ones that cost a debugging cycle

⚠ **`gum confirm --default` is `true`.** The pre-selected answer *and* the `--timeout` answer are
*Yes*. Anything destructive needs `--default=false`. `confirm` is also the one command that does not
return `124` on timeout — it returns the default.

⚠ **`gum confirm` short-circuits on a piped stdin.** It reads one line before touching the tty:
`yes`/`y` → 0, anything else → 1, no prompt drawn. That is how you pre-answer in CI, and how a stray
pipe silently auto-declines.

⚠ **`gum spin --show-*` are no-ops when stdout is not a tty.** Interactively, gum runs the command
under a pty and buffers its output, replaying it only if asked. Non-interactively the child inherits
gum's stdout/stderr directly, so output always passes through and `--show-error` has an empty buffer to
show. `out=$(gum spin -- cmd)` therefore captures output with or without `--show-output`.

⚠ **Three-token padding silently becomes zero.** `--padding "1 2 3"` — or any non-integer token —
parses to `0 0 0 0` with no error. Only 1, 2 and 4 tokens are valid.

⚠ **`gum log` needs `--structured` for key/value pairs**, even with `--formatter json`. Without it the
trailing arguments are appended to the message string. `--level fatal` styles a line; it does not exit.

⚠ **fish command substitution splits multi-line gum output.** `set -l b (gum style --border rounded A)`
yields a **3-element list**, so `gum join $b …` receives three arguments and the layout collapses. Pipe
through `string collect` *inside* the substitution:
`set -l b (gum style --border rounded A | string collect)`. For `choose --no-limit` the splitting is
exactly what you want.

⚠ **`gum table --widths` is ignored in `--print` mode.** Columns are auto-sized.

⚠ **`set -e` + `gum confirm` kills bash scripts silently** on a "No". Always write
`gum confirm … || <handler>`.

⚠ **Do not export the unprefixed style variables** (`$FOREGROUND`, `$BORDER`, `$PADDING`) — they
restyle every `gum style` call in every script in the shell.

## House rules

- **Guard before use**: `type -q gum` in fish, `command -v gum` in bash. A script that assumes gum and
  dies with `command not found` is worse than one that falls back to `read`.
- **Guard the tty** when a script may run non-interactively: `isatty stdin` / `[[ -t 0 ]]`.
- **Capture `$status` immediately** after a gum call in fish, and propagate `130`/`124` rather than
  continuing — an abort must abort.
- **`gum log`, not `echo`**, for status, warnings and errors in any script a human watches.
- **Never prompt for a credential** that 1Password can supply. `.claude/rules/security.md` and the
  `auth` skill: `op run` / `op://` beats `gum input --password`. When a passphrase genuinely must be
  typed, pipe it straight into the consumer — never into a variable.
- **Do not re-specify colours per call.** `conf.d/gum.fish` already exports the laramie palette, so a
  plain `gum choose`/`gum input` is already themed. Pass `--foreground`/`--border-foreground` only for
  semantic colour (a green PASS, a red FAIL), and take the hexes from the repo `CLAUDE.md`.

## Reference material

- [commands.md](references/commands.md) — the complete reference: the universal contract, exit codes,
  the env-var scheme, value formats, every enum, and all 13 commands with every flag, default and
  `GUM_*` variable. Read the section for any command you are about to use.
- [recipes.md](references/recipes.md) — composition and practice: fish and bash script skeletons, the
  fish idiom table, `style`+`join` layout, where colour disappears, glamour/markdown, a laramie `GUM_*`
  theme block ready to drop into `conf.d/gum.fish`, and worked recipes (menus, conventional commit,
  progress, tables, structured logging).

## The live configuration

**`~/.config/fish/conf.d/gum.fish`** (added 2026-07-29) is gum's entire configuration — gum has no
config file, so theming is ~24 `GUM_<COMMAND>_<FLAG>` environment variables. It sets foreground
accents only — `ui.accent` (violet) cursors and selections, `ui.label` (blue) headers and prompts,
`text.faint` placeholders — leaving every background at gum's default except `confirm`'s two pills.

⚠ **Since 2026-07-30 the values are `$theme_*` variables, not literal hex.** `conf.d/colours.fish`
sources the palette earlier and above its own interactive guard, so this is no longer a hand-maintained
copy at all. **The `laramie` skill owns every colour value** — look one up in its `references/spec.md`,
never pick a hex here. The file carries `set -q theme_violet_base; or return` so a failed palette load
cannot export empty strings.

⚠ **It is deliberately *not* interactive-guarded.** A script calling `gum choose` is exactly the case
that needs these variables, and `functions/reload.fish` is one such caller. Do not "fix" it by adding
a `status is-interactive` guard.

⚠ **Two variables, one file.** `GLAMOUR_STYLE` (set by `conf.d/xdg-apps.fish`, for `gh`) and
`GUM_FORMAT_THEME` (set by `conf.d/gum.fish`) both point at
`~/.config/glamour/laramie.json`. **gum does not read `GLAMOUR_STYLE`** — if markdown renders wrong in
gum, check `GUM_FORMAT_THEME`, and remember both need changing to move the theme.

Verified live: the exported values are bare hex once expanded (fish's `set` listing adds display quotes
around a leading `#` because it is a comment character — the value itself is 7 characters), and
`gum format` renders laramie. ⚠ Its *markdown chrome* is truecolour, but the fenced-code `chroma` path
always quantizes to 256 colours regardless of `COLORTERM` — see the `laramie` skill's `bindings.md`.

The block itself is *not* mirrored in this skill — `~/.config` is the single source of truth. Read
`conf.d/gum.fish` when you need the current values; [recipes.md](references/recipes.md) §6 covers the
rationale and how to extend it.

## Maintenance

After `brew upgrade gum`, re-verify before trusting this skill:

```sh
gum --version                                    # expected: 0.17.0
gum <cmd> --help                                 # flags/defaults for any command you doubt
gum version-check '>= 0.17'                      # exit 0
gum style --border double --padding '1 2' ok     # renders without a tty
```

If a flag, default or enum here disagrees with `gum <cmd> --help`, **the binary wins** — fix
[commands.md](references/commands.md) in the same turn and note the version bump here. Never correct a
value from memory; every default in these files was dumped from this machine's binary and
cross-checked against the `v0.17.0` source.

A gum behaviour that surprises you is a documentation defect: add it to the Caveats section above (or
the matching reference) in the same turn.

---
*Source of truth for gum in this repo. The always-on trigger lives in
`.claude/rules/interactive-scripts.md`; fish syntax belongs to the `fish` skill.*
