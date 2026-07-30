# Fish — config layout, startup order, autoloading

Where a line of fish config belongs and when it runs. Covers the full startup sequence, `conf.d`
precedence, `$fish_function_path`/`$fish_complete_path` autoloading, and a file-by-file inventory of
`~/.config/fish` as it actually exists. Formatting rules are in [style-guide.md](style-guide.md);
`fisher` is in [fisher.md](fisher.md).

Everything below was measured on **fish 4.8.1**, `/opt/homebrew/bin/fish`, on this machine.

## 1. Startup sequence, exact order

fish 4.x has **no on-disk `share/fish/config.fish`** — `$__fish_data_dir` contains only `man/`. The
internal init script and the entire standard function/completion library are embedded in the binary.
Retrieve them:

```sh
/opt/homebrew/bin/fish --no-config -c 'status get-file config.fish'
/opt/homebrew/bin/fish --no-config -c 'status get-file functions/fish_add_path.fish'
```

(`functions -D fish_add_path` reports `embedded:functions/fish_add_path.fish`, confirming this.)

Order from process start to first prompt:

| # | What | Notes |
| --- | --- | --- |
| 1 | **embedded `config.fish`** (`status get-file config.fish`) | sets `IFS`, computes `$__fish_vendor_*dirs` from `$__fish_user_data_dir` + `$XDG_DATA_DIRS`, seeds `$fish_function_path`/`$fish_complete_path`, registers `__fish_reconstruct_path` (`--on-variable fish_user_paths`), `fish_sigtrap_handler`, `__fish_on_interactive` |
| 2 | *login only* — macOS `path_helper` equivalent | `if status is-login && command -sq /usr/libexec/path_helper` → `__fish_macos_set_env PATH /etc/paths /etc/paths.d` |
| 3 | `__fish_reconstruct_path` | applies `$fish_user_paths` on top of `$PATH` |
| 4 | *interactive only* — `__fish_theme_migrate`, `fish_config theme choose default --no-override` | |
| 5 | `$__fish_config_dir/conf.d/*.fish` | `/Users/ethan/.config/fish/conf.d/` — sorted, see §2 |
| 6 | `$__fish_sysconf_dir/conf.d/*.fish` | `/opt/homebrew/etc/fish/conf.d/` — **empty on this machine** |
| 7 | each dir in `$__fish_vendor_confdirs`, in listed order | ⚠ none of the five exists on this machine, so nothing runs here |
| 8 | `$__fish_sysconf_dir/config.fish` | `/opt/homebrew/etc/fish/config.fish` — Homebrew's stock file, comments only |
| 9 | `$__fish_config_dir/config.fish` | **last** — `/Users/ethan/.config/fish/config.fish` |

Steps 5–7 are one loop in the embedded init. This is the literal source:

```fish
# As last part of initialization, source the conf directories.
# Implement precedence (User > Admin > Extra (e.g. vendors) > Fish) by basically doing "basename".
set -l sourcelist
for file in $__fish_config_dir/conf.d/*.fish $__fish_sysconf_dir/conf.d/*.fish $__fish_vendor_confdirs/*.fish
    set -l basename (string replace -r '^.*/' '' -- $file)
    contains -- $basename $sourcelist
    and continue
    set sourcelist $sourcelist $basename
    # Also skip non-files or unreadable files.
    # This allows one to use e.g. symlinks to /dev/null to "mask" something (like in systemd).
    test -f $file -a -r $file
    and source $file
end
```

⚠ **Sorting is per-directory, not global.** Every user `conf.d` file runs before every vendor one,
regardless of name. Verified: with `aaa-vendor.fish` in `vendor_conf.d` and `zlower.fish` in the user
`conf.d`, `zlower` ran first.

### Same-basename precedence

> *"If there are multiple files with the same name in these directories, only the first will be
> executed. They are executed in order of their filename, sorted (like globs) in a natural order
> (i.e. "01" sorts before "2")."* — `language.md`, Configuration files

**Verified**, not just documented: `abbrs.fish` placed simultaneously in the user `conf.d`, the
sysconf `conf.d` and a `vendor_conf.d` produced exactly one line of output — the user's. The other two
were skipped by the `contains`/`continue` guard.

The `test -f` guard gives you the masking trick: symlink a name to `/dev/null` in a
higher-precedence directory and the lower-precedence file of that name never runs. Verified —
`ln -sf /dev/null ~/.config/fish/conf.d/foo.fish` suppresses a vendor `foo.fish` and sources nothing
itself. Works on vendor/sysconf snippets only; you cannot mask your own file this way.

### Invocation variants

