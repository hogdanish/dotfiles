function ifconfig --wraps ifconfig --description 'ifconfig, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc ifconfig` not `grc command ifconfig` so grc finds conf.ifconfig.
    if isatty 1; and type -q grc
        grc --colour=on ifconfig $argv
    else
        command ifconfig $argv
    end
end
