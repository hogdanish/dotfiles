# Fish — bash → fish translation and de-bashification

Every construct an agent reflexively writes in bash and what it must become in fish 4.8.1. Right-hand
cells were run through `/opt/homebrew/bin/fish --no-config -c '…'`; anything unverifiable was cut.
Style rules (word operators, `set -l`, `--description`, no `alias`) live in
[style-guide.md](style-guide.md) — this file is about *semantics*.

## 1. Syntax translation

### 1.1 Substitution and expansion

| bash | fish | Notes |
| --- | --- | --- |
| `$(cmd)` | `(cmd)` or `$(cmd)` | identical, except only the `$`-form expands inside `"…"`; `"(cmd)"` is a literal |
| `` `cmd` `` | `(cmd)` | backticks are not fish syntax at all |
| `${var}` | `$var`, or `{$var}` when a following character would glue on | ⚠ `${var}` is a **parse error**: `Variables cannot be bracketed. In fish, please use {$var}.` |
| `"$var"` | `"$var"` | quoting is about *arity*, not word splitting (§4.1) |
| `${arr[@]}` / `"${arr[@]}"` | `$arr` | every variable is a list; expansion splats elements as separate arguments |
| `${arr[0]}` | `$arr[1]` | ⚠ **1-based.** `$arr[-1]` is the last, `$arr[2..-1]` a slice |
| `${#arr[@]}` | `count $arr` | `count` is also the `wc -l` replacement |
| `${#str}` | `string length -- $str` | |
| `${var:-def}` | `set -q var; or set -l var def` | the fish idiom is a guard, not an expansion (style-guide §3) |
| `${var:?msg}` | `set -q var; or begin; echo >&2 msg; return 1; end` | |
| `${var//a/b}` | `string replace -a a b -- $var` | `-r` for regex |
| `${var#pre}` / `${var%suf}` | `string replace -r '^pre' '' -- $var` / `string replace -r 'suf$' '' -- $var` | for paths prefer `path basename` / `path dirname` / `path change-extension` |
| `${var^^}` / `${var,,}` | `string upper $var` / `string lower $var` | |
| `${var:2:3}` | `string sub -s 3 -l 3 -- $var` | ⚠ `-s` is 1-based, so add 1 to bash's offset. `${var: -3}` → `string sub -s -3` |
| `${!name}` (indirect) | `echo $$name` | double-`$` expands the variable *named* by `$name` |
| `$((i+1))` | `math $i + 1` | floats by default: `math 5 / 2` → `2.5` |
| `$((7/2))` (integer) | `math -s0 7 / 2` → `3` | or `math "floor(7/2)"`; `%` works: `math 7 % 2` → `1` |
| `{1..10}` | `seq 1 10` | ⚠ fish does **not** expand numeric ranges — `echo {1..3}` prints `{1..3}` literally |
| `{a,b}` | `{a,b}` | brace expansion of alternatives is the same; works after a quoted prefix: `"$dir"/{a,b}` |
| `~`, `~root` | same | ⚠ not expanded when quoted: `echo "~"` prints `~` |
| `<(cmd)` | `(cmd \| psub)` | §1.6 |
| `>(cmd)` | — | no equivalent; restructure as a pipe |
| `$RANDOM` | `random` | `random 1 10` for a range |

### 1.2 Variables

| bash | fish | Notes |
| --- | --- | --- |
| `A=b` | `set A b` | ⚠ `set A=b` is an error; `set A = b` sets *two* values, `=` and `b` |
| `export A=b` | `set -gx A b` | "exported" is a bit, not a scope |
| `local x=1` | `set -l x 1` | |
| `declare -a arr=(a b)` | `set -l arr a b` | no separate array syntax — every variable is a list |
| `unset A` | `set -e A` | `set -e arr[2]` erases one element |
| `A=b cmd` | `A=b cmd` | works since fish 3.1. Verified: the override does not leak, and several may be stacked (`a=1 b=2 cmd`) |
| `readonly X` | — | convention only (SCREAMING_SNAKE + `-g`); fish has no readonly |
| `local -n ref=$1` | — | no namerefs. Pass the *name* and use `set $name …` / `$$name` |
| `declare -A map` | — | no associative arrays (§2) |
| `$0` | `status filename` | `path basename (status filename)` for the short form |
| `$1`, `$2`, `$@`, `$*` | `$argv[1]`, `$argv[2]`, `$argv` | |
| `$#` | `count $argv` | |
| `$?` | `$status` | ⚠ clobbered by the next command (§4.4) |
| `$PIPESTATUS` | `$pipestatus` | verified: `false \| true` → `status 0`, `pipestatus 1 0` |
| `$$` / `$!` | `$fish_pid` / `$last_pid` | |
| `$-` | `status is-interactive`, `status is-login` | |
| `$LINENO` | `status line-number` | |
| `$IFS` | — | fish does not word-split (§2) |
| `shift` | `set -e argv[1]` | verified |

