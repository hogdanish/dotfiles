# Fish style guide — mandatory for this repo

Law for every `.fish` file under `~/.config/fish` (and any fish snippet written into this repo).
Rules are **MUST** unless marked *prefer*. When a rule and a fish doc disagree, this file wins —
it encodes house preference, not fish capability.

`fish_indent` settles all formatting arguments. Never hand-format against it.

## 0. The five rules that catch 90% of agent mistakes

1. `set -l` unless another file needs the value. `-gx` only for real environment variables.
2. **Never `set -U`** in a config file — universal variables persist to `fish_variables`, which is
   machine state, not version-controlled config. See §3.
3. `--on-event` / `--on-variable` handlers **must** live in `conf.d/`, never in `functions/`.
   Autoloading does not register a handler (§6).
4. Guard every external tool with `type -q`, every optional file with `test -r`. A missing tool must
   never produce startup noise.
5. `string` and `path` builtins instead of `sed`/`grep`/`basename`/`dirname`. Forking a process at
   startup is the only fish performance mistake that matters.

## 1. Formatting

| Rule | Value |
| --- | --- |
| Indent | 4 spaces, never tabs — `fish_indent` default, non-negotiable |
| Line ending / encoding | LF, UTF-8, final newline present |
| Trailing whitespace | none |
| Line length | *prefer* ≤100 columns; wrap with `\` only when a pipeline genuinely needs it |
| Formatter | `fish_indent -w <file>`; `fish_indent --check <file>` must exit 0 |

Comments are **all-lowercase**, terse, and explain *why* — never restate the code:

```fish
# re-apply after homebrew prepends its own entries
fish_add_path --prepend --move $prepath
```

Section banners inside a longer file use a single `#` and a blank line before:

```fish
# path
fish_add_path -m "$HOMEBREW_PREFIX/bin"

# settings
set -gx HOMEBREW_NO_ANALYTICS 1
```

Flags: *prefer* short flags for the everyday set (`set -l`, `set -gx`, `abbr -a`, `test -r`) and long
flags where the short form is cryptic (`--description`, `--on-event`, `--prepend --move`, `--exclusive`).
Never mix `-d` and `--description` within one file.

## 2. Naming

| Thing | Convention | Example |
| --- | --- | --- |
| `conf.d/` snippet | one tool per file, lowercase, hyphenated | `conf.d/zoxide.fish` |
| Ordering prefix | `_` for foundational snippets others depend on | `conf.d/_init.fish` |
| Autoloaded function | file basename **must equal** the function name | `functions/reload.fish` → `function reload` |
| Private helper | `__` + namespace + name | `__laramie_hex` |
| Local variable | lowercase, `_` separated | `set -l brew_prefix` |
| Global/exported | `SCREAMING_SNAKE` for env vars, lowercase for fish-internal globals | `GIT_CONFIG_GLOBAL`, `fish_user_paths` |
| Private global | `__` prefix so it never collides with a tool's namespace | `__git_config_dir` |

⚠ **Sort order in `conf.d/` is `digits` → `_` → `letters`** (verified empirically on fish 4.8.1).
So `_init.fish` beats `abbrs.fish`, and a numeric prefix (`00-`) beats `_`. Reserve digits for
something that must load before the `_` files — currently nothing does, so **do not introduce numeric
prefixes**; extend the `_` set instead. `config.fish` always sources **last**, after all of `conf.d/`.

## 3. Variables and scope

```fish
set -l tmp          # default: function/block-local
set -g fish_thing   # only when another conf.d file or a function reads it
set -gx PAGER less  # only when a child process must see it
set -U  anything    # FORBIDDEN in config files
```

- **Let the environment win.** Defaults are conditional, never unconditional:
  ```fish
  set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
  ```
  Writing `set -gx XDG_CONFIG_HOME $HOME/.config` unconditionally overrides a value the user
  deliberately exported.
  ⚠ `set -q` returns 0 for a variable set to an *empty list*, so this idiom will not repair
  `set -gx EDITOR ''`. When an empty value must also be replaced, test the value:
  `test -n "$EDITOR"; or set -gx EDITOR code-insiders`. See [variables.md](variables.md).
