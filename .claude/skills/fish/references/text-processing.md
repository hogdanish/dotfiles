# Fish — text, path and number builtins

`string`, `path`, `math`, `printf`, `echo` and `read` — the builtins that replace `sed`, `grep`,
`cut`, `tr`, `awk`, `basename`, `dirname`, `realpath` and `bc`. Forking any of those is a style
violation ([style-guide.md](style-guide.md) §0.5, §8), so this is the lookup table for complying.
Verified against **fish 4.8.1** under `fish --no-config`. `test`, `argparse` and `status` are in
[builtins.md](builtins.md); expansion and command-substitution syntax in
[language.md](language.md); scoping in [variables.md](variables.md).

⚠ `seq` is `/usr/bin/seq`, an external — iterate lists directly instead (style-guide §5).

## 1. Translation table

| Unix pipeline | fish builtin |
| --- | --- |
| `grep pat` | `string match -e pat` (glob) / `string match -er pat` (regex) |
| `grep -v pat` | `string match -ev pat` / `string match -erv pat` |
| `grep -c pat` | `cmd \| string match -e pat \| count` |
| `grep -o pat` | `string match -r pat` — regex `match` prints only the match; `-a` for all |
| `sed 's/a/b/'` | `string replace a b` |
| `sed 's/a/b/g'` | `string replace -a a b` |
| `sed -E 's/re/x/'` | `string replace -r re x` |
| `sed -n 's/re/x/p'` | `string replace -rf re x` (`-f`/`--filter`: only changed lines) |
| `cut -d: -f2` | `string split -f2 : $line` (`-f2-4` for a span) |
| `awk '{print $2}'` | `string split -n " " -f2 $line`, or `string match -rg '^\S+\s+(\S+)'` |
| `tr '[:upper:]' '[:lower:]'` | `string lower` |
| `tr -d abc` | `string replace -ra '[abc]' ''` — or `string trim -c abc` for edges only |
| `wc -l` | `cmd \| count` |
| `head -n1` | `cmd \| read -l first`, or `string match -rm1 '.*'` |
| `basename $p` | `path basename $p` |
| `basename $p .gz` | `path basename -E $p` (strips the *last* extension; fish 4.0.0+) |
| `dirname $p` | `path dirname $p` |
| `realpath $p` / `readlink -f $p` | `path resolve $p` — for a nonexistent path it resolves as far as it can |
| `test -f $f` | `test -f $f` — already a builtin; for a **list** use `path filter -f` / `path is -f` |
| `test -d $d` | `path is -d $d` |
| `[ -x $f ]` | `path is -x $f` (`path is -fx` to also require a regular file) |
| `echo -n "$x"` | `printf %s $x` — see the `echo -n` trap below |
| `printf` | `printf` (builtin, GNU coreutils 6.9 semantics) |
| `bc` / `expr` | `math` |
| `expr $a / $b` (integer) | `math -s0 $a/$b` — see the `math` ⚠ |

## 2. `string`

- ⚠ **With no `STRING` arguments, `string` reads stdin, one string per line.** Arguments *and* a
  pipe is an error. Redirection works, so `string collect < file` reads a file with no fork.
- ⚠ **Non-zero exit when nothing happened** — no match, replacement, split or trim. That makes
  `string` usable directly as a condition; `-q`/`--quiet` makes any subcommand a pure predicate.

Put `--` before positional arguments whenever a value could start with `-`.

### `length`

`string length [-q] [-V | --visible] [STRING ...]` — characters per string, one line each. `-q` is
`test -n "$str"` with no output. `-V`/`--visible` counts terminal columns, discounting escape
sequences and counting each `\n` line separately.

```fish
string length hello # -> 5
string length --visible (set_color red)foobar # -> 6, the colour escape is discounted
```

### `sub`

`string sub [-s START] [-e END | -l LENGTH] [-q] [STRING ...]` — 1-based; negative indices count from
the end. `--length` and `--end` are mutually exclusive.

