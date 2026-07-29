# Fish — patterns from `mattmc3/fishconf`

A study of one reference-quality fish config, reduced to patterns worth importing here. **fishconf**
snippets are quoted unmodified; **adapted** snippets were rewritten to obey
[style-guide.md](style-guide.md) and verified with `fish -n` + `fish_indent --check` on fish 4.8.1.
Load order lives in [config-layout.md](config-layout.md), colours in
[prompt-and-colours.md](prompt-and-colours.md); this file does not repeat either.

---

## ✅ Adoption status — closed 2026-07-29

The ranked plan in §5 was executed. Startup self time **63.1 ms → 16.4 ms**, then **→ 10.05 ms** in a
benchmark pass later the same day. ⚠ The 6.2 ms written off here as atuin's irreducible per-session
`atuin uuid` turned out to be removable — see [caveats.md](caveats.md) and
[config-layout.md](config-layout.md) §7. `fish_variables` holds zero universals.
[config-layout.md](config-layout.md) §7 is the current-state inventory; this file is now the
*rationale* record — what was taken, what was changed on the way in, and what was refused.

**Adopted, adapted:** `cachecmd` (§3.1) with real invalidation, atomic writes, a stale-cache
fallback and `--depends`/`--clear`; `conf.d/tools.fish` as a one-line-per-tool table with the
uncached form in a comment (§3.2); `path filter` for existence tests and `path filter -vd` for
"only mkdir what is missing" (§3.3, §3.4); the `functions/<domain>/` subdirectory pattern, now
carrying 14 `grc` wrappers (§3.5); `.editorconfig` (§3.9); the profiling recipe, as
`functions/fishprof.fish` (§3.8); `funcfresh`; the `xdg-apps.fish` crib sheet, filtered to tools
actually installed here; `LESS_TERMCAP_*` via `set_color` and 8-colour theme-adaptive
`LS_COLORS`/`EZA_COLORS` from `init_env`; the "emit a code-generating function into `cachecmd`"
trick from `set_java_home` (§3.10) — kept in the docs, not needed in the end (see below).

**Refused, with reasons:**

| Pattern | Why not |
| --- | --- |
| `set -Ux` for preferences (`init_env`, `prompt.fish`, `FISH_THEME`) | House law bans universals in config files outright ([style-guide.md](style-guide.md) §3). Every adopted snippet was rewritten as `test -n "$X"; or set -gx X …`. This is the one place the two configs genuinely disagree, and it is not negotiable here |
| `fisher` / any plugin manager | Everything a plugin would provide is already brew-installed and needs a `conf.d` snippet, not a plugin. fishconf reached the same conclusion and deleted fisher in a refactor. [fisher.md](fisher.md) documents what adopting one would cost |
| `conf.d/events.fish` — the `preexecute` dispatcher (§3.7) | Pays off past ~3 transforms; there are zero. It also means owning Enter, so a bug in any handler makes the shell unable to run the command that would fix it |
| `conf.d/bashisms.fish`, `functions/bashisms/{do,then}` | Conceal real syntax errors (§3.10, §4) |
| `functions/macos/*` | macOS-version-coupled AppleScript and `defaults write`, unverified on 27.x; `trash` reimplements a binary this machine already ships at `/usr/bin/trash` |
| `zzz-post.fish` as a separate file | `config.fish` already sources last. The `fish_postinit` emitter is *documented* there rather than added, because nothing consumes it — `brew.fish` is the only `$PATH` writer and is ordered correctly |
| `$prepath` re-prepending | Same reason: no second `$PATH` writer to correct for. `~/bin` and `~/.local/bin` do not exist on this machine |
| `MANPATH` construction | macOS derives it from `$PATH` via `MANPATH_MAP`; setting it explicitly would *break* `man` for Homebrew and keg-only formulae. Verified `man -w eza` resolves with no `MANPATH` set |
| `functions/aliases/*` | The technique (a `command`-prefixed wrapper) is right, but the descriptions are cargo-culted `alias` output. Where a wrapper was wanted here it was written fresh |

**Two things fishconf gets wrong that were found only by executing them:** its `cachecmd` caches a
*failure* as a 0-byte file and then accepts it forever, and `starship init fish` returns a one-line
bootstrap — so caching it saves nothing. Both are in [caveats.md](caveats.md).

## 1. Orientation

`~/.config/fish` **is** the git repo — cloned over the config dir, with `fish_variables`, `.cache/`
and `fishprof*.txt` gitignored. 117 tracked files:

| Directory | Files | Contents |
| --- | --- | --- |
| `conf.d/` | 12 | `00-init`, `abbrs`, `bashisms`, `developer`, `direnv`, `events`, `iwd`, `keybindings`, `prompt`, `tools`, `xdg-apps`, `zzz-post` |
| `functions/` | 83 | 46 top-level + 37 in 5 domain subdirs: `git/` 11, `macos/` 12, `python/` 6, `aliases/` 6, `bashisms/` 2 |
| `completions/` | 9 | mostly for its own functions (`dict`, `funcfresh`, `gi`, `otp`, `workon`) |
| `themes/` | 8 | 7 `.theme` files (4× tokyonight, 2× gruvbox, lighthaus) + `starship.toml` |
| `config.fish` | 1 | **5 lines, all comments** |

Three decisions carry the design: **`config.fish` holds nothing** — all work is in `conf.d/`, bracketed
by a first and last file, so startup is a pipeline with explicit ends rather than a script with an
epilogue; **`conf.d/` wires, `functions/` implements** — startup logic is factored into autoloaded
`init_*` functions that `00-init.fish` calls by name, costing nothing until called; and **anything that
forks is cached to disk** (§3.1), which buys the ~10 ms startup the README advertises.

## 2. Load-order strategy

**fishconf** — `conf.d/00-init.fish`, in full:

```fish
# init: runs before every other conf.d file (the 00- prefix wins the sort),
# so snippets can rely on XDG, PATH, MANPATH and homebrew being ready.
# `finit <name>` runs functions/init/_finit_<name>.

# Autoload from functions/ subdirs first, so finit and the _finit_* steps
# (in functions/init/) and everything else resolve.
set fish_function_path (path resolve $__fish_config_dir/functions/*/) $fish_function_path

# Homebrew, etc. push their own paths; re-apply prepend to prepath afterwards.
set -g prepath (path filter $HOME/bin $HOME/.local/bin)
function prepend_prepath --on-event fish_postinit
    fish_add_path --prepend --move $prepath
end
prepend_prepath

# Initialize manpath
set -q MANPATH; or set -gx MANPATH ''
for mp in (path filter $__fish_data_dir/man /usr/local/share/man /usr/share/man)
    set -ax MANPATH $mp
end

init_xdg
init_homebrew
init_env

set -gx DOTFILES $HOME/.dotfiles
set -gx MY_PROJECTS $HOME/Projects
```

⚠ The `finit` / `functions/init/` comment is **stale** — no such function or directory exists.

**fishconf** — `conf.d/zzz-post.fish`, in full:

```fish
#
# zzz-post: Stuff to run at the very end
#

# Add local config
set -q DOTFILES; or set -gx DOTFILES $HOME/.dotfiles
if test -r $DOTFILES/.local/config/fish/config.fish
    source $DOTFILES/.local/config/fish/config.fish
end

# Clean cache in background
clean_cache > /dev/null 2>&1 &

emit fish_postinit
```

`fish_postinit` is **not a fish event** — the built-ins are `fish_prompt`, `fish_preexec`,
`fish_postexec`, `fish_exit`, `fish_cancel`, `fish_read`. It is a private name this config invents so
any snippet can register deferred work with `--on-event fish_postinit`. `00-init.fish` is the sole
consumer: it stashes `$prepath`, then re-prepends it once Homebrew and `developer.fish` have finished
reordering `PATH`.

### Recommendation: keep `_`, add a `zzz-` tail

Verified sort order is `digits` → `_` → `letters` ([config-layout.md](config-layout.md)), so both
schemes work and `00-` would sort before `_init.fish`. **Keep `_`** — numeric prefixes buy a third
ordering tier that nothing needs; renaming two files for it is churn. **Do adopt the tail**, because
`brew.fish` prepends to `PATH` after `_init.fish` and there is nowhere to correct for it. ⚠ But
`zzz-post.fish` is **partly redundant with `config.fish`**, which fish sources after all of `conf.d/`;
fishconf reserves `config.fish` for documentation by choice, whereas Ethan's is an empty
`if status is-interactive` block — put the `emit` there instead of adding a file.

## 3. The patterns worth stealing

### 3.1 `cachecmd` — the highest-value pattern in the repo

**fishconf** — `functions/cachecmd.fish`:

