# Fish — the interactive layer

Abbreviations, key bindings, the `commandline` builtin, event handlers, history, and terminal
shell integration, for fish 4.8.1. Prompt functions and every `fish_color_*` / `fish_pager_color_*`
variable belong to [prompt-and-colours.md](prompt-and-colours.md); load order and autoloading to
[config-layout.md](config-layout.md). All code here obeys [style-guide.md](style-guide.md).

⚠ Binding and abbreviation *behaviour* cannot be exercised non-interactively — `fish -c` never
reaches the line editor. Everything below was verified as far as it can be: `bind` registration via
`bind --user`, `abbr` via `abbr --show`, expansion functions by calling them directly, completions
via `complete -C`. Where only registration was verified, that is said inline.

## 1. `abbr` — complete reference

Abbreviations expand **in the buffer** before the command runs, so history records the real command.
They only expand on typed input; scripts never see them.

| Flag | Effect |
| --- | --- |
| `-a NAME EXPANSION` / `--add` | define. `--` before a `-`-leading NAME: `abbr -a -- -C --color` |
| `-e NAME` / `--erase` | remove. For `--command` abbrs you **must** repeat `--command` (see gotcha) |
| `-q NAME…` / `--query` | exit 0 if any NAME is an abbreviation. Scriptable guard |
| `-s` / `--show` | print every abbr as a re-runnable `abbr -a` line — the export form |
| `-l` / `--list` | print names only |
| `--rename OLD NEW` | rename; also needs `--command` for command-scoped abbrs |
| `--position command\|anywhere` | default `command`. `anywhere` expands mid-line (`L` → `\| less`) |
| `--command CMD` | expand only as an argument to CMD. Implies `--position anywhere`, forbids `--position command`. Repeatable |
| `-r PATTERN` / `--regex` | match by PCRE2 instead of literal NAME; must match the **whole** token. Last-added match wins |
| `--set-cursor[=MARKER]` | after expanding, move the cursor to MARKER (default `%`) and delete it |
| `-f FN` / `--function FN` | expansion is the **output of FN**, called with the matched token. Non-zero exit leaves the token untouched |

⚠ **`-U` and `-g` are dead.** fish 3.6.0 removed universal-variable storage. `abbr -a -U foo bar`
prints `abbr: Warning: Option '-U' was removed and is now ignored`; `-g` is accepted and silently
ignored. Abbreviations exist only for the life of the shell, which is exactly why this repo declares
them in `conf.d/abbrs.fish` — a plain list of `abbr -a` lines re-run at every startup, diffable and
version-controlled. Never `funcsave`-style persistence, never `set -U`; see
[style-guide.md](style-guide.md) §7 and §3.

⚠ **Erasing a command-scoped abbr needs the scope.** `abbr -e co` is a silent no-op for an abbr
added with `--command git`; `abbr -e --command git co` works. Same for `--rename`.

### Function-bodied abbreviations (3.6+)

The feature agents miss. `--function` names a fish function; the matched token is `$argv[1]`, and
whatever the function prints replaces the token. Combined with `--regex` this gives real custom
syntax. Verified: `__abbr_multicd ....` prints `cd ../../../`.

```fish
# conf.d/abbrs.fish

# expand a run of dots into the equivalent cd
function __abbr_multicd --description 'turn .. / ... / .... into cd ../..'
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
abbr -a dotdot --regex '^\.\.+$' --function __abbr_multicd

# bash-style !! — recall the previous commandline
function __abbr_last_history_item --description 'print the most recent history entry'
    echo $history[1]
end
abbr -a '!!' --position anywhere --function __abbr_last_history_item

# expand to `<cursor> | less`, cursor placed where the % was
abbr -a L --position anywhere --set-cursor '% | less'
```

`abbr --show` on the above prints, verbatim:

```
abbr -a --regex '^\\.\\.+$' --function __abbr_multicd -- dotdot
abbr -a --position anywhere --function __abbr_last_history_item -- !!
abbr -a --position anywhere --set-cursor='%' -- L '% | less'
```