```fish
string sub -s 2 -l 3 abcdef # -> bcd
string sub -s -3 abcdef # -> def
string sub -e -1 abcdef # -> abcde
```

### `split` / `split0`

`string split [-f FIELDS] [-m MAX] [-n] [-q] [-r] SEP [STRING ...]`. `-f`/`--fields` prints only
those 1-based fields (comma list and `2-4` spans) — this is `cut`. `-m`/`--max` caps the number of
splits, `-r`/`--right` splits from the right. `-n`/`--no-empty` drops empties — how you emulate
`awk`'s whitespace collapsing.

```fish
string split . example.com # -> example, com
string split -f2 : root:x:0:0 # -> x
string split -r -m1 / /usr/local/bin/fish # -> /usr/local/bin, fish
string split -n , 'a,,b' # -> a, b
string split '' abc # -> a, b, c  (empty SEP splits characters)
string split -m1 = 'KEY=a=b' # -> KEY, a=b  (keeps the value intact)
```

`split0` splits on NUL and its output is **not** re-split in a command substitution, which is how you
consume `find -print0` safely: `set -l files (find $dir -type f -print0 | string split0)`.
⚠ Never `string split0 (find . -print0)`: arguments cannot hold NUL, so it must be a pipe.

### `join` / `join0`

`string join [-q] [-n] [--] SEP [STRING ...]` — status 0 if at least one join happened; `-n` excludes
empty strings. `join0` uses NUL and appends a trailing one, for `sort -z`.

```fish
string join , a b c # -> a,b,c
string join -n + a b '' c # -> a+b+c  (-n drops the empty)
string join '' a b c # -> abc
string join / -- /tmp foo.txt # -> /tmp/foo.txt
```

⚠ **Always `--` before the list.** `set -l l '- a' '- b'; string join \n $l` fails with
`string join: - a: unknown option`; `string join -- \n $l` works. Same for any variable that
*might* start with a hyphen.

### `trim`

`string trim [-l] [-r] [-c CHARS] [-q] [STRING ...]` — whitespace by default; `-l`/`-r` restrict to
one side. ⚠ `-c CHARS` is a **character set**, not a substring: `-c foo` removes any `f` or `o`.

```fish
string trim '  abc  ' # -> abc
string trim -c =/ '==/usr/==' # -> usr
```

### `pad`

`string pad [-r] [-C] [-c CHAR] [-w WIDTH] [STRING ...]` — pads to *visible* width; left by default,
`-r` right, `-C`/`--center` both (fish 4.1.0+). Without `-w` it pads to the widest input.
`printf '%8s'` covers the plain left-pad case more legibly.

```fish
string pad -w 8 -c . abc # -> .....abc
string pad -r -w 8 -c . abc # -> abc.....
string pad -C -w 9 -c . abc # -> ...abc...
```

### `escape` / `unescape`

`string escape [-n] [--style=script|var|url|regex]` and its inverse `string unescape [--style=]`.
`script` (default) round-trips through `eval`, quoting for legibility unless `-n`; `var` hex-encodes
to a legal variable name; `url` percent-encodes; `regex` escapes a literal for interpolation into a
`-r` pattern and has no `unescape`. `string escape` is also the debugging tool of choice — it makes
stray newlines and whitespace visible.

```fish
string escape "it's" # -> "it's"
string escape --style=var 'brew --prefix' # -> brew_20_2D_2D_prefix
string escape --style=url 'a b/c' # -> a%20b/c
string escape --style=regex 'a.b*' # -> a\.b\*
string unescape --style=url 'a%20b%2Fc' # -> a b/c
```

### `match`

`string match [-a] [-e] [-i] [-g] [-r] [-n] [-q] [-v] [-m MAX] PATTERN [STRING ...]`

