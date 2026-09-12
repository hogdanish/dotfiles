function clauth --wraps clauth --description 'clauth; a `start` session gets the authored claude settings'
    # `clauth start <profile> [claude args…]` forwards anything clauth does not recognise to the
    # claude it spawns, verbatim. that is the only hook a clauth-launched session has for the
    # settings wrappers/claude.fish passes, because there is deliberately no settings.json in the
    # claude config dir for it to inherit — see that file's header for why.
    #
    # every other subcommand is passed through untouched: the tui, switch, daemon, mcp and herdr
    # all take no claude arguments, and handing them an unknown flag would be an error.
    #
    # ⚠ invisible to agents and to the herdr plugin — both reach clauth as a real binary through a
    # non-interactive shell. neither runs `clauth start`, so neither needs this.
    # ⚠ appended last, so a preceding VARIADIC claude flag (--mcp-config, --allowedTools) would
    # swallow the path. put such a flag after `--`, or pass --settings yourself.
    if test "$argv[1]" = start
        set -l settings $XDG_CONFIG_HOME/claude-code/settings.json
        if test -r $settings
            command clauth $argv --settings $settings
            return
        end
        echo >&2 "clauth: $settings is unreadable — the session gets NO authored settings"
    end

    command clauth $argv
end
