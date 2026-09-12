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
# ⚠ claude code's config dir is state, not config: transcripts, prompt history and vendored
# plugins — ~48 mb of it, and it has held plaintext credentials that were `cat`-ed into a
# session. it lives under $XDG_STATE_HOME so it is not inside a public repo's working tree, and
# the hand-authored files symlink back to $XDG_CONFIG_HOME/claude-code/, which is what is tracked.
#
# ⚠ NO `set -gx CLAUDE_CONFIG_DIR` HERE, AND IT MUST NOT COME BACK (removed 2026-09-12). the
# directory is unchanged — $HOME/.claude is now a SYMLINK to it — but the variable is gone,
# because claude code namespaces its macos keychain item as
# `Claude Code-credentials-<sha256(dir)[0:8]>` whenever it is set, and the bare
# `Claude Code-credentials` only when it is not. clauth and every other account manager read the
# bare item and hardcode ~/.claude, so any value at all hides the live login from them. setting
# it to $HOME/.claude does NOT help: that is still a hash. see .claude/CLAUDE.md.
# codex does not split config from state. keep its desktop-compatible root at ~/.codex;
# authored files inside it symlink back to $XDG_CONFIG_HOME/codex.
test -n "$CODEX_HOME"; or set -gx CODEX_HOME $HOME/.codex

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
    $PROJECTS $XDG_STATE_HOME/claude $CODEX_HOME \
    $__fish_config_dir $FISH_THEMES_DIR $XDG_CACHE_HOME/fish
set -l missing (path filter -vd $wanted)
test -n "$missing"; and mkdir -p $missing

# authenticated multiplexed ssh connections live here; keep other local users out of the directory.
set -l ssh_control_dir $XDG_CACHE_HOME/ssh/control
test -d $ssh_control_dir; or mkdir -m 700 -p $ssh_control_dir

# core environment
# ⚠ VISUAL's `--wait` is load-bearing: `edit_command_buffer` (alt-e) and `funced` return
# immediately without it, and the buffer is never updated.
set -gx PAGER less
set -gx VISUAL code-insiders --new-window --wait
# terminal-side counterpart to VISUAL. gh, sudoedit and git-over-ssh read EDITOR and were
# falling back to vi. conditional so an exported value wins; `test -n` also repairs an empty one.
test -n "$EDITOR"; or set -gx EDITOR micro
set -gx BROWSER open

# ⚠ $SHELL is inherited, never derived — nothing re-reads the passwd entry after login, so `chsh`
# does not reach a gui session that is already running. ghostty starts the shell through
# `login -flp` and `-p` *preserves the environment*, so the stale `/bin/zsh` captured at the last
# macos login survived into every fish started since the 2026-09-12 chsh. anything resolving a
# shell from $SHELL (herdr through portable-pty, vs code, tmux) therefore spawned zsh. fish is the
# one process that knows which fish is running, so it is the right place to publish it.
# ⚠ not `status fish-path` — that is the version-pinned cellar path, which `brew cleanup` deletes
# out from under a long-running herdr. login-only: a nested non-login fish is not the user's shell.
set -l __fish_bin (command -s fish)
test -n "$__fish_bin"; and status is-login; and set -gx SHELL $__fish_bin