- **`PATH` is only ever touched with `fish_add_path`.** It deduplicates and respects `$fish_user_paths`.
  `set -gx PATH ...` is forbidden. Use `-m`/`--move` when the entry must jump to the front:
  ```fish
  fish_add_path -m "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
  ```
- **Quoting.** fish does not word-split, so quotes are about *empty* and *list* semantics, not safety:
  - `"$var"` — you need exactly one argument, even if empty. Use for `test`, and for paths.
  - `$var` — you want list elements splatted as separate arguments (and nothing at all if empty).
  - ⚠ `test -n $var` is a **silent inversion** when `$var` is unset — not an error. The list expands to
    nothing, `test` sees the single argument `-n`, takes the one-argument form, and reports that
    non-empty *string* as true. So `test -n $unset` returns **0**. Always `test -n "$var"`.
- `$status` is clobbered by the next command. Capture it immediately: `set -l rc $status`.

## 4. Guards — never assume anything exists

```fish
type -q zoxide; and zoxide init fish | source # external command exists
test -r $some_file; and source $some_file # optional file is readable
functions -q fisher; or echo >&2 'fisher is not installed' # function is defined
set -q fisher_path; and mkdir -p $fisher_path # variable is set
contains -- /opt/homebrew/bin $PATH; or fish_add_path /opt/homebrew/bin # list membership
```

Interactive-only work is wrapped once, at the top of the snippet, not per-line:

```fish
status is-interactive; or return
```

⚠ `return` at the top level of a `conf.d/` file stops **that file only** — it is the idiomatic early
exit and is preferred over wrapping the whole body in `if status is-interactive ... end`.

## 5. Control flow

- Branch with `if`/`else if`/`else`. Chain short guards with `; and` / `; or` on one line.
- *Prefer* the word forms `and` / `or` / `not` over `&&` / `||` / `!` — they read as fish, and
  `fish_indent` formats them consistently. Be consistent within a file.
- `switch` + `case` beats a chain of `if` string comparisons; quote the case globs (`case "*.tar.gz"`).
- Errors go to **stderr** and set a **non-zero return**:
  ```fish
  if not type -q gum
      echo >&2 "reload: gum is required"
      return 1
  end
  ```
- Iterate lists directly — `for f in $files` — never `for i in (seq (count $files))`.

## 6. Functions

- One public function per file in `functions/`, named identically to the file. Private `__`-prefixed
  helpers used by exactly that function may share its file.
- **`--description` is mandatory** on every function. It is what `complete`, `alias` listing and
  `functions` show.
- Subdirectories under `functions/` are supported **only because** `_init.fish` extends
  `$fish_function_path` with `functions/*/`. ⚠ Group by **caller, not by topic**: the top level is
  reserved for commands a human types, and everything else goes to `wrappers/` (shadows a real
  binary), `internal/` (only `conf.d`, another function or fish itself calls it) or `grc/`. The
  decision table is in [config-layout.md](config-layout.md) §7. Same idea for `completions/`, which
  currently has no subdirectories.
- Arguments: `argparse` for anything with flags; `-a`/`--argument-names` for a fixed positional
  signature; raw `$argv` only for pure pass-through.
  ```fish
  function bak --description 'copy a file to <file>.bak'
      argparse h/help -- $argv; or return
      set -q _flag_help; and begin
          echo "usage: bak FILE..."
          return 0
      end
      for f in $argv
          cp -- $f $f.bak; or return 1
      end
  end
  ```
- Shadowing a command requires `command` inside the body, or you get infinite recursion:
  ```fish
  function ping --description 'ping with a sane default count'
      command ping -c 5 $argv
  end
  ```
