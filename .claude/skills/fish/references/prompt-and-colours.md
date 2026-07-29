# Fish — prompt, `set_color` and themes

Prompt functions, the `set_color` builtin, the complete `fish_color_*`/`fish_pager_color_*` catalogue,
`.theme` files, and a ready-to-install **laramie** theme. Verified against fish **4.8.1**. Not covered:
key bindings, and general style — see [style-guide.md](style-guide.md), which every snippet obeys.

## 1. How the prompt is assembled

Three ordinary autoloaded functions. Nothing is special about them except the names fish calls.

| Function | Position | Called when | Default present? |
| --- | --- | --- | --- |
| `fish_prompt` | left | fish needs a new prompt | yes (shipped) |
| `fish_right_prompt` | right, same row | with `fish_prompt` | **no** — undefined until you write it |
| `fish_mode_prompt` | prepended left of `fish_prompt` | on every vi mode change | yes (delegates to `fish_default_mode_prompt`) |

Whatever they print becomes the prompt, minus one trailing newline. Multiple lines work in `fish_prompt`
only — **not** in `fish_right_prompt` or `fish_mode_prompt`.

- `$status` inside `fish_prompt` does not leak out; capture it on line 1 anyway — every command in the
  body clobbers it.
- `$SHELL_PROMPT_PREFIX` / `$SHELL_PROMPT_SUFFIX` (4.6.0+) are prepended/appended to the left prompt
  automatically, customized or not.
- `set -g fish_transient_prompt 1` re-runs all three with `--final-rendering` before executing a
  commandline, so the version pushed to scrollback can be shorter. Branch on
  `contains -- --final-rendering $argv`.

⚠ **Every fork in `fish_prompt` is paid once per prompt, forever.** The output is cached and reused while
you type — keystrokes do not re-run it — but a command completing, a resize repaint, or
`commandline -f repaint` does. A `git status` in a prompt is ~20 ms of *every* prompt. Use builtins
(`string`, `path`, `prompt_pwd`) and let `fish_git_prompt` make the one git call it needs.

⚠ **A vi mode change repaints `fish_mode_prompt` only, and the rest of the prompt only if
`fish_mode_prompt` does not exist.** A mode indicator built into `fish_prompt` will not update until you
erase `fish_mode_prompt` — documented way: an empty `~/.config/fish/functions/fish_mode_prompt.fish`.

The minimal correct `fish_prompt` — status captured first, colour always reset, no forks:

```fish
# functions/fish_prompt.fish
function fish_prompt --description 'left prompt: cwd, non-zero status, marker'
    # must be the first statement — every later command overwrites $status
    set -l last_status $status

    set -l stat
    if test $last_status -ne 0
        set stat (set_color $fish_color_status)"[$last_status]"(set_color --reset)
    end

    string join '' -- (set_color $fish_color_cwd) (prompt_pwd) (set_color --reset) $stat '> '
end
```

Renders `~/P/dotfiles> `, and `~/P/dotfiles[1]> ` after `false` (verified). `set_color` with an unset
variable is a silent no-op returning 1 — no output, no error — so referencing `$fish_color_cwd` is safe
even when it is unset.

## 2. Prompt helper functions fish ships

All verified present in 4.8.1 with `fish -c 'functions -q X'`.

| Function | Output / purpose | Tuning |
| --- | --- | --- |
| `prompt_pwd` | `$PWD` with `$HOME`→`~`, each component but the last shortened to 1 char | `-d`/`--dir-length=N` or `$fish_prompt_pwd_dir_length` (0 = no shortening); `-D`/`--full-length-dirs=N` or `$fish_prompt_pwd_full_dirs` (default 1). Positional args are shortened instead of `$PWD` |
| `prompt_hostname` | `$hostname` up to the first dot | — |
| `prompt_login` | `user@host`, plus chroot marker (Debian `debian_chroot`) | — |
| `fish_is_root_user` | true when uid 0 — swap the prompt glyph | — |
| `fish_status_to_signal` | `130` → `SIGINT`; pass `$pipestatus` for a pipeline | — |
| `fish_vcs_prompt` | calls every VCS prompt below; each no-ops if its tool is absent | svn is commented out inside it (slow); `funced fish_vcs_prompt` to enable |
| `fish_git_prompt` | git info, default format `" (%s)"` | §3 |
| `fish_hg_prompt` | Mercurial | `$fish_color_hg_{added,clean,copied,deleted,dirty,modified,renamed,unmerged,untracked}` |
| `fish_svn_prompt` | Subversion | `$__fish_svn_prompt_color_revision` and friends |
| `fish_darcs_prompt` | Darcs | `$fish_color_darcs_{normal,conflict,rebasing}` |
| `fish_default_mode_prompt` | the shipped `[N]`/`[I]`/`[R]`/`[V]` indicator; returns immediately unless `$fish_key_bindings` is vi or hybrid | call it from your own `fish_mode_prompt` to reuse it |

