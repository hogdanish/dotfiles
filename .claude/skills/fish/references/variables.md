# Fish — variables, scope, and the special-variable catalogue

Everything about `set`: the five scopes and how fish resolves a read, the complete flag reference,
export semantics, universal variables (and the live `fish_user_paths` problem in this config), lists,
`PATH`, and the full catalogue of variables fish reads or writes. Expansion *syntax* (`$var`, slices,
`$$var`, quoting) lives in [language.md](language.md); the `fish_color_*` palette lives in
[prompt-and-colours.md](prompt-and-colours.md); the `fish_add_path` flag table lives in
[builtins.md](builtins.md).

House rules for scope are law, not taste: [style-guide.md](style-guide.md) §0 and §3.

## The scope model

| Scope | Create with | Lifetime | Visible to |
| --- | --- | --- | --- |
| block-local | `set -l` inside a `begin`/`if`/`for`/`while`/`switch`/`function` block | until the enclosing `end` | that block and nested blocks only |
| function | `set -f` (or bare `set` on a new name inside a function) | until the function returns | the whole function body, all its blocks |
| global | `set -g` | the fish session | every function and every `conf.d` file in this session |
| universal | `set -U` — **forbidden in config**, see below | forever; written to `fish_variables` | every fish session of this user on this machine |
| exported | `-x` — **not a scope**, an attribute on top of one of the above | as its scope | child processes |

Outside any block, `-l` and `-f` are the same thing. Outside any function, a bare `set` with a new
name creates a **global** — which is why `conf.d` files that forget `-l` leak globals silently:

```fish
# _init.fish is sourced at top level, so a bare `set` here would be global.
# the leading `-l` is what keeps this one out of the session.
set -l fish_config_dir "$XDG_CONFIG_HOME/fish"
```

**Resolution order on read.** `$var` uses the *narrowest* scope that has the name: block-local →
function → global → universal. A wider scope is shadowed, not overwritten.

**Resolution order on write.** Bare `set name value` (no scope flag):

1. If any scope already has `name`, the **narrowest** one is updated and its scope is unchanged.
2. Otherwise, the variable is created function-scoped if a function is executing, global if not.

Worked example — block-local shadows global, and the global survives:

```fish
set -g colour blue
echo "top: $colour"
begin
    set -l colour red
    echo "block: $colour"
    set -S colour
end
echo "after: $colour"
```

```
top: blue
block: red
$colour: set in local scope, unexported, with 1 elements
$colour[1]: |red|
$colour: set in global scope, unexported, with 1 elements
$colour[1]: |blue|
after: blue
```

`set -S` is the debugger for this: it lists **every** scope holding the name, narrowest first.

## `set` — complete flag reference

`set` requires all options before any other argument. `set flags -l` sets `$flags` to `-l`.

| Flag | Long | Effect |
| --- | --- | --- |
| `-l` | `--local` | scope to the innermost block; outside a block == `--function` |
| `-f` | `--function` | scope to the executing function; outside a function it does not go out of scope |
| `-g` | `--global` | scope to the session |
| `-U` | `--universal` | persist to `fish_variables`, shared across sessions — **forbidden here** |
| `-x` | `--export` | mark exported (environment variable) |
| `-u` | `--unexport` | mark not exported |
| `-a` | `--append` | append values to the existing list |
| `-p` | `--prepend` | prepend values; may be combined with `-a` |
| `-e` | `--erase` | erase the variable, or `NAME[INDEX]` to erase list elements |
| `-q` | `--query` | test definedness; **return value == number of names that were *not* found** |
| `-n` | `--names` | print names only, sorted; honours scope/attribute filters |
| `-S` | `--show` | describe a name in every scope it exists in; no other flag may be combined |
| `-L` | `--long` | do not abbreviate long values when printing |
| — | `--path` | treat as a path variable: split on `:`, joined by `:` when quoted or exported |
| — | `--unpath` | stop treating as a path variable |
| — | `--no-event` | suppress the `--on-variable` event (only inside a handler for that variable) |

⚠ **In assignment mode `set` does not touch `$status`** — it passes through whatever the previous
command left, which is what makes `if set -l out (some-cmd)` work. A command substitution in the
values *does* set it.

### `-q`/`--query` semantics

The exit status is the **count of names that were not defined**, capped at 255. So it is a *failure
count*, not a boolean, and `set -q a b` is only 0 when **both** exist.

