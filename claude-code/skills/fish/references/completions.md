# Fish — writing completions

How to give a custom command tab completion in fish 4.8.1: where the file goes, every `complete`
flag, the `__fish_*` condition helpers that actually exist on this machine, and how to test the
result without an interactive shell. Abbreviations, bindings and `commandline` as a line editor are
in [interactive.md](interactive.md); house rules in [style-guide.md](style-guide.md).

Everything below was verified with `complete -C` under `/opt/homebrew/bin/fish --no-config`.

## 1. Where completions live and when they load

One file per command, named after the command: `~/.config/fish/completions/<cmd>.fish`. It is
**autoloaded on the first completion attempt** for that command — same mechanism as `functions/`, but
driven by `$fish_complete_path` instead of `$fish_function_path`. Nothing is read at startup, so a
completion file costs zero startup time no matter how large.

`$fish_complete_path`, in search order (first match for a given filename wins):

```
~/.config/fish/completions/*/         <- added by conf.d/_init.fish (see config-layout.md)
~/.config/fish/completions
/opt/homebrew/etc/fish/completions
~/.local/share/fish/vendor_completions.d
/usr/share/fish/vendor_completions.d
<embedded in the fish binary>          <- 1061 shipped completions; `status list-files`
~/.cache/fish/generated_completions    <- scraped from man pages
```

⚠ **Autoloading only happens if the command exists.** Verified: with
`completions/deploy.fish` on the path, `complete -C 'deploy '` offers files until `deploy` resolves to
an executable on `$PATH` or a defined function — then it offers the real candidates. When testing a
completion for a command you have not written yet, `source` the completion file explicitly.

⚠ The `completions/*/` glob is expanded **once**, by `conf.d/_init.fish`, at startup — a subdirectory
created afterwards is invisible until `exec fish`. Group into subdirectories only once a domain has
≳3 files ([style-guide.md](style-guide.md) §6).

## 2. `complete` — full flag reference

| Flag | Effect |
| --- | --- |
| `-c CMD` / `--command` | the command these completions are for. Repeatable to define the same completions for several commands |
| `-p PATH` / `--path` | match by absolute path (globs allowed) instead of name. `--wraps` is ignored for these |
| `-s C` / `--short-option` | a single-character option, `-x`. Groupable (`-la`) |
| `-l NAME` / `--long-option` | a GNU long option, `--colour` |
| `-o NAME` / `--old-option` | one leading dash, more than one character: `-Wall`, `-name`. Use this for any command that does not support option grouping or `-d9`-style attached values |
| `-a STR` / `--arguments` | candidates, as **one string**, tokenized on space/tab at completion time with full expansion. With `-s`/`-l`/`-o` these become the *option's* arguments; alone they are the command's non-option arguments |
| `-d STR` / `--description` | pager description. Options sharing a non-empty description are collapsed into one candidate |
| `-f` / `--no-files` | this completion may not be followed by a filename |
| `-F` / `--force-files` | re-enable filenames even though another `complete` said `--no-files` |
| `-r` / `--require-parameter` | the option's argument is the *next* token, not just an attached `-xFoo` / `--foo=bar` |
| `-x` / `--exclusive` | `-r` and `-f` together. The usual choice for an option with a fixed value set |
| `-n CMD` / `--condition` | only offer this if CMD exits 0. Multiple `-n` are tried in order until one fails |
| `-w CMD` / `--wraps` | inherit CMD's completions. Transitive |
| `-k` / `--keep-order` | present `-a` candidates in the given order instead of sorted. Later `-k` calls display first |
| `-e` / `--erase` | delete. `complete -c CMD -e` erases *everything* for CMD, including a global `-f` |
| `-C STR` / `--do-complete` | print the candidates for STR. The test harness — see §7 |

⚠ `-f` is scoped by whatever `-n` sits on the same line. `complete -c mycmd -f` with no condition is
the global "this command never takes a filename" switch; `complete -c mycmd -f -n cond -a x` only
suppresses files while `cond` holds. Verified: a subcommand list guarded by `__fish_use_subcommand`
and marked `-f` still offers files once a subcommand has been typed.

⚠ `complete -c mycmd -e` is not selective — it removes the global `-f` too, so files come back.
Erase one rule by repeating the flags that defined it.

## 3. Dynamic arguments

`-a` takes a string, and fish re-tokenizes and re-expands it on **every** Tab. So the command
substitution must survive as literal text in the stored string. Three spellings, three different
results — all verified with `complete -c <cmd>` to show exactly what got stored:

