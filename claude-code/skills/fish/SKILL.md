---
name: fish
description: "Fish 4.8.1 on this machine: house style, language, builtins, variables, functions, scripts, completions, abbreviations, key bindings, prompt, theming, startup cost, and verified caveats. Load before writing or editing any .fish file in any directory, translating bash or zsh to fish, debugging fish behaviour or startup time, or changing ~/.config/fish. Owns fish syntax and style everywhere; gum owns human-facing prompts and output, laramie owns colour values."
---

# Fish shell

fish **4.8.1** (`/opt/homebrew/bin/fish`) is the interactive shell on this machine and the default for
any script a human runs. This skill covers **all** fish work in **any** directory — a script in a
project, a one-off function, a port from bash, a debugging session — not only `~/.config/fish`.

`/bin/zsh` remains the login shell and is deliberately unconfigured; Ghostty launches fish explicitly.

**Do not ration your reading.** [style-guide.md](references/style-guide.md) is mandatory for every
`.fish` file. Then read **every file in the Required-reading row matching your task** — the rows are
floors, not menus. Each reference is 287–613 lines and the count is listed, so the cost is never a
guess: reading four of them is cheaper than one `set -gx` that silently rewrites `fish_variables`.
When two rows apply, read both. Skipping a listed file to save tokens is the most common way fish work
goes wrong.

⚠ **Bash tool calls run under zsh.** Fish functions and abbreviations do not exist for you. Call fish
explicitly: `/opt/homebrew/bin/fish -c '...'`. Add `--no-config` when this machine's config must not
mask the result — ⚠ but `--no-config` also leaves `$fish_function_path` unset and demotes `set -U` to
global, so it cannot test autoloading or universals.

## The style guide is law

Five load-bearing rules. [style-guide.md](references/style-guide.md) has the reasoning, the naming and
scope discipline, and annotated templates for a `conf.d` snippet, a function, a namespaced helper, a
completion and a standalone script.

1. `set -l` by default; `-gx` only for real environment variables; **never `set -U`** in a file.
2. `--on-event` / `--on-variable` / `--on-signal` handlers register only when a file is *sourced* →
   they belong in `conf.d/`, never `functions/`.
3. Guard everything external: `type -q <cmd>` before a tool, `test -r <file>` before an optional file.
4. `string` and `path` builtins instead of `sed`/`grep`/`cut`/`basename` — a startup fork is the only
   fish performance mistake that matters.
5. `fish_indent` decides all formatting. 4 spaces. No `alias`. `--description` on every function.

⚠ Quote for **arity**, not safety: `test -n "$x"`. Unquoted, an unset variable makes `test` see a lone
`-n` and silently return **true**.

⚠ Does it prompt, ask, list, wait, or print for a human? **Load the `gum` skill** — gum is the house
default for every one of those, and `interactive-scripts.md` is the always-on rule that says so. ⚠ In
fish, `(gum style …)` splits on newlines and shreds a multi-line block; pipe through `string collect`
*inside* the substitution.

⚠ Never write a literal credential into a `.fish` file. Use `op run --` / `op://` references — the
`auth` skill owns this.

## Two contexts

**Portable fish** — a script, function or completion in any project. The style guide plus the
Required-reading row are the whole law; nothing in the next section applies.

**This machine's config** — `~/.config/fish`, **edited in place**. That directory *is* the `~/.config`
dotfiles repo: no mirror, no templating, no deploy step. Read that repo's `CLAUDE.md` before changing
anything under it, and note that nothing there is tracked unless `.gitignore` (an allowlist) names it.

`conf.d/*` sources **before** `config.fish`, sorted `digits` → `_` → `letters` (verified on 4.8.1);
the `_` prefix is this config's ordering mechanism, and `config.fish` is intentionally empty. Four
orderings are **load-bearing**, not incidental:

- `bun.fish` and `uv.fish` after `brew.fish` — `brew.fish` resets `set -g fish_user_paths`, so any
  `fish_add_path` before it is discarded.