⚠ The helper must be **autoloadable** (`functions/__abbr_multicd.fish`) or defined in the same
`conf.d/` file. An abbr referencing a missing function leaves the token unchanged, silently.

### abbr vs function vs alias

- **`abbr`** when you want the real command visible in the buffer and recorded in history, and only
  interactively: `abbr -a cd z`, `abbr -a ls eza`.
- **`function`** when it must work in scripts, pipelines, and command substitutions, or when it needs
  arguments in the middle — plus `command <name>` inside the body to avoid recursion.
- **`alias`** never. It is a `function` wrapper that hides its body in the description;
  [style-guide.md](style-guide.md) §7 bans it outright.

⚠ ~~The live `conf.d/abbrs.fish` points at three things that do not exist~~ — **fixed 2026-07-29**:
`cls` is `functions/cls.fish`, `tree` points at `eza --tree` (`tre` was never installed) and `z` comes
from zoxide in `conf.d/tools.fish`. Re-run the every-target-resolves check in the skill's verification
section after editing that file — an abbr to a missing command is harmless until used, but still broken.

⚠ **Abbreviations are interactive-only, so declare them behind a guard.** Since expansion happens in
the line editor and "scripts never see them", the 30 `abbr -a` calls in `conf.d/abbrs.fish` were pure
waste in every `fish -c` — 0.37 ms of a 4.1 ms non-interactive startup. That file now opens with
`status is-interactive; or return`. ⚠ Consequence: any check that inspects `abbr --show` must run under
`fish -i`, not `fish -c`.

## 2. `bind` — key notation and practice

⚠ **fish 4.0 introduced human-readable key names.** Write `ctrl-x`, `alt-c`, `shift-tab`,
`ctrl-x,ctrl-e` (comma = a *sequence* of two keys). Modifier prefixes are `ctrl-`, `alt-`, `shift-`,
`super-`; key names are case-sensitive and `alt-W` means `alt-shift-w`. Use lowercase after
`shift-`: `shift-a`, not `shift-A` (rejected as of the 4.1.0 release notes; 4.8.1's parser still
takes it, but do not write it).

The **old escape notation still works** — verified: `bind \cx 'echo hi'` lists back as
`bind ctrl-x 'echo hi'`, and `bind \ec …` as `bind alt-c …`. Compatibility rule from the 4.0 notes:
an argument starting with an ASCII control escape (`\e`, `\cX`), or ≤3 characters long, not a named
key, and containing neither `,` nor `-`, is read in the old syntax. **Write new-style anyway** — the
old form is the reason a binding like `bind up` used to mean "u then p". Terminfo names (`bind -k nul`)
were removed in 4.x.

```fish
# wrong — legacy, ambiguous, and what an agent defaults to
bind \co copybuffer
bind -k nul expand-abbr

# right
bind ctrl-o copybuffer
bind ctrl-space expand-abbr
```

Named keys (`bind -K` lists all 30): `up down left right backspace comma delete end enter escape
f1`…`f12 home insert menu minus pageup pagedown printscreen space tab`.

| Task | Command |
| --- | --- |
| Discover a key's name | `fish_key_reader` (single key) or `fish_key_reader --continuous`. Prints a ready-made `bind` line. `--verbose` also shows the raw sequence |
| List everything | `bind` (both levels), `bind --user`, `bind --preset` |
| List one key | `bind ctrl-c` → `bind --preset ctrl-c cancel-commandline` |
| Erase a user binding | `bind --erase ctrl-c` — the preset underneath takes effect again, no need to remember it |
| Nuke a mode | `bind --erase --all -M insert` |
| Available input functions | `bind --function-names` (111 in 4.8.1) |
| Available modes | `bind --list-modes` — `default` only until a vi keymap is installed, then `default insert visual replace replace_one operator f F t T` |

