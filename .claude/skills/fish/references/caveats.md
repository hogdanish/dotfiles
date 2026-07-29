# Fish — caveats log

Append-only record of fish behaviour that **surprised someone and cost a debugging cycle**. Read this
first when something is behaving impossibly. Every entry here was verified against fish **4.8.1** on
this machine, not recalled from training data — several contradict what a model will confidently assert.

## How to append (mandatory — see `.claude/rules/fish.md`)

Found a new caveat? Add an entry in the same turn, newest at the top of its section, using this shape:

```markdown
### <one-line symptom, not the cause>
`YYYY-MM-DD` · <where it bit: file, command, or task>
- **Cause** — the actual mechanism, one or two sentences.
- **Do** — the correct form, as code if possible.
- **Verified** — the command that proves it.
```

Rules: state the *symptom* in the heading (that is what a future reader greps for); never delete an
entry, mark it `RESOLVED in <version>` instead; if a caveat contradicts a reference file, **fix that
file too** and note it here. Keep entries under ~6 lines.

---

## Corrections — things widely believed that are false on 4.8.1

These were each asserted confidently during this skill's authoring and then disproved. Assume a model
will get them wrong again.

### fish itself runs `fish_config theme choose` on **every** interactive startup, and there is no opt-out
`2026-07-29` · chasing the largest startup line that is not in `conf.d/`
- **Cause** — the embedded `config.fish` ends with
  `if status is-interactive || set -qgx __fish_force_load_default_theme` → `fish_config theme choose default --no-override`,
  which runs *after* all of `conf.d/`. It reads and tokenises the shipped `default.theme` to fill in any
  `fish_color_*` the config did not set. The only documented variable, `__fish_force_load_default_theme`,
  forces it **on**; nothing turns it off.
- **Consequence** — 0.3–0.5 ms warm and up to 4.4 ms cold, i.e. the biggest remaining line here, and it
  is fish's, not this config's. Setting every `fish_color_*` yourself does not skip it — `--no-override`
  changes what is *applied*, not what is read. Do not "optimise" it by shadowing `fish_config`.
- **Verified** — `fish -c 'status get-file config.fish' | grep -n -B4 'theme choose'` shows the guard;
  the line appears in every interactive profile and in none of the non-interactive ones.

### `set_color` **does** accept a leading `#`, but a `.theme` file does not
`2026-07-29` · authoring `themes/laramie.theme`
- **Cause** — two different parsers. `set_color` strips a leading `#` itself, so
  `set_color '#7aa2f7'` works. A `.theme` file is read with `read -lat toks`, i.e. **fish tokenizer
  rules**, where `#` starts a comment — so `fish_color_normal #a9b1d6` parses to *one* token and the
  variable is set to nothing. It is silent: the line still passes the `^fish_(pager_)?color_` name
  whitelist, so there is no warning and no non-zero status.
- **Do** — `#`-prefixed hex in `themes/*.fish` (consumed by `set_color`), **bare** hex in
  `themes/*.theme`. Generate one from the other rather than hand-keeping both:
  `.claude/skills/fish/scripts/gen-fish-theme.fish`.
- **Verified** — `printf 'fish_color_normal #a9b1d6\n' | while read -lat t; count $t; end` → `1`;
  without the `#` → `2`. `fish -c "set_color '#f7768e'" | cat -v` → `^[[38;2;247;118;142m`.
- Corrected [prompt-and-colours.md](prompt-and-colours.md) §4, which said hex must have "no `#`".

### `edit_command_buffer` and the clipboard functions are **not** bound by default
`2026-07-29` · writing `conf.d/keybindings.fish`
- **Cause** — the manual describes `alt-e`/`alt-v` for `edit_command_buffer` and `ctrl-x`/`ctrl-v`
  for the clipboard helpers, but on 4.8.1 `bind` reports no binding for any of them, preset or user.
  The functions exist; nothing points at them.
- **Do** — bind them yourself. Do not assume a documented default binding exists; check with
  `bind <key>`, which reports `--preset` bindings too.
- **Verified** — `fish -ic 'bind | string match -r ".*edit_command_buffer.*"'` → no output.

### `2>&1 |` is valid fish and must not be "fixed"
`2026-07-28` · authoring `bash-to-fish.md`
- **Cause** — fish creates the pipe first, then applies redirections left to right, so `2>&1` targets
  the already-created pipe. The official manual shows it beside `&|`.