## 3. `fish_git_prompt` configuration

Set these in `conf.d/`, before the first prompt. `fish_git_prompt` caches validated chars/colours in
`___fish_git_prompt_*` (three underscores) and ships `--on-variable` handlers that invalidate the cache,
so changing a variable later also works — but only once the function has been autoloaded. Where a git
option exists it **takes precedence** over the fish variable. Booleans accept `1`, `yes`, `true`;
anything else is false.

| Variable | git option | Effect |
| --- | --- | --- |
| `__fish_git_prompt_show_informative_status` | `bash.showInformativeStatus` | counts of dirty/staged/untracked/unmerged + ahead/behind, and switches to the fancy glyph set |
| `__fish_git_prompt_use_informative_chars` | — | the fancy glyphs **only**, without the extra git work |
| `__fish_git_prompt_showdirtystate` | `bash.showDirtyState` | show that the tree has uncommitted changes |
| `__fish_git_prompt_showuntrackedfiles` | `bash.showUntrackedFiles` | show untracked files (off by default — counting them is expensive) |
| `__fish_git_prompt_showstashstate` | — | show stash state |
| `__fish_git_prompt_showupstream` | — | list of `auto`, `verbose`, `name`, `informative`, `git`, `svn`, `none` |
| `__fish_git_prompt_showcolorhints` | — | colour the branch name and status symbols |
| `__fish_git_prompt_describe_style` | — | `contains` \| `branch` \| `describe` \| `default`; otherwise the 8-char SHA |
| `__fish_git_prompt_shorten_branch_len` | — | truncate the branch name to N chars |
| `__fish_git_prompt_shorten_branch_char_suffix` | — | ellipsis character used when truncating |
| `__fish_git_prompt_status_order` | — | which counters appear and in what order. Default: `stagedstate invalidstate dirtystate untrackedfiles stashstate`. Dropping a name also skips the git work for it |
| `__fish_git_prompt_hide_<state>` | — | set to hide one counter in informative mode, e.g. `__fish_git_prompt_hide_untrackedfiles` |

Glyphs — `usual` (`informative`) default:

| Variable | Default | Variable | Default |
| --- | --- | --- | --- |
| `char_dirtystate` | `*` (`✚`) | `char_upstream_ahead` | `>` (`↑`) |
| `char_stagedstate` | `+` (`●`) | `char_upstream_behind` | `<` (`↓`) |
| `char_invalidstate` | `#` (`✖`) | `char_upstream_diverged` | `<>` (`↓↑`) |
| `char_untrackedfiles` | `%` (`…`) | `char_upstream_equal` | `=` |
| `char_stashstate` | `$` (`⚑`) | `char_upstream_prefix` | *(empty)* |
| `char_cleanstate` | *(empty)* (`✔`) | `char_stateseparator` | `' '` (`\|`) |

Colours — all prefixed `__fish_git_prompt_`, all falling back to `$__fish_git_prompt_color`, each with a
matching `_done` variable printed immediately **after** the element: `color`, `color_prefix`,
`color_suffix`, `color_bare`, `color_merging`, `color_cleanstate`, `color_dirtystate` (red with
`showcolorhints`), `color_stagedstate` (green with `showcolorhints`), `color_invalidstate`,
`color_stashstate`, `color_untrackedfiles`, `color_upstream`, `color_branch` (green),
`color_branch_detached` (red), `color_branch_dirty`, `color_branch_staged`, `color_flags` (`--bold blue`).

⚠ **`show_informative_status` costs real time.** Measured in this repo (6 tracked files, 20 iterations):
plain ≈ 20 ms/prompt, informative + `showuntrackedfiles` ≈ 32 ms/prompt. In a large monorepo it is far
worse — the documented escape hatch is per repository:
`git config --local bash.showInformativeStatus false`. A cheap, informative default:

```fish
# conf.d/git.fish — prompt bits only; no informative status, so no extra git walks
set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showstashstate 1
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_showcolorhints 1
set -g __fish_git_prompt_shorten_branch_len 24
```