**Modes.** `-M MODE` picks the mode a binding lives in (default `default`, which is vi's *normal*);
`-m NEW_MODE` switches mode after the binding runs. `$fish_bind_mode` holds the current one. Under vi
bindings a bare `bind` therefore lands in *normal* mode — insert-mode bindings need `-M insert`.
Modes are created on demand: `bind -M insert ctrl-y …` works before any vi keymap exists and makes
`insert` appear in `bind --list-modes`.

**`--preset` vs user.** User bindings win at lookup time. Every `bind` you write is a user binding.
Verified: `fish_default_key_bindings` and `fish_vi_key_bindings` run `bind --erase --all --preset`,
so switching keymaps **does not** destroy bindings declared in `conf.d/`. Only touch `--preset` if you
are authoring a whole keymap set.

**Where bindings go.** `conf.d/keybindings.fish` is correct and sufficient for a fixed keymap.
`fish_user_key_bindings` (in `functions/`) is required when the keymap can change: fish's
`__fish_config_interactive` registers an `--on-variable fish_key_bindings` handler that re-runs
`$fish_key_bindings` and then `fish_user_key_bindings`, so only the latter is re-applied after a
runtime `set -g fish_key_bindings fish_vi_key_bindings`. It is also the only place that can reliably
bind into vi modes.

```fish
# functions/fish_user_key_bindings.fish — re-run whenever $fish_key_bindings changes
function fish_user_key_bindings --description 'bindings that must survive a keymap switch'
    fish_default_key_bindings
    bind ctrl-x,ctrl-e edit_command_buffer
end
```

### The input functions worth knowing

`COMMAND` may mix input functions and shell commands, and several may be listed on one `bind`
(4.0+: `bind ctrl-g expand-abbr 'commandline -i \n'` works).

| Function | Effect |
| --- | --- |
| `repaint` | re-run the prompt functions and redraw. **End every buffer-modifying binding with it** |
| `repaint-mode` | redraw `fish_mode_prompt` only; what mode-changing vi bindings must call |
| `execute` | run the current commandline (also expands abbreviations) |
| `expand-abbr` | expand the abbreviation under the cursor, nothing else |
| `accept-autosuggestion` | take the whole suggestion; returns false when there is none |
| `complete` / `complete-and-search` | tab / shift-tab: complete the token, or open the searchable pager |
| `pager-toggle-search` | toggle the pager's search field; after `history-pager`, search forwards |
| `history-pager` | open the searchable history pager (`ctrl-r`) |
| `history-prefix-search-backward` / `-forward` | search history by *prefix* rather than substring |
| `history-token-search-backward` / `-forward` | search by the token under the cursor (`alt-up`/`alt-down`) |
| `history-delete` | permanently drop the selected history item |
| `beginning-of-line` / `end-of-line` | line ends; `beginning-of-buffer` / `end-of-buffer` for multiline |
| `kill-word` / `backward-kill-word` / `kill-line` / `backward-kill-line` | move text to the killring |
| `backward-kill-path-component` | `ctrl-w`: back to the previous `/ : @` |
| `yank` / `yank-pop` | paste the killring head / rotate to the previous entry |
| `clear-commandline` / `cancel-commandline` | empty the buffer / cancel it leaving a `^C` marker |
| `clear-screen` / `scrollback-push` | repaint without flicker / push output into scrollback |
| `self-insert` | insert the matched keys. Bind to `''` for the generic fallback |
| `undo` / `redo` | line-edit history, kept for the life of the shell since 4.0 |
| `and` / `or` | conditionally run the *next* function — only some functions report success |

Not input functions but ordinary functions designed for bindings: `edit_command_buffer`,
`fish_clipboard_copy`, `fish_clipboard_paste`, `fish_commandline_prepend`,
`fish_commandline_append`, `up-or-search`, `down-or-search`.

**Key timeouts.** `$fish_escape_delay_ms` disambiguates a bare `escape` from `alt`+key (raise to
~100 if you want `escape`-then-key to count as alt). `$fish_sequence_key_delay_ms` bounds the wait
for the rest of a multi-key sequence — set it (e.g. 200) whenever you bind something like `j,k`, or
every `j` stalls.

## 3. `commandline` — the builtin that makes bindings useful

Reads and rewrites the buffer. With no options it prints the whole buffer.

| Flag | Effect |
| --- | --- |
| `-r` / `--replace` | replace the selected scope with the argument (the default action) |
| `-i` / `--insert` | insert at the cursor. `--insert-smart` also strips a `$ ` prompt prefix |
| `-a` / `--append` | append to the end of the selected scope |
| `-f` / `--function` | queue input functions ahead of real keypresses. Cannot combine with other flags. Since 4.0 they apply immediately, so `commandline -i foo; commandline \| grep foo` succeeds |
| `-C` / `--cursor` | get, or set, the cursor offset — relative to the scope if `-j`/`-p`/`-t` is also given |
| `-b` / `--current-buffer` | the whole buffer, excluding the autosuggestion (default scope) |
| `-j` / `--current-job` | the pipeline under the cursor (stops at `;`, `&`, newline, `and`/`or`) |
| `-p` / `--current-process` | the single command under the cursor (also stops at pipes) |
| `-t` / `--current-token` | the token under the cursor |
| `-c` / `--cut-at-cursor` | truncate the output at the cursor. With `-x`, stops at the last *completed* token |
| `-x` / `--tokens-expanded` | expand the scope and print one argument per line |
| `--input=STR` | operate on STR instead of the real buffer — the only way to test this non-interactively |
| `--is-valid` | 0 = complete and runnable, 2 = incomplete, 1 = syntax error (verified) |
| `--search-field` | act on the pager's search field; false when no pager is shown (verified: exits 1) |
| `-S` / `--search-mode`, `-P` / `--paging-mode`, `--showing-suggestion` | state predicates for conditional bindings |

Verified with `--input`: `commandline --input 'git add foo bar' -x` prints `git`/`add`/`foo`/`bar`,
one per line; `--is-valid` returns 0 for `echo hi`, 2 for `if true`, 1 for `echo )`.

Three bindings built from it. Registration and formatting verified (`bind --user`, `fish -n`,
`fish_indent --check`); the editing behaviour itself is only observable in a real terminal.

```fish
# conf.d/keybindings.fish
# interactive line-editing bindings

status is-interactive; or return

# prefix search on the arrows rather than the default substring search
bind up history-prefix-search-backward
bind down history-prefix-search-forward

# ctrl-o: copy everything left of the cursor to the clipboard
bind ctrl-o 'commandline --cut-at-cursor | fish_clipboard_copy' repaint

# alt-p: page the job under the cursor
bind alt-p 'commandline --current-job --append " &| $PAGER"' repaint

# alt-q: escape the token under the cursor so it survives as one argument
bind alt-q __quote_current_token repaint
```

```fish
# functions/__quote_current_token.fish
function __quote_current_token --description 'escape the token under the cursor'
    set -l tok (commandline --current-token)
    test -n "$tok"; or return
    commandline --current-token --replace (string escape -- $tok)
end
```

⚠ Inside `complete -C 'STRING'`, `commandline` reads STRING — which is how completion generators
work, and how they can be tested. The canonical pair (verified) is:

```fish
set -l tokens (commandline --cut-at-cursor --tokens-expanded) # or -cx
set -l current (commandline --current-token --cut-at-cursor) # or -ct
```

`commandline -cx` tilde-expands: for `dd ~/Pro par` it yields `dd` and `/Users/ethan/Pro`, with
`-ct` giving `par`.

## 4. Event handlers

`function` turns a function into a handler with one of these flags:

| Flag | Fires when |
| --- | --- |
| `--on-event NAME` | `emit NAME` runs, or fish emits a built-in event |
| `--on-variable NAME` | NAME's value is set. No guarantee of one call per `set`, or that the value changed |
| `--on-signal SIGSPEC` | the signal reaches **fish** (not the foreground job). Observing it stops fish exiting on it |
| `--on-job-exit PID` | the job containing PID exits. `caller` inside a command substitution means "the job that created me" |
| `--on-process-exit PID` | that child exits. `%self` = `$fish_pid`, i.e. fish itself |

Built-in `--on-event` names in 4.8.1 — the complete list:

| Event | First argument | Fires |
| --- | --- | --- |
| `fish_prompt` | — | before each prompt is displayed |
| `fish_preexec` | the commandline | just before running an interactive command; skipped if empty |
| `fish_postexec` | the commandline | just after; skipped if empty |
| `fish_posterror` | the commandline | after a command with syntax errors |
| `fish_cancel` | — | a commandline is cleared |
| `fish_exit` | — | just before fish exits |
| `fish_focus_in` / `fish_focus_out` | — | the terminal gains / loses focus |

There is no `fish_read` and no `fish_postinit` event — verified absent from the 4.8.1 docs.
`fish_postinit` is a *convention*: fishconf's last-sorting `conf.d/zzz-post.fish` ends with
`emit fish_postinit`, giving every earlier snippet a hook that runs after all of `conf.d/` and
`config.fish` are read. That is the idiomatic "run after everything" pattern, and its own
`conf.d/00-init.fish` uses it to re-prepend `$PATH` entries after Homebrew has pushed its own:

```fish
# conf.d/events.fish

# a consumer, anywhere earlier than the emitter
function __prepend_prepath --on-event fish_postinit --description 're-assert my path entries'
    fish_add_path --prepend --move $prepath
end

function __on_postexec --on-event fish_postexec --description 'note missing commands'
    test $status -eq 127; and echo >&2 "not found: $argv[1]"
end

function __on_pwd --on-variable PWD --description 'react to a directory change'
end

# the emitter belongs in the last-sorting conf.d file, e.g. conf.d/zzz-post.fish
emit fish_postinit
```

⚠ Handlers register **only when the file is sourced** — autoloading does not fire them, so every
handler belongs in `conf.d/`. See [style-guide.md](style-guide.md) §6.

Inspect what is registered with `functions --handlers` (verified output for the above):

```
Event variable
PWD __on_pwd

Event generic
fish_postexec __on_postexec
fish_postinit __prepend_prepath
```

## 5. History

Stored at `$XDG_DATA_HOME/fish/fish_history` — on this machine
`/Users/ethan/.local/share/fish/fish_history` (verified). Duplicates are dropped automatically.

| Command | Purpose |
| --- | --- |
| `history search [PATTERN]` | default subcommand; newest first, `--reverse` flips it, `--max N` caps it, `--show-time[=FMT]` prefixes timestamps |
| `history delete PATTERN` | interactive picker; the **builtin** only does `--exact --case-sensitive` |
| `history merge` | pull in changes from sessions started after this one |
| `history clear` / `clear-session` | wipe the file / just this session's entries |
| `history append CMD` | record a command without running it |
| `--contains` / `--prefix` / `--exact` | match mode. `--contains` is the search default, `--exact` the delete default. Last flag wins if both `--prefix` and `--contains` are given |
| `-C` / `--case-sensitive` | searches are case-insensitive otherwise |
| `-z` / `--null` | NUL-terminate, for `read -z` on multiline entries |

`history` is a *function* wrapping the builtin: it pages output and adds the interactive delete
prompt. Reach for `builtin history` in scripts to skip both.

**Named sessions.** `set -gx fish_history NAME` switches to `$XDG_DATA_HOME/fish/NAME_history`,
effective immediately and changeable mid-session. `default` restores `fish`. Any other value also
suppresses bash-history import. `set -gx fish_history ''` stores nothing at all.

⚠ **Keeping a command out of history**, in increasing order of force:

1. **Prefix it with a space.** Recallable until the next command, never written to disk.
2. `set -gx fish_history ''` for the rest of the session.
3. Private mode: `fish --private` / `fish -P`, or `set fish_private_mode 1`. `-P` also hides existing
   history. Respect it in your own scripts: `test -n "$fish_private_mode"`.
4. Override `fish_should_add_to_history` (4.0+). It receives the commandline as `$argv[1]` and runs
   *before* the command, so `$status` is not available. Return non-zero to skip.

⚠ Defining `fish_should_add_to_history` takes over **all** the filtering — the leading-space rule
stops working unless you reimplement it:

```fish
# functions/internal/fish_should_add_to_history.fish
function fish_should_add_to_history --description 'keep secrets and noise out of the history file'
    # preserve fish's built-in rule, which this function otherwise replaces
    string match -q ' *' -- $argv[1]; and return 1
    string match -qr '^(op|vault) ' -- $argv[1]; and return 1
    return 0
end
```

## 6. Autosuggestions, pager, cursor, editor, clipboard

- **Autosuggestions**: `set -g fish_autosuggestion_enabled 0` disables them. `right`/`ctrl-f` accepts
  all; `alt-right`/`alt-f` one word; `ctrl-right` one token. `suppress-autosuggestion` drops the
  current one from a binding.
- **Pager**: arrows, `pageup`/`pagedown`, `tab`, `shift-tab` navigate; `ctrl-s` (`pager-toggle-search`,
  `/` in vi mode) opens the filter field. `commandline --search-field` targets that field.
- **Cursor shapes**: `$fish_cursor_default`, `_insert`, `_replace`, `_replace_one`, `_visual`,
  `_external`. Values are `block`, `line`, `underscore`, optionally `+ blink`; anything else is
  ignored, and a terminal that lacks the capability silently does nothing.
  `$fish_cursor_selection_mode` is `exclusive` (default) or `inclusive` — prefer `inclusive` with a
  block cursor. Writing the raw escape yourself is a fishconf pattern: `printf '\e[%d q' 6` for a
  steady bar, `2` block, `4` underline, `+1` on each for blinking.
- **External editor**: `edit_command_buffer` (bound to `alt-e` / `alt-v`) opens the buffer in
  `$VISUAL`, falling back to `$EDITOR`. ⚠ This repo sets
  `VISUAL='code-insiders --new-window --wait'` in `conf.d/_init.fish` — the `--wait` is load-bearing;
  without it the editor returns instantly and the buffer never updates.
- **Clipboard**: `fish_clipboard_copy` (`ctrl-x`) and `fish_clipboard_paste` (`ctrl-v`). Both take
  piped stdin, so `commandline | fish_clipboard_copy` is the idiom. On macOS they use `pbcopy` /
  `pbpaste` (present); otherwise `wl-copy`, `xsel`, `xclip`, `clip.exe`, or OSC 52.
- **Bracketed paste** is always on and, as of 4.0, **not configurable** — the `paste` bind mode was
  removed. Pasting inside single quotes auto-escapes quotes and backslashes. Killring entries live in
  `$fish_killring`.
- **Greeting**: `set -g fish_greeting` (empty) suppresses it; a string replaces it; or override the
  `fish_greeting` function. The shipped function only prints when `$fish_greeting` is non-empty, so
  the empty-value form is enough. `conf.d/_shell.fish` uses exactly that.

## 7. Terminal shell integration

A terminal's integration is a fish snippet the terminal ships and the shell sources. Ghostty's lives
at `$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish`, and
**`conf.d/ghostty.fish`** sources it directly — it was split out of `_shell.fish` on 2026-07-29 so a
failure there cannot take the rest of the interactive setup with it.

⚠ ~~The live call is unguarded~~ — **fixed.** With `GHOSTTY_RESOURCES_DIR` unset (any non-Ghostty
terminal, or fish launched from a script) the bare form failed loudly: `source: Error encountered while
sourcing file '/shell-integration/…': No such file or directory`, exit 1 — exactly the startup noise
[style-guide.md](style-guide.md) §4 forbids. The live guarded form, verified clean both with and
without the variable set:

```fish
# conf.d/ghostty.fish
# terminal (ghostty) — absent when fish runs under another terminal
set -l ghostty_init \
    "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
test -r "$ghostty_init"; or return
source $ghostty_init
```

`test -r` covers both the unset variable (the path becomes `/shell-integration/…`, unreadable) and a
Ghostty install whose layout has moved, so no `set -q` is needed as well.