- ⚠ **`--on-event`, `--on-variable`, `--on-signal`, `--on-job-exit` handlers only register when the
  file is sourced.** Autoloading does not fire them, so they belong in `conf.d/`. (Official wording:
  *"event handlers only become active when a function is loaded, which means you need to otherwise
  source or execute a function instead of relying on autoloading."*)

## 7. Aliases and abbreviations

- **`alias` is banned in config.** It is a thin `function` wrapper that stores its definition in the
  description; the docs themselves recommend `function` or `abbr` instead. Write the real thing.
- `abbr -a` for anything you want **expanded in the buffer** so history records the real command —
  this is why `abbr -a cd z` is correct and `alias cd=z` is not.
- A wrapper that must work in scripts and pipelines is a **function**, not an abbr. Abbrs only
  expand interactively.

## 8. Performance

Startup cost is the one thing worth optimizing; everything else is noise.

- Never fork a process at startup when a builtin will do (`string`, `path`, `test`, `math`).
- `tool init fish | source` forks. Cache it to a file and source the cache instead.
- Prefer autoloading (`functions/`) over defining functions in `conf.d/` — an autoloaded function
  costs nothing until first call. `conf.d/` is for *wiring*: variables, `abbr`, `bind`, event handlers.
- Measure, don't guess:
  ```fish
  fish --profile-startup=/tmp/fishprof.txt -c exit
  awk 'NR==1 || $3==">"{print}' /tmp/fishprof.txt
  ```

## 9. Secrets

Never write a literal credential into a `.fish` file. Use a `op://` reference resolved at use time:

```fish
# wrong — plaintext token on disk
set -gx GITHUB_TOKEN github_pat_11A43...

# right — resolved by the 1Password CLI when the value is actually needed
set -gx GITHUB_TOKEN (op read "op://Private/GitHub/token")   # still eager; prefer `op run --`
```

*Prefer* not exporting the secret at all: run the consuming command under
`op run -- <cmd>` with an `.env` of `op://` references, so nothing lands in the shell environment.

---

# Complete annotated file templates

Copy these. The **order of sections** is part of the style, not a suggestion.

## `conf.d/<tool>.fish` — a tool snippet

```fish
# conf.d/zoxide.fish
# what this snippet owns, in one line if it isn't obvious from the filename

# 1. bail out early — cheapest possible no-op when the tool is absent
type -q zoxide; or return

# 2. interactive-only? bail again. (omit if the snippet is also useful non-interactively)
status is-interactive; or return

# 3. configuration variables the tool reads, before it initializes
set -gx _ZO_DATA_DIR $XDG_DATA_HOME/zoxide
set -gx _ZO_ECHO 1

# 4. initialize. `zoxide init fish` forks a process on every startup; cache it once
#    and source the cache instead (see fishconf-patterns.md → cachecmd).
zoxide init fish | source

# 5. wiring that depends on the tool being loaded
abbr -a cd z
abbr -a cdi zi
```

## `functions/<name>.fish` — an autoloaded function

```fish
# functions/bak.fish  — filename MUST match the function name
function bak --description 'copy each argument to <name>.bak'
    # 1. parse and validate; fail loudly on stderr, never silently
    argparse f/force -- $argv; or return
    if test (count $argv) -eq 0
        echo >&2 'bak: expected at least one file'
        return 1
    end

    # 2. locals up front
    set -l failed 0

    # 3. body — builtins over forks, iterate the list directly
    for src in $argv
        set -l dst $src.bak
        if test -e $dst; and not set -q _flag_force
            echo >&2 "bak: $dst exists (use --force)"
            set failed 1
            continue
        end
        cp -R -- $src $dst; or set failed 1
    end

    # 4. explicit return status
    return $failed
end
```

## `functions/<domain>/<name>.fish` — a namespaced helper

```fish
# functions/git/git_is_repo.fish — reachable only because _init.fish adds functions/*/
function git_is_repo --description 'true if cwd is inside a non-bare git repo'
    # `command git` — this file lives next to functions that shadow `git`
    set -l info (command git rev-parse --git-dir --is-bare-repository 2>/dev/null); or return 1
    test $info[2] = false
end
```

## `completions/<cmd>.fish` — a completion

```fish
# completions/bak.fish
# private generator, __-prefixed so it cannot collide
function __bak_existing_baks
    path filter -f -- *.bak
end

# --exclusive: no file completion beyond what we offer
complete -c bak -f
complete -c bak -s f -l force -d 'overwrite an existing .bak'
complete -c bak -s h -l help -d 'show usage'
complete -c bak -a '(__fish_complete_path)' -d 'file to back up'
```

## A standalone script (`#!/usr/bin/env fish`)

Full canonical order — shebang, doc comment, strictness, constants, helpers, `main`, dispatch:

```fish
#!/usr/bin/env fish
#
# rebuild-themes — regenerate the laramie theme for every tool that needs it.
# usage: rebuild-themes [--dry-run] [TOOL...]

# strictness: fish has no `set -e`; the closest equivalent is checking every
# status and returning early. make that explicit rather than implied.
status is-interactive; and echo >&2 'warning: sourcing a script meant to be executed'

# constants — readonly by convention (fish has no readonly), SCREAMING_SNAKE, -g
set -g LARAMIE_BG 1f2335
set -g LARAMIE_FG a9b1d6
set -g THEME_TOOLS ghostty git micro bat

# helpers first, `main` last — fish executes top-to-bottom, so every function
# must be defined before the line that calls it.
function __die --description 'print to stderr and exit non-zero'
    echo >&2 "rebuild-themes: $argv"
    exit 1
end

function __render_one --argument-names tool outdir
    test -d $outdir; or __die "no such directory: $outdir"
    echo "rendering $tool -> $outdir"
end

function main
    argparse n/dry-run h/help -- $argv; or return
    if set -q _flag_help
        echo 'usage: rebuild-themes [--dry-run] [TOOL...]'
        return 0
    end

    # default the positional list rather than branching on count
    set -l tools $argv
    test (count $tools) -gt 0; or set tools $THEME_TOOLS

    for tool in $tools
        contains -- $tool $THEME_TOOLS; or __die "unknown tool: $tool"
        set -q _flag_dry_run; and begin
            echo "would render $tool"
            continue
        end
        __render_one $tool "$XDG_CONFIG_HOME/$tool"; or return 1
    end
end

# dispatch last, forwarding argv. no `if __name__ == '__main__'` equivalent exists.
main $argv
```

## Review checklist

Before calling a fish change done:

```sh
fish_indent --check <file>                  # formatting is canonical
fish -n <file>                              # parses
fish --no-config -c 'source <file>'         # sources clean in isolation — judge STDOUT, not exit code
script -q /dev/null fish --login --interactive -c exit   # a real startup, on a tty
```

⚠ **That third check is a no-stray-output test, not an exit-status test.** A snippet ending in the
house idiom `set -q VAR; or set -gx VAR val` exits **1** whenever `VAR` was unset, because a successful
`set` preserves the previous `$status` rather than clearing it ([caveats.md](caveats.md)). Silence is
the pass condition; `conf.d` discards the status anyway.

⚠ `--no-config` has two blind spots: it leaves `$fish_function_path` **unset**, so it cannot exercise
autoloading (a function your file calls will appear missing), and it **demotes `set -U` to global**, so
it hides universal-variable behaviour entirely. Use it to prove a file is self-contained and quiet; use
a real `exec fish` to prove it works. See [config-layout.md](config-layout.md), [variables.md](variables.md).

⚠ **All three of the first checks redirect stdin, so none of them runs on a tty** — which is why the
fourth line is not optional for a `conf.d` file. A bare `source $var` whose variable is empty reads
stdin, hits EOF and exits 0 under every redirected check, and errors only in a real window. That exact
bug lived in `conf.d/theme.fish` while passing this checklist ([caveats.md](caveats.md)).

- [ ] `fish_indent --check` exits 0
- [ ] `fish -n` clean
- [ ] every new function has a `--description`
- [ ] every external command is `type -q`-guarded; every optional file is `test -r`-guarded
- [ ] no `set -U`; no bare `set -gx PATH`; no `alias`
- [ ] `--on-event` handlers are in `conf.d/`, not `functions/`
- [ ] autoloaded function name == filename
- [ ] no plaintext secret
- [ ] `exec fish` in a real terminal produced no new output or error
