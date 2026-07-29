function lsof --wraps lsof --description 'lsof, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc lsof` not `grc command lsof` so grc finds conf.lsof.
    if isatty 1; and type -q grc
        grc --colour=on lsof $argv
    else
        command lsof $argv
    end
end