| Invocation | What changes |
| --- | --- |
| `fish --login` / `-l` | adds step 2 only. **No separate profile file exists** — there is no fish equivalent of `.profile`. Test with `status is-login`. Measured effect here: a login shell gains `/usr/local/bin`, `/System/Cryptexes/App/usr/bin`, the `cryptexd` bootstrap paths and `/pkg/env/global/bin` from `/etc/paths` + `/etc/paths.d`; a non-login shell in a clean env gets only `/bin /sbin /opt/homebrew/{bin,sbin} /usr/bin /usr/sbin` |
| `fish -c '…'` (non-interactive) | **reads every config file anyway.** Only step 4 is skipped (`status is-interactive` is false); 5–9 all run. This is why an unguarded `conf.d` line makes every script slower and noisier |
| `fish --no-config` / `-N` | skips **all** of 5–9 (user + sysconf + vendor `conf.d`, both `config.fish` files). Embedded init still runs, so builtins and shipped functions work |

⚠ `--no-config` also leaves `$fish_function_path` and `$fish_complete_path` **unset** (verified:
`count $fish_function_path` → `0`). So `fish --no-config -c 'reload'` fails with
`Unknown command: reload` — your own functions do not autoload. `--no-config` is for testing a file in
isolation (`--no-config -c 'source <file>'`), not for testing autoloading.

## 2. ⚠ conf.d sort order — verified facts

Re-confirmed on fish 4.8.1 before writing this. Files sort **digits → `_` → letters**, letters
case-insensitively with lowercase first on a tie.

Given `00-num`, `_under`, `abbrs`, `Ahigh`, `zlower`, `Zupper` in one `conf.d`, the observed source
order was exactly:

```
00-num  _under  abbrs  Ahigh  zlower  Zupper
```

and `config.fish` sourced **after** all of them.

Reproduction — throwaway `HOME`/`XDG_CONFIG_HOME`, `echo`-only snippets, no risk to the live config:

```sh
R=$(mktemp -d)
mkdir -p "$R"/cfg/fish/conf.d "$R"/data/fish/vendor_conf.d "$R"/home
for n in 00-num _under abbrs Ahigh zlower Zupper; do
  printf 'echo "user:%s"\n' "$n" > "$R/cfg/fish/conf.d/$n.fish"
done
printf 'echo "user:config.fish"\n' > "$R/cfg/fish/config.fish"
for n in aaa-vendor abbrs zzz-vendor; do
  printf 'echo "vendor:%s"\n' "$n" > "$R/data/fish/vendor_conf.d/$n.fish"
done
env -i HOME="$R/home" XDG_CONFIG_HOME="$R/cfg" XDG_DATA_HOME="$R/data" \
    TERM=dumb PATH=/usr/bin:/bin /opt/homebrew/bin/fish -c true
```

Expect user files in the order above, then `vendor:aaa-vendor`, `vendor:zzz-vendor` (never
`vendor:abbrs`), then `user:config.fish`.

**Consequences.**

- This config's `_init.fish` → `_shell.fish` → tool-files scheme works: `_` beats every letter.
- A numeric prefix beats `_`. Nothing currently needs to run before `_init.fish`, so **do not
  introduce numeric prefixes** — extend the `_` set instead (see [style-guide.md](style-guide.md) §2).
- Case is not a sort key you can rely on for ordering; never distinguish two snippets by case.

## 3. What belongs where

| Kind of config | Destination |
| --- | --- |
| Environment variable, general | `~/.config/fish/conf.d/_init.fish` (`set -gx`) |
| Environment variable owned by one tool | `~/.config/fish/conf.d/<tool>.fish` — e.g. `HOMEBREW_*` → `brew.fish` |
| `PATH` entry | `~/.config/fish/conf.d/<tool>.fish` via `fish_add_path`; never `set -gx PATH` |
| Abbreviation | `~/.config/fish/conf.d/abbrs.fish` |
| Key binding | `~/.config/fish/conf.d/_shell.fish` (interactive-guarded). Docs: *"Put `bind` statements into config.fish or a function called `fish_user_key_bindings`."* Bare `bind` at config time works since fish 3.0; a `functions/fish_user_key_bindings.fish` is the alternative and survives a `fish_key_bindings` switch |
| ⚠ Event handler (`--on-event`, `--on-variable`, `--on-signal`, `--on-job-exit`) | **`conf.d/` only.** Autoloading does not register handlers — *"Autoloading also won't work for event handlers, since fish cannot know that a function is supposed to be executed when an event occurs when it hasn't yet loaded the function."* |
| Function | `~/.config/fish/functions/<name>.fish` (autoloaded, free until first call) |
| Function, domain-grouped | `~/.config/fish/functions/<domain>/<name>.fish` — works only via `_init.fish`, see §4 |
| Completion | `~/.config/fish/completions/<command>.fish` |
| Prompt | `~/.config/fish/functions/fish_prompt.fish` (also `fish_right_prompt.fish`, `fish_mode_prompt.fish`) |
| Colour / theme | `~/.config/fish/themes/<name>.theme`, selected with `fish_config theme choose <name>` from `conf.d/_shell.fish`. `fish_color_*` set directly also belongs in `_shell.fish` |
| Interactive-only tweak | `~/.config/fish/conf.d/_shell.fish`, or `status is-interactive; or return` at the top of a tool file |
| External tool's `init` output | `~/.config/fish/conf.d/<tool>.fish`: `type -q <tool>; or return`, then `<tool> init fish \| source` — cache it to a file if startup cost shows up in the profile |
| Machine-local override | a new `conf.d/local.fish`. Never `config.fish`, and ⚠ never a credentials file — see [style-guide.md](style-guide.md) §9 |