### 1.3 Conditionals and control flow

| bash | fish | Notes |
| --- | --- | --- |
| `[[ x == y ]]` | `test x = y` | ⚠ there is no `[[`, and `test` rejects `==`: `test: unexpected argument at index 2: '=='` |
| `[[ $x == pre* ]]` | `string match -q 'pre*' -- $x` | glob compare |
| `[[ $x =~ re ]]` | `string match -qr 're' -- $x` | regex compare |
| `[[ -z $x ]]` | `test -z "$x"` | quotes mandatory |
| `[[ -n $x ]]` | `test -n "$x"` or `string length -q -- $x` | ⚠ unquoted `test -n $x` on an unset/empty var silently returns **true** — the list expands to nothing and `test` reads the one-argument form. Silent wrong answer, not an error |
| `[[ -v var ]]` | `set -q var` | `set -q var[1]` for "has at least one element" |
| `[[ $a && $b ]]` | `test -n "$a" -a -n "$b"` | `test` has its own `-a`/`-o` |
| `cmd1 && cmd2` | `cmd1; and cmd2` | `&&` also works; word forms are house style (style-guide §5) |
| `cmd1 \|\| cmd2` | `cmd1; or cmd2` | |
| `! cmd` | `not cmd` | `!` also works |
| `if …; then …; fi` | `if …` … `end` | no second starting word |
| `case …) …;; esac` | `switch $x` / `case "*.tar.gz"` / `end` | quote case globs |
| `for x in …; do …; done` | `for x in …` … `end` | |
| `for ((i=0;i<n;i++))` | `for i in (seq 0 (math $n - 1))` | but prefer iterating the list itself (style-guide §5) |
| `until cmd; do` | `while not cmd` | fish has no `until` |
| `while read -r line` | `while read -l line` | `-l` scopes it to the loop; fish's `read` never interprets backslashes, so bash's `-r` has no analogue |
| `function f() { … }` | `function f --description '…'` … `end` | `--description` is mandatory here (style-guide §6) |
| `getopts` | `argparse` | |
| `return N` | `return N` | in a function; verified `$status` == N |
| `exit N` | `exit N` | in a script; ⚠ in a function it exits the whole shell |
| `trap 'h' INT` | `function __h --on-signal INT` | verified in a script: the handler runs and the script continues |
| `trap 'h' EXIT` | `function __h --on-event fish_exit` | verified: fires when the shell exits |
| `set -x` (xtrace) | `set -gx fish_trace 1` | prints `> cmd` per command |
| `set -e` / `set -u` / `set -o pipefail` | — | nothing equivalent (§2) |
| `shopt -s nullglob` / `failglob` | — | not configurable; fish is always `failglob` except in `set`/`path`/`count`/`for`/env-override, where it is `nullglob` (§4.2) |
| `shopt`-style toggles generally | `status features` | the only feature switches fish has, and they are compatibility flags |

### 1.4 Strings instead of parameter expansion

`string` and `path` replace `sed`/`grep`/`cut`/`basename`/`dirname` as well as `${…}` tricks
(style-guide §0.5). The five that come up constantly:

```fish
string replace -a / : -- $p # ${p//\//:}
string replace -r '\.txt$' '' -- $p # ${p%.txt}
string split -m 1 = -- $line # split on the first = only
string match -qr '^v\d+$' -- $tag # [[ $tag =~ ^v[0-9]+$ ]]
string join , -- $list # "${list[*]}" with IFS=,
path basename $p # also: path dirname $p, path resolve $p (readlink -f)
```

