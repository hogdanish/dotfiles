function whois --wraps whois --description 'whois, colourised by grc when stdout is a terminal'
    # see grc/df.fish for why this shape: per-call guard (autoloaded, no startup hook),
    # isatty so pipes stay clean, and `grc whois` not `grc command whois` so grc finds conf.whois.
    if isatty 1; and type -q grc
        grc --colour=on whois $argv
    else
        command whois $argv
    end
end
