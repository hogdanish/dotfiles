function du --wraps du --description 'du, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc du` not `grc command du` so grc finds conf.du.
    if isatty 1; and type -q grc
        grc --colour=on du $argv
    else
        command du $argv
    end
end
