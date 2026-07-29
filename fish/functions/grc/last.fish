function last --wraps last --description 'last, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc last` not `grc command last` so grc finds conf.last.
    if isatty 1; and type -q grc
        grc --colour=on last $argv
    else
        command last $argv
    end
end