`config.fish` is for **overriding a snippet you cannot edit** — a vendor or sysconf file. That is the
only reason it sources last. Nothing else goes there.

## 4. Autoloading

`$fish_function_path` and `$fish_complete_path` are searched **in order**, first match wins.

- Function `banana` → the first `banana.fish` found in `$fish_function_path`. Loaded on **first
  reference**, and re-read by all running shells when the file's mtime changes.
- Completion for command `git` → the first `git.fish` in `$fish_complete_path`, loaded the first time
  completion for `git` is requested.
- ⚠ **The filename must equal the function name.** A file whose name matches but which does not define
  that function stops the search: *"If a file of the right name doesn't define the function, fish will
  not read other autoload files, instead it will go on to try builtins and finally commands."* That is
  the documented way to mask a lower-precedence function.
- Multiple functions in one file is legal but only the name-matching one triggers the load.
- ⚠ Event handlers are never autoloaded. See §3.

Live values on this machine:

```
$fish_function_path                          $fish_complete_path
/Users/ethan/.config/fish/functions/*/ ←§    /Users/ethan/.config/fish/completions/*/ ←§
/Users/ethan/.config/fish/functions          /Users/ethan/.config/fish/completions
/opt/homebrew/etc/fish/functions             /opt/homebrew/etc/fish/completions
/Users/ethan/.local/share/fish/vendor_functions.d   …/vendor_completions.d
/usr/local/share/fish/vendor_functions.d     /usr/local/share/fish/vendor_completions.d
/usr/share/fish/vendor_functions.d           /usr/share/fish/vendor_completions.d
/Applications/Ghostty.app/…/fish/vendor_functions.d  …/vendor_completions.d
/opt/homebrew/share/fish/vendor_functions.d  /opt/homebrew/share/fish/vendor_completions.d
                                             /Users/ethan/.cache/fish/generated_completions
```

`←§` marks entries that exist **only because of this config**. As of 2026-07-30 the functions glob
expands to **three** directories, in glob order — `functions/grc/`, `functions/internal/`,
`functions/wrappers/` — so those are `$fish_function_path[1..3]` and `~/.config/fish/functions` is
`[4]`. The completions glob still expands to nothing. The three-way split is deliberate and §7
explains the rule; the top level is reserved for commands a **human** types.

⚠ Because the subdirectory entries are **prepended**, `functions/grc/ls.fish` would shadow a
top-level `functions/ls.fish`. Never duplicate a basename across a subdirectory and the top level —
this is why `ls` and `cat` are excluded from the grc set rather than wrapped. With three
subdirectories the same rule now also runs *between* them: `grc/` beats `internal/` beats
`wrappers/`, silently, so a name may appear in at most one.

⚠ Subdirectories under `functions/` and
`completions/` are **not** searched by default. These two lines in `conf.d/_init.fish` are what make
them work — verbatim:

```fish
set fish_function_path (path resolve "$fish_config_dir/functions"/*/) $fish_function_path # to allow subfolders in functions dir
set fish_complete_path (path resolve "$fish_config_dir/completions"/*/) $fish_complete_path # to allow subfolders in completions dir
```

Three things to know about them:

1. They **prepend**, so `functions/git/reload.fish` would shadow `functions/reload.fish`. Do not
   duplicate a basename across a subdirectory and the top level.
2. The `*/` glob is safe when there are no subdirectories — `functions/` currently has none. Normally a
   failed glob aborts the command with status 124, but *"There are exceptions, namely `set` and `path`,
   overriding variables in overrides, `count` and `for`. Their globs will instead expand to zero
   arguments"*. `path resolve` is on that list, so this expands to nothing and the assignment is a no-op.
   Verified: no error, status 0. Change `path resolve` to any other command and startup breaks.
3. ⚠ **Failure mode: the glob runs once, at startup.** Creating `functions/macos/` in a live shell does
   not make it searchable — `exec fish` (or the `refresh` abbreviation) is required. If a brand-new
   namespaced function reports `Unknown command`, restart before debugging anything else.

## 5. `funcsave` / `funced` / `fish_config` — discouraged here

