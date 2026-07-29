# terminal integration (ghostty). split out of _shell.fish so a problem here cannot take
# the rest of the interactive setup with it.
#
# ghostty auto-injects this snippet by prepending its own directory to $XDG_DATA_DIRS, which
# puts it on $__fish_vendor_confdirs — but the snippet strips that entry once loaded, so a
# *nested* fish inherits the stripped value and gets nothing. sourcing it manually here is
# what covers nested shells; the top-level shell just loads it twice, which is safe because
# the snippet is re-entrant. see references/caveats.md.

status is-interactive; or return

# `test -r` covers both cases: an unset $GHOSTTY_RESOURCES_DIR (the path collapses to
# /shell-integration/... and is unreadable) and a ghostty install whose layout has moved.
# unguarded, this printed `source: No such file or directory` in every non-ghostty shell.
set -l ghostty_init "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
test -r "$ghostty_init"; or return
source $ghostty_init

# ⚠ not load-bearing for fish — since 4.1.0 `set_color <hex>` emits 24-bit sequences
# unconditionally. it is set for the TUIs that still sniff it (see references/caveats.md),
# and only once we know we are actually in ghostty.
set -gx COLORTERM truecolor