### 1.5 Heredocs — fish has none

⚠ There is no `<<EOF`, no `<<-`, and no `<<<`. Four replacements, in order of preference:

```fish
# 1. one argument per line
printf '%s\n' 'line one' 'line two' | cmd

# 2. a quoted string — quotes carry across newlines
echo "line one
line two" | cmd

# 3. build then reuse; `string collect` keeps it as ONE value
set -l body (printf '%s\n' 'line one' 'line two' | string collect)

# 4. feed fish code straight to source (no temp file, no psub)
echo 'echo hi' | source
```

`read -z` is the inverse: it reads all of stdin into one variable, trailing newline included
(`printf 'l1\nl2\n' | read -lz blob` → `$blob` splits into 3 on `\n`).

### 1.6 Redirection and pipes

| bash | fish | Notes |
| --- | --- | --- |
| `cmd >&2` | `cmd >&2` | identical. `echo >&2 'msg'` is the house error idiom |
| `cmd &>file` | `cmd &>file` | supported, plus `&>>` to append |
| `cmd >file 2>&1` | same | |
| `cmd 2>&1 \| next` | `cmd &\| next` | ⚠ **`2>&1 \|` also works in fish** and is in the official manual — the pipe is created first, then redirections apply left to right. `&\|` is the fish spelling and the house preference; do not "fix" working `2>&1 \|` code |
| `cmd 2> >(next)` | `cmd 2>\| next` | pipe just stderr |
| `cmd >\| file` (noclobber off) | `cmd >? file` | fish's `>?` is the *noclobber* form: it warns and returns 1 if the file exists |
| `diff <(a) <(b)` | `diff (a \| psub) (b \| psub)` | `psub` writes a temp file (`--file` is the default) and prints its name; `--fifo` only for <8 KiB; `--suffix .c` when the reader cares about the extension |
| `source <(cmd)` | `cmd \| source` | fish's `source` reads stdin (`source -` explicitly), so `psub` is unnecessary here |

## 2. No fish equivalent

| bash feature | Reality | Do this instead |
| --- | --- | --- |
| `set -euo pipefail` | none of the three exist | check every fallible command: `cmd; or return 1`. For pipelines inspect `$pipestatus`. `set -u` is unneeded-ish: an unset variable expands to nothing **silently** (verified `count $nosuchvar` → 0), so guard with `set -q` where emptiness matters |
| heredocs | absent by design (they are "minor syntactical sugar with a lot of special rules" — `fish_for_bash_users.md`) | §1.5 |
| `$IFS` splitting | fish never word-splits; setting `IFS` changes nothing (verified: `count` of a 2-line substitution stays 2 with `IFS=,`) | `string split`, `string split0`. ⚠ The one residual effect: `IFS=""` disables line splitting in command substitutions — deprecated, use `string collect` |
| associative arrays | absent | (a) two parallel lists plus `contains --index`: `set -l i (contains --index -- green $keys); echo $vals[$i]`; (b) one variable per key, name-mangled so any key is legal: `set -g __map_(string escape --style=var -- $k) $v`, read back via `set -l n __map_(string escape --style=var -- $k); echo $$n`. Both verified; (b) is what fisher itself does |
| `local -n` namerefs | absent | pass the variable *name*: `set $name value`, read `$$name` |
| `${var//a/b}` in-place expansion | absent | `set var (string replace -a a b -- $var)` |
| `( … )` subshell | ⚠ `begin/end` is **not** a subshell — it shares the enclosing scope (verified: `set v inner` inside `begin` changes the outer `$v`) | `begin; …; end` when you only need grouping/redirection; `fish -c '…'` when you genuinely need an isolated process. A pipeline into `while read` also stays in the same shell, so assignments survive the loop |
| `export -f` / exported functions | absent | `fish -c` with the body inline, or a real script on `PATH` |
| sourcing a bash script | `source` parses **fish** syntax only | §3 |

## 3. Crossing the bash boundary