| Command | What it does | What it writes |
| --- | --- | --- |
| `funced NAME` | opens the function in `$VISUAL` (here: `code-insiders --new-window --wait`), reloads it into the session on exit. Edits the *original* file if it can; otherwise a copy | `~/.config/fish/functions/NAME.fish` when the original is not writable |
| `funcsave NAME` | persists the in-memory definition to the autoload directory. `funcsave` after `functions --erase NAME` **deletes** the saved file | `~/.config/fish/functions/NAME.fish` |
| `fish_config theme save` | *(docs: "not recommended")* stores the theme in **universal variables** — and it then stops tracking `$fish_terminal_color_theme` | `~/.config/fish/fish_variables` |
| `fish_config prompt save` | saves the current prompt via `funcsave` | `~/.config/fish/functions/fish_prompt.fish` |
| `fish_config` / `fish_config browse` | starts a local web server + browser (`$BROWSER`, here `open`) to edit prompt/colours interactively | same targets as above |

**House position.** All of these generate files and universal variables behind your back, in fish's
formatting, with no comments and no `--description` discipline — they silently overwrite hand-authored
config. `set -U` is already banned by [style-guide.md](style-guide.md) §3, and `fish_config theme save`
is a `set -U` with extra steps.

**Author the file directly.** If you do reach for `funced` — legitimate for iterating on a prompt in a
real terminal, where nothing else gives you live feedback:

```sh
funced fish_prompt          # iterate
funcsave fish_prompt        # writes ~/.config/fish/functions/fish_prompt.fish
fish_indent -w ~/.config/fish/functions/fish_prompt.fish
git -C ~/.config diff -- fish/functions/fish_prompt.fish    # review before keeping
```

Then add the `--description` and lowercase comments by hand; `funcsave` will not.

## 6. Directory reference

Real values, printed with `/opt/homebrew/bin/fish -c`:

```
__fish_config_dir             /Users/ethan/.config/fish
__fish_data_dir               /opt/homebrew/Cellar/fish/4.8.1/share/fish   (contains only man/)
__fish_sysconf_dir            /opt/homebrew/etc/fish
__fish_user_data_dir          /Users/ethan/.local/share/fish
__fish_vendor_confdirs        /Users/ethan/.local/share/fish/vendor_conf.d
                              /usr/local/share/fish/vendor_conf.d
                              /usr/share/fish/vendor_conf.d
                              /Applications/Ghostty.app/Contents/Resources/ghostty/../fish/vendor_conf.d
                              /opt/homebrew/share/fish/vendor_conf.d
__fish_vendor_functionsdirs   same five paths, vendor_functions.d
__fish_vendor_completionsdirs same five paths, vendor_completions.d
```

Which of those 15 directories actually exist (checked with `test -d`):

| Set | Existing |
| --- | --- |
| `vendor_conf.d` | ⚠ **none** — step 7 sources nothing on this machine |
| `vendor_functions.d` | ⚠ **none** |
| `vendor_completions.d` | two: `/opt/homebrew/share/fish/vendor_completions.d` (23 files, dropped by Homebrew formulae) and Ghostty's — the listed `…/ghostty/../fish/vendor_completions.d` resolves to `/Applications/Ghostty.app/Contents/Resources/fish/vendor_completions.d`, containing `ghostty.fish` |

⚠ Ghostty's shell-integration snippet lives at
`$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish`, and fish
**does** scan it — Ghostty prepends `…/shell-integration` to `XDG_DATA_DIRS`, so step 1 computes
`$__fish_vendor_confdirs` with that directory in it. The snippet's first act is to strip that entry
again, which is why the table above shows no existing `vendor_conf.d`: the measurement is taken after
the strip. Consequences, both verified:

- The manual `source` in `_shell.fish` makes the top-level shell load the snippet **twice** (step 5 by
  hand, step 7 from `vendor_conf.d`). It is written to be re-entrant, so this is harmless.
- A **nested** fish inherits the already-stripped `XDG_DATA_DIRS` and gets **no** integration. That —
  not unreachability — is why the manual source has to stay.

```sh
GI=/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration
XDG_DATA_DIRS=$GI fish -c 'for d in $__fish_vendor_confdirs; test -d $d; and echo $d; end'   # prints it
XDG_DATA_DIRS=$GI/../.. fish -c 'for d in $__fish_vendor_confdirs; test -d $d; and echo $d; end'  # silent
```

⚠ `$__fish_vendor_confdirs` is computed in step 1; changing it from a `conf.d` file has no effect —
*"Note that changing that in a running fish won't do anything as by that point the directories have
already been read."*