```fish
# wrong — bare parens run once, at load time; stored as `-a aaa`, never updates
complete -c workon -f -a (command ls $WORKON_HOME)

# half wrong — parens are deferred (fish does not substitute inside double quotes),
# but $WORKON_HOME is expanded now, so the directory is frozen at load time
complete -c workon -f -a "(command ls $WORKON_HOME)"

# right — the whole thing is deferred; stored as `-a '(command ls $WORKON_HOME)'`
complete -c workon -f -a '(command ls $WORKON_HOME)'
```

⚠ Note the second case: unlike bash, fish performs **no** command substitution inside double quotes,
so `"(cmd)"` is literal text. Single-quote anyway — it is the only form that also defers `$variables`.

Each output line is one candidate; anything after a **tab** on that line is its description, and
overrides `-d`. `printf` with a cycling format is the tidiest generator:

```fish
function __deploy_targets --description 'list configured deploy targets'
    printf '%s\t%s\n' staging pre-production production 'live site'
end
```

⚠ Single-quoted fish strings do **not** interpret `\t` — `printf '%s\n' 'staging\tpre-prod'` yields a
candidate literally named `staging\tpre-prod` (verified). Put the tab in the *format*.

⚠ **Never run a slow or networked command in a generator without caching.** fishconf's
`completions/gi.fish` is the cautionary example:

```fish
function __gitignoreio_topics
    curl -sfL https://www.toptal.com/developers/gitignore/api/list | tr "," "\n"
end
complete --exclusive --command gi --arguments "(__gitignoreio_topics)"
```

Measured on this machine: **0.14 s per Tab**, every Tab, and an empty candidate list with no error
when offline. The cached form is 0.01 s (verified, both numbers):

```fish
# completions/gi.fish

# cache the topic list for a day; a completion must never block on the network
function __gi_topics --description 'gitignore.io topic list, cached'
    set -l cache $XDG_CACHE_HOME/fish/gi-topics
    if not test -s $cache; or test (path mtime -R -- $cache) -gt 86400
        type -q curl; or return
        mkdir -p (path dirname $cache)
        curl -sfL https://www.toptal.com/developers/gitignore/api/list \
            | string split , >$cache
    end
    cat $cache
end

complete -c gi -x -a '(__gi_topics)'
```

`path mtime -R` gives age in seconds — verified. Guard the fetch with `type -q` so a missing tool
produces no candidates rather than an error in the pager.

## 4. Conditions and the `__fish_*` helper library

Every helper below was verified present in fish 4.8.1 with
`fish --no-config -c 'functions -q NAME'`.

| Helper | Use |
| --- | --- |
| `__fish_use_subcommand` | true while no subcommand has been given — the standard guard for a subcommand list |
| `__fish_seen_subcommand_from a b c` | true if any of a/b/c already appears on the line |
| `__fish_is_first_token` / `__fish_is_first_arg` | true while completing the first non-switch argument |
| `__fish_is_nth_token N` | true while completing token N (1-based, command included) |
| `__fish_seen_argument -s v -l verbose` | true if that option was already given |
| `__fish_contains_opt [-s C] LONG…` | older equivalent; matches short and long forms |
| `__fish_prev_arg_in --mode --target` | true when the token immediately before the cursor is one of these |
| `__fish_complete_directories [STR DESC]` | directory-only path completion, each described |
| `__fish_complete_path [STR DESC]` | plain path completion with a description |
| `__fish_complete_suffix .md` | file completion sorting `.md` first; pair with `-k` |
| `__fish_complete_users` / `__fish_complete_groups` | users with full names / groups with members |
| `__fish_complete_pids` | PIDs described by command name |
| `__fish_print_hostnames` | hosts from ssh known_hosts, `/etc/hosts`, fstab NFS entries |
| `__fish_complete_command` | complete a command name plus its own arguments (for `sudo`-alikes) |

⚠ **`__fish_no_arguments` exists but is unusable.** Verified: inside a completion, `commandline -tc`
yields a single empty element, so its loop always hits `case '*'` and it returns 1 — the completion is
never offered. Use `__fish_use_subcommand` or `__fish_is_first_arg` instead.

⚠ `-n` with `-a` and `-r` do not combine the way you expect. An `-a` list with only a condition
supplies *non-option* arguments and is skipped while fish is completing the argument to a `-r`
option. Attach the values to the option instead:

```fish
# wrong — never offered after `--mode `, files appear instead
complete -c pa -l mode -r
complete -c pa -f -n '__fish_prev_arg_in --mode' -a 'fast slow'

# right
complete -c pa -l mode -x -a 'fast slow'
```

## 5. The subcommand pattern

Complete, verified file. `complete -C` output for each stage follows.

