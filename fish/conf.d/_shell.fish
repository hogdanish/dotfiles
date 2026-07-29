# interactive shell behaviour — fish itself, nothing else. tool integrations are in
# conf.d/tools.fish, terminal wiring in conf.d/ghostty.fish, colour in conf.d/colours.fish.
#
# ⚠ nothing in this file may `return` except the interactive guard below. it previously
# carried four unrelated concerns behind a `type -q starship; or return 1`, which meant a
# missing starship would have silently taken ghostty integration and the whole of atuin
# with it. one concern per file is what makes that class of bug impossible.

status is-interactive; or return

# greeting. the shipped `fish_greeting` function only prints when $fish_greeting is
# non-empty, so an empty value is enough — no need to override the function itself.
set -g fish_greeting

# suppress the macos login banner. one `touch`, on first run only.
test -f $HOME/.hushlogin; or touch $HOME/.hushlogin

# cursor shape is deliberately not set here: ~/.config/ghostty/config.ghostty owns it
# (`cursor-style = bar`), and fish's $fish_cursor_* variables only take effect under vi
# key bindings, which this config does not use.