```fish
function cachecmd --description "Cache command output, skip running if fresh"
    set -l source_it false
    if string match -q -- '--source' $argv[1]
        set source_it true
        set argv $argv[2..]
    end

    set -l cachedir $__fish_config_dir/.cache
    set -l cmdfile (string join '_' -- $argv | string replace -ar '[/-]' '_' | string replace -ar '_+' '_' | string replace -r '^_' '').fish
    set -l cachefile $cachedir/$cmdfile

    test -d $cachedir; or mkdir -p $cachedir
    test -f $cachefile; or $argv > $cachefile

    if $source_it
        builtin source $cachefile
    else
        cat $cachefile
    end
end
```

`zoxide init fish | source` forks and waits on *every* shell start; five such tools is five forks, and
caching the generated code makes each one a `builtin source`. Three weaknesses, which compound:

1. **Invalidation is time-based only, and indirect.** Nothing here checks whether the tool changed —
   freshness comes entirely from `zzz-post.fish` backgrounding `clean_cache`, i.e.
   `find … -mmin +1200 -delete` (20 h). A `brew upgrade zoxide` at hour 2 leaves the old init sourced
   for 18 more hours, and since `clean_cache` runs at the *end* of startup the fix lands two shells later.
2. **A failed command is cached as an empty file.** In `test -f $cachefile; or $argv > $cachefile` the
   redirect creates the file before `$argv` runs, so a tool error yields a 0-byte cache `test -f` accepts forever.
3. **`.cache/` sits inside `$__fish_config_dir`** — generated state in the config dir. Ethan's
   `_init.fish` already creates `$XDG_CACHE_HOME/fish`; use that.

**The fix** — key off the tool binary's mtime with `test … -nt`, write atomically, refuse to cache a
failure. Verified: cache hit on the second call, regenerated after the binary is replaced.

```fish
# adapted — functions/cachecmd.fish
function cachecmd --description 'cache a command\'s output, then source or print the cache'
    argparse --stop-nonopt s/source -- $argv; or return
    if test (count $argv) -eq 0
        echo >&2 'cachecmd: expected a command'
        return 2
    end

    # slugify argv into a filename: `fzf --fish` -> fzf_fish.fish
    set -l slug (string join _ -- $argv | string replace -ar '[^a-zA-Z0-9]+' _ | string trim -c _ | string lower)
    set -l cachefile $XDG_CACHE_HOME/fish/cachecmd/$slug.fish

    # invalidate when the tool binary is newer than the cache (upgrade-safe)
    set -l tool (command -s $argv[1])
    if not test -s $cachefile; or test -n "$tool" -a "$tool" -nt "$cachefile"
        mkdir -p (path dirname $cachefile)
        set -l tmp $cachefile.(random).part
        if $argv >$tmp 2>/dev/null; and test -s $tmp
            command mv -f $tmp $cachefile
        else
            command rm -f $tmp
            echo >&2 "cachecmd: '$argv' produced nothing; not caching"
            return 1
        end
    end

    if set -q _flag_source
        builtin source $cachefile
    else
        cat $cachefile
    end
end
```

⚠ `argparse --stop-nonopt` is load-bearing: without it, `cachecmd --source fzf --fish` makes argparse
choke on the *tool's* `--fish`. `test -s` (non-empty) replaces `test -f`.

**Adopt** — the single change that unblocks all five uninitialized tools without five forks per shell.

### 3.2 `conf.d/tools.fish` — the one-line-per-tool table

**fishconf** — keeping the uncached form as a comment documents what the cache holds and gives a
one-character bisect when a tool's init changes shape:

```fish
# type -q zoxide; and zoxide init fish | source
type -q zoxide; and cachecmd --source zoxide init fish
```

```fish
# adapted — conf.d/tools.fish
# one line per tool: guard, then source the cached init. see cachecmd.
status is-interactive; or return

type -q fzf; and cachecmd --source fzf --fish
type -q zoxide; and cachecmd --source zoxide init fish
type -q atuin; and cachecmd --source atuin init fish
type -q starship; and cachecmd --source starship init fish

# grc ships a static fish integration, not an init subcommand
test -r $HOMEBREW_PREFIX/etc/grc.fish; and source $HOMEBREW_PREFIX/etc/grc.fish
```

⚠ Verified: `grc` has **no** `init fish`; Homebrew installs `/opt/homebrew/etc/grc.fish`, so a guarded
`source` is correct and `cachecmd` does not apply.

**Adopt** — one file replaces five `conf.d/<tool>.fish` stubs. Split a tool back out only once it needs
configuration variables of its own.

### 3.3 `init_xdg` / `init_homebrew` / `init_env` — startup as autoloaded functions

**fishconf** — `functions/init_xdg.fish`, excerpted:

```fish
    set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
    set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share
    for xdgdir in (path filter -vd $XDG_CONFIG_HOME $XDG_DATA_HOME $XDG_STATE_HOME $XDG_CACHE_HOME $XDG_RUNTIME_DIR)
        mkdir -p $xdgdir
    end
```

Two gaps in Ethan's `_init.fish` are visible right there: the `set -q …; or set -gx` guard (his XDG
assignments are unconditional, overriding a deliberately exported value —
[style-guide.md](style-guide.md) §3), and `path filter -vd` to `mkdir` **only the missing** dirs.

**fishconf** — `functions/init_homebrew.fish`, the load-bearing part:

```fish
    set --local brewcmd (path filter /opt/homebrew/bin/brew /usr/local/bin/brew)
    test -n "$brewcmd[1]"; or return 1

    # Cache brew shellenv
    set --local brew_shellenv $__fish_config_dir/.cache/brew_shellenv.fish
    if not test -f $brew_shellenv
        $brewcmd[1] shellenv fish > $brew_shellenv
        echo "set -gx HOMEBREW_OWNER" (stat -f "%Su" $HOMEBREW_PREFIX 2>/dev/null) >> $brew_shellenv
    end
    source $brew_shellenv
```

After `source`: a `brew` wrapper running `sudo -Hu $HOMEBREW_OWNER brew` when
`$USER != $HOMEBREW_OWNER`; `fish_add_path` + `MANPATH` per `$HOMEBREW_KEG_ONLY_APPS`
(`curl ruby sqlite postgresql@18`); `fish_add_path` for `lib/ruby/gems/*/bin` and `~/.gem/ruby/*/bin`;
and a `contains`-guarded append of `share/fish/completions` to `$fish_complete_path`. Versus Ethan's
`conf.d/brew.fish`:

- **Missing `brew shellenv`** — `brew.fish` hardcodes `HOMEBREW_PREFIX` and hand-rolls the path append,
  so `HOMEBREW_CELLAR`, `HOMEBREW_REPOSITORY`, `INFOPATH` and Homebrew's `MANPATH` never get set.
- **Missing the `contains` guard** on the `fish_complete_path` append — re-sourcing duplicates it.
- ⚠ **Real bug: ordering.** Line 4 uses `"$HOMEBREW_PREFIX/bin"`; line 18 is where `HOMEBREW_PREFIX`
  is set. Verified with `env -u HOMEBREW_PREFIX`, that `fish_add_path -m` call adds literal `/bin` and
  `/sbin` — and it already happened: `fish_variables` line 3 reads
  `SETUVAR fish_user_paths:/opt/homebrew/bin\x1e/opt/homebrew/sbin\x1e/bin\x1e/sbin`.
- **Unnecessary here:** the `HOMEBREW_OWNER`/`sudo` wrapper (single-user Mac, Ethan owns
  `/opt/homebrew`); the keg-only list (nothing in the Brewfile is keg-only *and* wanted on `PATH`); the
  ruby gems globs (`gem` is not in use).

**Adapt** — take cached `brew shellenv`, the `path filter` discovery and the `contains` guard; fix the
ordering bug; drop the sudo/keg-only/gems machinery. `init_env` is **skip** (§4).

### 3.4 `path filter` for existence tests

```fish
set --local brewcmd (path filter /opt/homebrew/bin/brew /usr/local/bin/brew)

set -g prepath (path filter $HOME/bin $HOME/.local/bin)
fish_add_path --prepend --move $prepath
```

`path filter` is a builtin, and per the 4.8.1 docs *"In all cases, the paths need to exist, nonexistent
paths are always filtered."* One call replaces an `if test -x A; …; else if test -x B` ladder **and**
collapses to an empty list when nothing exists — `fish_add_path` with an empty list is a no-op, so no
downstream guard is needed; `-vd` inverts it into "which of these dirs are missing". The `prepath` half
is subtler: capture priority paths in a global, then re-apply `fish_add_path --prepend --move` from a
`fish_postinit` handler after every other snippet has reordered `PATH` — `--move` makes it idempotent
by relocating an existing entry instead of duplicating it. **Adopt**: `path filter` improves any
`test -e/-d/-x` ladder, and `prepath` matters here because `brew.fish` prepends after `_init.fish`.

### 3.5 `functions/<domain>/` subdirectory namespacing

fish autoloads from `$fish_function_path` **non-recursively**, so subdirectories are invisible until
each is added explicitly. One line globs them all in — 37 of fishconf's 83 functions live there:

```fish
set fish_function_path (path resolve $__fish_config_dir/functions/*/) $fish_function_path
```

⚠ **Ethan's `_init.fish` already does exactly this**, for functions *and* completions:

```fish
set fish_function_path (path resolve "$fish_config_dir/functions"/*/) $fish_function_path # to allow subfolders in functions dir
set fish_complete_path (path resolve "$fish_config_dir/completions"/*/) $fish_complete_path # to allow subfolders in completions dir
```

**Already done — validation, not a change.** The only gap: `functions/` holds exactly one function
(`reload`), so no domain has earned a subdirectory yet ([style-guide.md](style-guide.md) §6 sets the
threshold at ≳3).

### 3.6 The `git_is_*` predicate family

```fish
function git_is_worktree -d "Check if directory is inside the worktree of a repository"
    git_is_repo
    and test (command git rev-parse --is-inside-git-dir) = false
end

function git_is_dirty -d "Check if there are changes to tracked files"
    git_is_worktree; and not command git diff --no-ext-diff --quiet --exit-code
end
```

The convention: **return status, print nothing** — the function *is* the condition
(`git_is_dirty; and …`), and anything that prints forces callers into `test -n (…)`; **compose upward**
(`git_is_dirty` → `git_is_worktree` → `git_is_repo`, one check per layer); **`command git`, always**,
since these files sit beside functions that shadow git commands; and **`--quiet --exit-code` /
`2>/dev/null`**, because a predicate is silent on both branches. The family is `git_is_repo`,
`git_is_worktree`, `git_is_dirty`, `git_is_staged`, `git_is_stashed`, `git_is_touched`, plus
value-returning `git_ahead`, `git_branch_name`, `git_untracked`. `git_is_touched` documents its own
ordering — *"We put them in this order because checking staged changes is *fast*"* — the right instinct
for anything a prompt calls. **Adopt when a prompt needs them** — starship owns the prompt today, so
there is no consumer yet, but the convention applies immediately.

### 3.7 `conf.d/events.fish` — a custom `preexecute` event bound to Enter

The most advanced thing in the repo. The dispatcher:

```fish
# This allow us to handle multiple transform via a preexecute event
function _preprocess_commandline --description 'Fire preexecute events before a command executes'
    set -g __preexecute_cancel 0
    emit preexecute (commandline)
    if test "$__preexecute_cancel" = 1
        commandline -f repaint
        return
    end
    commandline -f execute
end

# Bind enter to prerun
if test "$fish_key_bindings" = fish_vi_key_bindings
    bind -M insert  \r _preprocess_commandline
    bind -M default \r _preprocess_commandline
else
    bind \r _preprocess_commandline
end
```

Consumers register as ordinary event handlers and mutate the buffer with `commandline -r`:

```fish
function strip_dollar_prefix --on-event preexecute
    set -l cmd (commandline)
    if string match -qr '(^|\n)\$ ' -- $cmd
        commandline -r -- (string replace -ar '(^|\n)\$ ' '$1' -- $cmd)
    end
end
```

…plus `magic-enter`, which runs `git status -sb` (or `ls`) on an empty line, guarded by
`functions -q magic-enter-cmd` so a user override wins.

**Why an event, not more bindings?** Verified: a key sequence holds exactly **one** command list —
after `bind \r 'echo one'; bind \r 'echo two'`, `bind \r` reports only `bind enter 'echo two'`. A
second transform would mean editing the *existing* binding's command string, so every transform has to
know about every other one. `emit` inverts that: the binding is written once, and each transform lives
in its own file, registers itself, and never sees its siblings (`emit` fans out to all handlers in
registration order — verified).

**Cost, clear-eyed.** You now own Enter, so a bug in any handler makes the shell unable to run the
command that would fix it. Handlers must live in `conf.d/` to register at all
([style-guide.md](style-guide.md) §6). Inter-transform order is registration order — implicit, and it
matters the moment two of them rewrite the same text; vi mode needs two extra binds. fishconf has
already tripped on it: `conf.d/bashisms.fish` defines its own `_preprocess_commandline` (no cancel
support) and also binds `\r`, and `events.fish` sorts later and silently overwrites both.

**Skip the framework; steal `strip_dollar_prefix` alone if wanted** — the registry only pays off past
~3 transforms, and one transform is one `bind`. If ever adopted, `conf.d/events.fish` must be the
*only* file that binds `\r`.

### 3.8 Startup benchmarking