| Path | Role | State here |
| --- | --- | --- |
| `~/.config/fish/conf.d/` | sourced snippets, step 5 | 15 files — see §7 |
| `~/.config/fish/functions/` | autoloaded functions | **8** top-level + 14 `grc/` + 3 `internal/` + 3 `wrappers/` = 28 (reorganised 2026-07-30; count with `fd -e fish . fish/functions`). ⚠ all three subdirectories are *prepended* to `$fish_function_path`, so each shadows the top level and, between themselves, glob order decides |
| `~/.config/fish/completions/` | autoloaded completions | 6 files: `op`, `up`, `extract`, `funcfresh`, `cachecmd`, `fishprof` |
| `~/.config/fish/themes/` | `*.theme` files for `fish_config theme` | `laramie.fish` (the `$theme_*` palette, sourced by `conf.d/colours.fish`, hex **with** `#`) and the generated `laramie.theme` (hex **without** `#`). The starship and glamour configs that used to sit here moved to `~/.config/starship.toml` and `~/.config/glamour/` |
| `~/.config/fish/fish_variables` | universal-variable store, fish-managed | present, header comments only — **zero universals**, which is the intended steady state |
| `~/.local/share/fish/fish_history` | **where history actually lives** — `$XDG_DATA_HOME/fish/`, *not* the config dir | present |
| `~/.cache/fish/generated_completions/` | man-page-derived completions, last entry of `$fish_complete_path` | fish-managed |
| `~/.cache/fish/cachecmd/` | `cachecmd`'s store — the four cached tool inits | generated; clear with `funcfresh --cache` |
| ~~`~/.config/fish/plugins/`~~ | ⚠ never a fish convention — fish does not read it | **removed 2026-07-29.** No plugin manager; the decision is to stay vendored, see [fisher.md](fisher.md) |

Verified details: `$fish_history` is empty, meaning the default session, whose file is
`$XDG_DATA_HOME/fish/fish_history`. `set -U` writes to `$__fish_config_dir/fish_variables`, not the
data dir — confirmed by running `set -U` under a throwaway `XDG_CONFIG_HOME` and finding the file
under `cfg/fish/`. Theme files are looked up by `__fish_theme_dir`, which is hardcoded:

```fish
function __fish_theme_dir
    echo $__fish_config_dir/themes
end
```

## 7. This machine's config, file by file

Rewritten **2026-07-29**, after the overhaul that adopted the `mattmc3/fishconf` patterns, then
re-benchmarked the same day. Startup self time went 63.1 ms → 16.4 ms → **10.05 ms** (median of 15
login+interactive startups on a tty; non-interactive `fish -c` is 3.67 ms).

⚠ The 16.4 ms figure came with the note that "6.2 ms is atuin's **unavoidable** per-session
`atuin uuid`". That was wrong — the fork is preemptable by satisfying atuin's own guard with builtins,
and removing it is where most of the second reduction came from. See
[caveats.md](caveats.md) → "atuin's per-session `atuin uuid` fork is **avoidable**".

The largest single line remaining is **not** in this config: fish's own embedded `config.fish` runs
`fish_config theme choose default --no-override` on every interactive startup, with no opt-out
(caveats.md). Treat ~0.5 ms of the total as fish's floor.

⚠ Measure with the median of several runs. Single startups vary by a few ms and outliers of 3× the
median do occur — `fishprof` reports one run, so do not read a 1 ms difference as a regression.

Design rules the layout now enforces:

1. **`conf.d/` wires, `functions/` implements.** Anything not needed at startup is autoloaded.
2. **Anything that forks is cached** — with invalidation, which fishconf's original lacks.
3. **One concern per file**, so an early `return` can only ever skip its own concern.
4. **No universal variables.** `fish_variables` holds nothing but its header comment.

### `conf.d/`, in load order