- `colours.fish` before `fzf.fish` — it exports the `$theme_*` palette that `fzf.fish` reads.
- `fzf.fish` before `tools.fish` — `FZF_CTRL_R_COMMAND` is read at source time.
- atuin **last** inside `tools.fish` — whichever tool binds a key last wins.

⚠ **One concern per `conf.d` file.** A bare `return` ends the whole file, so a multi-concern file
couples unrelated things. Anything later files depend on goes in `_init.fish`; new tool config gets
its own `conf.d/<tool>.fish`, never `config.fish`.

⚠ **Startup cost is maintained, not accidental** — 10.0 ms interactive, 3.7 ms non-interactive. Cache
anything that forks: `type -q X; and cachecmd --source X init fish`. Measure with `fishprof` before
and after, and compare **medians** — it reports a single run and startups vary by a few ms with
occasional 3× outliers.

⚠ `conf.d/secrets.fish` was **retired 2026-07-28** and must never be recreated — credentials come from
1Password at the moment of use (`auth` skill).

Full load sequence, autoloading semantics, the `functions/` filed-by-caller layout and a file-by-file
inventory: [config-layout.md](references/config-layout.md).

## Verify a change

```sh
fish_indent --check <file>                              # formatting is canonical (exit 0)
/opt/homebrew/bin/fish -n <file>                        # parses
/opt/homebrew/bin/fish --no-config -c 'source <file>'   # sources clean, no stray output
```

⚠ **All three redirect stdin, so a whole class of startup error is invisible to them.** After touching
anything in `~/.config/fish/conf.d/`, run a real startup on a tty as well, and confirm no universal
variable survived:

```sh
script -q /dev/null /opt/homebrew/bin/fish --login --interactive -c exit
/opt/homebrew/bin/fish -c 'set -U --names'              # must print nothing
```

`conf.d/theme.fish` passed the first three checks for months while erroring in every real window,
because `source` with no arguments reads stdin and only fails on a tty
([caveats.md](references/caveats.md)). Startup got slower? `fishprof`.

After touching `abbrs.fish`, check every abbreviation target still exists. ⚠ Write it to a **file** and
run that — inlining it after `-c` nests three levels of quoting and the innermost never survives, which
once reported all 13 quoted abbreviations as dead:

```sh
cat > /tmp/abbrcheck.fish <<'FISH'
for l in (abbr --show)
    set -l p (string split -- " -- " $l)
    test (count $p) -ge 2; or continue
    set -l r (string split -m 1 " " -- $p[2])
    test (count $r) -ge 2; or continue
    set -l head (string trim -c "'" -- $r[2] | string split " ")[1]
    string match -qr '^[$(]|^\.\.' -- $head; and continue
    type -q $head; or echo "DEAD: $r[1] -> $head"
end
FISH
/opt/homebrew/bin/fish -i /tmp/abbrcheck.fish
```

## Required reading

`style-guide.md` is mandatory for every fish task. Then read **all** of the matching row.

<!-- duplicated in claude-code/rules/fish.md so it is present even unloaded — change both -->

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

## Reference material

- [caveats.md](references/caveats.md) (514) — **read first when debugging.** Verified fish behaviour
  that contradicts what a model will confidently assert, plus this machine's live config defects.
  Several entries were disproved premises from this skill's own authoring. Append to it — see
  Maintenance.
- [style-guide.md](references/style-guide.md) (388) — **mandatory.** House rules, naming, scope
  discipline, complete annotated templates, and the pre-commit review checklist.
- [language.md](references/language.md) (573) — quoting, the full expansion set, lists as the only data
  type, redirection and pipes, conditionals, loops, functions, `$status` and error handling (fish has
  no `set -e`), debugging.
- [builtins.md](references/builtins.md) (613) — `argparse` in full, `test` operators, `status`,
  introspection (`type`/`functions`/`command`), `fish_add_path`, and an index of all 125 shipped
  commands.
- [text-processing.md](references/text-processing.md) (515) — `string`, `path`, `math`, `printf`,
  `read`, and a unix-pipeline → fish-builtin translation table. Read this instead of reaching for `sed`.