- **Just shell out** when the logic is already POSIX and correctness matters more than idiom:
  `bash -c 'set -euo pipefail; …'`. Quote the body in single quotes so fish leaves `$` alone.
- **One-shot variables** need no `export`: `A=b cmd` (fish 3.1+) or `env A=b cmd` when the command is a
  wrapper that re-execs.
- **A POSIX `.env` cannot be sourced.** Parse it — verified pattern for plain `KEY=value` files:
  ```fish
  # skip comments and blank lines; split on the first = only
  for line in (string match -rv '^\s*(#|$)' <$envfile)
      set -l kv (string split -m 1 = -- $line)
      set -gx $kv[1] (string trim -c '"\'' -- $kv[2])
  end
  ```
  ⚠ This handles neither `export ` prefixes, multi-line values, nor `$VAR` interpolation. If the file has
  any of those, use `bash -c 'set -a; . ./.env; exec …'` instead. For secrets use `op run --env-file`
  (style-guide §9) and parse nothing.
- ⚠ **Bash tool calls in this repo run under zsh** (CLAUDE.md), so fish functions, abbreviations and
  everything in `conf.d/` are unavailable to you. To exercise the user's shell, invoke it explicitly:
  ```sh
  /opt/homebrew/bin/fish -c '…'              # with the user's config
  /opt/homebrew/bin/fish --no-config -c '…'  # isolated — how every claim in this file was checked
  ```
  ⚠ `--no-config` also disables universal variables, history, and autoloading from the user's
  `functions/` — so `$fish_function_path` is empty and `functions -q` fails for anything user-defined.

## 4. Behaviours that surprise, not just syntax

### 4.1 No word splitting

A variable's value is never re-split. `set foo "bar baz"; printf '%s\n' $foo` prints one line. This
removes the entire class of `"$@"`-quoting bugs, so quotes are decided by *arity*: `"$var"` is exactly
one argument (possibly empty), `$var` is however many elements there are (possibly zero). ⚠ Zero is the
trap — `test -n $empty` and `cmd --flag $empty` lose the argument entirely.

Glob characters inside a variable are **not** expanded: `set foo "*"; echo $foo` prints `*`.

### 4.2 An unmatched glob is an error

`echo /nonexistent/*` does not run and sets `$status` **124** (`failglob`). The exceptions —
`set`, `path`, `count`, `for`, and environment overrides — expand to nothing instead (`nullglob`), which is
why `for f in $dir/*.fish` is safe and `ls $dir/*.fish` is not. Quote or escape a wildcard you mean
literally (`scp host:'dir/*'`).

### 4.3 Command substitution splits on newlines

| Form | Result |
| --- | --- |
| `(printf 'x\n')` | 1 element |
| `(printf 'x\n\n\n')` | **3** elements: `x`, ``, `` — only the final newline is dropped, blank lines become empty elements |
| `"$(printf 'a\nb\n\n')"` | 1 element, `a\nb` — quoting suppresses splitting and drops trailing empty lines |
| `(cmd \| string collect)` | 1 element, whitespace preserved |
| `(cmd \| string split0)` | split on NUL — the only NUL-safe way to iterate filenames |
| `(cmd \| string split -n ' ')` | when a tool (`pkg-config`) really does emit space-separated output |

⚠ A substitution or variable **adjacent to literal text distributes over the list**:
`set -l a x y; echo v=$a` prints `v=x v=y`, and an empty list annihilates the whole token
(`echo (printf '')banana` prints nothing). Double-quote when you want one token.

Reading more than 1 GiB in a substitution fails the *entire* outer command with status 122
(`$fish_read_limit`).

### 4.4 `$status` and scope

- `$status` is overwritten by the very next command, including `test` and `echo`. Capture immediately:
  `set -l rc $status`.
- `if set -l out (cmd)` tests **`cmd`'s** exit status while capturing its output — verified both ways.
- Every variable is a list; there is no scalar type. `set -q var` asks "defined", `set -q var[1]` asks
  "non-empty list", `string length -q -- $var` asks "has any content".
- `source` opens a new local scope: `set -l` inside a sourced file does not leak out.
- ⚠ Nested `function` definitions are **global** and outlive the enclosing function — defining a helper
  inside a function pollutes the session. Use a `__`-prefixed top-level function instead.