- **Do** — prefer `&|` as the house spelling; never rewrite a working `2>&1 |` as a "bash-ism".
- **Verified** — `fish -c 'begin; echo o; echo e >&2; end 2>&1 | wc -l'` → `2`.

### `test -n $unset` returns true, it does not error
`2026-07-28` · style-guide §3
- **Cause** — the empty list expands to nothing, `test` sees the single argument `-n`, and takes the
  one-argument form: a non-empty *string*, therefore true. Silent logic inversion, no warning.
- **Do** — always `test -n "$var"`. (`test-require-arg` is still off in 4.8.1.)

### `set -q` returns 0 for a variable set to an empty list
`2026-07-28` · the `set -q X; or set -gx X …` default idiom
- **Cause** — `-q` tests *existence*, not emptiness. So the house default idiom will not repair
  `set -gx EDITOR ''`.
- **Do** — when an empty value must also be replaced: `test -n "$EDITOR"; or set -gx EDITOR …`.

### There is no `share/fish/config.fish`, and no `share/fish/themes/`, in fish 4.x
`2026-07-28` · trying to read fish's init logic
- **Cause** — the init script, the standard library and the shipped themes are compiled into the
  binary. `$__fish_data_dir` holds only `man/`.
- **Do** — `status get-file config.fish`, `status list-files themes`, `functions -D <name>`.

### Ghostty's fish integration *is* reachable through `vendor_conf.d` — it hides its own path
`2026-07-28` · guarding the `source` in `conf.d/_shell.fish`
- **Cause** — Ghostty prepends `$GHOSTTY_RESOURCES_DIR/shell-integration` to `XDG_DATA_DIRS`, so
  `$__fish_vendor_confdirs` (computed at step 1) *does* include its `fish/vendor_conf.d`. The snippet
  then strips that entry and erases `GHOSTTY_SHELL_INTEGRATION_XDG_DIR`, so by the time you inspect the
  environment the path is gone and the directory looks like it was never scanned. It was.
- **Consequence** — with the manual `source` in `_shell.fish` the snippet loads **twice** in the
  top-level shell (harmless, it is re-entrant); nested fish shells inherit the stripped `XDG_DATA_DIRS`
  and get **nothing**, which is the real reason to keep the manual source.
- **Verified** — `XDG_DATA_DIRS=<…>/ghostty/shell-integration fish -c 'for d in $__fish_vendor_confdirs; test -d $d; and echo $d; end'`
  prints the directory; with the post-strip value `<…>/ghostty/..` it prints nothing. A scratch config
  reproducing both showed the snippet running twice, then once when the manual source was removed.
- Corrected [config-layout.md](config-layout.md) §6, which claimed the path is "a path fish never scans".

### Vendor `conf.d` runs *after* the user's, and sorting is per-directory
`2026-07-28` · reasoning about load order
- **Cause** — precedence is User > Admin > Vendor > fish, implemented by basename masking. Sorting
  happens within each directory, so a vendor `aaa-x.fish` still runs after a user `zzz-y.fish`.
- **Do** — see [config-layout.md](config-layout.md) §1 for the full sequence.

### Truecolour does not require `$COLORTERM`
`2026-07-28` · authoring the laramie theme
- **Cause** — since 4.1.0 `set_color <hex>` emits `\e[38;2;…m` unconditionally. `_shell.fish` setting
  `COLORTERM` is harmless but not load-bearing. The real switches are `fish_term24bit`/`fish_term256`.

### Assigning past the end of a list does not error
`2026-07-28` · authoring `variables.md`
- **Cause** — `set -l l a b c; set l[5] z` returns 0 and pads the gap with an empty string.
- **Verified** — `count $l` → `5`.

### `__fish_initialized` no longer exists
`2026-07-28` · authoring the special-variable catalogue
- **Cause** — fish 4.8.1 stopped creating it. Any config branching on it takes the unset path forever.

---

## Language and builtin surprises

### every `fish_add_path` call rebuilds the whole of `$PATH` — batch them
`2026-07-29` · `conf.d/brew.fish` made two calls where one would do
- **Cause** — fish's embedded init registers `__fish_reconstruct_path` as an
  `--on-variable fish_user_paths` handler, so the cost is per *call*, not per path. Measured ~0.55 ms
  each; three calls across `brew.fish` and `bun.fish` were 1.6 ms of a 14.6 ms startup.
