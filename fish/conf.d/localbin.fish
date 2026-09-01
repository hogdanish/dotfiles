# ~/.local/bin on $PATH.
#
# not a tool's config, which is why it is not in one: this is the directory two unrelated
# installers write into, and it must be on $PATH whether or not either of them is present.
#   • `uv tool install` symlinks its shims here — verified with `uv tool dir --bin`, which
#     resolves $XDG_DATA_HOME/../bin. gdtoolkit was installed 2026-07-29 and gdformat/gdlint
#     were invisible to fish *and* zsh until that path landed on $PATH.
#   • claude code's native installer puts its launcher here
#     (~/.local/bin/claude -> ~/.local/share/claude/versions/<version>).
#
# ⚠ this lived in conf.d/uv.fish until 2026-09-01, behind that file's `type -q uv; or return`.
# harmless while uv owned the directory; a latent outage once claude code left the Brewfile for
# the self-updating native installer, because removing uv would have taken `claude` off $PATH
# with it. one concern per file, for exactly the reason _shell.fish's header gives.
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
