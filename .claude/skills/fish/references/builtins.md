# Fish — builtin command reference

Argument parsing (`argparse`), conditionals (`test`), runtime introspection (`status`, `type`,
`functions`, `command`, `builtin`), the small load-bearing builtins, `fish_add_path`, and a complete
index of all 125 commands fish 4.8.1 ships. `string`/`path`/`math`/`printf` are in
[text-processing.md](text-processing.md); `set`, scoping and special variables in
[variables.md](variables.md). Formatting and guard law: [style-guide.md](style-guide.md).

## 1. `argparse` — complete

Mandatory for any function taking flags ([style-guide.md](style-guide.md) §6). Shape:
`argparse [ARGPARSE-FLAGS] OPTION_SPEC ... -- [ARG ...]`. The `--` is **required** even with no specs;
it separates argparse's own flags and the specs from the arguments, and a second `--` inside `ARG` is
passed through untouched.

### Option spec grammar

| Spec | Accepts | `_flag_*` holds | Notes |
| --- | --- | --- | --- |
| `h/help` | `-h`, `--help` | `_flag_h` **and** `_flag_help` | boolean, repeatable |
| `help` | `--help` only | `_flag_help` | `/` omissible with no short flag and a name >1 char |
| `/x` | `--x` only | `_flag_x` | long form of a 1-char name |
| `q` | `-q` only | `_flag_q` | short-only boolean |
| `n/name=` | value **required** | last value | `--name a --name b` → `b` |
| `n/name=?` | value **optional** | last value | value must be *attached* |
| `name=+` | value required, repeatable | every value | list |
| `n/name=*` | value optional, repeatable | every value | empty string where the value was omitted |
| `n#count` | `-55`, `-n 55`, `--count 55` | `_flag_n`, `_flag_count` | integer flag, matches `^--?\d+$`; no other modifier allowed |
| `#count` | `-55`, `--count 55` | `_flag_count` | long-only integer flag |
| `help&` | as `help` | unchanged | `&` also strips the flag from `$argv_opts` (4.1.0+) |
| `d/dir=!CODE` | value required, validated | value if `CODE` returns 0 | see validators |

⚠ **`=?` / `=*` values must be attached.** `--flag=value` and `-fvalue` work; `--flag value` leaves the
flag valueless and `value` becomes a positional — `getopt(3)` behaviour, not a fish quirk. Verified:
`argparse c/colour=? -- --colour auto extra` leaves `$_flag_colour` empty with `$argv` = `auto extra`,
while `--colour=auto extra` gives `$_flag_colour` = `auto`, `$argv` = `extra`.

### What the variables hold

- **Local** scope, as if `set -l`. Unset entirely when the flag was absent — so the test is always
  `set -q _flag_x`, never `test -n "$_flag_x"`.
- **Booleans** hold each form of the flag as typed, once per occurrence:
  `argparse h/help -- -h -h --help` → `$_flag_h` = `-h -h --help`, `count $_flag_h` = 3. That count is
  how you implement `-vv` verbosity levels.
- Characters invalid in a variable name become `_`: `--dry-run` → `$_flag_dry_run`.
- `$argv` is reset to the leftover positionals. `$argv_opts` (4.1.0+) holds the consumed options and
  their values, ready to forward: `command head $argv_opts -- $argv`.
- Accumulate long spec lists with `set -a specs …` instead of a 200-column `argparse` line, then
  splat: `argparse --name mytool $specs -- $argv; or return`.

### argparse's own flags

| Flag | Effect |
| --- | --- |
| `-n` / `--name NAME` | name in error messages; defaults to the enclosing function name, else `argparse` |
| `-N` / `--min-args N` | minimum positionals (default 0); violation → status **1** |
| `-X` / `--max-args N` | maximum positionals (default ∞); violation → status **1** |
| `-x` / `--exclusive a,b` | mutually exclusive set, repeatable, short or long names; violation → status **2** |
| `-s` / `--stop-nonopt` | stop scanning at the first positional — how you implement subcommands |
| `-u` / `--move-unknown` | accept unknown options, move them to `$argv_opts` (4.1.0+) |
| `-i` / `--ignore-unknown` | **deprecated**: keeps unknowns in `$argv`, indistinguishable from positionals |
| `--unknown-arguments=KIND` | `optional` (default) \| `required` \| `none` — how much an unknown option swallows |
| `-S` / `--strict-longopts` | forbid `-long` / `--lo` / `-lo` abbreviations of `--long` (4.1.0+); may become the default, so do not rely on the loose form |

