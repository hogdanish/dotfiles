# uv — put `uv tool install` shims on $PATH.
#
# uv needs no UV_* variables here: it is already xdg-correct on macos, and behaviour (as opposed to
# location) lives in $XDG_CONFIG_HOME/uv/uv.toml — see that file's header. the one thing it does not
# do for itself is make its tool shims reachable. `uv tool install` symlinks into ~/.local/bin
# (verified with `uv tool dir --bin`, which resolves $XDG_DATA_HOME/../bin), and nothing on this
# machine put that directory on $PATH: gdtoolkit was installed 2026-07-29 and gdformat/gdlint were
# invisible to fish *and* zsh until this file landed.
#
# ⚠ the path is a literal. `uv tool dir --bin` is a fork, and this file is sourced by every shell
# including non-interactive ones — java.fish makes the same trade for the same reason.

type -q uv; or return

set -l uv_bin $HOME/.local/bin

# ⚠ fish_add_path silently skips a directory that does not exist — it returns 1 and emits no `set`.
# without this the first `uv tool install` on a fresh machine lands somewhere off $PATH.
test -d $uv_bin; or mkdir -p $uv_bin

# sorts after brew.fish, which is load-bearing: brew.fish resets `set -g fish_user_paths`, so an
# entry added before it would be discarded. `-g` is explicit so the call can never resolve to a
# universal.
#
# ⚠ `-a`, because fish_add_path *prepends* by default — without it a `uv tool install` shim would
# shadow the homebrew binary of the same name, and the Brewfile is the machine's inventory.
fish_add_path -g -a $uv_bin