## 4. `set_color` — complete

`set_color [OPTIONS] [VALUE]` writes an escape sequence to stdout. It prints nothing else, so it is
safe inside command substitution — but the escapes **are** captured, which is why scripts gate on
`isatty stdout`.

`VALUE` is one of: the 8 base names `black red green yellow blue magenta cyan white`; the 8 bright names
`brblack brred brgreen bryellow brblue brmagenta brcyan brwhite` (`brblack` is grey — *brighter* than
`black`); 3 or 6 hex digits, any case (`set_color 7aa2f7` → `\e[38;2;122;162;247m`, and `2BC`
expands to `22BBCC`); or `normal`, which resets **everything**.

⚠ **A leading `#` is accepted here and rejected in a `.theme` file** — two different parsers, and this
file previously claimed hex must have "no `#`". `set_color '#7aa2f7'` emits the same sequence as
`set_color 7aa2f7` (verified). But a `.theme` file is read with `read -lat`, i.e. fish tokenizer
rules, where `#` starts a **comment** — so `fish_color_normal #a9b1d6` sets the variable to nothing,
silently, because the line still passes the name whitelist. Hence `themes/laramie.fish` keeps the `#`
and `themes/laramie.theme` must not; generate the second from the first with
`.claude/skills/fish/scripts/gen-fish-theme.fish`. See [caveats.md](caveats.md).

| Option | Short | Emits (verified) |
| --- | --- | --- |
| `--foreground COLOR` | `-f` | as bare `VALUE`, but `normal` resets only the foreground |
| `--background COLOR` | `-b` | `\e[48;2;…m` — since 4.1.0 this no longer implies bold |
| `--underline-color COLOR` | — | `\e[58:2::247:118:142m` (4.1.0+) |
| `--bold` | `-o` | `\e[1m` |
| `--dim` | `-d` | `\e[2m` |
| `--italics[=on\|off]` | `-i` | `\e[3m` / `\e[23m` |
| `--reverse[=on\|off]` | `-r` | `\e[7m` / `\e[27m` |
| `--strikethrough[=on\|off]` | `-s` | `\e[9m` / `\e[29m` (4.4.0+) |
| `--underline[=STYLE]` | `-u` | `single \e[4m`, `double \e[4:2m`, `curly \e[4:3m`, `dotted \e[4:4m`, `dashed \e[4:5m`, `off \e[24m` (styles 4.1.0+) |
| `--reset` | — | `\e[m`; accepts a colour in the same call — `set_color --reset green` → `\e[;32m` |
| `--print-colors` | `-c` | list the 16 names + `normal`, each rendered in its own colour |
| `--theme=THEME` | — | ignored as styling; the marker `fish_config theme choose` stamps on variables it owns |

`set_color -c` on a tty (verified under a pty) prints one name per line, each in its own colour —
`black blue brblack brblue brcyan brgreen brmagenta brred brwhite bryellow cyan green magenta red white
yellow normal`. Piped, the same list arrives uncoloured. `set_color -c red 7aa2f7` prints just those.

⚠ **Always reset.** `set_color` changes terminal state until something changes it back; forget it and the
colour bleeds into command output and the next prompt. Prefer `set_color --reset` over `set_color normal`
(less ambiguous, resets the background too). The `string join` pattern in §1 makes the reset structural
rather than something you can forget.

⚠ An unknown name is an error (`set_color: Unknown color 'notacolour'`, status 2), but **no arguments at
all is a silent status-1 no-op** — so `set_color $some_unset_var` degrades quietly.

Truecolour: fish 4.8.1 emits 24-bit sequences unconditionally — `$COLORTERM` has not been required since
4.1.0 (it only appears as the *reason* in `fish -d term_support`). Downgrade explicitly if a terminal
cannot cope: `set -g fish_term24bit 0` → nearest 256-colour (`\e[38;5;111m`), plus
`set -g fish_term256 0` → nearest of 16 (`\e[37m`).

## 5. The `fish_color_*` / `fish_pager_color_*` catalogue