| Flag | Effect |
| --- | --- |
| `-r`/`--regex` | PCRE2 instead of glob; **does not** have to match the whole string |
| `-a`/`--all` | report every match, not just the first per string |
| `-e`/`--entire` | print the whole string, prefix and suffix included — `grep` without `-o` |
| `-g`/`--groups-only` | print only capture groups, skipping the full match. Requires `-r`; the cutting tool |
| `-v`/`--invert` | select the non-matching strings — `grep -v` |
| `-q`/`--quiet` | status only, exits early |
| `-i` / `-n` / `-m MAX` | case-insensitive / report `start length` pairs / stop after MAX matches (4.0.0+) |

⚠ Default mode is **glob**, and a glob must match the *entire* string. ⚠ Glob `*` crosses `/` —
`string match -q '*.fish' -- a/b/c.fish` is true, unlike filename globbing.

```fish
string match 'a*b' axxb # -> axxb;  string match 'a*b' nope -> status 1
string match -e foo foo1 foo foo2 # -> foo1, foo, foo2
string match -r '(\d+)\.(\d+)' 1.22 # -> 1.22, 1, 22  (full match, then each group)
string match -rg '(\d+)\.(\d+)' 1.22 # -> 1, 22        (groups only)
string match -rg '^(\w+)://' https://example.com # -> https
string match -ran at ratatat # -> "2 2", "4 2", "6 2"
string match -er -- - -h --version foo # -> -h, --version  (-- protects the pattern)
printf '%s\n' a=1 '# c' '' b=2 | string match -rv '^\s*(#|$)' # -> a=1, b=2
```

### `replace`

`string replace [-a] [-f] [-i] [-r] [-q] [-m MAX] PATTERN REPLACEMENT [STRING ...]`

| Flag | Effect |
| --- | --- |
| `-r`/`--regex` | PCRE2 pattern; REPLACEMENT may use `$1`, `${1}`, named groups and `\n`/`\t` |
| `-a`/`--all` | replace every occurrence, not just the first (`sed` `/g`) |
| `-f`/`--filter` | print only strings that actually changed (`sed -n …/p`) |

⚠ Default `PATTERN` is a **literal substring**, not a regex — the opposite default from `match`.
⚠ Like `sed s///`, non-matching strings are still printed; `-f` suppresses them.

```fish
string replace a b abcabc # -> bbcabc
string replace -a a b abcabc # -> bbcbbc
string replace -r '[0-9]+' N a12b345 # -> aNb345  (first match only)
string replace -r '(\w+)\s+(\w+)' '$2 $1' 'left right' # -> right left
string replace -r '(\d+)' 'v${1}x' 12 # -> v12x  (braces when text follows)
string replace -rf '^export ' '' 'export FOO=1' nope # -> FOO=1 only
```

### `repeat`

`string repeat [-n COUNT] [-m MAX] [-N] [-q] [STRING ...]`; the first bare argument is COUNT if
neither `-n` nor `-m` is given. `-m` caps output characters, `-N` omits the trailing newline.

```fish
string repeat -n3 ab # -> ababab
string repeat -n3 -m5 ab # -> ababa
string repeat -n 20 -N = # a 20-column rule, no newline
```

### `upper` / `lower`

`string upper|lower [-q] [STRING ...]`. Status 0 means a change *would* be made, so `-q` answers "is
this already lowercase?" — `string lower -q ABC` exits 0, `string lower -q abc` exits 1.

### `collect`

⚠ **The problem `collect` solves:** a command substitution splits its output on newlines, so
`set -l v (cmd)` yields a *list*, one element per line. `string collect` makes it one element.
Trailing newlines are trimmed exactly as `"$(cmd)"` would; `-N`/`--no-trim-newlines` keeps them.
`-a`/`--allow-empty` forces one empty argument out so it cannot vanish:
`echo foo(true | string collect --allow-empty)bar` prints `foobar`.

```fish
set -l v (printf 'a\nb\nc\n') # count $v -> 3   ← usually a bug
set -l v (printf 'a\nb\nc\n' | string collect) # count $v -> 1, value "a\nb\nc"

# read a whole file into one variable, no `cat` fork
set -l contents (string collect </etc/hosts)
string length $contents # -> 212
```