`functions/fbench.fish` runs `/usr/bin/time fish -i -c exit` ten times, writes a profile, then greps
entries over a μs threshold; `functions/fprof.fish` is a two-line `--profile-startup` + `cat`. The
README recipe is the one to memorize — it keeps the header row and only top-level (`>`) entries:

```fish
set fprof (mktemp)
fish --profile-startup=$fprof -c exit
awk 'NR==1 || $3==">"{print}' $fprof | string replace $HOME '~'
rm $fprof

for i in (seq 1 10); /usr/bin/time fish -i -c exit; end
```

**Adopt the recipe, skip the functions** — one-liners run twice a year, and `fbench` writes profile
output into the config dir (hence the `fishprof*.txt` gitignore entry). The `awk`/`--profile-startup`
pair is already in [style-guide.md](style-guide.md) §8.

### 3.9 `.editorconfig`

Verified: **this repo has none** (`find … -name .editorconfig` → nothing). fishconf's, in full:

```ini
# top-most EditorConfig file
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.{Makefile,makefile}]
indent_style = tab

[*.{md,markdown}]
trim_trailing_whitespace = false

[*.json]
indent_size = 2
```

**Adopt**, plus an explicit `[*.fish] indent_size = 4` block. This is
[style-guide.md](style-guide.md) §1 in a format VS Code enforces on save, and the live config already
has files it would have caught: `_shell.fish` has **no final newline** and `brew.fish` a trailing space
on the `HOMEBREW_CURL_RETRIES` line — both fail `fish_indent --check` today. Also worth copying:
fishconf's `.vscode/settings.json` line `"files.associations": {"*.theme": "fish"}`.

### 3.10 Smaller items, with verdicts

- **`functions/bashisms/{do,then}.fish` — no-op shims.** Both are `function do; $argv; end`. Muscle
  memory types `for x in *; do …; end` and these make it harmless instead of `Unknown command: do` —
  but they conceal real bugs: `functions/macos/trash.fish` has a stray bare `then` on its own line
  that only parses *because* the shim exists. `conf.d/bashisms.fish` pairs them with
  `abbr -a --position command -- fi end` and `done end`, which fix the typo in the buffer instead of
  hiding it. **Skip the functions, consider the abbrs** — the abbrs teach, the functions conceal. See
  [bash-to-fish.md](bash-to-fish.md).
- **Theme files.** `themes/tokyonight_night.theme` is a checked-in file of bare `fish_color_*` /
  `fish_pager_color_*` assignments (no `set`), source palette preserved in a comment block, selected
  via `fish_config theme choose $FISH_THEME`. A `.theme` file is version-controlled text `fish_config`
  reads, whereas letting `fish_config` write universals strands the palette in `fish_variables` —
  machine state, not config. Ethan has an empty `~/.config/fish/themes/` and `FISH_THEMES_DIR`
  pointing at it, so a hand-written `laramie.theme` is the natural home for the fish half of the
  palette. ⚠ fishconf's own selection line (`set -U FISH_THEME`) is banned here.
  **Adopt**; [prompt-and-colours.md](prompt-and-colours.md) owns the topic.
- **`cachecmd` over a fish function, not just an external tool.** `functions/set_java_home.fish` wraps
  an expensive lookup (`/usr/libexec/java_home`) in a private `__java_home_cmd` that *echoes fish
  code* — `echo "set -gx JAVA_HOME $home"` — then calls `cachecmd --source __java_home_cmd`,
  generalizing §3.1 from "tool integrations" to "any slow startup query". **Adopt the pattern.**
- **Dynamic variable dereference to walk argparse flags.** `functions/print_colorscheme.fish` handles
  16 colour flags without 16 `if set -q` blocks: `set --local flagvar "_flag_$name"` then
  `set --local color $$flagvar`, since `$$name` resolves the variable whose *name* is in `$name`.
  **Adopt** where it applies; obscure enough to warrant a comment.
- **Draw below the prompt without disturbing it.** `functions/colorize_hex.fish`, bound to `ctrl-k`,
  previews any 6-hex-digit colour on the command line with `printf '\e7\n\r\e[K%s\e[K\e8' $colorized`
  — `\e7` save-cursor / `\e8` restore, `\e[K` clearing each line touched. **Adopt** if a
  colour-preview binding is wanted for `laramie` work.

## 4. Patterns to NOT copy