- **Do** — collect into a local list and make one call: `set -l p a b; set -a p c d; fish_add_path -g -m $p`.
  The list order is the resulting `$PATH` order. Calls in *different* files cannot be merged without
  breaking one-concern-per-file, so leave those alone.
- **Verified** — `diff` of `printf '%s\n' $PATH` from a login+interactive fish before and after was
  empty; the profile shows one `fish_add_path` line where it showed two.

### `mkdir -p` with an empty list is an error, not a no-op
`2026-07-29` · the batched "only create what is missing" idiom in `conf.d/_init.fish`
- **Cause** — an empty fish list expands to *zero arguments*, so `mkdir` gets none and prints its
  usage with status 64. In the steady state (every directory already exists) that is **every**
  startup, so the unguarded form is noisy exactly when it should be silent.
- **Do** — guard on the list, never on the call:
  ```fish
  set -l missing (path filter -vd $wanted)
  test -n "$missing"; and mkdir -p $missing
  ```
- **Verified** — `fish --no-config -c 'set -l m; mkdir -p $m; echo $status'` → usage error, `64`.

### `seq` is an external command — never call it in `conf.d/`
`2026-07-29` · generating the `..N` dirstack abbreviations
- **Cause** — fish ships no `seq` builtin, so `for i in (seq 2 9)` forks. Measured at **1.7 ms**,
  more than every cached tool init in this config combined.
- **Do** — write the literal list (`for i in 2 3 4 5 6 7 8 9`), or `string repeat`/`math` in a loop.
  Startup forks are the only fish performance mistake that matters ([style-guide.md](style-guide.md) §8).

### Bare `(cmd)` does not substitute inside double quotes
`2026-07-28` · writing `complete -a "(generator)"`
- **Cause** — only `$(cmd)` expands inside `"`. This is exactly why 3.4 added `$(…)`.
- **Do** — `"$(cmd)"` to substitute; `'(cmd)'` or `"(cmd)"` to defer (both store the parens literally).
  For `complete`, the real difference between quote styles is *when `$variables` freeze*, not whether
  the command runs.
- **Verified** — `fish -c 'echo "x (echo Y)"'` → `x (echo Y)`.

### A builtin on the receiving end of a pipe sees nothing inside a block or function
`2026-07-28` · authoring `language.md`
- **Cause** — stdin is not threaded into the block for builtins.
- **Do** — `echo x | begin; string upper; end` prints nothing; use `read`, or restructure. External
  commands and `read` are unaffected.

### `path normalize` / `path resolve` return 1 when the path was already canonical
`2026-07-28` · using their status as an existence test
- **Do** — never branch on their exit status. Use `path filter` or `test -e`.

### `path is A B` is true if *any* argument passes
`2026-07-28` · translating `test -f A -a -f B`
- **Do** — `path filter --all` is the "all of them" form.

### `string match`'s glob `*` crosses `/`
`2026-07-28` · filtering paths
- **Cause** — it is string matching, not filename globbing.
- **Verified** — `string match -q '*.fish' -- a/b/c.fish` → true.

### `math -s0` truncates toward zero; it is not floor division
`2026-07-28` · integer arithmetic
- **Verified** — `math -s0 -- -7/2` → `-3`. Use `math -m floor` for flooring.

### `echo $v` prints nothing when `$v` is `-n`
`2026-07-28` · the case for banning `echo`
- **Do** — use `printf` for anything containing a variable, and for anything going to stderr.

### `--argument-names` defines unsupplied names as empty lists
`2026-07-28` · detecting a missing argument
- **Cause** — so `set -q name` is *always* true and can never detect a missing argument.
- **Do** — test `count $argv`, or use `argparse` with `-N`/`--min-args`.

### `argparse --min-args` fires before `$_flag_help` is readable
`2026-07-28` · authoring `builtins.md`
- **Cause** — `-N 1` therefore makes `--help` unreachable. Also, argparse's own flags must precede all
  option specs or you get `Short flag '-' invalid`.

### `exit` inside a function kills the whole shell
`2026-07-28` · authoring `bash-to-fish.md`
- **Do** — `return` in a function. `exit` is only for a script's top level.

### Unmatched globs are an error (status 124), except in a few commands
`2026-07-28` · authoring `language.md`
- **Cause** — exempt: `set`, `path`, `count`, `for`, and environment-override prefixes.