| File | Owns | Notable |
| --- | --- | --- |
| `_init.fish` | XDG base dirs, `$PROJECTS`/`$DOTFILES`/`$CLAUDE_CONFIG_DIR`, `$FISH_THEMES_DIR`, the `functions/*/` + `completions/*/` autoload globs, core env (`PAGER`/`VISUAL`/`EDITOR`/`BROWSER`) | XDG defaults are conditional (`test -n "$X"; or set -gx …`) so an exported value wins. One guarded `mkdir` via `path filter -vd` replaced five unconditional ones. ⚠ `mkdir -p` with an empty list is an *error*, hence the `test -n "$missing"` guard. No `MANPATH` block — macOS derives it from `$PATH` via `MANPATH_MAP` and setting it explicitly would break that |
| `_shell.fish` | interactive shell behaviour only: greeting, `~/.hushlogin` | Was a four-concern grab-bag behind a `type -q starship; or return 1`. Cursor shape is deliberately absent — Ghostty owns it, and `$fish_cursor_*` only applies under vi bindings |
| `abbrs.fish` | abbreviations | Every target verified to exist. Generated `..2`…`..9` dirstack abbrs (⚠ literal list, not `(seq 2 9)` — that forks), and `!!` via `--function __abbr_last_history_item`. ⚠ `status is-interactive; or return` since 2026-07-29: an abbr only expands in the line editor, so defining 30 of them in a `fish -c` was 0.37 ms nothing could read. The every-target-resolves check must therefore run under `fish -i` |
| `brew.fish` | `$HOMEBREW_PREFIX`, the whole base `$PATH`, 12 `HOMEBREW_*` settings | Absorbed the former `homebrew-first.fish` (keg-only `curl`, prefixed `make`). ⚠ Its four path entries are collected into one local list and added with a **single** `fish_add_path -g -m` — each call fires `__fish_reconstruct_path` and rebuilds all of `$PATH` (~0.55 ms), so the list order *is* the `$PATH` order. ⚠ Never call bare `brew` here — `functions/brew.fish` shadows it during `conf.d` sourcing and would raise a 1Password prompt every start. No `brew shellenv` and no completions block: Homebrew ships to `vendor_completions.d`, which fish already loads |
| `bun.fish` | `BUN_INSTALL_CACHE_DIR`, `BUN_INSTALL_GLOBAL_DIR`, `BUN_INSTALL_BIN`, `BUN_CREATE_DIR`, and `$BUN_INSTALL_BIN` on `$PATH` | ⚠ Must sort **after** `brew.fish`, which resets `set -g fish_user_paths` — an entry added earlier is discarded. `fish_add_path -g -a`: `-a` because the default is *prepend*, and a `bun add -g` package must not shadow a Homebrew binary. ⚠ `mkdir` first — `fish_add_path` silently skips a directory that does not exist. It is a `conf.d/<tool>.fish` rather than an `xdg-apps.fish` block precisely because it touches `$PATH`. ⚠ No `BUN_RUNTIME_TRANSPILER_CACHE_PATH`: bun checks `$XDG_CACHE_HOME` itself first, so the transpiler cache is already XDG-correct. Behaviour (as opposed to location) lives in `$XDG_CONFIG_HOME/.bunfig.toml` — note the leading dot and the absence of a `bun/` subdirectory |
| `colours.fish` | **all** colour: the `$theme_*` palette, `LESS`, `LESS_TERMCAP_*`, `BAT_*`, `MANPAGER`, `LS_COLORS`, `EZA_COLORS`, every `fish_color_*`/`fish_pager_color_*` | Renamed from `theme.fish`; the rename moved it before `fzf.fish` in the sort, which is **load-bearing** — it exports `$theme_*`, which `fzf.fish` reads. The palette is sourced *above* the interactive guard for the same reason. `LS_COLORS` is 8-colour ANSI on purpose, so it inherits whatever the terminal theme is |
| `fzf.fish` | `FZF_DEFAULT_OPTS` (laramie), `FZF_DEFAULT_COMMAND` (fd), the ctrl-r opt-out | ⚠ Must sort before `tools.fish`: `FZF_CTRL_R_COMMAND`, `FZF_CTRL_T_COMMAND` and `FZF_ALT_C_COMMAND` are read at **source** time by `fzf_key_bindings`, unlike the lazy `FZF_DEFAULT_*` |
| `ghostty.fish` | Ghostty shell integration, `COLORTERM` | Split out of `_shell.fish`. `test -r`-guarded, so a non-Ghostty shell is silent. The manual source is what gives *nested* fish shells the integration |
| `git.fish` | `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM=/dev/null`, `GIT_PAGER` | `__git_config_dir` is now `-g`, not `-gx` — only this file reads it. `mkdir` is `test -d`-guarded |
| `gum.fish` | `GUM_FORMAT_THEME` + ~23 `GUM_<COMMAND>_<FLAG>` colours (laramie) | Added 2026-07-29. Its own file rather than a stanza in `colours.fish` because gum has no config file, so the palette *is* two dozen environment variables. ⚠ Deliberately **not** interactive-guarded — a script calling `gum choose` is exactly the caller that needs it, and `functions/reload.fish` is one. ⚠ gum reads `GUM_FORMAT_THEME`, never `GLAMOUR_STYLE`; `xdg-apps.fish` sets the latter for **gh**, from the same json. ⚠ Never export the unprefixed `gum style` variables (`$FOREGROUND`, `$BORDER`, `$PADDING`) — they are not namespaced and would restyle every `gum style` call on the machine |
| `java.fish` | `JAVA_HOME` for the `temurin@25` cask | Added 2026-07-29. ⚠ The JDK path is a **literal**, `test -d`-guarded — `(/usr/libexec/java_home)` forks on every shell start including non-interactive ones, measured at **5.7 ms**, a third of the whole budget. Bump this line and the Brewfile together when temurin moves to 26. Only `JAVA_HOME` is set: macos' `/usr/bin/java*` stubs already dispatch to it, so `$PATH` needs nothing |
| `keybindings.fish` | `alt-e` editor, `ctrl-o` clipboard, `alt-p` pager, `ctrl-z` fg | ⚠ Sorts before `tools.fish`, so anything it binds that a tool init also binds **loses silently**. Nothing here is contested; the header documents the `fish_postinit` escape hatch if that changes |
| `op.fish` | 1Password SSH agent socket, the Claude Code environment id | Unchanged. ⚠ Never source `~/.config/op/plugins.sh` — POSIX shell, fails `fish -n` |
| `tools.fish` | cached inits: fzf, zoxide, starship, atuin | Interactive-only. Each line is `type -q X; and cachecmd --source X …`, with the uncached form as a comment above. ⚠ starship must be `--print-full-init`; ⚠ atuin needs `--disable-ai` and `--depends` on its config file; ⚠ atuin loads last so it wins ctrl-r. ⚠ The atuin block also **seeds `ATUIN_SESSION`/`ATUIN_SHLVL` with builtins before sourcing the cache**, which preempts the `atuin uuid` fork inside the init — 4.5 ms, formerly 31% of startup (caveats.md). Re-measure after an atuin upgrade |
| `xdg-apps.fish` | per-tool XDG env: `less`, `node`, `npm`, `rg`, `wget`, `sqlite3`, `python3` | ⚠ No early `return` — one file, many independent `if` blocks. Sorts last, so it may only hold variables no earlier snippet reads. ⚠ `GNUPGHOME` deliberately absent (repo `CLAUDE.md`) |
| `config.fish` | nothing — documentation only | Sources last. Documents the `emit fish_postinit` epilogue pattern rather than adding an unused emitter |

