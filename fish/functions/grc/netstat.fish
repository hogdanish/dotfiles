function netstat --wraps netstat --description 'netstat, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc netstat` not `grc command netstat` so grc finds conf.netstat.
    if isatty 1; and type -q grc
        grc --colour=on netstat $argv
    else
        command netstat $argv
    end
end
