function sysctl --wraps sysctl --description 'sysctl, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc sysctl` not `grc command sysctl` so grc finds conf.sysctl.
    if isatty 1; and type -q grc
        grc --colour=on sysctl $argv
    else
        command sysctl $argv
    end
end