```fish
set -l a 1
set -q a # status 0
set -q a b # status 1  — one of two missing
set -q x y z # status 3
set -q # status 255 — no names given at all
```

`-q` accepts an index (`set -q l[3]`) and filters by scope or attribute:
`set -q -g v`, `set -q -x v`, `set -q --path v` each ask "…and does it match this?".

### Indices, and the three states of a variable

```fish
set -l smurf blue small
set smurf[2] evil # replace one element
set -e smurf[1] # erase one element
echo $smurf # evil
```

⚠ Assigning past the end **does not error** in fish 4.8.1 — it pads with empty strings:

```fish
set -l l a b c
set l[5] z
count $l # 5 — element 4 is now the empty string
```

⚠ `-a`/`-p` cannot be combined with a slice: `set -a l[1] z` is an error (`status 2`).

The unset / empty-list / one-empty-string distinction matters because `test` and `count` disagree
with intuition. All three verified:

| State | `set -q` status | `count $v` | `"$v"` as an argument |
| --- | --- | --- | --- |
| `set -l v` (zero elements) | **0** — it *is* defined | 0 | one empty argument |
| `set -l v ''` (one empty element) | 0 | 1 | one empty argument |
| never set | 1 | 0 | one empty argument |

⚠ The first row is the trap: a variable set to zero elements passes `set -q`, so the house
conditional-default idiom will *not* fill it in. See House idioms below.

⚠ Do not read `$status` in the same command as a command substitution — the substitution runs first
and clobbers it:

```fish
set -l l # defined, zero elements

# wrong — (count $l) runs first and resets $status before the string is built
set -q l
echo "$status;"(count $l) # prints "1;0" — but set -q actually returned 0

# right — capture first, use later
set -q l
set -l found $status
echo "$found;"(count $l) # prints "0;0"
```

## Export semantics

`-x` is an **attribute on the variable in a scope**, not a separate namespace. Rules mirror scoping:
an explicit `-x`/`-u` wins; otherwise the variable keeps whatever it already was; a brand-new
variable is unexported. When an exported variable goes out of scope it is simply gone.

A *local* exported variable is visible to child processes but not to the rest of the file — this is
the scripted form of a `VAR=val cmd` prefix:

```fish
begin
    set -lx SECRET_X hello
    env | grep '^SECRET_X=' # SECRET_X=hello
end
echo "[$SECRET_X]" # []
```

Exported variables are *copied* into functions, so a function can shadow one for its children
without affecting the caller:

```fish
set -gx OUTER 1
function f
    set -lx OUTER 2
    env | grep '^OUTER=' # OUTER=2
end
f
env | grep '^OUTER=' # OUTER=1
```

Un-export without erasing — ⚠ `set -u NAME` with **no values wipes the value to the empty list**,
because "if no VALUE is given, the variable will be set to the empty list" applies to attribute
changes too. Pass the value back:

```fish
# wrong — FOO survives but is now empty
set -u FOO

# right
set -u FOO $FOO
```

The same trap applies to `set --unpath MYPATH` and `set --path MYPATH`.

## ⚠ Universal variables — the trap

`set -U` writes to `~/.config/fish/fish_variables` (format `VERSION: 3.0`, one `SETUVAR name:value`
line per variable, list elements joined by the literal byte `\x1e`). The write propagates instantly
to every running fish and survives reboot. Never hand-edit that file; fish overwrites it.

Why this repo forbids `-U` in config files ([style-guide.md](style-guide.md) §3):

- It is **machine state, not version-controlled config.** A fresh machine from this repo will not
  have it, so behaviour diverges with no diff to point at.
- It **outranks nothing but is written by everything.** A universal value is the widest scope, so a
  later `set -g` in a config file shadows it and hides the stale value — until a bare `set` (no
  scope flag) resolves to the universal and mutates the file behind your back.
- `set -Ua` in a config file grows the list on **every shell start**. The manual says so outright:
  *"Do not append to universal variables in config.fish."*

Find and undo strays:

```fish
set -U --names # every universal variable this user has
set -S fish_user_paths # which scopes hold it, and the values in each
set -eU some_name # erase only the universal copy
set -e -Ug some_name # erase the universal and global copies at once
```

### The live problem: `fish_user_paths` in this config

Two facts, both read from disk:

- `~/.config/fish/fish_variables` contains exactly one line:
  `SETUVAR fish_user_paths:/opt/homebrew/bin\x1e/opt/homebrew/sbin\x1e/bin\x1e/sbin`
- `conf.d/brew.fish` line 4 is `fish_add_path -m "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"`.

`fish_add_path` picks its scope as `$_flag_global $_flag_universal`, and *falls back to `-U` only if
`fish_user_paths` does not already exist*. It exists, universally — so `scope` is **empty**, and the
final `set $scope fish_user_paths $newvar` is a bare `set`, which resolves to the narrowest existing
scope: **universal**. `conf.d/brew.fish` is therefore a config file that writes `fish_variables`.

Current resulting `$PATH` (verified with `/opt/homebrew/bin/fish -c 'echo $fish_user_paths; echo $PATH'`):

```
$fish_user_paths = /opt/homebrew/bin /opt/homebrew/sbin /bin /sbin
$PATH            = /opt/homebrew/bin /opt/homebrew/sbin /bin /sbin
                   /usr/local/bin /System/Cryptexes/App/usr/bin /usr/bin /usr/sbin …
```

How the universal value interferes, reproduced in a sandbox config dir with the *original* ordering
`/bin /sbin /opt/homebrew/bin /opt/homebrew/sbin`:

| `brew.fish` line | resulting `$PATH[1..4]` | `fish_variables` after |
| --- | --- | --- |
| `fish_add_path …/bin …/sbin` (no `-m`) | `/bin /sbin /opt/homebrew/bin /opt/homebrew/sbin` | unchanged — entries already present are skipped |
| `fish_add_path -m …/bin …/sbin` | `/opt/homebrew/bin /opt/homebrew/sbin /bin /sbin` | **rewritten** to the new order |

So `-m` is doing real work — without it `/bin/*` shadows the Homebrew binaries — but it achieves it
by permanently reordering a universal variable. The value on disk today is the *output* of past
`brew.fish` runs, not something anyone typed. Because `-m` always finds both entries already present,
`fish_add_path` issues the `set` on **every** startup — whether that reaches disk when the value is
unchanged is an implementation detail, and not one to rely on.

Two further consequences worth naming:

- `/bin` and `/sbin` in `fish_user_paths` are **redundant**. A login fish with no universal variable
  and no config already produces `/usr/local/bin … /usr/bin /bin /usr/sbin /sbin` from `/etc/paths`.
- `/etc/paths.d/homebrew` contains `/opt/homebrew/bin`, so a bare login fish *appends* it — last on
  `$PATH`. That is the actual reason `-m` is needed.

The fix is **two steps, and both are required.** Declare the variable global before `fish_add_path`
sees it, so the call can never resolve to a universal:

```fish
# conf.d/brew.fish — a global fish_user_paths, rebuilt every session, nothing persisted
set -g fish_user_paths
fish_add_path -gm "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
```

…then erase the universal once, by hand, because ⚠ **shadowing alone leaves residue**. The universal
value is merged into `$PATH` during fish's own startup, before `conf.d` runs; a later empty global
`fish_user_paths` stops *adding* to `$PATH` but does not retract what was already added. Verified in
the sandbox: with the universal still on disk, `/bin /sbin` remain at `$PATH[3..4]`. Only after the
erase does `/bin` fall back to its natural `/etc/paths` position.

```fish
# run once, interactively — never from a config file
set -eU fish_user_paths
```

## Lists

Every fish variable is a list. There are no scalars, and lists cannot nest (fake it with
`$$name` dereferencing — see [language.md](language.md)).

| Operation | Form |
| --- | --- |
| index | `$l[1]` — ⚠ **1-based**; `$l[-1]` is the last |
| slice | `$l[2..3]`, `$l[-2..-1]`, `$l[-1..1]` reverses |
| length | `count $l` — returns status 1 when the count is 0 |
| membership | `contains -- $x $l`; `contains -i -- $x $l` prints the 1-based index |
| append / prepend | `set -a l x`, `set -p l x`, or both at once: `set -a -p l x y` → `x y <old> x y` |
| erase element | `set -e l[2]`, `set -e l[-1]` |
| iterate | `for i in $l` — never `for i in (seq (count $l))` |

⚠ An invalid index expands to **no argument at all**, not an empty string. `echo "n:"$l[9]"|"`
prints an empty line — the whole concatenated word vanishes.

Lists are splatted one element per argument, with no word splitting, which is what makes this safe:

```fish
set -l rg_args --hidden --glob '!.git' 'my string'
rg $rg_args .
```

## `PATH` and path variables

`$PATH` is a **path variable**: a normal list that is split on `:` on the way in and joined with `:`
when quoted or exported. Every variable whose name ends in `PATH` (case-sensitive) is one
automatically; `set --path` / `set --unpath` toggles it for any other name.

```fish
set -l --path p /a /b /c
echo "$p" # /a:/b:/c
echo $p # /a /b /c
```

fish composes `$PATH` as **`$fish_user_paths` followed by the inherited/system path**. On macOS a
**login** shell builds that system part from `/etc/paths` and `/etc/paths.d/*`. Ghostty launches
`fish --login --interactive`, so that parsing applies here.

**Rule: touch `PATH` only through `fish_add_path`.** `set -gx PATH …` is forbidden
([style-guide.md](style-guide.md) §3) — it drops the deduplication, ignores `$fish_user_paths`, and
is trivially order-dependent on `conf.d` load order. Always pass a scope flag so the call cannot
resolve to a universal variable. Full flag table in [builtins.md](builtins.md).

`MANPATH` — an **empty element is meaningful**: it tells `man` to splice its own default search path
in at that position. fish preserves empty elements (it stopped rewriting them to `.` in 2.7), so the
round trip works:

```fish
set -gx MANPATH /opt/local/share/man '' # exported as "/opt/local/share/man:"
```

`CDPATH` — prefixes `cd` tries for a relative argument. Unset by default. Keep `.` first, or `$PWD`
is tried *last*:

```fish
set -gx CDPATH . $PROJECTS
```

## Special-variable catalogue

### Read by fish, set by you

| Variable | Kind | What it does |
| --- | --- | --- |
| `fish_greeting` | list, `-g` | startup greeting. Set empty to silence. Also overridable as a function of the same name |
| `fish_key_bindings` | `-g` | name of the function that installs key bindings (`fish_default_key_bindings`, `fish_vi_key_bindings`, `fish_hybrid_key_bindings`, or your own) |
| `fish_escape_delay_ms` | `-g` | ms fish waits after `escape` to tell the key from a sequence. Default 30 |
| `fish_sequence_key_delay_ms` | `-g` | ms fish waits for the next key of a multi-key binding before treating the first as complete |
| `fish_autosuggestion_enabled` | `-g` | `0` disables autosuggestions; anything else enables. Default on |
| `fish_complete_path` | list, `-g` | directories searched for completions. `_init.fish` prepends `completions/*/`; `brew.fish` appends Homebrew's |
| `fish_function_path` | list, `-g` | directories searched for autoloaded functions. `_init.fish` prepends `functions/*/` |
| `fish_user_paths` | list | prepended to `$PATH`. **Keep it global here** — see the trap above |
| `fish_features` | list | opt-in feature flags (`status features` lists them). ⚠ Only read at startup, and only if universal or **exported** — with `-U` banned, the only config-legal route is `set -gx fish_features …` before fish re-execs, i.e. effectively `fish --features` |
| `fish_history` | `-g` | history session name → separate history file. Empty string = do not persist history |
| `fish_trace` | `-g` | non-empty traces commands to stderr (bash `set -x`). `all` also traces bindings, event handlers, prompt and title functions |
| `fish_cursor_default`, `_insert`, `_replace`, `_replace_one`, `_visual`, `_external` | `-g` | cursor shape per editor mode: `block`, `line`, `underscore` (optionally `blink`) |
| `fish_cursor_selection_mode` | `-g` | `inclusive` or `exclusive` (default) — does the selection include the character under the cursor |
| `fish_ambiguous_width` | `-g` | computed width of ambiguous-width characters: `1` (typical) or `2` |
| `fish_emoji_width` | `-g` | `1` or `2` cells per emoji. Defaults to 2 (Unicode 9 semantics) |
| `fish_handle_reflow` | `-g` | `1` repaints the commandline on terminal resize; anything else disables. Disable in terminals that reflow themselves |
| `fish_transient_prompt` | `-g` | `1` re-renders the prompt with `--final-rendering` before running a command |
| `fish_term24bit` / `fish_term256` | `-g` | `0` downgrades true colour to 256, then to 16 |
| `fish_prompt_pwd_dir_length` | `-g` | characters per path component in `prompt_pwd`. Default 1; `0` disables shortening |
| `fish_read_limit` | `-g` | byte ceiling for `read` and command substitution |
| `umask` | `-g` | file creation mask; prefer the `umask` function |
| `FISH_DEBUG` / `FISH_DEBUG_OUTPUT` | exported | debug categories and the file debug/`fish_trace` output goes to |
| `SHELL_PROMPT_PREFIX` / `SHELL_PROMPT_SUFFIX` / `SHELL_WELCOME` | exported | strings a session manager can inject around the left prompt / after the greeting |
| `fish_color_*`, `fish_pager_color_*` | `-g` | syntax-highlighting and pager palettes — the full list and this repo's `laramie` values are in [prompt-and-colours.md](prompt-and-colours.md) |

