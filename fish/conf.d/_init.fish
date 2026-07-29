# foundation. sorts first in conf.d (`_` beats every letter, digits beat `_`), so anything
# a later snippet depends on belongs here: XDG base dirs, the project dirs, fish's own
# autoload paths, and the core editor/pager environment.

# xdg base dirs
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# conditional, because an exported value is a deliberate choice and must win. `test -n`
# rather than `set -q`: -q is true for a variable set to the empty string, so it cannot
# repair `XDG_CACHE_HOME=''`.
test -n "$XDG_CONFIG_HOME"; or set -gx XDG_CONFIG_HOME $HOME/.config
test -n "$XDG_DATA_HOME"; or set -gx XDG_DATA_HOME $HOME/.local/share
test -n "$XDG_STATE_HOME"; or set -gx XDG_STATE_HOME $HOME/.local/state
test -n "$XDG_CACHE_HOME"; or set -gx XDG_CACHE_HOME $HOME/.cache

# project dirs. ⚠ $DOTFILES is deliberately the same path as $XDG_CONFIG_HOME — the dotfiles
# git repo is rooted at ~/.config itself and the configs are tracked in place, so there is no
# separate checkout to point at.
set -gx PROJECTS $HOME/Projects
set -gx DOTFILES $XDG_CONFIG_HOME
set -gx CLAUDE_CONFIG_DIR $XDG_CONFIG_HOME/claude

# fish dirs
# fish searches $fish_function_path and $fish_complete_path *non-recursively*, so these
# two lines are the only reason functions/<domain>/ and completions/<domain>/ resolve.
# ⚠ the glob is expanded once, here — a subdirectory created later is invisible until
# `exec fish`. an unmatched glob is safe: `set` and `path` expand it to zero arguments.
set -g FISH_THEMES_DIR $__fish_config_dir/themes
set fish_function_path (path resolve $__fish_config_dir/functions/*/) $fish_function_path
set fish_complete_path (path resolve $__fish_config_dir/completions/*/) $fish_complete_path

# one guarded mkdir instead of five unconditional ones. `path filter -vd` keeps only the
# arguments that are *not* already directories, so the steady state costs zero forks.
# this was 6.2 ms of a 63 ms startup, paid by every shell including non-interactive ones.
set -l wanted $XDG_CONFIG_HOME $XDG_DATA_HOME $XDG_STATE_HOME $XDG_CACHE_HOME \
    $PROJECTS $CLAUDE_CONFIG_DIR \
    $__fish_config_dir $FISH_THEMES_DIR $XDG_CACHE_HOME/fish
set -l missing (path filter -vd $wanted)
test -n "$missing"; and mkdir -p $missing

# core environment
# ⚠ VISUAL's `--wait` is load-bearing: `edit_command_buffer` (alt-e) and `funced` return
# immediately without it, and the buffer is never updated.
set -gx PAGER less
set -gx VISUAL code-insiders --new-window --wait
# terminal-side counterpart to VISUAL. gh, sudoedit and git-over-ssh read EDITOR and were
# falling back to vi. conditional so an exported value wins; `test -n` also repairs an empty one.
test -n "$EDITOR"; or set -gx EDITOR micro
set -gx BROWSER open
