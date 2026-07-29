function uptime --wraps uptime --description 'uptime, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc uptime` not `grc command uptime` so grc finds conf.uptime.
    if isatty 1; and type -q grc
        grc --colour=on uptime $argv
    else
        command uptime $argv
    end
end