⚠ **Every argparse flag must precede every OPTION_SPEC.** Put `-N 1` after a spec and argparse reads it
as a spec starting with `-`: `Short flag '-' invalid, must be alphanum or '#'`.

⚠ **`--min-args` fires before you can read `$_flag_help`**, so `mytool --help` errors instead of
printing usage. Verified:

```fish
# wrong — --help is unreachable
argparse -N 1 h/help -- $argv; or return # `mytool --help` → "expected >= 1 arguments; got 0"

# right — help first, then count by hand
argparse h/help -- $argv; or return
set -q _flag_help; and begin
    echo 'usage: mytool NAME...'
    return 0
end
test (count $argv) -gt 0; or begin
    echo >&2 'mytool: expected at least one NAME'
    return 1
end

# -s stops at the first positional, leaving the rest for a subcommand to parse
argparse -s v/verbose -- -v sub -v arg # _flag_verbose = -v, $argv = sub -v arg
```

### Validators (`!`)

Append `!` plus fish code. Exit 0 = valid; messages go to **stdout**, not stderr. Three
locally-exported variables exist inside the code: `$_flag_value` (the value), `$_flag_name` (the flag
being processed), `$_argparse_cmd` (the `--name` value).

```fish
argparse 'd/dir=!test -d "$_flag_value"' -- $argv # must be a directory
argparse 'f/func=!not functions -q "$_flag_value"' -- $argv # must not already exist
argparse 'j/jobs=!_validate_int --min 1 --max 16' -- $argv # shipped int validator
```

`_validate_int` ships with fish; `--min`/`--max` are optional and its message is prefixed with
`--name`. `fish_opt` builds specs verbosely (`fish_opt -s n -l name --required-val` → `n/name=`) — a
shipped function, rarely worth the extra line.

### The mandatory idiom

`argparse … -- $argv` then `or return` (or `; or return`). argparse prints its own error to stderr and
returns non-zero; `or return` propagates that and aborts. **Never omit it** — without it the body runs
on half-parsed arguments.

### Complete verified example

Runs as shown and passes `fish_indent --check`:

```fish
function bundle --description 'example: exercise most of argparse'
    # spec list first, so the argparse line stays short.
    # argparse's own flags must come before the specs.
    set -l specs h/help q/quiet v/verbose
    set -a specs o/out= i/include=+ c/colour=?
    set -a specs n#lines 'd/dir=!test -d "$_flag_value"'
    set -a specs 'j/jobs=!_validate_int --min 1 --max 16'
    argparse --name bundle --max-args 3 -x q,v $specs -- $argv
    or return

    if set -q _flag_help
        echo 'usage: bundle [-qv] [-o FILE] [-i PAT]... [-c[WHEN]] [-NUM] [-d DIR] [-j N] NAME...'
        return 0
    end
    if test (count $argv) -eq 0
        echo >&2 'bundle: expected at least one NAME'
        return 1
    end

    # a boolean holds every form of the flag as it was seen
    set -q _flag_verbose; and echo "verbose x"(count $_flag_verbose)": $_flag_verbose"

    # `=` keeps only the last occurrence
    set -l out /dev/stdout
    set -q _flag_out; and set out $_flag_out

    # `=+` accumulates — iterate the list directly
    for pat in $_flag_include
        echo "include: $pat"
    end

    # `=?` is set-but-empty when no value was attached
    if set -q _flag_colour
        test -n "$_flag_colour"; and echo "colour: $_flag_colour"; or echo 'colour: auto'
    end

    set -q _flag_lines; and echo "lines: $_flag_lines" # `#` integer flag
    set -q _flag_dir; and echo "dir: $_flag_dir" # already validated
    echo "out=$out names=$argv opts=$argv_opts"