### `functions/`

Reorganised **2026-07-30** into one rule: **the top level is what a human types.** Everything else
is filed by *who calls it*, in a subdirectory that `_init.fish`'s `functions/*/` glob picks up.

| Where | Holds | Test for "does it belong here?" |
| --- | --- | --- |
| top level | commands you run | you would type it at a prompt |
| `wrappers/` | functions that **shadow a real binary** of the same name | the body contains `command <own-name>`, `op run --` or `op plugin run --` |
| `internal/` | functions only `conf.d/`, another function, or fish itself calls | nothing a human types; renaming it would break a config file, not a habit |
| `grc/` | one `isatty`-guarded grc colouriser per command | it exists solely to add colour to an external tool |

⚠ Do not add a fifth directory casually — every one is another prepended `$fish_function_path` entry
and another shadowing edge (see §4). ⚠ A new subdirectory is invisible until `exec fish`, because
the glob runs once at startup.

| File | Purpose |
| --- | --- |
| `brewup.fish` | The full update command: `brew update`/`upgrade`, then `sudo mas upgrade` **only if `mas outdated` is non-empty**, then `brew cleanup`. Replaced the `brewup` abbreviation — an abbr cannot hold that conditional. ⚠ `mas update` requires root (`mas help update`), which is exactly why the `brew autoupdate` launchd agent does not do it and this does. Ships a private `__brewup_log` that degrades from `gum log` to `printf` |
| `cls.fish` | `clear` plus `\e[3J`, i.e. scrollback too |
| `extract.fish` | `switch`-based archive extractor |
| `fishprof.fish` | `--profile-startup` plus a sorted slow-line report; `--bench` also times repeated startups |
| `funcfresh.fish` | Re-source a function from its defining file (`functions --details`); `--cache` clears the cachecmd store |
| `mcpkill.fish` | Kill stray Godot MCP servers |
| `reload.fish` | Open a fresh terminal window at `$PWD` and close this one. `gum` is guarded; ⚠ `exit` is deliberate |
| `up.fish` | `up 3` → `cd ../../..`, with validation |
| `internal/cachecmd.fish` | The load-bearing one. Caches a command's output under `$XDG_CACHE_HOME/fish/cachecmd/`; `--source` to source it, `--depends` for extra invalidation inputs, `--clear` to discard. Invalidates when any input is newer than the cache, writes atomically, and **refuses to cache a failure** while keeping the previous cache if regeneration fails. ⚠ `argparse --stop-nonopt` is what lets `cachecmd --source fzf --fish` work. ⚠ Internal despite shipping a completion: its callers are `conf.d/tools.fish` and `funcfresh`, and the human-facing spelling of "clear the cache" is `funcfresh --cache` |
| `internal/fish_should_add_to_history.fish` | Keeps `op read`/`op run`, inline `--token=`/`--password=` values, and literal credential shapes out of the history file. ⚠ **fish** is the caller — it looks the name up by autoload like any other function, which is why filing it in a subdirectory is safe (verified 2026-07-30: leading-space returns 1, an ordinary command 0). ⚠ Defining it takes over **all** filtering, so it reimplements the leading-space rule; ⚠ it does not affect atuin, whose own `history_filter` in `~/.config/atuin/config.toml` is the other half |
| `internal/__abbr_last_history_item.fish` | Backs the `!!` abbreviation, called by `abbr --function` at expansion time |
| `wrappers/gh.fish` | `op plugin run -- gh $argv`. ⚠ The matching `brew.fish` was **removed 2026-07-30** — `HOMEBREW_GITHUB_API_TOKEN` buys nothing since Homebrew 4 moved metadata to the JSON API, and it cost a 1Password prompt per session on the most-used command here. Do not restore it without also making `conf.d/brew.fish` use `command brew` |
| `wrappers/claude.fish`, `wrappers/firecrawl.fish` | `op run` wrappers; see the `auth` skill |
| `grc/*.fish` (14) | One autoloaded wrapper per grc-colourised command — `df du ping ps mount netstat ifconfig traceroute lsof uptime last nmap sysctl whois`. Zero startup cost. Each checks `isatty 1` so pipes and command substitutions stay clean. ⚠ `grc <cmd>`, not `grc command <cmd>` |

