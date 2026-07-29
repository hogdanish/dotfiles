function ping --wraps ping --description 'ping, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc ping` not `grc command ping` so grc finds conf.ping.
    if isatty 1; and type -q grc
        grc --colour=on ping $argv
    else
        command ping $argv
    end
end