### `${var}` is a hard parse error, and `{1..3}` does not expand
`2026-07-28` · authoring `bash-to-fish.md`

---

## Tooling and environment

### atuin's per-session `atuin uuid` fork is **avoidable** — it was called unavoidable here for a day
`2026-07-29` · a benchmark pass; it was **31% of interactive startup**, the single largest line
- **Cause** — the cached init opens with
  `if not set -q ATUIN_SESSION; or test "$ATUIN_SHLVL" != "$SHLVL"` then `set -gx ATUIN_SESSION (atuin uuid)`.
  Caching the init text cannot remove a fork *inside* it, which is why it was written off. But the
  guard is satisfiable: seed both variables first and atuin's branch never runs. The session id is a
  grouping key stored verbatim in a text column — atuin never parses it as a UUID.
- **Do** — in `conf.d/tools.fish`, before sourcing the cache, reproduce the guard and build the same
  shape (32 lowercase hex) with builtins: `printf '%08x%08x%08x%08x' $fish_pid (random 0 4294967295)×3`.
  Degrades safely — if upstream changes the condition, its own fork returns.
- **Verified** — `atuin uuid` measured 6.9 ms standalone, 4.5 ms in-profile; after the change
  `grep -c 'atuin uuid'` on a fresh profile is `0` and median startup went 14.64 → 10.05 ms over 15
  runs. `history start`/`end`/`search`/`stats`/`doctor` all accept the synthetic id (tested against an
  isolated `ATUIN_DB_PATH`); 200 concurrent shells produced 200 distinct ids. Not logged in to sync, so
  no server-side validation applies.
- Corrected [config-layout.md](config-layout.md) §7, which said "6.2 ms is atuin's **unavoidable**
  per-session `atuin uuid`".

### fish's `--profile-startup` output is space-separated, and continuation rows break naive awk
`2026-07-29` · `functions/fishprof.fish` printed junk rows with no timings
- **Cause** — two things. The columns are **space**-separated (`time`, `sum`, `command`) with *trailing*
  tabs, so `-F'\t'` puts the whole row in `$1`. And a command spanning several source lines is written
  across as many rows, whose continuations begin with a **word**. `awk '$1 > 500'` then compares a
  string to a number *as strings*, so `"string"` and `"while"` pass and print as timing-less garbage.
- **Do** — gate every row on a numeric first field: `NR>1 && $1 ~ /^[0-9]+$/ && $1+0 > t`. Summing was
  never wrong (awk coerces a word to 0), only the filter and the report.
- **Verified** — `fishprof --threshold 150` now prints three real rows where it printed fifteen, of
  which twelve were fragments of `__fish_theme_cat`.

### `cachecmd starship init fish` caches a 70-byte stub and saves nothing
`2026-07-29` · 13 ms of startup that looked cached and was not
- **Cause** — `starship init fish` deliberately emits only a one-line bootstrap,
  `source (starship init fish --print-full-init | psub)`. Caching *that* caches the bootstrap, so
  every shell still forks starship **and** the whole `psub` machinery (`mktemp` + `cat` + `rm`).
- **Do** — cache the thing that is expensive: `cachecmd --source starship init fish --print-full-init`.
  The full init is deterministic; its only per-session value, `$STARSHIP_SESSION_KEY`, is evaluated
  when the cache is sourced, not when it is written.
- **Generalise** — before caching any `<tool> init <shell>`, look at the output. If it is one line,
  you are caching a pointer, not the payload.
- **Verified** — the cache file was 70 bytes; the profile showed `starship … --print-full-init | psub`
  at 6.4 ms cumulative plus 7.8 ms of psub `mktemp`/`cat`/`rm`, on every start.

### atuin's `bind -k` lines are in an **untaken** branch — do not "fix" them
`2026-07-29` · a `string replace` transform in `_shell.fish` that was pure dead code
- **Cause** — `atuin init fish` contains `bind -k up …`, which fish 4 removed. Grepping for it finds
  two hits and suggests a rewrite is needed. It is not: the lines sit in the `else` arm of
  `if string match -q '4.*' $version`, and `$version` is fish's own, so on 4.8.1 the modern arm always
  runs. `bind -k` is a *runtime* argument error, not a parse error, so an untaken branch costs nothing.
- **Do** — when a grep finds a deprecated construct in generated code, check whether the branch is
  reachable before writing a transform around it. The transform cost 21.6 ms per startup and bought
  nothing.
