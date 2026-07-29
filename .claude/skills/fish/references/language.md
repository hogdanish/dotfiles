# Fish — the language core

How fish code is *shaped*: syntax, list semantics, quoting, the expansion pipeline, redirection,
control flow, functions-as-syntax, exit status, debugging. Verified against **fish 4.8.1**. Variable
*scoping* and the special-variable catalogue live elsewhere; `string`/`path`/`argparse`/`set`/`test` are
in [builtins.md](builtins.md); formatting law is [style-guide.md](style-guide.md).

## 1. Syntax overview & terminology

Everything is a command: `NAME [ARG ...]` — `if`, `for`, `function`, `set` included. There is no
expression grammar, no operators, no `[[ ]]`. fish reads a line, expands it, runs the result.

| Term | Meaning |
| --- | --- |
| Builtin | implemented inside the shell (`echo`, `set`, `string`, `test`) |
| Command | an external executable found in `$PATH` |
| Function | a named block of fish commands, callable as a command |
| Job | one running pipeline or command |
| Pipeline | commands joined by `\|` |
| Block | `for`/`while`/`if`/`switch`/`function`/`begin` … `end` — also a variable scope |

**Separators.** Commands end at a newline or `;`; repeated or trailing `;` is harmless. Arguments split
on unquoted whitespace. A trailing `&` backgrounds the job, but only when followed by whitespace or one
of `;<>&|` (`ampersand-nobg-in-token`, default since 3.5).

**Reserved words** — cannot be function names, cannot be run via variable-as-command: `[`, `_`, `and`,
`argparse`, `begin`, `break`, `builtin`, `case`, `command`, `continue`, `else`, `end`, `eval`, `exec`,
`for`, `function`, `if`, `not`, `or`, `read`, `return`, `set`, `status`, `string`, `switch`, `test`,
`time`, `while`.

## 2. Everything is a list

**Every fish variable is a list.** A "scalar" is a one-element list. Splitting happens at `set` time,
never at use time — **fish does no word splitting**, so filenames with spaces are safe unquoted.

| `set` | elements | `$x` → | `"$x"` → |
| --- | --- | --- | --- |
| `set -l x 1 2 3` | 3 | 3 arguments | 1 argument `1 2 3` (space-joined) |
| `set -l x "1 2 3"` | 1 | 1 argument `1 2 3` | 1 argument `1 2 3` |
| `set -l x ""` | 1 | 1 argument, empty | 1 argument, empty |
| `set -l x` | 0 | **zero arguments** | 1 argument, empty |
| never set | 0 | **zero arguments** | 1 argument, empty |

`count $x` returns 0 for the last two rows; `count "$x"` returns 1. Inside double quotes a list always
becomes exactly one argument joined with spaces — **except** a path variable (any name ending in
`PATH`), which joins with `:`: `set -l MYPATH 1 2 3; echo "$MYPATH"` prints `1:2:3`.

⚠ **The failure mode.** `test` counts arguments, so an unquoted list changes which `test` you called:

```fish
# wrong — with 3 elements this runs `test -n one two three`
set -l foo one two three
test -n $foo # error: "Expected a combining operator like '-a' at index 3", status 1

# worse — when unset this runs `test -n`, whose lone argument "-n" is a
# non-empty string, so it returns TRUE. silently inverted, no error.
set -e foo
test -n $foo # status 0

# right
test -n "$foo"
```

(The one-argument `test` form survives because the `test-require-arg` feature flag is still off in
4.8.1.) Quote for `test`, for paths, and anywhere you need exactly one argument. Unquote when you want
elements splatted (`grep $grep_args .`) — that is most of the time. See
[style-guide.md](style-guide.md) §3. An empty list also **deletes the token** it is attached to (§4).

## 3. Quoting & escaping

| Form | Expands | Notes |
| --- | --- | --- |
| bare | everything | globs, braces, `~`, variables, command substitution |
| `'single'` | nothing | only `\'` and `\\` mean anything |
| `"double"` | variables and `$(cmd)` only | no globs, no braces, no `(cmd)`, escapes inert |