### Set by fish, read by you

Most are read-only; `set -S` marks them. Do not try to assign to a read-only one — `set -e` on it
fails too.

| Variable | Kind | What it holds |
| --- | --- | --- |
| `status` | read-only | exit status of the last foreground job. `128 + signum` when signalled. Special values: 121 bad arguments, 123 invalid command name, 124 no wildcard match, 125 not executable by the OS, 126 not executable, 127 not found |
| `status_generation` | read-only | incremented only when a command produced an explicit status — lets you tell "same status" from "ran again" |
| `pipestatus` | list, read-only | one status per process in the last pipeline. `not` applies to `$status` only |
| `argv` | list, writable | arguments to the current function or script. Only defined inside a function or when fish was given arguments |
| `argv_opts` | list, writable | options `argparse` successfully parsed, option-arguments included |
| `PWD` | read-only, exported | current working directory |
| `dirprev` / `dirnext` | `-g` | `cd` history, 25 deep — what `prevd`/`nextd`/`cdh`/`dirh` manipulate |
| `OLDPWD` | exported, writable | ⚠ **not maintained by fish** — it is only passed through from the parent environment. Verified: `cd` leaves it untouched. Use `$dirprev[-1]` or `prevd` |
| `CMD_DURATION` | `-g` | runtime of the last command, milliseconds |
| `SHLVL` | exported | shell nesting depth; fish increments it in interactive shells only |
| `fish_pid` | read-only | this shell's PID (replaces `%self`) |
| `last_pid` | `-g` | PID of the most recent background process |
| `fish_kill_signal` | `-g` | signal that killed the last foreground job, else 0 |
| `fish_killring` | list, `-g` | the kill-ring entries |
| `hostname` | read-only | machine hostname |
| `USER` / `HOME` / `EUID` | exported, writable | username, home directory, effective uid |
| `COLUMNS` / `LINES` | `-g` | terminal size. Only *used* by fish when the OS does not report it, and then both must be set or 80×24 is assumed |
| `version` / `FISH_VERSION` | read-only | `4.8.1` on this machine; the two names are aliases |
| `history` | list, read-only | recent commandlines. Prefer the `history` builtin |
| `fish_terminal_color_theme` | read-only | `light`, `dark`, or `unknown`. Only populated after the first interactive prompt; intended as an `--on-variable` trigger |
| `IFS` | writable | separator for `read`. Empty string also disables line splitting in command substitution |
| `_` | read-only | name of the running command — deprecated, use `status current-command` |

### fish internals (`__fish_*`)

Global, unexported, and the five path ones are read-only. Real values on **this** machine (printed
with plain `/opt/homebrew/bin/fish -c 'echo $__fish_…'`, i.e. with the user's config loaded):

| Variable | Value here |
| --- | --- |
| `__fish_config_dir` | `/Users/ethan/.config/fish` |
| `__fish_data_dir` | `/opt/homebrew/Cellar/fish/4.8.1/share/fish` |
| `__fish_sysconf_dir` | `/opt/homebrew/etc/fish` |
| `__fish_user_data_dir` | `/Users/ethan/.local/share/fish` |
| `__fish_bin_dir` | `/opt/homebrew/Cellar/fish/4.8.1/bin` |
| `__fish_vendor_confdirs` | `~/.local/share/fish/vendor_conf.d` `/usr/local/share/fish/vendor_conf.d` `/usr/share/fish/vendor_conf.d` `/Applications/Ghostty.app/Contents/Resources/ghostty/../fish/vendor_conf.d` `/opt/homebrew/share/fish/vendor_conf.d` |
| `__fish_vendor_functionsdirs` | the same five roots, `vendor_functions.d` |
| `__fish_vendor_completionsdirs` | the same five roots, `vendor_completions.d` |
| `__fish_initialized` | **unset.** fish 4.8.1 stopped creating this universal variable; it exists only as a leftover on machines upgraded from earlier versions, where `set --erase __fish_initialized` removes it |

Prefer `$__fish_config_dir` over `$XDG_CONFIG_HOME/fish` when a script needs the fish config root —
it is what fish itself resolved, including a `--config-dir` override. The vendor dirs are writable,
which is how Ghostty's shell integration is on the list (`conf.d/_shell.fish` sources it explicitly
rather than relying on that).