- **Verified** — `atuin init fish | sed -n '180,196p'` shows both arms;
  `fish -i -c 'atuin init fish | source; bind ctrl-r'` is silent and binds correctly.

### atuin binds `?` to a network AI call unless you pass `--disable-ai`
`2026-07-29` · auditing what `atuin init fish` actually installs
- **Cause** — the tail of the init defines `_atuin_ai_question_mark` and does `bind "?"` to it. At an
  empty command line, pressing `?` runs `atuin ai inline --hook`, which calls Atuin's AI service. Every
  other `?` also round-trips through a fish function.
- **Do** — `atuin init fish --disable-ai` unless that is wanted deliberately. Verified the flag removes
  the `?` binding and keeps ctrl-r and up.
- **Verified** — `fish -ic 'bind "?"'` → `bind ? _atuin_ai_question_mark` before, `No binding found` after.

### fzf's ctrl-r opt-out is an **empty but set** variable
`2026-07-29` · giving ctrl-r to atuin without depending on `conf.d` load order
- **Cause** — `fzf --fish` guards its bind with
  `if not set -q FZF_CTRL_R_COMMAND; or test -n "$FZF_CTRL_R_COMMAND"`. Empty-but-set therefore skips
  the binding silently, while any **non-empty** value prints
  `warning: FZF_CTRL_R_COMMAND is set to a custom command…` on every single startup.
- **Do** — `set -g FZF_CTRL_R_COMMAND ''` in a file that sorts **before** the one sourcing
  `fzf --fish`. ⚠ `FZF_CTRL_T_COMMAND` and `FZF_ALT_C_COMMAND` are also read at *source* time; only
  `FZF_DEFAULT_OPTS`/`FZF_DEFAULT_COMMAND` are lazy.
- **Note** — a key sequence holds exactly one command list, so without this the last tool to bind
  ctrl-r wins. That is how fzf silently took ctrl-r from atuin here for months.

### `/opt/homebrew/etc/grc.fish` must never be sourced
`2026-07-29` · wiring up grc
- **Cause** — Homebrew's snippet does `set -U grc_plugin_execs …` (a universal written from config,
  banned by [style-guide.md](style-guide.md) §3), then defines ~40 wrapper functions in a loop at
  source time, and each wrapper runs `eval command $executable $argv` — so a filename containing `;`
  or `$(…)` executes. It also shadows `ls`, `cat`, `diff` and `dig`, all of which are deliberately
  replaced here by eza/bat/delta/doge.
- **Do** — write one autoloaded wrapper per command under `functions/grc/<cmd>.fish`; zero startup
  cost, no universals, no `eval`. ⚠ `grc <cmd>`, not `grc command <cmd>`: grc selects its config file
  by the command *name*, so `grc command df` looks for `conf.command` and emits no colour.

### An early `return` in a multi-concern `conf.d` file silently skips everything below it
`2026-07-29` · `_shell.fish` — `type -q starship; or return 1` above the ghostty and atuin blocks
- **Cause** — `return` at the top level of a sourced file ends **that file**, which is the idiomatic
  early exit and is correct for a single-concern snippet. In a file holding four concerns it couples
  them: a missing starship would have taken ghostty shell integration and all of atuin with it, with
  no error.
- **Do** — one concern per file, so `return` can only ever skip its own concern. Where several
  independent blocks genuinely share a file (`xdg-apps.fish`), guard each block with `if` and say so
  in the header — never `return`.

### A startup error that appears in a real terminal but never under `fish -c`
`2026-07-28` · `conf.d/theme.fish` — `source: missing filename argument or input redirection`
- **Cause** — two mechanisms compounding. `$__fish_themes_dir` does not exist (the real variable is
  `$FISH_THEMES_DIR`, or `__fish_theme_dir`), so `$__fish_themes_dir/$THEME.fish` annihilated the whole
  token ([language.md](language.md) §4) and `source` got **zero arguments**. `source` with no arguments
  reads **stdin** — so with stdin a pipe or `/dev/null` it hits EOF and silently succeeds, and only on a
  **tty** does it error. Every check in [style-guide.md](style-guide.md)'s review checklist redirects
  stdin, so all three passed on a file that was broken at every real startup.
