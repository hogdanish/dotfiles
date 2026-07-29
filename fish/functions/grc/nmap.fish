function nmap --wraps nmap --description 'nmap, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc nmap` not `grc command nmap` so grc finds conf.nmap.
    if isatty 1; and type -q grc
        grc --colour=on nmap $argv
    else
        command nmap $argv
    end
end