### `shorten`

`string shorten [-m MAX] [-c CHARS] [-l] [-N] [-q] [STRING ...]` — truncate to a visible width and
mark it with `…` (`...` if the locale can't). `-l`/`--left` keeps the *suffix*; `-c ''` disables the
ellipsis; `-N` uses only the first (with `-l`, last) line of a multi-line argument.

```fish
string shorten -m 10 'hello this is long' # -> hello thi…
string shorten -m 10 --left 'hello this is long' # -> …s is long
string shorten -m6 -c '' abcdefgh # -> abcdef
```

## 3. Regex reference for `-r`

The dialect is **PCRE2** — `grep -P`, not `grep -E`, and definitely not `sed`.

| | fish `-r` | `sed` BRE |
| --- | --- | --- |
| Grouping | `(…)` capturing, `(?:…)` non-capturing | `\(…\)` |
| Repetition | `+ ? {n,m}` are metacharacters by default | need backslashes |
| Shorthand classes | `\d \D \s \S \w \W \b \B` | unavailable |
| Group in the *replacement* | `$1` / `${1}` (`\1` in the *pattern*) | `\1` in both |

`^`/`$` anchor the start/end of each input string, matched separately. `.` excludes newline.
POSIX named classes work inside brackets: `[[:alnum:]] [[:alpha:]] [[:ascii:]] [[:blank:]]
[[:cntrl:]] [[:digit:]] [[:graph:]] [[:lower:]] [[:print:]] [[:punct:]] [[:space:]] [[:upper:]]
[[:word:]] [[:xdigit:]]`, each negatable as `[[:^xxx:]]`.

**Named captures are supported.** `string match -r` sets a variable per group in the current scope —
the idiomatic way to destructure a string. With `-a` each becomes a *list*; a group that did not
participate leaves the variable unset (`count $var` is 0), not empty. `-q` + `-r` is the canonical
`if` condition — no `test`, no fork; `not string match -qr …` negates it (style-guide §5).

```fish
# right
if string match -qr '^(?<key>[^=]+)=(?<value>.*)$' -- $line
    printf '%s -> %s\n' $key $value
end

# wrong — forks, and `[[ ]]`/`=~` do not exist in fish
if [[ $line =~ ^KEY= ]]
```

## 4. `path`

Introduced in **fish 3.5.0**; `mtime` added in 3.6.0, `basename -E` in 4.0.0. Every subcommand takes
`-q`/`--quiet`, `-z`/`--null-in` and `-Z`/`--null-out`, reads stdin when given no arguments, and
accepts a list. The string-only ones (`basename`, `dirname`, `extension`, `change-extension`,
`normalize`) work on non-existent paths; the rest silently drop paths that do not exist.
⚠ **`path`'s output is split correctly in a command substitution even for paths containing
newlines** — `for f in (path filter -f $dir/*)` is safe where `for f in (ls $dir)` is not.

| Subcommand | Result | Status 0 when |
| --- | --- | --- |
| `basename [-E]` | last component; `-E` also strips the last extension | there was a basename |
| `dirname` | everything before the last `/` | there was a dirname |
| `extension` | last `.` and after, empty line if none | there was an extension |
| `change-extension EXT` | swap the extension; `''` strips it; leading dot optional | any path was given |
| `normalize` | squash `//`, collapse `..`, drop `.` — string-only, stays relative | ⚠ a change was made |
| `resolve` | normalize + resolve symlinks + absolutize (`realpath`) | ⚠ a change was made |
| `filter` | the paths passing the filters | at least one passed |
| `is` | nothing (≡ `filter -q`) | at least one passed |
| `mtime [-R]` | mtime in epoch seconds; `-R` seconds *ago* | any read succeeded |
| `sort [-r] [-u] [--key=]` | glob order, digit runs compared numerically | any path was given |

⚠ `normalize` and `resolve` return **1 when the path was already canonical**: `path normalize /etc`
prints `/etc` and exits 1. Never use their status as an existence or success test.

```fish
path basename /usr/local/bin/fish # -> fish ;  path basename /usr/bin/ -> bin
path basename -E /tmp/foo.tar.gz # -> foo.tar
path dirname /usr/local/bin/fish # -> /usr/local/bin
path extension /tmp/foo.tar.gz # -> .gz ; /tmp/README -> empty line, status 1
path change-extension md /tmp/foo.txt # -> /tmp/foo.md
path change-extension '' /tmp/foo.txt # -> /tmp/foo
path normalize /usr/bin//../../etc/fish # -> /etc/fish
path resolve /tmp/../etc/hosts # -> /private/etc/hosts  (macOS symlink resolved)
path mtime -R ~/.config/fish/config.fish # -> seconds since last modification
path sort 10-foo 2-bar # -> 2-bar, 10-foo
path sort -u --key=basename a/x b/x c/y # -> a/x, c/y
```

### `path filter` — the existence test to reach for

`path filter [-v] [-d -f -l -r -w -x] [-t TYPE] [-p PERM] [--all] [PATH ...]`

`-f`/`-d`/`-l` are `--type=file|dir|link`; `-r`/`-w`/`-x` are `--perm=read|write|exec`. Other types
(`block`, `char`, `fifo`, `socket`) and permissions (`suid`, `sgid`, `user`, `group`) need the long
form. A path must be **any** of the given types but have **all** of the given permissions; links
count as their target's type. `-v`/`--invert` passes what would fail, *including non-existent paths*.
`path filter -fx $PATH/*` lists every command fish could run.
Because it takes a list and returns only what exists, it replaces the whole
`if test -x A; …; else if test -x B; …` cascade:

```fish
# pick whichever prefix actually exists, in preference order
set -l brewcmd (path filter /opt/homebrew/bin/brew /usr/local/bin/brew)
if set -q brewcmd[1]
    $brewcmd[1] shellenv | source
end
```

⚠ `path is A B` (≡ `path filter -q`) is true if **any** argument passes — it is not
`test -f A -a -f B`. For "all of them" use `path filter --all` (status only, no output), equivalently
`not path filter -v`.

```fish
path filter -f /etc/hosts /etc # -> /etc/hosts
path filter -d /etc/hosts /etc # -> /etc
path filter -fx /bin/sh /etc/hosts # -> /bin/sh  (regular file AND executable)
path filter -v -f /etc/hosts /etc /nope # -> /etc, /nope
path is /nope /etc # status 0 — /etc passed
path filter --all /nope /etc # status 1 — /nope did not
```

`test -f`/`-d`/`-x` remain fine for a single known path (`test` is a builtin, nothing forks); reach for
`path filter`/`path is` for a list, a type+permission combination, or a fallback chain.

## 5. `math`

`math [-s N] [-b BASE] [-m MODE] EXPRESSION ...` — tinyexpr since fish 3.0.0, no `bc` fork. Arguments
are joined with a space, so `math 2 +2` and `math "2 + 2"` are identical; no `--` needed before a
leading minus. Status is 1 on overflow, NaN or division by zero (which also writes to stderr).

⚠ **`math` is floating point and defaults to 6 decimal places — `math 10/3` is `3.333333`, not `3`.**
There is no integer type; get integers deliberately. `-m`/`--scale-mode` is
`truncate|round|floor|ceiling`, defaulting to `round` at non-zero scale and `truncate` at scale 0.

```fish
math 10/3 # -> 3.333333
math -s0 10/3 # -> 3   (scale 0 truncates, for bc compatibility)
math -s0 -- -7/2 # -> -3   (truncation is toward zero, NOT floor)
math -s0 -m floor -- -7/2 # -> -4
math 'floor(10/3)' # -> 3 ;  ceil(10/3) -> 4 ;  round(10/3) -> 3
math -s3 10/6 # -> 1.667  (non-zero scale rounds)
```

| | |
| --- | --- |
| Operators | `+ - * / ^ %`, `x` for multiply, `( )` for grouping |
| Quoting | ⚠ `*` is a glob, `()` is command substitution — quote or escape: `math '3 * 4'`, `math 3 \* 4`. Function parens are optional, but a comma binds to the inner function, so parenthesize when nesting |
| `x` caveat | must be followed by whitespace: `math 0 x 3` is 0×3, `math 0x3` is hex 3 |
| Constants | `e`, `pi`, `tau` — no `$` |
| Input | decimal, `0xFF` hex, `10e5` scientific, `1_000_000` separators. Octal is **not** read |
| Output base | `-b hex` → `0xc0`, `-b octal` → `010`; implies scale 0 |
| Functions | `abs ceil floor round sqrt exp ln log log10 log2 pow fac min max ncr npr`, `sin cos tan asin acos atan atan2 sinh cosh tanh` (radians), `bitand bitor bitxor` (no `bitnot` — mask with `bitxor`) |

```fish
math '2^10' # -> 1024
math '10 % 3' # -> 1
math 0xFF # -> 255 ;  math --base=hex 192 -> 0xc0
math max 5,2,3 # -> 5 ;  math 'bitand(0xFE, 0x2e)' -> 46
math (path mtime /etc/hosts) - 0 # arithmetic on builtin output, no forks anywhere
```

## 6. `printf` vs `echo`

**Default to `printf`.** It takes no options, so it can never mistake data for a flag, and it never
appends a newline you did not write. ⚠ The trap, verified:

```fish
set -l v -n
echo $v # prints NOTHING — the value was consumed as echo's -n flag
printf '%s\n' $v # prints -n
echo -- $v # also prints -n, but you have to remember the --
```

Any `echo` whose argument is a variable, and anything going to stderr, should be `printf`. The
FORMAT is **reused** until the arguments run out.

```fish
printf '%s\n' a b c # three lines
printf '%s=%s\n' a 1 b 2 # a=1 then b=2
printf '%s\t%s\n' flounder fish # tab-separated — the shape `complete` wants
printf '%5s|\n' ab # "   ab|" — a number before the letter is a width
printf '%.2f\n' 3.14159 # 3.14
printf 'error: %s\n' $msg >&2 # errors go to stderr (style-guide §5)
```

Specifiers: `%d`/`%i`, `%u`, `%o`, `%x`/`%X`, `%f`/`%g`/`%G`, `%e`/`%E`, `%s`, `%b`, `%%`. Escapes:
`\n \t \r \e \a \b \f \v \\ \" \ooo \xhh \uhhhh \Uhhhhhhhh`. A failed conversion (`%d` given
`102.234`) writes to stderr and returns non-zero while still printing what it can; so does no
argument at all. `echo` is fine for a fixed literal: `-n` no trailing newline, `-s` no space between
arguments (`echo -s a b c` → `abc`), `-e` interpret escapes (`echo -e 'a\tb'` → `a<TAB>b`), `-E`
don't (default), `--` end of options — a fish extension POSIX forbids, so `command echo --` is not
portable.

## 7. `read`

`read [OPTIONS] [VARIABLE ...]` — one line from stdin, split into the named variables; the last one
absorbs the remainder. There is no `$REPLY`: with **no** variable names `read` copies stdin to
stdout, which is what makes `mysql -p(read)` work. It returns 1 at EOF, which terminates a
`while read` loop. Input is capped at `$fish_read_limit` (100 MiB); over it, the variable is emptied
and the status is 122.

| Flag | Effect |
| --- | --- |
| `-l`/`--local` | block-local — the default choice ([style-guide.md](style-guide.md) §3) |
| `-g`/`--global` | global; `-f` function-scoped, `-x` exported. ⚠ Never `-U` in config |
| `-d`/`--delimiter STR` | split on STR as a whole string, not a character set |
| `-t`/`--tokenize` | split by shell tokenization rules — honours quotes and escapes, ignores `IFS` |
| `-a`/`--list` | collect all tokens into one list variable (only one name allowed) |
| `-z`/`--null` | NUL-terminated instead of newline; also reads a whole file in one go |
| `-n`/`--nchars N` | stop after N characters or end of line |
| `-L`/`--line` | fill each variable with a whole *untokenized* line |
| `-P`/`--prompt-str STR` | literal prompt (`-p CMD` runs a command for it); `-s` masks typed input. Interactive-only, so unverifiable non-interactively: `read -ls -P 'passphrase: ' secret` |

Without `-d`/`-t`/`-L`, splitting uses `IFS` (space, tab, newline). ⚠ `IFS` reliance is deprecated
and will be removed — always be explicit.

```fish
echo 'a b c' | read -l x y z # x=a y=b z=c
echo 'a b c d' | read -l x y # x=a, y="b c d"  ← last var takes the rest
echo KEY=some=value | read -l -d = k v # k=KEY v=some=value
echo 'a,b,c' | read -la parts -d , # count $parts -> 3
echo 'a\ b c' | read -lt first second # first="a b", second=c

# whole file into one variable, no fork (the -z terminator never appears)
read -lz contents <~/.config/fish/config.fish

# first line only; then the first two lines, untokenized
printf '%s\n' l1 l2 l3 | read -l first # first=l1
read -l --line first second </tmp/two-lines.txt

# the line-by-line loop; `-l` keeps $line out of the enclosing scope
while read -l line
    printf 'got %s\n' $line
end <~/.config/fish/conf.d/git.fish

# NUL-delimited stream
find . -type f -print0 | while read -lz file
    printf '%s\n' $file
end
```

## 8. Recipes

```fish
# 1. strip a trailing comment and surrounding whitespace
set -l value (string replace -r '\s*#.*$' '' -- $line | string trim)

# 2. skip blank lines and comments while reading a file
while read -l line
    string match -qr '^\s*(#|$)' -- $line; and continue
    printf 'data: %s\n' $line
end <~/.config/fish/conf.d/git.fish

# 3. parse KEY=value, keeping '=' inside the value
if string match -qr '^(?<key>[^=]+)=(?<value>.*)$' -- $line
    set -gx $key $value
end

# 4. lowercase and slugify an identifier
set -l slug (string lower -- $name | string replace -ra '[^a-z0-9]+' -) # "My Tool v2" -> my-tool-v2

# 5. split $PATH into its entries, and join a list back up with commas
for dir in (string split : -- $PATH)
    printf '%s\n' $dir
end
printf 'tools: %s\n' (string join ', ' -- $THEME_TOOLS) # -> tools: ghostty, git, micro

# 6. extension, and the basename without it
set -l ext (path extension -- $file) # /tmp/a.tar.gz -> .gz
set -l stem (path change-extension '' -- (path basename -- $file)) # -> a.tar

# 7. build a path with no doubled or missing slashes
set -l target (string join / -- $XDG_CONFIG_HOME fish conf.d $tool.fish | path normalize)

# 8. guard, then source — never assume the file is there (style-guide §4)
set -l cache $XDG_CACHE_HOME/fish/zoxide.fish
test -r $cache; and source $cache

# 9. extract a version number from a tool's own output
set -l ver (fish --version | string match -rg '(\d+\.\d+\.\d+)') # -> 4.8.1
set -l major (string split -f1 . -- $ver) # -> 4

# 10. trim whitespace off command output without a second fork
set -l branch (git rev-parse --abbrev-ref HEAD 2>/dev/null | string trim)

# 11. hold multi-line output as ONE value, then split deliberately
#     plain `set -l x (cmd)` would already be a 3-element list here — often a silent bug
set -l blob (git config --file ~/.config/git/.gitconfig --get-regexp '^user\.' | string collect)
for line in (string split \n -- $blob)
    printf '  %s\n' $line
end
```