### Locale and environment fish treats specially

| Variable | Notes |
| --- | --- |
| `LANG` | the locale for every category not otherwise set. Encoding is ignored — fish always assumes UTF-8 |
| `LC_ALL` | overrides `LANG` and all `LC_*`. Temporary overrides only |
| `LC_MESSAGES` | language of messages (see the `_` builtin) |
| `LC_NUMERIC` | number formatting for `printf` |
| `LC_TIME` | date/time rendering, used by `history --show-time` |
| `LANGUAGE` | like `LC_MESSAGES` but a **path variable** — a `:`-priority list of translation languages |
| `TERM` | ⚠ since the `ignore-terminfo` flag became mandatory (4.5) fish no longer looks `$TERM` up in terminfo. It still matters to other programs |
| `COLORTERM` / `TERM_PROGRAM` | not read by fish 4.8.1 for colour decisions (`set_color` emits 24-bit regardless; use `fish_term24bit` to override). `_shell.fish` exports `COLORTERM=truecolor` for **other** tools |
| `EDITOR` / `VISUAL` | `funced`, `alt-e` and `alt-o` use `$VISUAL` first, then `$EDITOR`, then the built-in editor |
| `PAGER` | used by `alt-p`, `history`, and `--help` output (`$MANPAGER` wins for `--help`). Set in `_init.fish` |
| `BROWSER` | which browser `help` opens the fish documentation in. Set in `_init.fish` |
| `TMPDIR` | ⚠ **not** a fish special variable — it appears nowhere in the 4.8.1 manual. Honoured only by whatever program reads it |

## House idioms

**Conditional default** — let an inherited value win. Unconditional `set -gx` overrides a
deliberate export.

```fish
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
```

⚠ `set -q` is true for a variable set to zero elements, so this will not repair `set -gx EDITOR ''`.
When emptiness must also trigger the default, test the value: `test -n "$EDITOR"; or set -gx …`.

**Private global for a derived path** — `__`-prefixed so it cannot collide with a tool's namespace,
then reused by the variables that depend on it (`conf.d/git.fish`):

```fish
set -gx __git_config_dir $XDG_CONFIG_HOME/git
set -gx GIT_CONFIG_GLOBAL "$__git_config_dir/.gitconfig"
```

**Derive a directory, then guarantee it exists.** Every `conf.d` file that names a directory it will
later write to creates it in the same breath:

```fish
mkdir -p $XDG_CONFIG_HOME $XDG_DATA_HOME $XDG_STATE_HOME $XDG_CACHE_HOME
```

**Capture `$status` on the very next line** — anything else, including a command substitution inside
an `echo`, destroys it:

```fish
some-command
set -l rc $status
test $rc -eq 0; or echo >&2 "some-command failed ($rc)"
```

**`set -l` in every function, `-g` only to publish, `-gx` only for children.** A function that
leaves a global behind is a bug unless the global is the point.

**`set -q` as an existence guard before use** — cheaper and safer than `test -n`, and correct for
lists:

```fish
set -q fisher_path; and mkdir -p $fisher_path
```

## Verifying variable work

```sh
/opt/homebrew/bin/fish --no-config -c 'set -S NAME'          # which scopes hold it, isolated
/opt/homebrew/bin/fish -c 'set -S NAME'                      # …with this machine's config
/opt/homebrew/bin/fish -c 'set -U --names'                   # any stray universals?
/opt/homebrew/bin/fish -c 'printf "%s\n" $PATH'              # real resolved path order
/opt/homebrew/bin/fish -c 'fish_add_path -n -m /some/dir'     # the `set` it *would* run
```

⚠ `fish_add_path -n`/`--dry-run` prints the exact `set` command including its scope flags — or their
absence. Use it before adding any path line to a config file; an empty scope in that output means
the line will write `fish_variables`.