```fish
# completions/deploy.fish

# no bare filenames anywhere; re-enable per option with -F
complete -c deploy -f

# private generator, __-prefixed so it cannot collide
function __deploy_targets --description 'list configured deploy targets'
    printf '%s\t%s\n' staging pre-production production 'live site'
end

# subcommands, only in command position
complete -c deploy -n __fish_use_subcommand -a build -d 'compile the artifact'
complete -c deploy -n __fish_use_subcommand -a push -d 'upload the artifact'
complete -c deploy -n __fish_use_subcommand -a status -d 'show the current release'
complete -c deploy -n __fish_use_subcommand -a rollback -d 'revert to the previous release'

# global options
complete -c deploy -s h -l help -d 'show usage'
complete -c deploy -s v -l verbose -d 'log every step'

# per-subcommand options
complete -c deploy -n '__fish_seen_subcommand_from push' -l target -x -a '(__deploy_targets)' \
    -d 'where to push'
complete -c deploy -n '__fish_seen_subcommand_from push' -l dry-run -d 'print, do not upload'
complete -c deploy -n '__fish_seen_subcommand_from build' -l config -r -F -d 'config file'
complete -c deploy -n '__fish_seen_subcommand_from rollback' -a '(__deploy_targets)' -d target
```

```
> complete -C 'deploy '
build      compile the artifact
push       upload the artifact
rollback   revert to the previous release
status     show the current release

> complete -C 'deploy push --'
--dry-run  print, do not upload
--help     show usage
--target   where to push
--verbose  log every step

> complete -C 'deploy push --target '
production  live site
staging     pre-production

> complete -C 'deploy build --config '   # -r -F re-enables files for this option only
Brewfile
CLAUDE.md
```

For a tool that can list its own completions, skip all of this — one line is enough:

```fish
complete -f -c dotnet -a '(dotnet complete (commandline -cp))'
```

## 6. `--wraps` and wrapper functions

Two equivalent spellings for "this completes like that":

```fish
# in the completion file
complete -c mygit -w git

# on the function itself — preferred when you are already writing the wrapper
function code-insiders --wraps code --description 'open VS Code Insiders'
    command code-insiders $argv
end
```

Wrapping is transitive (A wraps B wraps C ⇒ A gets C's completions) and the wrapper may add its own
rules on top. Remove it with `complete -c mygit -w git -e`. Verified: `complete -C 'mygit check'`
returns git's `checkout`; a function declared `--wraps ls` immediately offers every `ls` flag.
⚠ `--wraps` is ignored for `complete -p` (path-based) completions.

## 7. Testing a completion

`complete -C 'STR '` prints the candidates for STR and exits — no terminal, no pager, no keypress.
This is the only completion test worth writing.

```sh
# a completion already on the path, for a command that exists
fish -c "complete -C 'deploy push --'"

# a file for a command that does not exist yet, or is not yet installed
fish --no-config -c "source completions/deploy.fish; complete -C 'deploy '"
```

`complete -c deploy` with no other flags lists the rules currently registered for `deploy` — the way
to confirm a file loaded, and to see exactly what string a dynamic `-a` stored.

⚠ `complete -C` matches the trailing token against the candidates, so **the trailing space matters**:
`complete -C 'deploy push --target '` completes a new argument, `complete -C 'deploy push --target st'`
filters to `staging`. Always test both.

Inside a generator, `commandline` reads the `complete -C` string rather than a real buffer — which is
what makes generators testable at all. The canonical pair:

```fish
set -l tokens (commandline --cut-at-cursor --tokens-expanded) # -cx: tokens completed so far
set -l current (commandline --current-token --cut-at-cursor) # -ct: the token being typed
```

Prefer printing every possibility and letting fish's own matching filter them; re-implementing prefix
matching inside a generator defeats fish's infix and fuzzy matching.

## 8. Checklist for adding a completion here

```sh
fish_indent --check ~/.config/fish/completions/<cmd>.fish
fish -n ~/.config/fish/completions/<cmd>.fish
fish --no-config -c "source ~/.config/fish/completions/<cmd>.fish; complete -C '<cmd> '"
```

- [ ] file is `completions/<cmd>.fish`, basename exactly the command name
- [ ] generators are `__<cmd>_`-prefixed and carry a `--description`
- [ ] `complete -c <cmd> -f` first if the command takes no bare filenames; `-F -r` on the options
      that do
- [ ] dynamic `-a` bodies are **single**-quoted
- [ ] every candidate line is `value` or `value<TAB>description`; the tab is in the `printf` format
- [ ] nothing slow, networked, or unguarded runs per Tab — cache it, and `type -q` the tool
- [ ] `-x` rather than bare `-a` for options with a fixed value set
- [ ] conditions use a verified `__fish_*` helper, never `__fish_no_arguments`
- [ ] `complete -C` checked with **and** without a trailing space
- [ ] `fish_indent --check` exits 0