- **Consequence** — the theme never applied either. Each `fish_color_*` was assigned an unset variable,
  i.e. a **zero-element list**, which fish treats as unset and falls back to its own defaults. A theme
  that reads as "applied" in the file and is not, with no error beyond the one `source` line.
- **Do** — add a pty startup to the checklist whenever a `conf.d` file is touched, and never let
  `source` take a bare variable:
  ```fish
  set -l palette "$FISH_THEMES_DIR/$THEME.fish"
  test -r "$palette"; or return 1   # guard, so a bad path fails loudly instead of reading stdin
  source $palette
  ```
- **Verified** — `script -q /dev/null fish --login --interactive -c exit` reproduces it;
  `fish -c true` and `fish --no-config -c 'source conf.d/theme.fish'` both exit 0 on the same file.
  `fish --no-config -c 'set -l e; source $e'` → the error on a tty, status 1.

### `--no-config` cannot test autoloading or universals
`2026-07-28` · the style guide's isolation check
- **Cause** — it leaves `$fish_function_path` unset and demotes `set -U` to global.
- **Do** — use it to prove a file is self-contained and quiet; use `exec fish` to prove it works.

### A misspelled `fish_color_*` in a `.theme` file is silently dropped
`2026-07-28` · authoring the laramie theme
- **Cause** — no warning, zero exit status, no variable set. The warning loop in `__fish_theme_cat`
  matches the wrong variable, so it never fires.
- **Do** — spell-check against the table in [prompt-and-colours.md](prompt-and-colours.md) §5.

### Four `fish_color_*` variables look real but are never read
`2026-07-28` · copying from a shipped theme
- **Cause** — `fish_color_background`, `fish_color_match`, `fish_color_statement_terminator`,
  `fish_color_gray` pass the `.theme` whitelist but fish 4.8.1 ignores them. Shipped
  Catppuccin/tokyonight themes set some of them, so copying from them imports dead config.

### `$FISH_THEMES_DIR` is decorative
`2026-07-28` · `conf.d/_init.fish`
- **Cause** — fish never reads it; `__fish_theme_dir` hardcodes `$__fish_config_dir/themes`.

### `__fish_no_arguments` is unusable in a completion
`2026-07-28` · authoring `completions.md`
- **Cause** — in a completion context `commandline -tc` yields one empty element, so its loop always
  hits `case '*'` and returns 1 — the completion is never offered.
- **Do** — `__fish_use_subcommand` or `__fish_is_first_arg`.

### fish only autoloads `completions/<cmd>.fish` when `<cmd>` resolves
`2026-07-28` · testing a completion for an unwritten tool
- **Do** — `source` the completion file explicitly, then `complete -C '<cmd> '`.

### A non-interactive `fisher install` hangs
`2026-07-28` · scripted plugin install
- **Cause** — `isatty || read` waits on stdin.
- **Do** — redirect: `fisher install owner/repo </dev/null`.

---

## Live config defects

Tracked here only while unfixed; the current-state inventory is
[config-layout.md](config-layout.md) §7. Delete an entry when the fix lands.

### ~~`conf.d/brew.fish` uses `$HOMEBREW_PREFIX` 14 lines before setting it~~ — RESOLVED
`2026-07-28` · `$PATH` order was non-deterministic; **fixed 2026-07-28**
- **Cause** — Ghostty launches fish directly with no zsh, so the variable was unset and
  `"$HOMEBREW_PREFIX/bin"` expanded to literal `/bin`. `fish_add_path -m` then moved `/bin` and
  `/sbin` to the front of `$PATH` **and persisted it to `fish_variables`**.
- **Outcome** — the prefix is now set first, `set -g fish_user_paths` precedes `fish_add_path -g -m`,
  and the stale universal was erased. Verified: `$PATH` leads with the Homebrew entries.

### ~~`conf.d/_shell.fish` writes a universal `STARSHIP_CONFIG`~~ — RESOLVED
`2026-07-29` · `set -Ux STARSHIP_CONFIG` re-issued on every interactive start
- **Cause** — a universal variable written from a config file, banned by
  [style-guide.md](style-guide.md) §3. It was the only entry in `fish_variables`.
- **Outcome** — `themes/starship.toml` moved to `~/.config/starship.toml`, starship's own default
  location, so the variable is not needed at all. The universal was erased with `set -eU` once
  interactively — ⚠ deleting the line does **not** delete the universal.
- **Verified** — `fish -c 'set -U --names'` prints nothing; `fish_variables` holds only its header.

