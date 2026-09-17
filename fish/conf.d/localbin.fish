# ~/.local/bin on $PATH.
#
# not a tool's config, which is why it is not in one: this is where `uv tool install` symlinks its
# shims — verified with `uv tool dir --bin`, which resolves $XDG_DATA_HOME/../bin. gdtoolkit was
# installed 2026-07-29 and gdformat/gdlint were invisible to fish *and* zsh until this path landed
# on $PATH.
#
# ⚠ this lived in conf.d/uv.fish until 2026-09-01, behind that file's `type -q uv; or return`, then
# had to move here 2026-09-01..2026-09-17 while claude code's native installer also put its launcher
# in this directory — removing uv would otherwise have taken `claude` off $PATH with it. claude code
# moved back to a cask on 2026-09-17 (see .claude/CLAUDE.md), so this directory is uv's alone again,
# but it stays its own file rather than folding back into uv.fish: one concern per file, for exactly
# the reason _shell.fish's header gives.
#
# uv itself needs nothing here: it is already xdg-correct on macos, and its behaviour (as opposed
# to location) lives in $XDG_CONFIG_HOME/uv/uv.toml — see that file's header.
#
# ⚠ the path is a literal. `uv tool dir --bin` is a fork, and this file is sourced by every shell
# including non-interactive ones — java.fish makes the same trade for the same reason.

set -l local_bin $HOME/.local/bin

# ⚠ fish_add_path silently skips a directory that does not exist — it returns 1 and emits no `set`.
# without this the first `uv tool install` on a fresh machine lands somewhere off $PATH.
test -d $local_bin; or mkdir -p $local_bin

# ⚠ sorts after brew.fish, which is load-bearing: brew.fish resets `set -g fish_user_paths`, so an
# entry added before it would be discarded. `-g` is explicit so the call can never resolve to a
# universal.
#
# ⚠ `-a`, because fish_add_path *prepends* by default — without it a shim here would shadow the
# homebrew binary of the same name, and the Brewfile is the machine's inventory.
fish_add_path -g -a $local_bin