### `completions/`, `themes/`, and state

| Path | State |
| --- | --- |
| `completions/` | `op.fish` (generated via `cachecmd`) and `bunx.fish` — the two installed tools with no completion from any source; bun ships one for `bun` but none for `bunx`. Plus `up`, `extract`, `funcfresh`, `cachecmd`, `fishprof` |
| `themes/laramie.fish` | The palette: 23 named `$theme_*` colours, hex **with** a leading `#` (`set_color` accepts it). Source of truth |
| `themes/laramie.theme` | Generated by `.claude/skills/fish/scripts/gen-fish-theme.fish` so `fish_config theme list/show` works. ⚠ Bare hex, **no** `#` — a `.theme` file is tokenised, so `#` starts a comment and the value is silently lost |
| `fish_variables` | Header comments only. **Zero universal variables** |
| `~/.cache/fish/cachecmd/` | The four cached tool inits. Regenerated automatically on tool upgrade; `funcfresh --cache` forces it |
| `plugins/` | Removed. No plugin manager — the decision is to stay vendored ([fisher.md](fisher.md) documents what adopting one would cost) |

### Known gaps

| # | Problem |
| --- | --- |
| 1 | **Nothing is version-controlled.** `~/.config/fish` is a plain directory and `~/Projects/dotfiles` has no commits. A dotfiles manager is still undecided; until then a mistake is only recoverable from a shell that is still running |
| 2 | ~~`~/.config/glamour/*.json` is read by nothing~~ — **closed 2026-07-29.** `xdg-apps.fish` sets `GLAMOUR_STYLE` (for gh) and `gum.fish` sets `GUM_FORMAT_THEME`, both pointing at `laramie.json`. Do not re-report |
| 3 | `fzf` has no preview: `FZF_DEFAULT_OPTS` is themed but `FZF_CTRL_T_OPTS`/`FZF_ALT_C_OPTS` are unset, so `ctrl-t` and `alt-c` list bare filenames while `bat` and `eza` sit installed and themed (repo `CLAUDE.md` gap #4) |


## 8. Verification & debugging

```sh
F=/opt/homebrew/bin/fish

# parse only — exit 0 clean, 127 on a syntax error
$F -n ~/.config/fish/conf.d/_init.fish

# formatting is canonical — exit 0; exit 1 and prints the filename when it would reformat
fish_indent --check ~/.config/fish/conf.d/brew.fish
fish_indent ~/.config/fish/conf.d/brew.fish | diff -u ~/.config/fish/conf.d/brew.fish -

# source in isolation: no user config can mask a mistake, no stray output allowed
# ⚠ autoload paths are unset under --no-config; your functions/ will not be found
$F --no-config -c 'source ~/.config/fish/conf.d/git.fish'

# trace exactly which config files are found and sourced
FISH_DEBUG=config $F -c true

# profile startup; column 3 is nesting depth ('>' = top level)
$F --profile-startup=/tmp/fishprof.txt -c exit
awk 'NR==1 || $3==">"{print}' /tmp/fishprof.txt   # top-level timeline
sort -nk2 /tmp/fishprof.txt | tail -15            # worst offenders by cumulative time
awk 'NR>1{s+=$1} END{print s" us total self time"}' /tmp/fishprof.txt

# build facts and embedded sources
$F -c 'status buildinfo'                          # -> CMake / 4.8.1 / aarch64-apple-darwin
$F --no-config -c 'status get-file config.fish'   # fish's own init script
$F -c 'status features'                           # feature-flag state

# reload the current shell (abbreviated as `refresh`)
exec fish
```

### Bisecting a slow or noisy startup

`.fish` is the only extension globbed, so renaming disables a snippet without moving it:

```sh
mv ~/.config/fish/conf.d/abbrs.fish ~/.config/fish/conf.d/abbrs.fish.off
/opt/homebrew/bin/fish -ic exit          # noise gone? that file is the culprit
mv ~/.config/fish/conf.d/abbrs.fish.off ~/.config/fish/conf.d/abbrs.fish
```

For a **vendor or sysconf** snippet you cannot edit, mask it instead — same basename in
`~/.config/fish/conf.d/`, symlinked to `/dev/null` (§1):

```sh
ln -sf /dev/null ~/.config/fish/conf.d/<basename>.fish
```

Halve-and-repeat with a scratch environment when the interaction is between files — this reproduces a
startup without touching the live config at all:

```sh
env -i HOME=/tmp/fh XDG_CONFIG_HOME=/tmp/fh/cfg TERM=dumb PATH=/usr/bin:/bin \
    /opt/homebrew/bin/fish -ic exit
```