### ~~`conf.d/secrets.fish` holds plaintext credentials~~ — RESOLVED
`2026-07-28` · four live API tokens as environment variables; **file retired the same day**
- **Outcome** — moved to the `Claude Code` 1Password Environment, consumed by `functions/claude.fish`
  via `op run --no-masking --environment`. Verified: a fresh login fish exports none of the four.
- **⚠ Never recreate it.** A shell that needs a credential gets it at the moment of use.

### ~~Live files fail `fish_indent --check`~~ — RESOLVED
`2026-07-29` · `abbrs.fish`, `tools.fish`, `cachecmd.fish`
- **Outcome** — `fish_indent -w` on each, plus `.editorconfig` at the repo root so an editor
  enforces it on save. Every `.fish` file under `~/.config/fish` now passes both
  `fish_indent --check` and `fish -n`. The `fish-validate.sh` hook catches regressions on write.

### ~~`abbrs.fish` references three commands that do not exist~~ — RESOLVED
`2026-07-29` · `cls`, `tre`, `z`
- **Outcome** — `cls` is now `functions/cls.fish`; `tree` points at `eza --tree` instead of the
  uninstalled `tre`; `z` works because zoxide is initialised in `conf.d/tools.fish`. An
  every-target-resolves check is in the fish skill's verification section — run it after editing
  `abbrs.fish`.

### ⚠ `~/.config/op/plugins.sh` is POSIX shell and cannot be sourced from fish
`2026-07-28` · `op plugin init` tells you to source it; doing so errors on every fish start
- **Cause** — `op plugin init` writes POSIX function definitions (`gh() { op plugin run -- gh "$@" }`)
  regardless of the invoking shell. `op plugin init --help` even suggests adding the `source` line to
  `~/.config/fish/config.fish`. It does not parse as fish.
- **Verified** — `fish -n ~/.config/op/plugins.sh` →
  `command substitutions not allowed in command position` at `brew() {`.
- **Do** — write one autoloaded `functions/<cli>.fish` per plugin calling `op plugin run -- <cli> $argv`.
  No recursion: `op plugin run` resolves the binary from `$PATH` in a fresh process where the fish
  function does not exist. Plugin state lives in `~/.config/op/plugins/*.json` and needs no wiring.
- **⚠ Knock-on** — an autoloaded `brew` function is visible *during `conf.d` sourcing*, so any startup
  snippet calling `brew` (e.g. a cached `brew shellenv`) must use `command brew` or every shell start
  raises a 1Password prompt. Same trap for any wrapped CLI a `conf.d` file invokes.

### `fish_add_path -g` snapshots a stale universal instead of clearing it
`2026-07-28` · fixing `brew.fish` alone did not remove `/bin` and `/sbin` from `$PATH`
- **Cause** — `fish_add_path -g` reads whatever `fish_user_paths` currently holds (the universal) and
  copies it into the new global, preserving the junk. Shadowing also leaves residue: the universal is
  merged into `$PATH` during fish's own startup, *before* `conf.d` runs.
- **Do** — three things, in order: `set -eU fish_user_paths` once interactively; `set -g
  fish_user_paths` (empty) in the first `conf.d` file that touches the path; then `fish_add_path -g -m`.
- **Verified** — `env -i HOME=$HOME TERM=xterm fish -l -c 'printf "%s\n" $PATH'` now leads with
  `/opt/homebrew/bin`, and `/bin` fell back to its natural `/etc/paths` position.

### Claude Code's Bash tool is a *non-interactive login* zsh
`2026-07-28` · aliases and `~/.zshrc` are unreachable, but the fish environment is inherited
- **Cause** — the tool spawns `/bin/zsh -l` without `-i`. `~/.zprofile` is read; `~/.zshrc` is **not**;
  aliases do not expand. But `claude` itself is launched *from fish*, so the whole fish environment is
  inherited by the tool's subprocesses.
- **Consequence** — `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM`, `CLAUDE_CONFIG_DIR` and any `-gx` from
  `conf.d/` **are** set in Bash tool calls (contradicting an earlier note in `CLAUDE.md`), while no
  fish function, abbreviation or `plugins.sh` alias ever is.
- **Verified** — `[[ -o interactive ]]` → false, `[[ -o login ]]` → true; `echo $GIT_CONFIG_GLOBAL` →
  `/Users/ethan/.config/git/.gitconfig`.