Inside `"`, the only live escapes are `\"`, `\$`, `\\`, and `\` + newline (deletes both). `(cmd)` is
literal inside quotes but `$(cmd)` is not — that is the whole reason `$(...)` exists.

```fish
set -l w cat
echo "the $w \$literal \n and $(echo sub) but not (echo nosub) nor {a,b}"
# the cat $literal \n and sub but not (echo nosub) nor {a,b}
```

**Character escapes:**

| Escape | Value | Escape | Value |
| --- | --- | --- | --- |
| `\a` | alert | `\v` | vertical tab |
| `\e` | escape | `\xHH` / `\XHH` | byte, hex |
| `\f` | form feed | `\ooo` | byte, octal, max `\177` |
| `\n` | newline | `\uXXXX` | 16-bit Unicode |
| `\r` | carriage return | `\UXXXXXXXX` | 32-bit Unicode, max `U10FFFF` |
| `\t` | tab | `\cX` | control-X (`\ci` = tab) |

**Metacharacter escapes** — backslash makes any of these literal:
`\ ` (space) `\$` `\\` `\*` `\?` `\~` `\#` `\(` `\)` `\{` `\}` `\[` `\]` `\<` `\>` `\&` `\|` `\;` `\"` `\'`

**Line continuation.** `\` immediately before a newline joins the lines, adding no whitespace and not
ending the token — so `echo one \`⏎`    two` is two arguments (`one two`) while `echo one\`⏎`two` is one
(`onetwo`).

## 4. Expansions

Applied in this order, **right to left** across the token, nested substitutions and braces inside-out:
**command substitution → variable expansion (incl. slices and `$$`) → brace expansion → wildcards.**
With files `foo` and `bar` in cwd, `echo a(ls){1,2,3}` gives `abar1 abar2 abar3 afoo1 afoo2 afoo3`.
The total result is capped at 524288 items.

### Wildcards

| Pattern | Matches |
| --- | --- |
| `*` | any run of characters, **not** `/` |
| `**` | any run of characters, descending into subdirectories; as a whole segment it may match zero times |
| `?` | any single character — **disabled** in 4.x (`qmark-noglob` default since 4.0); `?` is ordinary |

Matches sort case-insensitively, numbers naturally (`f1 f5 f12`). Dotfiles match only when the pattern
has a literal dot in that position. `.` and `..` never match.

⚠ **An unmatched glob is an error, not a literal.** The command does not run, `$status` is 124, and a
warning is printed (bash's `failglob`, not bash's default). Exceptions that expand to *nothing*
instead: `set`, `path`, `count`, `for`, and variable overrides.

```fish
ls /nope/*.zz # "No matches for wildcard" — ls never runs, status 124

# the safe pattern: collect with `set`, then test
set -l foos *.foo
if test (count $foos) -gt 0
    ls $foos
end
```

To pass a pattern *to* a command, quote it (`apt install "postgres-*"`) — fish never hands on an
unexpanded glob.

### Variable expansion

`$name` splices the list; undefined or empty expands to nothing. Separate a name from adjacent text
with `{}` or quotes, never bare:

```fish
set -l WORD cat
echo The plural of $WORD is "$WORD"s # cats
echo {$WORD}s # cats
echo $WORDs # empty — expanded a variable named "WORDs"
```

### Index and slice

Indices are **1-based**; `-1` is the last element. Ranges `a..b` walk in the direction their endpoints
imply, so a reversed range reverses. Out-of-range indices clamp; an invalid index yields no argument at
all (not an empty string). Multiple ranges separate with spaces; a missing start means `1`, a missing
end `-1`.

```fish
set -l v one two three four
echo $v[1] $v[-1] # one four
echo $v[2..-1] $v[2..-2] # two three four two three
echo $v[-1..1] # four three two one   (reversed)
echo $v[2..16] # two three four       (clamped)
echo (seq 10)[2..5 1..3] # 2 3 4 5 1 2 3
```

Slices work on command substitutions, but ⚠ **a variable cannot be used as a command-substitution
index** — assign to a variable first, then slice that.

### Command substitution

`(cmd)` and `$(cmd)` both capture stdout and split it one argument per line (`$IFS` is not used).
`$(cmd)` arrived in **fish 3.4**; its only advantage is expanding inside double quotes, where the
output stays one argument (trailing newlines still stripped).

```fish
echo (printf 'a\nb\n') # a b -> two arguments
echo "$(printf 'a\nb\n')" # one argument, newline preserved
set -l data "$(cat file)" # whole file, unsplit
set -l data (cat file | string split0) # split on NUL instead of newline
```

Pipe to `string split`/`string split0` as the last step to override line splitting. For a command that
demands a *file*, use `psub`: `diff -u (cmd1 | psub) (cmd2 | psub)`. Reading past
`$fish_read_limit` (default 1 GiB) fails the whole outer command with `$status` 122.

### Brace expansion

```fish
echo input.{c,h,txt} # input.c input.h input.txt
echo {,,/usr}/bin # /bin /bin /usr/bin   (empty elements are real)
echo foo-{} # foo-{}   — no comma and no variable, so not special
```

That last rule is why `git reset --hard HEAD@{2}` works. Since **fish 4.1** a brace at the *start of a
command token* is a compound statement, not an expansion: `{ echo a; echo b }` == `begin; …; end`.

### Combining lists (cartesian product)

A string attached to a list is concatenated onto every element; two lists produce all combinations —
`set -l a x y z; set -l b 1 2 3` gives `echo 1$a` → `1x 1y 1z` and `echo $a$b` →
`x1 y1 z1 x2 y2 z2 x3 y3 z3`.

⚠ **A zero-element list annihilates the whole token.** This is the mechanism behind
`for file in $PATH/*` (all files in all path directories) and behind bugs:

```fish
set -l c # empty
echo {$c}word # prints an empty line — "word" is gone
echo "$c"word # prints "word"
```

Same for a substitution that emits nothing: `echo (printf '')banana` prints nothing, while
`echo (printf '\n')banana` and `echo "$(printf '')"banana` both print `banana`.

### Tilde

`~` at the *start* of a token only: `~/Music`, `~root`. Not mid-token, not inside quotes.

### `$$name` dereference

`$$name` is "the value of the variable named by `$name`". Indices apply inside-out, so index every
level:

```fish
set -g listone 1 2 3
set -g listtwo 4 5 6
set -g var listone listtwo
echo $$var # 1 2 3 4 5 6
echo $$var[1] # 1 2 3        (first *name*, all its elements)
echo $$var[2][3] # 6
echo $$var[..][2] # 2 5      (second element of every named variable)
```

The named variable must be reachable from the current scope — a caller's function-local is invisible.

### Variable as command

`$cmd arg` runs element 1 as the command and the rest as arguments — functions, builtins and externals,
but **not** reserved words. `set -l cmd string upper; $cmd hello` prints `HELLO`. Note
`set -l EDITOR "emacs -nw"` is one element and looks for a command literally named `emacs -nw`;
`set -l EDITOR emacs -nw` is two.

### PID forms

`$fish_pid` is this shell's PID, `$last_pid` the last backgrounded process. `%self` still expands (the
`remove-percent-self` flag is **off** in 4.8.1) but only as an entire token, and is deprecated.

## 5. Redirection & piping

| Form | Effect |
| --- | --- |
| `>FILE` / `1>FILE` | stdout to file, truncating |
| `>>FILE` | stdout appended |
| `2>FILE` / `2>>FILE` | stderr to file / appended |
| `&>FILE` / `&>>FILE` | stdout **and** stderr to file / appended |
| `N>FILE`, `N>>FILE`, `N<FILE` | arbitrary fd |
| `>&N` | redirect to wherever fd N points *at that moment* |
| `>&-` | close the descriptor |
| `<FILE` | stdin from file |
| `<?FILE` | stdin from file, or `/dev/null` if unreadable (no fd number allowed) |
| `>?FILE` / `2>?FILE` | **noclobber** — refuse if the file exists (warning, status 1) |
| `\|` | stdout to next command |
| `N>\|` | fd N to next command (`2>\|` pipes stderr) |
| `&\|` (or `\|&`) | stdout **and** stderr to next command |

`&>`/`&|` arrived in fish 3.1; `|&` is a Bash-compatible alias accepted in 4.x. Redirecting a builtin,
function or block to an fd above 2 is an error (externals are fine).

**Ordering: the pipe is set up first, then redirections left to right.** So `>&2` means "wherever
stderr points *now*".

```fish
function print --description 'writes to both streams'
    echo out
    echo err >&2
end

print &| less # both streams to less — fish spelling, house preference
print 2>&1 | less # identical result: the pipe exists before `2>&1` is applied
print >&2 2>/dev/null # "out" on stderr, "err" discarded
print >/dev/null 2>&1 # silence both
```

`2>&1 |` is not broken in fish — it works for the reason above — but write `&|`. Drop output with
`>/dev/null`, drop only errors with `2>/dev/null` (e.g. `test "$n" -gt 2 2>/dev/null` so a non-numeric
`$n` fails quietly), and report errors with `echo >&2 'msg'`.

Blocks and loops take redirections as a unit — `begin; echo out; echo err >&2; end >/dev/null` prints
only `err`.

**`$pipestatus`** is the list of every process's status in the last pipeline; `$status` is only the
last. `not` rewrites `$status` but leaves `$pipestatus` alone:

```fish
false | true | false
echo $status $pipestatus # 1  /  1 0 1

not printf 'fish\n' | grep -q fish
echo $status $pipestatus # 1  /  0 0
```

A `141` in `$pipestatus` is `128 + 13` — SIGPIPE, the normal consequence of `head` closing the pipe
early. fish has no `pipefail`, deliberately.

⚠ A builtin that reads stdin does **not** see the pipe when it is nested inside a block or function on
the receiving end (verified 4.8.1): `echo x | begin; string upper; end` prints nothing, and so does a
function whose body is `string upper`. `read` and external commands are unaffected — read with `read`
and pass the value as an argument.

## 6. Conditionals

The condition is a **command** and it ends at the first job — there is no `then`.

Extend a condition with combiners, indented on their own lines or inlined with `;`:

```fish
if test -f foo.txt
    and test -r foo.txt
    echo readable
else if test -f bar.txt
    echo other
else
    echo neither
end
```

Useful conditions: `test`, `string match -q`, `path is`, `contains --`, `type -q`, `set -q`,
`functions -q`, `command -q`, `status is-interactive`.

### Combiners

| Word form | Symbol | Runs the next job when |
| --- | --- | --- |
| `and` | `&&` | previous status was 0 |
| `or` | `\|\|` | previous status was non-zero |
| `not` | `!` | — inverts the status of a whole job/pipeline |

Word forms are the house preference ([style-guide.md](style-guide.md) §5). `and`/`or` are job
decorators, not operators: **lazy**, evaluated strictly left to right, with **no precedence**. `not`
applies to the entire following pipeline, and to `$status` only.

⚠ Chains longer than two do not mean what they look like:

```fish
# wrong — `return 1` also runs when the test SUCCEEDED, because the skipped
# `echo` leaves $status at 0
test -e /etc/my.config
or echo 'need a config file'
and return 1

# right
if not test -e /etc/my.config
    echo >&2 'need a config file'
    return 1
end
```

Group with `begin` for real precedence: `if true; and begin; false; or true; end`. The one-line guard
form is idiomatic for short conditions:

```fish
type -q zoxide; and zoxide init fish | source
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
```

### `switch` / `case`

Compares one string against globbed patterns. **No fallthrough** — first match wins, then control
leaves the block. Quote the globs or they expand against filenames. `break` does **not** work here.

```fish
switch $file
    case '*.tar.gz' '*.tgz'
        echo tarball
    case '*.md' '*.txt'
        echo text
    case '*'
        echo unknown
end
```

⚠ Command substitutions inside a `case` run even when that branch is not taken — every pattern must be
expanded before the comparison happens.

## 7. Loops & blocks

```fish
for f in *.txt # iterate the list directly; no word splitting, so spaces are safe
    echo "[$f]"
end

begin # grouping: a new scope and a redirection target
    set -l tmp secret
end
echo $tmp # empty — died with the block
```

- `for` over an empty list runs zero iterations. Its variable is local to the *enclosing* scope, not
  the loop, and survives the loop holding the last value (since fish 3.0).
- `for` and `set` do not themselves modify `$status`.
- `while CONDITION; …; end` is a repeated `if`; its status is that of the last iteration's body, or 0
  if the body never ran. Complex conditions: `while test -f a; or test -f b`.
- `break` exits the innermost loop, `continue` skips to the next iteration. Neither works in `switch`.
- Never `for i in (seq (count $files))` — iterate `$files`.

**Reading a command's output line by line.** A pipeline into `while read` runs the body in the *same*
shell — fish forks no subshell here, so assignments survive the loop (verified 4.8.1):

```fish
set -l n 0
printf 'a\nb\nc\n' | while read -l line
    set n (math $n + 1)
end
echo $n # 3
```

`while read -l line; …; end <file` behaves identically. Use `read -lz` for NUL-separated input. Prefer
this over `for line in (cmd)` when the output may be large or contains blank lines you must keep.

## 8. Functions as language

```fish
function bak --description 'copy each argument to <name>.bak'
    for src in $argv
        cp -R -- $src $src.bak; or return 1
    end
end
```

`--description` is mandatory in this repo. `$argv` holds the arguments and exists only inside a
function or a script invoked with arguments.

| Option | Use |
| --- | --- |
| `-d` / `--description` | required; what `functions`, `complete` and `type` show |
| `-a` / `--argument-names` | fixed positional signature; the names stay available in `$argv` too |
| `-w` / `--wraps CMD` | inherit `CMD`'s completions |
| `-S` / `--no-scope-shadowing` | see the *caller's* locals — no closures; the calling scope, not the defining one |
| `-V` / `--inherit-variable NAME` | snapshot `NAME` at definition time |
| `--on-event` / `--on-variable` / `--on-signal` / `--on-job-exit` | event handlers — only register when **sourced**, so `conf.d/` only |

⚠ `--argument-names` defines *every* name, including unsupplied ones, as an empty list. `set -q name`
therefore returns true and cannot detect a missing argument — test `count` or `test -n`:

```fish
function greet --description 'greet someone' --argument-names name greeting
    test -n "$greeting"; or set greeting hello
    echo "$greeting, $name"
end
```

For flags use `argparse` — see [builtins.md](builtins.md). `return [N]` stops the function with status
N; at the top level of a script it behaves like `exit`, and interactively it only sets `$status`.

⚠ **Nested functions are not local.** A `function` inside a function is defined globally when the outer
function *runs*, and outlives it. Namespace such helpers `__` and erase them explicitly
(`functions -e __helper`) if they are genuinely temporary.

### Function, builtin, or command

Lookup order for a name without a `/`: **function** (already defined, then autoloaded from
`$fish_function_path`) → **builtin** → **executable in `$PATH`**. If nothing matches, fish runs
`fish_command_not_found` and sets `$status` 127.

| Force it | Query it |
| --- | --- |
| `command ls` — skip functions and builtins | `command -q ls` (0, else 127); `command -s ls` prints the path |
| `builtin echo` — skip functions | `builtin -q echo`; `builtin -n` lists all |
| — | `type -q NAME`, `type -t NAME` (kind), `type -a NAME` (every resolution) |

```fish
# shadowing a command requires `command`, or you recurse forever
function ping --description 'ping with a sane default count'
    command ping -c 5 $argv
end
```

`functions` manages them: `-q` query, `-e` erase (also blocks autoloading for this session), `-n` list
names, `-c OLD NEW` copy the body (not its event handlers), `-D` report where it came from.

### `eval`, `source`, `exec`, `exit`

| Builtin | Semantics |
| --- | --- |
| `source FILE [ARGS]` | run in the current shell, new **local** scope; also `CMD \| source` or `source -`; relative paths resolve against cwd, never `$PATH` |
| `eval STRING...` | join args with spaces, parse and run as fish source; needed only for pipelines/redirections built at runtime |
| `exec CMD` | replace this shell; never returns; illegal in a pipeline |
| `exit [CODE]` | exit the shell (`min(CODE, 255)`); inside `source` it only aborts the rest of the file |

Prefer variable-as-command when there is no shell syntax to build, and `source` when the code must read
stdin. Escape interpolated values with `string escape` before `eval`.

## 9. Exit status & error handling

`$status` is the exit status of the last foreground job; `$pipestatus` the per-process list. `128 + N`
means the job died from signal N (`$fish_kill_signal` holds N).

⚠ **Capture immediately** — the next command overwrites it. `set` and `for` do not clobber it, but
almost everything else does, so write `some-command` then `set -l rc $status` on the very next line.

Values fish reserves:

| Status | Meaning |
| --- | --- |
| 0 | success |
| 1 | generic failure |
| 121 | invalid arguments |
| 122 | command substitution or `read` exceeded `$fish_read_limit` |
| 123 | command name contained invalid characters |
| 124 | no wildcard in the command matched |
| 125 | the executable was found but the OS could not run it |
| 126 | the file was found but is not executable |
| 127 | no function, builtin or command by that name |
| 128+N | killed by signal N |

Verified in 4.8.1: 122, 124, 126 and 127 behave exactly as listed; builtins report *usage* errors as
status **2**, not 121, so never test for 121.

**fish has no `set -e`, no `errexit` and no `pipefail`.** Nothing aborts a script on a failed command —
you must check every time:

```fish
function __die --description 'print to stderr and exit non-zero'
    echo >&2 "rebuild: $argv"
    exit 1
end

cmd; or return 1 # inside a function
test -d $outdir; or __die "no such directory: $outdir" # top level of a script
set -l out (cmd); or return 1 # a substitution's status is visible through `set`
```

`status` the **builtin** is unrelated to `$status` the variable — it reports on the shell:
`status is-interactive`, `status is-login`, `status current-command`, `status basename`,
`status fish-path`, `status features`, `status print-stack-trace`.

## 10. Comments, line structure, multi-line jobs

`#` to end of line. **No block comments** — prefix every line. Comments may trail code and may sit
inside a multi-line pipeline. House style: all-lowercase, explain *why*
([style-guide.md](style-guide.md) §1).

A job continues onto the next line automatically after `|`, `&&` or `||`, and a leading `and`/`or` on
the next line continues it logically. Use `\` only when nothing else carries the line.

```fish
printf 'a\nb\n' |
    string upper |
    string join ,

true
and echo yes
```

## 11. Debugging

| Tool | Use |
| --- | --- |
| `fish -n FILE` | parse only; prints the syntax error and its location |
| `fish_indent --check FILE` | formatting is canonical (exit 0) |
| `fish --no-config -c 'source FILE'` | sources clean in isolation, with no user config masking it |
| `fish_trace=1 cmd` | print each command before running it (fish's `set -x`); nests with `-->` per call depth. `all` also traces bindings, event handlers, prompt and title functions. Goes to stderr unless `$FISH_DEBUG_OUTPUT` is set |
| `breakpoint` | drop into an interactive prompt there; `exit`/ctrl-d resumes. `kill -s TRAP <pid>` does the same to a running script |
| `status print-stack-trace` | print the function call stack from where it runs |
| `fish --profile FILE -c '...'` | per-command timings in µs: self / cumulative / command |
| `fish --profile-startup FILE -c exit` | the same, for config load |
| `time CMD` | wall-clock plus usr/sys split across fish and external time; works on blocks; output cannot be redirected |
| `$CMD_DURATION` | runtime of the last command, ms |

`fish --profile-startup /tmp/fishprof.txt -c exit`, then
`sort -nk2 /tmp/fishprof.txt | tail -20` puts the slowest cumulative entries last. `fish_trace` is the
fastest way to see which autoloaded function or `conf.d` snippet actually ran.
