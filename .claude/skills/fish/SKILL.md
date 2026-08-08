---
name: fish
description: Fish shell (4.8.1) for this dotfiles repo — the mandatory house style guide, the language (expansions, lists, control flow, $status), builtins (string/path/argparse/set/test/math), variable scoping and the special-variable catalogue, conf.d/functions/completions load order and autoloading, abbr/bind/commandline, prompt and fish_color_* theming for laramie, writing completions, startup-cost caching via cachecmd, the mattmc3/fishconf adoption record, and an append-only caveats log of verified 4.8.1 behaviour that contradicts common assumptions. Covers the live config at ~/.config/fish — the 17 conf.d snippets (_init, _shell, abbrs, brew, bun, colours, fzf, ghostty, git, gum, java, keybindings, op, rust, tools, uv, xdg-apps), functions/ incl. cachecmd and the grc/ wrappers, completions/, and themes/laramie.
when_to_use: Load before writing or editing any .fish file, anything under ~/.config/fish, or a fish function, completion, abbreviation, key binding or prompt — and whenever fish behaviour, startup order, shell startup cost, or a bash idiom needing a fish translation is in question. Also for tool integrations (fzf/zoxide/atuin/starship/grc), fish theming, and before proposing a plugin manager or another fishconf pattern. Boundary- this owns the fish side only; git/delta/ghostty/micro configuration lives with those tools even though fish exports their variables.
---

# Fish shell

**Do not ration your reading.** Read [style-guide.md](references/style-guide.md) plus **every file in
the Required-reading row matching your task** — the rows below are floors, not menus. Each reference is
287–613 lines, and the line count is listed so you never have to guess the cost: reading four of them
is cheaper than one wrong `set -gx` that silently rewrites `fish_variables`. When two rows could apply,
read both. When unsure, read more. Skipping a listed file to save tokens is the single most common way
fish work goes wrong here.

fish **4.8.1** (`/opt/homebrew/bin/fish`) is the interactive shell on this machine. `/bin/zsh` is still
the login shell and is deliberately unconfigured — Ghostty launches fish explicitly. All real shell
configuration is fish, and it lives in **`~/.config/fish`, edited in place** (this repo holds no mirror;
see the repo `CLAUDE.md`).

⚠ **Bash tool calls run under zsh.** Fish functions and abbreviations are not available to you. To
exercise anything fish, call it explicitly: `/opt/homebrew/bin/fish -c '...'`, and add `--no-config`
when the user's config must not mask the result.

## The style guide is law

[style-guide.md](references/style-guide.md) is **mandatory** for every `.fish` file. Read it before
writing fish, not after. Its five load-bearing rules, in brief — the guide has the reasoning:

1. `set -l` by default; `-gx` only for real environment variables; **never `set -U`** in a config file.
2. `--on-event` / `--on-variable` handlers only register when a file is *sourced* → they belong in
   `conf.d/`, never `functions/`.
3. Guard everything: `type -q <cmd>` before an external tool, `test -r <file>` before an optional file.
4. `string` and `path` builtins instead of `sed`/`grep`/`basename` — startup forks are the only fish
   performance mistake that matters.
5. `fish_indent` decides all formatting. 4 spaces. No `alias`. `--description` on every function.

## How this config loads

`conf.d/*` sources **before** `config.fish`, sorted `digits` → `_` → `letters` (verified on 4.8.1). The
`_` prefix is this config's ordering mechanism. Load order as of 2026-08-07 — **seventeen** snippets:

| # | File | Role |
| --- | --- | --- |
| 1 | `_init.fish` | XDG dirs, `$PROJECTS`/`$DOTFILES`/`$CLAUDE_CONFIG_DIR`/`$CODEX_HOME`, the `functions/*/` + `completions/*/` autoload globs, core env (`PAGER`/`VISUAL`/`EDITOR`/`BROWSER`) |
| 2 | `_shell.fish` | interactive shell behaviour only — greeting, `~/.hushlogin` |
| 3 | `abbrs.fish` | abbreviations |
| 4 | `brew.fish` | `$HOMEBREW_PREFIX`, the whole base `$PATH`, `HOMEBREW_*` |
| 5 | `bun.fish` | `BUN_INSTALL_*`/`BUN_CREATE_DIR` → XDG, and `$BUN_INSTALL_BIN` on `$PATH` — ⚠ must follow `brew.fish` |
| 6 | `colours.fish` | **all** colour: the `$theme_*` palette, `LESS*`, `BAT_*`, `MANPAGER`, `LS_COLORS`/`EZA_COLORS`, every `fish_color_*` |
| 7 | `fzf.fish` | `FZF_*` — ⚠ must precede `tools.fish` |
| 8 | `ghostty.fish` | terminal shell integration, `COLORTERM` |
| 9 | `git.fish` | `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM`, `GIT_PAGER` |
| 10 | `gum.fish` | ~24 `GUM_*` laramie accents + `GUM_FORMAT_THEME` — ⚠ *not* interactive-guarded, scripts need it (`gum` skill) |
| 11 | `java.fish` | `$JAVA_HOME` — ⚠ hardcoded, not `/usr/libexec/java_home` (a 5.7 ms fork) |
| 12 | `keybindings.fish` | `bind` statements — ⚠ loses any key a tool init later binds |
| 13 | `op.fish` | 1Password agent socket, Claude Code and Codex environment ids |
| 14 | `rust.fish` | rustup/Cargo XDG homes, sccache cache, and rustup's keg-only paths |
| 15 | `tools.fish` | cached inits: fzf, zoxide, starship, atuin |
| 16 | `uv.fish` | `~/.local/bin` (uv's tool-shim dir) on `$PATH` — ⚠ must follow `brew.fish`, same as `bun.fish` |
| 17 | `xdg-apps.fish` | per-tool XDG env incl. `GLAMOUR_STYLE` — ⚠ sorts last, so nothing earlier may read it |
| last | `config.fish` | documentation only |

Four ordering facts are **load-bearing**, not incidental: `bun` after `brew` (`brew.fish` resets
`set -g fish_user_paths`, so a `fish_add_path` before it is discarded); `colours` before `fzf` (it
exports the palette `fzf.fish` reads); `fzf` before `tools` (`FZF_CTRL_R_COMMAND` is read at source
time); and atuin last within `tools.fish` (whichever tool binds a key last wins). Anything later files depend on
goes in `_init.fish`; new tool config gets its own `conf.d/<tool>.fish`, never `config.fish`. Full
sequence, autoloading semantics and a file-by-file inventory:
[config-layout.md](references/config-layout.md).

⚠ `conf.d/secrets.fish` was **retired 2026-07-28** and must never be recreated — credentials come
from 1Password at the moment of use. See the `auth` skill.

## Verify a change

```sh
fish_indent --check <file>                        # formatting is canonical (exit 0)
/opt/homebrew/bin/fish -n <file>                  # parses
/opt/homebrew/bin/fish --no-config -c 'source <file>'   # sources clean, no stray output
script -q /dev/null /opt/homebrew/bin/fish --login --interactive -c exit   # a real startup, on a tty

# no universal variables may survive — the steady state is zero
/opt/homebrew/bin/fish -c 'set -U --names'        # must print nothing

# after touching abbrs.fish: every target must actually exist.
# ⚠ write it to a FILE and run that. inlining it after `-c` nests three levels of quoting
# (zsh -> fish -> the trim character) and the innermost one never survives — the 2026-07-29
# version used `-c "\x27"`, which fish does NOT expand inside double quotes, so it trimmed the
# literal characters \ x 2 7 and reported all 13 quoted abbreviations as DEAD. false alarm.
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

⚠ `--no-config` leaves `$fish_function_path` unset, so it proves a file is *self-contained and quiet*,
not that it works — autoloaded functions will look missing. Startup got slow?
`fish --profile-startup=/tmp/fishprof.txt -c exit`.

⚠ **The first three checks all redirect stdin, so a whole class of startup error is invisible to them** —
run the `script` line too. `conf.d/theme.fish` passed all three for months while erroring in every real
window, because `source` with no arguments reads stdin and only fails on a tty
([caveats.md](references/caveats.md)).

## Required reading

`style-guide.md` is mandatory for every fish task. Then read **all** of the matching row.

<!-- duplicated in .claude/rules/fish.md so it is guaranteed present even unloaded — change both -->

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

- [caveats.md](references/caveats.md) (207) — **read first when debugging.** Verified fish behaviour
  that contradicts what a model will confidently assert, plus the live config's open defects. Several
  entries were disproved premises from this skill's own authoring. Append to it — see Maintenance.
- [style-guide.md](references/style-guide.md) (374) — **mandatory.** House rules, naming, scope discipline,
  and complete annotated templates for a `conf.d` snippet, a function, a namespaced helper, a
  completion, and a standalone script. Plus the pre-commit review checklist.
- [language.md](references/language.md) (573) — the language: quoting, the full expansion set, lists as the
  only data type, redirection and pipes, conditionals, loops, functions, `$status` and error handling
  (fish has no `set -e`), debugging.
- [builtins.md](references/builtins.md) (613) — `argparse` in full, `test` operators, `status`, introspection
  (`type`/`functions`/`command`), `fish_add_path`, and an index of all 125 shipped commands.
- [text-processing.md](references/text-processing.md) (515) — `string`, `path`, `math`, `printf`, `read`, and
  a unix-pipeline → fish-builtin translation table. Read this instead of reaching for `sed`.
- [variables.md](references/variables.md) (504) — the five scopes, `set` flags, export semantics, the
  universal-variable trap (and the live `fish_user_paths` conflict), `PATH` handling, and the complete
  special-variable catalogue with this machine's real values.
- [config-layout.md](references/config-layout.md) (396) — startup order end to end, `conf.d` precedence,
  autoloading, "what belongs where" decision table, this config file-by-file, and its known gaps.
- [interactive.md](references/interactive.md) (416) — `abbr` (incl. regex and function abbreviations),
  `bind` and fish 4.x key notation, `commandline`, event handlers and `emit`, history, shell integration.
- [completions.md](references/completions.md) (302) — writing completions: the `complete` flag table, dynamic
  arguments, the `__fish_*` condition helpers, the subcommand pattern, and testing with `complete -C`.
- [prompt-and-colours.md](references/prompt-and-colours.md) (420) — `fish_prompt`/`fish_right_prompt`,
  `fish_git_prompt` variables, `set_color`, the full `fish_color_*` catalogue, `.theme` file format,
  and a ready-to-use **laramie** theme for fish (the one tool still missing the palette).
- [bash-to-fish.md](references/bash-to-fish.md) (287) — the translation table for every bash idiom that is
  wrong in fish (`$(...)`, `$?`, `export`, `[[ ]]`, heredocs, `set -euo pipefail`, `<(...)` → `psub`),
  and what fish genuinely lacks. Read this if you catch yourself writing bash.
- [fisher.md](references/fisher.md) (308) — the fisher plugin manager: what it actually does, XDG-correct
  installation, `fish_plugins`, plugin events, and authoring. **Not yet installed** — this is the plan.
- [fishconf-patterns.md](references/fishconf-patterns.md) — a study of `mattmc3/fishconf` with
  adopt/adapt/skip verdicts. **The adoption plan was executed on 2026-07-29**; the file now leads with
  the outcome and, more usefully, the *refusals and their reasons* (universals, fisher, the
  `preexecute` dispatcher, `MANPATH`). Read it before proposing another fishconf pattern.

## Scripts

- [`scripts/gen-fish-theme.fish`](scripts/gen-fish-theme.fish) — regenerate
  `~/.config/fish/themes/laramie.theme` from the live palette. Run it after editing
  `themes/laramie.fish`. ⚠ The `.theme` file needs **bare** hex; the `.fish` palette keeps the `#`.

## Maintenance — this skill is expected to grow

Fish has a long tail of surprises, and rediscovering one is a documentation defect, not bad luck.
`.claude/rules/fish.md` makes this mandatory; here is the mechanic:

1. **A surprise costs you a debugging cycle** → append an entry to
   [caveats.md](references/caveats.md) in the same turn, using the entry format at the top of that file.
   Symptom in the heading, mechanism in the body, the verifying command last.
2. **A reference file was wrong or incomplete** → fix it *and* log the correction in `caveats.md`, so
   the next agent knows the belief was actively disproved rather than merely absent. Six entries there
   started as confident assertions during this skill's authoring.
3. **A live config defect** → add it to `caveats.md` → "Live config defects" and to
   [config-layout.md](references/config-layout.md) §7. Delete both when the fix lands.
4. **A new fish subsystem gets used here** (a plugin manager, a prompt framework, a new tool's
   `conf.d` snippet) → extend the owning reference; only add a new reference file if no existing one
   fits, and then add it to the Required-reading table *and* the mirror in `.claude/rules/fish.md`.
5. **Verify before you write it down.** Everything in these files was executed against fish 4.8.1, not
   recalled. `/opt/homebrew/bin/fish --no-config -c '...'` and `fish_indent --check` are the standard.
   An unverified caveat is worse than none.

⚠ Never "fix" a reference from memory. If a claim here looks wrong, reproduce it first — several
entries in `caveats.md` exist precisely because the confident-sounding correction was the wrong one.

---
*Source of truth for fish in this repo — update it in the same change as `~/.config/fish`.
The always-on subset lives in `.claude/rules/fish.md`; the write-time check is
`.claude/hooks/fish-validate.sh`.*
