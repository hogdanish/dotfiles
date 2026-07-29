function mount --wraps mount --description 'mount, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc mount` not `grc command mount` so grc finds conf.mount.
    if isatty 1; and type -q grc
        grc --colour=on mount $argv
    else
        command mount $argv
    end
end