Every variable below is real in 4.8.1 (cross-checked against the manual, the shipped `default.theme`,
and the binary's own variable list). Each takes a colour plus any `set_color` option, e.g.
`set -g fish_color_error f7768e --bold`. Defaults are the values fish's `default` theme applies.

**Syntax highlighting and the default prompt — 26 variables**

| Variable | Colours | Default |
| --- | --- | --- |
| `fish_color_normal` | default text; the fallback for almost everything else | `--reset` |
| `fish_color_command` | commands like `echo` | `--reset` |
| `fish_color_builtin` | builtins like `cd`, `set` | *(unset → `command`)* |
| `fish_color_function` | user-defined functions | *(unset → `command`)* |
| `fish_color_keyword` | keywords like `if` | *(unset → `command`)* |
| `fish_color_param` | ordinary parameters | `cyan` |
| `fish_color_option` | options starting `-`, up to the first `--` | *(unset → `param`)* |
| `fish_color_quote` | quoted text | `yellow` |
| `fish_color_redirection` | `>/dev/null` and friends | `cyan --bold` |
| `fish_color_end` | process separators `;` and `&` | `green` |
| `fish_color_error` | syntax errors | `brred` |
| `fish_color_comment` | `# comments` | `red` |
| `fish_color_operator` | expansion operators `*`, `~` | `brcyan` |
| `fish_color_escape` | escapes `\n`, `\x70` | `brcyan` |
| `fish_color_autosuggestion` | the proposed rest of the command | `brblack` |
| `fish_color_valid_path` | parameters/redirect targets that are existing files | `--underline` |
| `fish_color_selection` | selected text in vi visual mode | `white --background=brblack --bold` |
| `fish_color_search_match` | history search matches and selected pager rows (**background only**) | `white --background=brblack --bold` |
| `fish_color_history_current` | current position in `dirh`/`cdh` listings | `--bold` |
| `fish_color_cwd` | cwd in the default prompt | `green` |
| `fish_color_cwd_root` | cwd in the default prompt when root | `red` |
| `fish_color_user` | username in the default prompt | `brgreen` |
| `fish_color_host` | hostname in the default prompt | `--reset` |
| `fish_color_host_remote` | hostname when the session is remote (ssh) | `yellow` |
| `fish_color_status` | non-zero exit code in the default prompt | `red` |
| `fish_color_cancel` | the `^C` marker on a cancelled commandline | `-r` |

Fallback when a variable is unset or empty after `--theme=` options are subtracted:
`builtin`/`function`/`keyword` → `command` → `normal`; `option` → `param` → `normal`; all else →
`normal`. `valid_path` is additive — a modifiers-only value merges onto the colour that would apply.

**Pager — 13 variables**

| Variable | Colours | Default |
| --- | --- | --- |
| `fish_pager_color_progress` | the progress bar, bottom left | `brwhite --background=cyan --bold` |
| `fish_pager_color_background` | background of a row | *(unset)* |
| `fish_pager_color_prefix` | the part already typed | `--bold --underline` |
| `fish_pager_color_completion` | the proposed rest | *(unset)* |
| `fish_pager_color_description` | the description column | `yellow --italics` |
| `fish_pager_color_selected_background` | background of the selected row | `-r` |
| `fish_pager_color_selected_prefix` | prefix of the selected row | *(unset)* |
| `fish_pager_color_selected_completion` | completion of the selected row | *(unset)* |
| `fish_pager_color_selected_description` | description of the selected row | *(unset)* |
| `fish_pager_color_secondary_background` | background of every second unselected row | *(unset)* |
| `fish_pager_color_secondary_prefix` | prefix, every second row | *(unset)* |
| `fish_pager_color_secondary_completion` | completion, every second row | *(unset)* |
| `fish_pager_color_secondary_description` | description, every second row | *(unset)* |

Unset `secondary_*`/`selected_*` fall back to the plain variable, except `selected_background`, which
tries the *background* of `$fish_color_search_match` first.

⚠ **Do not copy these from older themes — fish 4.8.1 no longer reads any of them:**
`fish_color_background`, `fish_color_match`, `fish_color_statement_terminator`, `fish_color_gray` (the
last still ships in the Catppuccin themes). They pass the `.theme` whitelist and set harmlessly, so a
stale name produces no error and no effect.

## 6. Theme files (`.theme`)

A `.theme` file is a flat list of `NAME value…` lines — like `set NAME value` with **no expansions**
(quotes allowed but unnecessary), plus `#` comments and optional `[light]` / `[dark]` / `[unknown]`
section headers. Only names matching `^fish_(?:pager_)?color_.*$` are accepted.

Head of the shipped `default` theme (`fish -c 'status get-file themes/default.theme'`) — commented lines
document a fallback rather than setting anything:

```
# name: fish default (terminal colors)

fish_color_normal --reset
fish_color_autosuggestion brblack
fish_color_cancel -r
…
# fish_color_keyword $fish_color_command
```

- **Where they live:** `$__fish_config_dir/themes/*.theme`, i.e. `~/.config/fish/themes/`. fish's own
  themes are compiled into the binary — `status list-files themes` lists them, `status get-file
  themes/nord.theme` prints one. There is no `share/fish/themes` directory in 4.x.
- ⚠ `_init.fish` sets `$FISH_THEMES_DIR`. **fish does not read that variable** — `__fish_theme_dir`
  hard-codes `$__fish_config_dir/themes`. Local convenience only; it cannot relocate themes.
- `# name:` and `# preferred_background:` comments feed the web config tool.
- Sectioned themes are colour-theme-aware: `fish_config theme choose` picks the section matching the
  read-only `$fish_terminal_color_theme` (`light`/`dark`/`unknown`, populated only after the first
  interactive prompt) and installs an `--on-variable` handler to re-apply on change. ⚠ A sectionless
  theme applies unconditionally, but passing `--color-theme=light` to one **fails** with
  `failed to find '[light]' section`. Only pass that flag to sectioned themes.

| Command | Does |
| --- | --- |
| `fish_config theme list` | names of all themes, user dir first |
| `fish_config theme show [NAME…]` | render the current theme then each named one |
| `fish_config theme demo` | render sample text in the *current* colours |
| `fish_config theme choose NAME` | apply now, as **global** variables tagged `--theme=NAME` |
| `fish_config theme dump` | print the live theme in `.theme` format (with the `--theme=` tags) |
| `fish_config theme save [NAME]` | *(not recommended)* apply as **universal** variables |

⚠ **`fish_config theme save` writes universal variables** — machine state in `fish_variables`, which
[style-guide.md](style-guide.md) §3 forbids outright. It also forfeits light/dark switching. Never run
it in this repo.

⚠ An unrecognized variable name in a `.theme` file is **silently dropped**: `fish_colour_normal red`
produces no warning, non-zero status, or variable (verified). Spell-check against §5.

**House approach.** fish's shipped `config.fish` runs `fish_config theme choose default --no-override`
*before* sourcing `conf.d/`, so a plain `set -g` in `conf.d/` wins (verified — the global keeps your
value, untagged). Keep the `.theme` file as the readable source of truth for `fish_config theme show`,
and put explicit `set -g` lines in `conf.d/theme.fish` for startup: a `fish_config theme choose` call in
`conf.d/` costs ~5.4 ms per `--profile-startup`; the `set -g` block costs nothing measurable.
Regenerate the block, never hand-sync it:

```sh
fish -c 'fish_config theme choose laramie
    fish_config theme dump |
        string replace -r " --theme=\S+\s*\$" "" |
        string replace -r "^" "set -g "' > /tmp/theme-body.fish
```

```fish
# conf.d/theme.fish — generated from themes/laramie.theme, do not hand-edit
status is-interactive; or return

set -g fish_color_normal a9b1d6
set -g fish_color_command 7aa2f7
# … 37 more lines
```

## 7. Adding laramie to fish

Palette, confirmed against `~/.config/ghostty/themes/laramie` (16-colour palette + bg/fg/selection) and
`~/.config/git/themes.gitconfig` (the `[delta "laramie"]` block):

| From ghostty | Hex | From ghostty | Hex | From delta (extras) | Hex |
| --- | --- | --- | --- | --- | --- |
| background | `1f2335` | red 1/9 | `f7768e` | panel background | `24283b` |
| foreground, palette 7 | `a9b1d6` | green 2/10 | `9ece6a` | line highlight | `292e42` |
| black, palette 0 | `1a1b29` | yellow 3/11 | `e0af68` | dim foreground | `737aa2` |
| brblack 8 (comment) | `414868` | blue 4/12 | `7aa2f7` | teal (diff add) | `73daca` |
| brwhite 15, selection fg | `c0caf5` | magenta 5/13 | `bb9af7` | light grey | `cfc9c2` |
| selection background | `373d5a` | cyan 6/14 | `7dcfff` | | |

laramie's bright variants 9–14 are identical to 1–6; only `brblack` and `brwhite` differ from their base.

⚠ **Superseded by the live config as of 2026-07-29.** `~/.config/fish/themes/laramie.theme` is now
**generated** from `themes/laramie.fish` by `.claude/skills/fish/scripts/gen-fish-theme.fish`, and
`conf.d/colours.fish` is what actually applies the palette at startup. Do not hand-edit either the
`.theme` file or the block below; regenerate. The table below is kept as the design record of which
hex maps to which role.

Deliberately sectionless — laramie is dark-only, and a sectionless theme applies whatever the
terminal reports. Verified: `theme list` shows it, `choose` exits 0 and round-trips
`fish_color_command` as `7aa2f7`.

```
# name: 'Laramie'
# preferred_background: 1f2335

fish_color_normal a9b1d6
fish_color_command 7aa2f7
fish_color_keyword bb9af7
fish_color_builtin 7dcfff
fish_color_function 73daca
fish_color_param a9b1d6
fish_color_option 9ece6a
fish_color_quote e0af68
fish_color_redirection 7dcfff
fish_color_end 737aa2
fish_color_error f7768e
fish_color_comment 414868
fish_color_operator 9ece6a
fish_color_escape bb9af7
fish_color_autosuggestion 414868
fish_color_valid_path --underline
fish_color_selection c0caf5 --background=373d5a
fish_color_search_match --background=373d5a
fish_color_history_current --bold
fish_color_cwd 73daca
fish_color_cwd_root f7768e
fish_color_user 9ece6a
fish_color_host 7aa2f7
fish_color_host_remote e0af68
fish_color_status f7768e
fish_color_cancel -r
fish_pager_color_progress 737aa2
fish_pager_color_background
fish_pager_color_prefix 7dcfff --bold
fish_pager_color_completion a9b1d6
fish_pager_color_description 414868 --italics
fish_pager_color_selected_background --background=373d5a
fish_pager_color_selected_prefix 7dcfff --bold
fish_pager_color_selected_completion c0caf5
fish_pager_color_selected_description 737aa2 --italics
fish_pager_color_secondary_background --background=24283b
fish_pager_color_secondary_prefix 7dcfff
fish_pager_color_secondary_completion a9b1d6
fish_pager_color_secondary_description 414868 --italics
```

Then generate `conf.d/theme.fish` with the pipeline in §6. `fish_color_search_match` carries no
foreground because the docs call it background-only; the selection foreground `c0caf5` matches
ghostty's `selection-foreground` exactly; and empty `fish_pager_color_background` is a deliberate
"inherit the terminal background", the shape the tokyonight themes use.

The sibling gap in `CLAUDE.md` stays open: there is still no laramie **bat** theme, which is why
`delta.syntax-theme = laramie` does not resolve. Not this file's problem.

## 8. Testing colours and prompts

```sh
fish -c 'fish_config theme demo'               # sample text in the current colours
fish -c 'fish_config theme show laramie'       # current, then laramie, side by side
fish -c 'fish_prompt' | cat -v                 # one prompt, escapes visible
fish -c 'false; fish_prompt' | cat -v          # the non-zero-status branch
fish -c 'set_color 7aa2f7 --bold' | cat -v     # -> ^[[38;2;122;162;247;1m
fish -c 'set_color -c'                         # the 16 names, each in its colour

# a theme file in isolation — the user's config cannot mask a mistake
env XDG_CONFIG_HOME=/tmp/sandbox HOME=/tmp/sandbox fish -c 'fish_config theme choose laramie'
fish -c 'fish_config theme choose laramie; fish_config theme dump'   # what it actually set

# startup/prompt cost, attributed line by line
fish --profile-startup=/tmp/fishprof.txt -i -c exit </dev/null
awk 'NR>1 && $2>800 {print $2, substr($0, index($0,$3))}' /tmp/fishprof.txt | sort -rn | head
```

A swatch helper, if one is wanted — an autoloaded function, never a `conf.d` definition:

```fish
# functions/colormap.fish
function colormap --description 'print the 256-colour palette as swatches'
    for i in (seq 0 255)
        printf '\e[48;5;%dm  \e[49m\e[38;5;%dm%03d\e[39m ' $i $i $i
        test (math "($i + 1) % 6") -eq 4; and printf '\n'
    end
end
```

⚠ Colour output is not a tty test. `set_color -c` colours its output only on a terminal; piped, you get
plain names. Force a pty with `script -q /dev/null fish -c '…'` when you need to see the real thing.
`TERM=dumb` disables colour entirely — `set_color 7aa2f7` emits nothing.

⚠ `$fish_terminal_color_theme` is empty until the first interactive prompt has been drawn, so it is
always empty in `fish -c '…'` and in `conf.d/`. Never branch on it at startup.
