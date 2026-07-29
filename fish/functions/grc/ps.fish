function ps --wraps ps --description 'ps, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc ps` not `grc command ps` so grc finds conf.ps.
    if isatty 1; and type -q grc
        grc --colour=on ps $argv
    else
        command ps $argv
    end
end