end
```

```
$ bundle -vv -o /tmp/o -i '*.fish' -i '*.md' --colour -20 -d /tmp -j 4 alpha beta
verbose x2: -v -v
include: *.fish
include: *.md
colour: auto
lines: 20
dir: /tmp
out=/tmp/o names=alpha beta opts=-vv -o /tmp/o -i *.fish -i *.md --colour -20 -d /tmp -j 4
$ bundle -q -v a  # bundle: q/quiet v/verbose: options cannot be used together  (status 2)
$ bundle -j 0 a   # bundle: Value '0' for flag 'j' less than min allowed of '1' (status 1)
$ bundle a b c d  # bundle: expected <= 3 arguments; got 4                      (status 1)
```

## 2. `test` / `[`

Sets status 0 (true) or 1 (false). `[ EXPRESSION ]` is the compatibility spelling; **prefer `test`**.

⚠ **fish has no `[[ ]]`.** `[[ -n foo ]]` fails with `Unknown command: '[[ -n foo ]]'`.

| Files | | Strings / numbers | | Structure | |
| --- | --- | --- | --- | --- | --- |
| `-e F` | exists | `A = B` | strings identical (**single** `=`) | `! EXPR` | negate |
| `-f F` | regular file | `A != B` | strings differ | `C1 -a C2` | and |
| `-d F` | directory | `-n S` | length > 0 | `C1 -o C2` | or |
| `-r/-w/-x F` | readable / writable / executable | `-z S` | length 0 | `\( … \)` | group |
| `-s F` | size > 0 | `-eq` `-ne` | numerically equal / not | | |
| `-L F` | symlink | `-lt` `-le` | less / less-or-equal | | |
| `-b/-c/-p/-S F` | block, char, FIFO, socket | `-gt` `-ge` | greater / greater-or-equal | | |
| `-g/-u/-k F` | setgid / setuid / sticky | | ints **and** floats | | |
| `-O/-G F` | owned by current user / group | | | | |
| `-t FD` | FD is a terminal | | | | |
| `A -nt/-ot/-ef B` | newer / older / same file | | | | |

### The four things agents get wrong

```fish
# 1. unquoted variable + -n is a BUG. unset $v leaves bare `test -n`, the
#    one-argument form, which asks "is the string -n non-empty?" — always true.
test -n $v # wrong: true even when $v is unset
test -n "$v" # right

# 2. numeric comparison is -eq/-lt, never ==/</>
test $status -eq 0 # right
test $status == 0 # wrong: == is not an operator
test a "<" b # wrong: "unexpected argument at index 2" — < and > are unimplemented

# 3. string equality is a single equals
test "$a" = "$b" # right
test "$a" == "$b" # wrong

# 4. parentheses need escaping or fish reads them as command substitution
test \( -f /etc/hosts -o -f /nope \) -a -d /tmp
```

⚠ The one-argument misfeature is deprecated. Feature flag `test-require-arg` makes `test -n` false,
`test -z` true, and any other one/zero-argument invocation an error. **Off** by default in 4.8.1
(`status test-feature test-require-arg` → 1); `fish -d deprecated-test` warns on affected calls. Quote
now and nothing breaks later.

### `test` vs `string match`

| Question | Use |
| --- | --- |
| exists / directory / readable / newer | `test` (or `path`, see [text-processing.md](text-processing.md)) |
| exact string equality, emptiness | `test "$a" = "$b"`, `test -n "$a"` |
| numeric comparison | `test $n -lt 5` |
| glob or regex match, prefix/suffix/substring | `string match [-r]` |
| does **any** element of a list match? | `string match -q` |
| membership in a known list | `contains` |

```fish
set -l files a.fish b.md c.fish
string match -q '*.fish' -- $files; and echo 'at least one fish file'
string match '*.fish' -- $files # also *prints* the matches: a.fish c.fish
```

## 3. `status`

One subcommand per invocation. The `--is-login`-style flag spellings are deprecated.

| Subcommand | Returns / prints |
| --- | --- |
| `is-interactive` | 0 when connected to a keyboard — the standard `conf.d/` guard |
| `is-login` | 0 in a login shell |
| `is-interactive-read` | 0 during an interactive `read` |
| `is-command-substitution` | 0 inside `(...)` |
| `is-block` | 0 inside a `begin`/`if`/`for` block |
| `is-breakpoint` | 0 while stopped at a `breakpoint` |
| `is-no-job-control` / `is-full-job-control` / `is-interactive-job-control` | current mode |
| `job-control none\|full\|interactive` | set the mode |
| `filename` (`current-filename`) | running script's path **as invoked**; `-` when piped into `source` |
| `basename` | that filename without directories |
| `dirname` | that filename's directory |
| `function` (`current-function`) | innermost running function, else `Not a function` |
| `current-command` | currently running function or command |
| `current-commandline` | the whole running command line, all jobs and operators |
| `line-number` | line currently executing |
| `stack-trace` | full call stack |
| `fish-path` | absolute path of this fish binary (best effort) |
| `features` | every feature flag: name, on/off, introducing version, description |
| `test-feature NAME` | 0 enabled, 1 disabled, 2 unrecognized |
| `build-info` (`buildinfo`) | build system, version, target triple, profile |
| `terminal` / `terminal-os` / `test-terminal-feature F` | terminal identity and capabilities — only from the first interactive prompt onward |
| `language [list-available\|set …\|unset]` | fish's own message localization |
| `get-file F` / `list-files [PATH]` | files embedded in the binary; fish-internal, not for config |

⚠ `status dirname` can be **relative** — it is `dirname(3)` of the path as invoked, so running
`./sd/probe.fish` yields `.`. Resolve before use:

```fish
# a script locating files next to itself
set -l here (path resolve (status dirname))
test -r $here/data.txt; and source $here/data.txt
```

## 4. Introspection & dispatch

### `type` — what would run

`-q`/`--query` (silent, status only — **the guard form**) · `-t`/`--type` (prints `function`, `builtin`
or `file`) · `-a`/`--all` (every definition, resolution order) · `-p`/`--path` (binary path, or the
file defining the function) · `-P`/`--force-path` (the `PATH` binary even when shadowed) ·
`-s`/`--short` (no function bodies) · `-f`/`--no-functions`. `-q`/`-t`/`-p`/`-P` are mutually
exclusive. Status 0 if any name resolved, 1 if none, 2 on bad flags.

⚠ `type -p` can print a pseudo-path: fish 4.x embeds its shipped functions, so `type -p cd` →
`embedded:functions/cd.fish`.

### `functions` — the function table

| Flag | Effect |
| --- | --- |
| `-q` / `--query` | test existence, silent. True for *autoloadable* functions too, before first call. |
| `-e` / `--erase` | erase, and block autoloading for this session (`funcsave` removes the saved copy) |
| `-c` / `--copy OLD NEW` | copy the body only — event handlers are **not** copied |
| `-n` / `--names` | list names (`-a` to include `_`-prefixed) |
| `-D` / `--details [-v]` | defining file; with `-v`, five lines: path, autoload state, line number, scope-shadowing, description |
| `-H` / `--handlers [-t TYPE]` | list event handlers — the way to confirm an `--on-event` actually registered |
| `-d` / `--description` | change a description |

Exit status is the **number of named functions that do not exist**.

### `command` / `builtin` — force a resolution path

`command`: `-q`/`--query` (0 found, **127** not found, silent) · `-s`/`--search` (`-v`; print the
binary that would run) · `-a`/`--all` (every `PATH` match in order). `command NAME` bypasses functions
and builtins — the only way to shadow a command without infinite recursion, e.g.
`function pwd --description '…'; command pwd $argv; end`.

`builtin NAME` forces the builtin; `-n`/`--names` lists all; `-q`/`--query` tests.
⚠ `builtin --names` includes builtins that a shipped **function shadows** — `cd`, `bg`, `fg`,
`history`, `realpath`, `wait` are builtins you never reach by name. `builtin source` appears in careful
configs for the same reason a wrapper uses `command`: a stray user function named `source` would
otherwise intercept every config load, and unlike `command` there is no external fallback to notice it.

### "Is X available?" — pick the right query

| Question | Query | Matches |
| --- | --- | --- |
| would this name run *anything*? | `type -q NAME` | function **or** builtin **or** binary |
| is this **program installed**? | `command -q NAME` | binaries only |
| is this **builtin** present? | `builtin -q NAME` | builtins only |
| is this **function** defined or autoloadable? | `functions -q NAME` | functions, before first call too |
| is this **variable** set? | `set -q NAME` | see [variables.md](variables.md) |
| is this **abbreviation** defined? | `abbr -q NAME` | interactive wiring only |

Guessing wrong is silently wrong in both directions, verified on 4.8.1:

```fish
command -q string # 127 — string is a builtin, so this is FALSE
type -q ls # 0 — but only because fish ships an `ls` *function*, not because a system ls exists
```

Use `type -q` for "can I call this" — the [style-guide.md](style-guide.md) §4 guard, correct for
`zoxide`, `starship`, `gum`, none of which fish shadows. Use `command -q` when you specifically need
the external binary.

## 5. Small but load-bearing builtins

**`contains KEY [VALUES…]`** — list membership; `-i`/`--index` prints the 1-based index of the first
match. Options must precede `KEY`; everything after `KEY` is a value, so `--` is required when `KEY`
itself starts with `-`.

```fish
contains /usr/bin $PATH; or fish_add_path -g /usr/bin
contains -- -q $argv; and echo 'called with -q' # -- needed, else -q is read as contains' own flag
contains -i c a b c # prints 3
```

**`count`** — arguments plus newlines on stdin. Accepts **no flags at all**, not even `-h`. Non-zero
status when given nothing, but write the intent: `test (count $argv) -eq 0`.

**`eval`** — joins its arguments with spaces and runs them as fish code. Needed only when the string
contains pipes, redirections or other compound syntax *and* the code must read stdin. Otherwise don't:

```fish
set -l cmd string upper hi
$cmd # right — variable-as-command, no re-parse
set -l pipeline 'echo hi | string upper'
echo $pipeline | source # right — cheaper, and no eval quoting hazards
eval $pipeline # only when the code must also read stdin
```

**`source FILE [ARGS…]`** — run a file in the current shell. `source -`, or bare `source` with a pipe
on stdin, reads stdin: the `tool init fish | source` idiom. Extra arguments become `$argv` (the
filename is not included). Creates a **new local scope**, so `set -l` inside does not leak. `.` is a
deprecated synonym. Relative paths resolve against `$PWD`, never `$PATH`.

**`isatty [FD]`** — 0 if the descriptor is a terminal; `FD` is a number or `stdin`/`stdout`/`stderr`,
default 0. A shipped *function*, not a builtin. (Not verifiable non-interactively — under a pipe every
FD is non-tty.)

**`random`** — `random` (0–32767) · `random START END` · `random START STEP END` · `random choice
ITEMS…` · `random SEED` (seeds, prints nothing). Not cryptographically secure.

**`wait [-n|--any] [PID|NAME…]`** — wait for background jobs; no argument waits for all, `-n` returns
after the first completes. `sleep 10 &; wait $last_pid`.

**`jobs`** — `-p` PIDs · `-c` command names · `-g` group IDs · `-l` last job only · `-q` status only.
Exit 0 when background jobs exist, 1 otherwise; the header is omitted when redirected or in a `(...)`.

**`time COMMAND`** — fish's timing keyword; works on builtins **and blocks**, unlike `command time`.
Prints wall-clock plus usr/sys split across fish vs external. Output cannot be redirected. After the
fact read `$CMD_DURATION` instead.

**`exec COMMAND`** — replace the fish process; never returns; illegal in a pipeline. `exec fish` is the
config-reload idiom.

**`trap [ARG] REASON`** — POSIX shim that generates an event handler: `trap "cmd" INT` literally defines
`function __trap_handler_INT --on-signal SIGINT`. `-l` lists signal names, `-p` prints handlers. Prefer
a real `--on-signal` function in `conf.d/` ([style-guide.md](style-guide.md) §6).

**`ulimit`** — `-a` all · `-n` descriptors · `-f` files (default) · `-s` stack · `-c` core · `-u`
processes; `-H`/`-S` pick hard/soft. Values in kB except `-t` (seconds) and `-n`/`-u` (counts).
Accepts `hard`, `soft`, `unlimited`.

**`umask [MASK]`** — octal by default; `-S` symbolic, `-p` reusable form. ⚠ The docs state symbolic
masks "currently do not work as intended"; use octal.

## 6. `fish_add_path`

The **only** sanctioned way to touch `PATH` ([style-guide.md](style-guide.md) §3). A shipped function.
It normalizes with `realpath` (trailing slashes dropped, relative made absolute, symlinks kept),
**silently skips non-existent directories**, and neither re-adds nor reorders an entry that is already
present unless `--move` is given. If nothing is new it does not write the variable at all, so variable
handlers do not fire.

| Flag | Effect |
| --- | --- |
| `-p` / `--prepend` | add to the front (**default**) |
| `-a` / `--append` | add to the end |
| `-m` / `--move` | move an already-present entry to where it would be added |
| `-g` / `--global` | use a **global** `fish_user_paths` |
| `-U` / `--universal` | use a **universal** `fish_user_paths` — the default when none exists yet |
| `-P` / `--path` | modify `$PATH` directly (always global, so must re-run each startup) |
| `-v` / `--verbose` | print the `set` it ran plus skip warnings; automatic when interactive on a tty |
| `-n` / `--dry-run` | print the `set` without running it — how you inspect scope before committing |

`-g`/`-U`/`-P` are mutually exclusive, as are `-a`/`-p`. `$fish_user_paths` is prepended to `$PATH`
wholesale, so even `--append`ed entries precede the system paths; only `--path` appends to the true end
of `$PATH`.

### ⚠ `-g` vs `-U` — why this repo must avoid the universal form

A bare `fish_add_path` **creates a universal variable** when no `fish_user_paths` exists, and follows
the existing one otherwise. Universal variables persist to `~/.config/fish/fish_variables`, which is
machine state, not version-controlled config — exactly what [style-guide.md](style-guide.md) §3
forbids. Verified in a clean `$HOME`:

```
$ fish_add_path -n ~/bin
set -U fish_user_paths /home/x/bin    # universal → written to fish_variables
$ fish_add_path -n -g ~/bin
set -g fish_user_paths /home/x/bin    # session-only → re-created from config each startup
```

⚠ Testing note: `fish --no-config` **demotes `set -U` to global**, so universal behaviour must be
verified with a throwaway `HOME`/`XDG_CONFIG_HOME` and *without* `--no-config`.

### ⚠ The live issue in this config

`~/.config/fish/fish_variables` currently holds
`SETUVAR fish_user_paths:/opt/homebrew/bin␞/opt/homebrew/sbin␞/bin␞/sbin`, and
`~/.config/fish/conf.d/brew.fish` line 4 is
`fish_add_path -m "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"`. Three things interact, all verified:

1. **`$HOMEBREW_PREFIX` is unset when that line runs.** `set -gx HOMEBREW_PREFIX /opt/homebrew` is 14
   lines *later* in the same file, nothing in `_init.fish` sets it, and Ghostty launches fish directly
   rather than through zsh, so no `brew shellenv` is inherited. With the variable unset,
   `"$HOMEBREW_PREFIX/bin"` expands to exactly `/bin` — which is why `/bin` and `/sbin` are pinned in
   `fish_variables`. Both exist, so `fish_add_path` accepted them without a word.
2. **The persisted universal value, not `brew.fish`, is what sets `PATH`.** A fresh session reads
   `fish_user_paths` from `fish_variables` and prepends it to `PATH` before `conf.d/` runs; the
   `fish_add_path -m` call then merely re-affirms entries already there. Editing or deleting
   `brew.fish` does **not** change `PATH` — only editing `fish_variables` does. That is the shadowing
   CLAUDE.md warns about.
3. **`-g` snapshots the junk rather than clearing it.** `fish_add_path -g` reads the universal's current
   contents and copies them into a global: `set -g fish_user_paths <new> <every existing entry>`. The
   global then shadows the universal for reads *and* for the `PATH` rebuild in that session, while the
   universal stays on disk and resurfaces the moment the `-g` line is removed.

The fix is two steps, in this order — erase the machine-state copy once, then make config authoritative:

```fish
# once, at an interactive prompt
set -e -U fish_user_paths

# then in conf.d/brew.fish: define the prefix *before* using it, and stay global
set -q HOMEBREW_PREFIX; or set -gx HOMEBREW_PREFIX /opt/homebrew
fish_add_path -g -m "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
```

⚠ `--move` in a startup file reorders `PATH` on every launch. Intended here (Homebrew must beat
`/usr/bin`), a hazard anywhere the order is not deliberate.

## 7. Complete command index

All 125 pages under fish 4.8.1's `cmds/`. **Kind** determined with `type -t` and `builtin --names` on
this machine: `builtin` · `fn/builtin` (a builtin a shipped function shadows — you reach the function)
· `function` (shipped, autoloaded from the binary's embedded set) · `undefined` (customization point
with no default definition) · `external` · `subpage` (documentation for a `string` subcommand, not a
command).
| **Language keywords & control flow (23)** | | |
| `and` | builtin | conditionally execute a command |
| `begin` | builtin | start a new block of code |
| `break` | builtin | stop the current inner loop |
| `builtin` | builtin | run a builtin command |
| `case` | builtin | conditionally execute a block of commands |
| `command` | builtin | run a program, bypassing functions and builtins |
| `continue` | builtin | skip the rest of the current loop iteration |
| `else` | builtin | execute a command if a condition is not met |
| `end` | builtin | end a block of commands |
| `exec` | builtin | replace the shell with a command |
| `exit` | builtin | exit the shell |
| `false` | builtin | return an unsuccessful result |
| `for` | builtin | perform a set of commands multiple times |
| `function` | builtin | create a function |
| `if` | builtin | conditionally execute a command |
| `not` | builtin | negate the exit status of a job |
| `or` | builtin | conditionally execute a command |
| `return` | builtin | stop the current inner function |
| `switch` | builtin | conditionally execute a block of commands |
| `test` | builtin | perform tests on files and text |
| `time` | builtin | measure how long a command or block takes |
| `true` | builtin | return a successful result |
| `while` | builtin | perform a set of commands multiple times |
| **Variables, arguments & scope — see [variables.md](variables.md) (9)** | | |
| `argparse` | builtin | parse options passed to a script or function |
| `contains` | builtin | test if a word is present in a list |
| `count` | builtin | count the elements of a list |
| `export` | function | compatibility shim for exporting variables (do not use) |
| `fish_add_path` | function | add a directory to the path |
| `fish_opt` | function | build an option specification for `argparse` |
| `read` | builtin | read a line of input into variables |
| `set` | builtin | display and change shell variables |
| `vared` | function | interactively edit the value of a variable |
| **Text, paths & numbers — see [text-processing.md](text-processing.md) (23)** | | |
| `echo` | builtin | display a line of text |
| `math` | builtin | perform mathematics calculations |
| `path` | builtin | manipulate and check paths |
| `printf` | builtin | display text according to a format string |
| `realpath` | fn/builtin | convert a path to an absolute path without symlinks |
| `string` | builtin | manipulate strings |
| `string-collect` | subpage | join strings into one |
| `string-escape` | subpage | escape special characters |
| `string-join` | subpage | join strings with a delimiter |
| `string-join0` | subpage | join strings with zero bytes |
| `string-length` | subpage | print string lengths |
| `string-lower` | subpage | convert strings to lowercase |
| `string-match` | subpage | match substrings (glob or regex) |
| `string-pad` | subpage | pad strings to a fixed width |
| `string-repeat` | subpage | multiply a string |
| `string-replace` | subpage | replace substrings |
| `string-shorten` | subpage | shorten strings to a width, with an ellipsis |
| `string-split` | subpage | split strings by a delimiter |
| `string-split0` | subpage | split on zero bytes |
| `string-sub` | subpage | extract substrings |
| `string-trim` | subpage | remove leading/trailing whitespace |
| `string-unescape` | subpage | expand escape sequences |
| `string-upper` | subpage | convert strings to uppercase |
| **Interactive, UI & directory navigation (34)** | | |
| `abbr` | builtin | manage abbreviations |
| `alias` | function | create a wrapper function — **banned in config** (style-guide §7) |
| `bind` | builtin | handle key bindings |
| `cd` | fn/builtin | change directory |
| `cdh` | function | change to a recently visited directory |
| `commandline` | builtin | get or set the current command line buffer |
| `complete` | builtin | edit command-specific tab completions |
| `dirh` | function | print directory history |
| `dirs` | function | print the directory stack |
| `fish_clipboard_copy` | function | copy text to the system clipboard |
| `fish_clipboard_paste` | function | get text from the system clipboard |
| `fish_command_not_found` | function | hook for an unknown command |
| `fish_config` | function | start the web-based configuration interface |
| `fish_default_key_bindings` | function | select emacs key bindings |
| `fish_delta` | function | diff your functions/completions against the defaults |
| `fish_greeting` | function | welcome message in interactive shells |
| `fish_key_reader` | builtin + binary | show what escape sequence a keypress produces |
| `fish_should_add_to_history` | undefined | decide whether a command enters history |
| `fish_tab_title` | undefined | set the terminal tab's title (4.2.0+) |
| `fish_title` | function | set the terminal window's title |
| `fish_update_completions` | function | regenerate completions from man pages |
| `fish_vi_key_bindings` | function | select vi key bindings |
| `funced` | function | edit a function interactively |
| `funcsave` | function | save a function to the autoload directory |
| `functions` | builtin | print or erase functions |
| `help` | function | display fish documentation |
| `history` | fn/builtin | show and manipulate command history |
| `nextd` | function | move forward through directory history |
| `open` | external | open a file in its default application (`/usr/bin/open` here) |
| `popd` | function | pop from the directory stack |
| `prevd` | function | move backward through directory history |
| `pushd` | function | push a directory onto the stack |
| `pwd` | builtin | print the current working directory |
| `set_color` | builtin | set the terminal colour |
| **Prompt helpers (14)** | | |
| `fish_breakpoint_prompt` | function | prompt shown while stopped at a breakpoint |
| `fish_darcs_prompt` | function | Darcs status for a prompt |
| `fish_git_prompt` | function | git status for a prompt |
| `fish_hg_prompt` | function | Mercurial status for a prompt |
| `fish_is_root_user` | function | true if the current user is root |
| `fish_mode_prompt` | function | vi-mode indicator |
| `fish_prompt` | function | the left prompt |
| `fish_right_prompt` | undefined | the right prompt |
| `fish_status_to_signal` | function | turn an exit code into a signal name |
| `fish_svn_prompt` | function | Subversion status for a prompt |
| `fish_vcs_prompt` | function | dispatch to whichever VCS prompt applies |
| `prompt_hostname` | function | hostname, shortened for a prompt |
| `prompt_login` | function | user@host, noting chroot/ssh |
| `prompt_pwd` | function | current directory, shortened for a prompt |
| **Jobs & processes (11)** | | |
| `bg` | fn/builtin | send jobs to the background |
| `disown` | builtin | remove a process from the job list |
| `fg` | fn/builtin | bring a job to the foreground |
| `isatty` | function | test if a file descriptor is a terminal |
| `jobs` | builtin | print currently running jobs |
| `psub` | function | process substitution — a temp file/fifo standing in for a pipeline |
| `suspend` | function | suspend the current shell |
| `trap` | function | run an action on a signal (POSIX shim over event handlers) |
| `ulimit` | builtin | get or set resource usage limits |
| `umask` | function | get or set the file creation mode mask |
| `wait` | fn/builtin | wait for background jobs to complete |
| **Misc — evaluation, events, introspection (11)** | | |
| `_` | builtin | look up one of fish's own translations |
| `block` | builtin | temporarily block delivery of events |
| `breakpoint` | builtin | drop into an interactive debug prompt |
| `emit` | builtin | emit a generic event (pairs with `--on-event`) |
| `eval` | builtin | evaluate a string as fish code |
| `fish` | external | the shell itself |
| `fish_indent` | builtin + binary | indent and prettify fish code |
| `random` | builtin | generate a random number or pick from a list |
| `source` | builtin | evaluate the contents of a file or stdin |
| `status` | builtin | query fish runtime information |
| `type` | builtin | locate a command and describe its type |