| Source | Why not |
| --- | --- |
| `functions/init_env.fish` (17 `set -Ux`), `conf.d/prompt.fish`, `functions/dotf.fish`, `functions/wordle_helper.fish` | **`set -U` is banned outright** — [style-guide.md](style-guide.md) §3: universals persist into `fish_variables`, so the config stops being the source of truth and later edits stop taking effect. Rewrite as `set -q X; or set -gx X …`. `init_env`'s `LESS_TERMCAP_*` block additionally bakes `set_color` output into a universal at first run, freezing man-page colours against whatever theme was active that day. `prompt.fish` also calls `enable_transience` unconditionally — it does not exist unless starship's init defined it, so it needs a `functions -q` guard. `dotf` is a two-line `cd` plus a commented-out bare-repo implementation: dead code. |
| `functions/aliases/*.fish` (all 6) | Descriptions read `--description 'alias grep command grep --color=auto …'` — the literal shape `alias` generates, carried over by hand. §7 bans `alias`; §6 wants a description saying what the function *does*. `wget.fish` even has a typo'd `--wraps='wget"'`. The technique (a `command`-prefixed wrapper) is right; the metadata is cargo. |
| 18 files using `-d` instead of `--description` | Including the whole `git/` and `macos/` families. §1: prefer the long form where the short is cryptic, and never mix the two in one file — fishconf mixes them across the repo. |
| `conf.d/bashisms.fish` | Duplicates `events.fish`'s `_preprocess_commandline` and its `bind \r`; the later file wins, so half this file is dead. Its `_transform_var_assignment` also rewrites `FOO=bar` into `set FOO bar` — silently creating a *global* on a line the user thought was scoped. |
| `functions/bashisms/{do,then}.fish` | §3.10 — conceals real syntax errors. |
| `functions/macos/` — `hidefiles`, `showfiles`, `flushdns`, `pfd`, `pfs`, `trash`, `manp` | macOS-version-coupled: `defaults write com.apple.finder AppleShowAllFiles` + `killall Finder`, `killall -HUP mDNSResponder`, AppleScript against Finder's object model. Unverified on 27.x. `trash` reimplements via `osascript` what the installed `trash` binary already does — and carries a stray bare `then`. |
| `functions/allexts.fish`, `functions/noext.fish` | A `find`/`sed`/`sort`/`uniq` pipeline — four forks where `path extension` over a fish list does it. §0.5. |
| `functions/repo.fish` | `[ … ]` instead of `test`, `case \*` instead of `case '*'`, `set err` with no scope flag. Superseded anyway: `functions/git/clone.fish` covers the useful half. |
| `functions/cdpr.fish` | `if ! git rev-parse …` (bash `!`, not `not`), and it prints the error then falls through to `cd` regardless — no `return`. Genuine bug. |
| `functions/fish_user_key_bindings.fish` | Calls `fish_default_key_bindings` inside itself while `conf.d/keybindings.fish` also sets `fish_key_bindings fish_default_key_bindings`. Pick one; the `conf.d` variable is the documented way. |
| `functions/up.fish` | Right idea, but `-d`, and a bad argument leaks a raw `string repeat` error. Adapted below. |
| `functions/speedtest.fish` | Hardcodes a third-party 10 MB URL that may not exist. |

## 5. Ranked adoption plan — ✅ executed 2026-07-29

Historical record; see the adoption-status block at the top of this file for the outcome. Rows 1–14
landed (some in modified form — row 5's `cachecmd` gained `--depends`/`--clear` and a stale-cache
fallback; row 11's `prepath` was refused for want of a consumer; row 13's `.theme` is generated, not
hand-written). Row 15 (`functions/git/` predicates) remains deferred: starship still owns the prompt,
so there is still no consumer.

Ordered by payoff ÷ effort. Every row was a gap verified against the live config.

