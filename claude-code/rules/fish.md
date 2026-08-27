---
paths:
  - "**/*.fish"
---

# Fish shell rules

Applies to every `.fish` file on this machine, in any directory — a project script as much as
`~/.config/fish`. The **`fish` skill is authoritative**; this is the always-on subset that must never
depend on the skill having been loaded.

## Load the skill, and read enough of it

**Invoke the `fish` skill** (or Read `~/.config/claude-code/skills/fish/SKILL.md`). Writing or
editing fish without reading its
`references/style-guide.md` is not acceptable. It is 388 lines and it is law.

**Then read every reference in the row matching your task.** These are floors, not menus — do not skip
a listed file to save tokens. Each is 287–613 lines; the cost is small and known.

| Task | Also read, in full |
| --- | --- |
| Any `.fish` code at all | `language.md`, `variables.md` |
| A function, script, or anything with flags/arguments | + `builtins.md`, `text-processing.md` |
| `conf.d/`, startup, `$PATH`, or load order | + `config-layout.md` |
| An `abbr`, key binding, event handler, history | + `interactive.md` |
| A completion | + `completions.md` |
| A prompt, colour, or theme | + `prompt-and-colours.md` |
| Porting bash/zsh, or you caught yourself writing bash | + `bash-to-fish.md` |
| Plugins, or "how should this be organized?" | + `fisher.md`, `fishconf-patterns.md` |
| **Anything behaving impossibly** | **`caveats.md` first** |

Writing a `conf.d/<tool>.fish` snippet, or an abbr/function wrapping a command? **Confirm the tool is
on this machine first** — check `~/.config/Brewfile`. Three abbreviations in `abbrs.fish` were dead
for months because this was skipped.

Does it prompt, ask, list, wait, or print for a human? **Read
`~/.config/claude-code/skills/gum/SKILL.md` too** — see the `interactive-scripts` rule. ⚠ In fish, `(gum style …)` splits on newlines and shreds a multi-line
block; pipe through `string collect` inside the substitution.

## Non-negotiable

1. `set -l` by default. `-g` only when another file reads it, `-gx` only for real environment
   variables. **Never `set -U` in a config file** — it writes `fish_variables`, machine state rather
   than version-controlled config. The steady state on this machine is **zero universals**; check with
   `fish -c 'set -U --names'`. ⚠ Deleting a `set -U` line does not erase the variable — that needs a
   one-off interactive `set -eU NAME`.
2. `--on-event` / `--on-variable` / `--on-signal` handlers register only when a file is *sourced*. They
   go in `conf.d/`, never `functions/`.
3. Guard everything external: `type -q <cmd>` before a tool, `test -r <file>` before an optional file.
   A missing tool must produce no startup output.
4. Use `string` and `path` builtins, never `sed`/`grep`/`cut`/`basename`/`dirname`. A fork at startup
   is the only fish performance mistake that matters.
5. `fish_indent` decides all formatting — 4 spaces, no exceptions. Comments all-lowercase.
6. `--description` on every function. An autoloaded function's name **must** equal its filename.
7. No `alias`. Use a `function` (works in scripts) or `abbr -a` (expands in the buffer).
8. `fish_add_path` only. Never `set -gx PATH`.
9. Quote for *arity*, not safety: `test -n "$x"` — unquoted, an unset variable makes `test` see a lone
   `-n` and silently return **true**.
10. `argparse` for any function taking flags, always with `; or return`.
11. Capture `$status` immediately; the next command clobbers it. fish has **no** `set -e`.
12. Never write a literal credential into a `.fish` file — use `op run --` / `op://` references.
13. **One concern per `conf.d` file.** A bare `return` ends the whole file, so a multi-concern file
    couples unrelated things — that is how a missing starship once silently disabled terminal
    integration and all of atuin. Where blocks must share a file, guard each with `if`, never `return`.
14. **Cache anything that forks at startup**: `type -q X; and cachecmd --source X init fish`. Look at
    the output first — `starship init fish` is a one-line bootstrap, so caching it caches nothing.
15. ⚠ **A key sequence holds exactly one command list.** The last `bind` wins, silently. `conf.d` files
    that bind keys must account for the tool inits that sort later.

## Bash habits that are wrong in fish

`$(cmd)` → `(cmd)` · `$?` → `$status` · `export A=b` → `set -gx A b` · `[[ ]]` → `test` or
`string match` · `${var}` → parse error · `${#a[@]}` → `count $a` · `$a[0]` → `$a[1]` (1-based) ·
`for ((i=0;...))` → `for i in (seq ...)` · `local` → `set -l` · `<(cmd)` → `(cmd | psub)` ·
`$((...))` → `math`. No heredocs, no `IFS`, no associative arrays, no `set -euo pipefail`.
⚠ `2>&1 |` **is valid fish** — `&|` is the idiomatic spelling, but do not "fix" the long form.

## Verify before claiming done

```sh
fish_indent --check <file> && /opt/homebrew/bin/fish -n <file>
/opt/homebrew/bin/fish -c 'set -U --names'   # must print nothing
```

⚠ Both checks redirect stdin, so they miss a whole class of startup error. After touching anything in
`~/.config/fish/conf.d/`, run a real startup on a tty as well:

```sh
script -q /dev/null /opt/homebrew/bin/fish --login --interactive -c exit
```

Startup got slower? `fishprof`.

⚠ Bash tool calls run under **zsh** — fish functions and abbreviations are unavailable. Invoke
`/opt/homebrew/bin/fish -c '...'` explicitly. `--no-config` isolates, but leaves
`$fish_function_path` unset and demotes `set -U` to global, so it cannot test autoloading or
universals.

## Maintenance is mandatory

When you discover a fish behaviour that surprised you, cost you a debugging cycle, or contradicts the
skill — **append it to the skill's `references/caveats.md` in the same turn**, and fix the reference
that was wrong. A caveat rediscovered twice is a documentation defect, not bad luck.