- ⚠ A **builtin** on the receiving end of a pipe *inside* a block or function sees no input:
  `echo x | begin; string upper; end` prints nothing (verified). `read` and external commands are fine —
  so use `read` to consume piped input inside a block, or move the builtin out of it.

### 4.5 Resolution order

Functions → builtins → external commands. Verified: defining `function echo` shadows the builtin.
Escape hatches: `command foo` (external only — mandatory inside a function that shadows a command,
style-guide §6), `builtin foo`, `type -q foo` / `command -q foo` / `functions -q foo` for existence tests.

### 4.6 fish is not POSIX and does not try to be

`fish_for_bash_users.md` opens with "fish is intentionally not POSIX-compatible"; `design.md` treats
compatibility as subordinate to consistency. Do not file a translation gap as a bug or reach for a
compatibility shim — rewrite the logic (§5).

## 5. The `bashisms` shim (mattmc3/fishconf) — and why not to adopt it

`conf.d/bashisms.fish` plus `functions/bashisms/{do,then}.fish` make pasted bash *parse*:

- `abbr -a --position command -- fi end` and the same for `done` → the terminators expand to `end`.
- `function do; $argv; end` and `function then; $argv; end` → the leftover bash keywords become
  functions that execute their arguments, so `for x in *` / `do echo $x` / `done` runs.
- Two `--on-event preexecute` handlers rewrite the buffer before execution: `[[ … ]]` → `[ … ]`, and a
  whole line of bare `VAR=value` assignments → `set VAR value`.
- The handlers only run because `bind \n` and `bind \r` are rebound to a wrapper that `emit`s
  `preexecute` and then `commandline -f execute`. (Not verifiable non-interactively — key bindings need a
  TTY.)

**Recommendation: do not adopt it.** Three reasons, in order of weight:

1. It hijacks Enter. Any plugin or prompt that also binds `\r` (fzf.fish widgets, magic-enter, vi-mode
   wrappers) either loses or breaks it — and the failure mode is "the shell stops executing commands".
2. It rewrites the command line before running it, so what you typed, what ran, and what history records
   diverge. That is a bad trade for a keystroke.
3. It fixes the *symptom* of pasting bash. The honest fix for a one-off paste is `bash -c '…'` (§3), and
   for anything kept, a rewrite. `do`/`then` as generic "execute my arguments" functions also swallow
   typos that would otherwise be a clean `command not found`.

Worth stealing from the same repo: nothing in this file's domain. The clever part is the `preexecute`
event pattern itself, which is a legitimate tool for *other* jobs.

## 6. Porting checklist

1. **Read the whole script first.** Decide whether it should be fish at all — a working POSIX script with
   heavy `set -euo pipefail` logic may be better left as bash and invoked from fish.
2. **Skeleton:** shebang → doc comment → constants (`set -g`, SCREAMING_SNAKE) → helpers → `main` →
   `main $argv`. Functions must be defined above their first call (style-guide, script template).
3. **Mechanical pass, top to bottom:** §1.1 substitutions, §1.2 variables, §1.3 blocks. Fix array indices
   (⚠ off-by-one, 1-based) and every `$?` → `$status`.
4. **Replace forks with builtins:** `sed`/`cut`/`tr` → `string`, `basename`/`dirname`/`readlink` → `path`,
   `expr`/`bc` → `math`, `wc -l` → `count`, `getopt` → `argparse`.
5. **Re-add the error handling `set -e` was doing for you** — every fallible command gets `; or return 1`
   (or `; or exit 1` at the top level), pipelines get a `$pipestatus` check.
6. **Requote from scratch:** `"$var"` where exactly one argument is required (all of `test`, and any path),
   bare `$var` where a list should splat. Delete bash's defensive quoting everywhere else.
7. **Remove the workarounds bash needed:** `test -f "$f" || continue` inside a glob loop, `IFS=` dances,
   `"${arr[@]:-}"` guards.
8. **Run it:** `fish -n file` parses, `fish --no-config file` runs clean in isolation,
   `fish_indent --check file` exits 0, then walk style-guide's review checklist.