| # | Change | File to touch | Effort | Payoff |
| --- | --- | --- | --- | --- |
| 1 | **Fix the `HOMEBREW_PREFIX` ordering bug** (§3.3): move `set -gx HOMEBREW_PREFIX` above the `fish_add_path`, or derive it from `brew shellenv`. Then `set -e fish_user_paths` and let the config rebuild it. | `conf.d/brew.fish` + `fish_variables` | S | Removes `/bin` and `/sbin` from the front of `PATH` — verified present in `fish_variables`. Silent, active, wrong. |
| 2 | **Guard the Ghostty source** with `test -r`. Verified: with `GHOSTTY_RESOURCES_DIR` unset the current line prints `source: No such file or directory` on every non-Ghostty shell (ssh, VS Code task, `fish -c`). | `conf.d/_shell.fish` | S | Startup noise → silence. §0.4. |
| 3 | **Add `.editorconfig`** (§3.9 verbatim + a `[*.fish]` block). | `/Users/ethan/Projects/dotfiles/.editorconfig` (new) | S | Enforces §1 on save; `_shell.fish` and `brew.fish` both fail `fish_indent --check` today. |
| 4 | **`fish_indent -w` the three failing files** — `_shell.fish`, `brew.fish`, `abbrs.fish` fail `--check`; `_init.fish` and `git.fish` pass. | `conf.d/*.fish` | S | Makes `fish_indent --check` a usable gate. Do after #3. |
| 5 | **Add `functions/cachecmd.fish`** (adapted, §3.1). | `functions/cachecmd.fish` (new) | M | Prerequisite for #6; five forks per shell → five `builtin source`s, with the upgrade-safe invalidation the original lacks. |
| 6 | **Add `conf.d/tools.fish`** (adapted, §3.2) — `starship`, `atuin`, `zoxide`, `fzf`, `grc` are all installed and all uninitialized (CLAUDE.md gap 5). | `conf.d/tools.fish` (new) | S | Closes five gaps in one file. Notably makes `abbr -a cd z` work — it is dead today. |
| 7 | **Add `functions/cls.fish`.** Verified: no `cls` binary and no `cls` function, so `abbr -a c cls` expands to nothing runnable. | `functions/cls.fish` (new) | S | Fixes a broken abbr in 3 lines (below). |
| 8 | **Resolve `abbr -a tree tre`.** Verified: `tre` is not installed. Either `brew install tre-command` or repoint the abbr at `eza --tree`. | `conf.d/abbrs.fish` or `Brewfile` | S | Fixes CLAUDE.md gap 4. Decide; don't leave it dangling. |
| 9 | **Make XDG defaults conditional** and `mkdir` only what's missing (§3.3). | `conf.d/_init.fish` | S | Stops overriding a deliberately exported `XDG_*`; four `mkdir` calls → zero on the common path. |
| 10 | **Import cached `brew shellenv`** and add the `contains` guard on the completions append (§3.3). | `conf.d/brew.fish` | M | Gains `HOMEBREW_CELLAR`, `HOMEBREW_REPOSITORY`, `INFOPATH`, Homebrew's `MANPATH`. Skip the sudo/keg-only/gems machinery. |
| 11 | **Add the deferred-work tail** — `prepath` captured in `_init.fish`, re-applied by a `--on-event fish_postinit` handler, `emit` in `config.fish` (§2, §3.4). | `conf.d/_init.fish` + `config.fish` | M | Makes `PATH` priority deterministic regardless of what `brew.fish` or future snippets prepend. Do after #1, not instead of it. |
| 12 | **Add `functions/up.fish`** (adapted below). | `functions/up.fish` (new) | S | Small but daily. |
| 13 | **Write `themes/laramie.theme`** in the `.theme` format (§3.10) instead of letting `fish_config` write universals. | `themes/laramie.theme` (new) | M | Puts the fish half of `laramie` under version control alongside the other four copies. Coordinate with [prompt-and-colours.md](prompt-and-colours.md). |
| 14 | **Split an `xdg-apps` snippet out of `_init.fish`**, whose "unorganized" block already holds `LESSHISTFILE`/`BAT_PAGER`. Cherry-pick from fishconf's 130-line `conf.d/xdg-apps.fish`. | `conf.d/xdg-apps.fish` (new) | L | Keeps `$HOME` clean for `cargo`, `docker`, `gnupg`, `npm`, `node`, `rustup`, `go`, `python3`, `rg` — all installed. Import only the tools in the Brewfile. |
| 15 | **Add `functions/git/` predicates** (§3.6). | `functions/git/` (new) | M | Deferred — no consumer until something other than starship draws the prompt. Take the convention now, the files later. |

Snippets for rows 7 and 12, both verified with `fish -n` and `fish_indent --check`:

```fish
# adapted — functions/cls.fish
function cls --description 'clear the screen and drop the scrollback'
    clear; and printf '\e[3J'
end

# adapted — functions/up.fish
function up --description 'travel up any number of directories'
    set -l levels 1
    set -q argv[1]; and set levels $argv[1]
    if not string match -qr '^[0-9]+$' -- $levels
        echo >&2 "up: expected a number, got '$levels'"
        return 2
    end
    cd (string repeat -n $levels ../)
end
```

Deliberately absent: `conf.d/events.fish` (§3.7), `fbench`/`fprof` (§3.8), `functions/bashisms/`
(§3.10), and everything in §4.
