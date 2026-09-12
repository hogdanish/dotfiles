# clauth — claude code account switcher, usage monitor and auto-switch chain.
# installed with `cargo install clauth` into $CARGO_HOME/bin; see the Brewfile entry.

# ⚠ `command -q`, not `type -q`: functions/wrappers/clauth.fish shadows the name, so `type -q`
# is true whether or not the binary is actually installed.
command -q clauth; or return

# the daemon carries no external surface by default and none is wanted here. this pins that
# shut regardless of what a --listen ever ends up in a plist or a stray invocation.
set -gx CLAUTH_NO_API 1

# completions are installed deliberately (`clauth completions install fish`), so the first-run
# prompt has nothing left to ask for. ⚠ it would otherwise write to fish's completions dir on
# the first tui launch, unasked.
set -gx CLAUTH_NO_COMPLETIONS 1