- [variables.md](references/variables.md) (504) — the five scopes, `set` flags, export semantics, the
  universal-variable trap, `PATH` handling, and the complete special-variable catalogue with this
  machine's real values.
- [config-layout.md](references/config-layout.md) (469) — startup order end to end, `conf.d`
  precedence, autoloading, the "what belongs where" decision table, `~/.config/fish` file-by-file, and
  its known gaps.
- [interactive.md](references/interactive.md) (425) — `abbr` (incl. regex and function abbreviations),
  `bind` and fish 4.x key notation, `commandline`, event handlers and `emit`, history, shell
  integration.
- [completions.md](references/completions.md) (302) — the `complete` flag table, dynamic arguments, the
  `__fish_*` condition helpers, the subcommand pattern, and testing with `complete -C`.
- [prompt-and-colours.md](references/prompt-and-colours.md) (381) — `fish_prompt`/`fish_right_prompt`,
  `fish_git_prompt` variables, `set_color`, the full `fish_color_*` catalogue, `.theme` file format,
  and the **laramie** theme for fish.
- [bash-to-fish.md](references/bash-to-fish.md) (287) — the translation table for every bash idiom that
  is wrong in fish (`$(...)`, `$?`, `export`, `[[ ]]`, heredocs, `set -euo pipefail`, `<(...)` →
  `psub`), and what fish genuinely lacks. Read this if you catch yourself writing bash.
- [fisher.md](references/fisher.md) (308) — the fisher plugin manager: what it does, XDG-correct
  installation, `fish_plugins`, plugin events, authoring. **Not installed** — this is the plan.
- [fishconf-patterns.md](references/fishconf-patterns.md) (569) — a study of `mattmc3/fishconf` with
  adopt/adapt/skip verdicts. The adoption plan was executed on 2026-07-29; the file leads with the
  outcome and the *refusals and their reasons* (universals, fisher, the `preexecute` dispatcher,
  `MANPATH`). Read it before proposing another fishconf pattern.

## Scripts

- [`scripts/gen-fish-theme.fish`](scripts/gen-fish-theme.fish) — regenerate
  `~/.config/fish/themes/laramie.theme` from the live palette. Run it after editing
  `fish/themes/laramie.fish`. ⚠ The `.theme` file needs **bare** hex; the `.fish` palette keeps the `#`.

## Maintenance — this skill is expected to grow

Fish has a long tail of surprises, and rediscovering one is a documentation defect, not bad luck.
`claude-code/rules/fish.md` makes this mandatory; here is the mechanic:

1. **A surprise costs you a debugging cycle** → append an entry to
   [caveats.md](references/caveats.md) in the same turn, using the entry format at the top of that
   file. Symptom in the heading, mechanism in the body, the verifying command last.
2. **A reference file was wrong or incomplete** → fix it *and* log the correction in `caveats.md`, so
   the next agent knows the belief was actively disproved rather than merely absent. Six entries there
   started as confident assertions during this skill's authoring.
3. **A live config defect** → add it to `caveats.md` → "Live config defects" and to
   [config-layout.md](references/config-layout.md) §7. Delete both when the fix lands.
4. **A new fish subsystem gets used** → extend the owning reference; only add a new reference file if
   none fits, and then add it to the Required-reading table *and* its mirror in
   `claude-code/rules/fish.md`.
5. **Verify before you write it down.** Everything in these files was executed against fish 4.8.1, not
   recalled. `/opt/homebrew/bin/fish --no-config -c '...'` and `fish_indent --check` are the standard.
   An unverified caveat is worse than none.

⚠ Never "fix" a reference from memory. If a claim here looks wrong, reproduce it first — several
entries in `caveats.md` exist precisely because the confident-sounding correction was the wrong one.

---
*User-level skill: it loads in every project on this machine. The always-on subset is
`claude-code/rules/fish.md`; the write-time check is `claude-code/hooks/fish-validate.sh`. Changes to
`~/.config/fish` update this skill in the same change.*
