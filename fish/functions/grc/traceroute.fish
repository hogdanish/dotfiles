function traceroute --wraps traceroute --description 'traceroute, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc traceroute` not `grc command traceroute` so grc finds conf.traceroute.
    if isatty 1; and type -q grc
        grc --colour=on traceroute $argv
    else
        command traceroute $argv
    end
end
