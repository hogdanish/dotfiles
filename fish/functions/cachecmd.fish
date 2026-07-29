# cache the output of a slow command to disk, so a `<tool> init fish` fork becomes a
# `builtin source`. adapted from mattmc3/fishconf with the fixes its version lacks: the
# cache lives outside the config dir, it invalidates when its inputs change, a failed
# command is never cached, and a failure never costs you the cache you already had.

function cachecmd --description "cache a command's output, then source or print the cache"
    # ⚠ --stop-nonopt is load-bearing: without it argparse chokes on the *tool's* own flags,
    # e.g. `cachecmd --source fzf --fish`. it also means our flags must come FIRST — written
    # last they are passed through to the tool and this silently prints instead of sourcing.
    argparse --stop-nonopt s/source d/depends=+ c/clear -- $argv; or return

    if test (count $argv) -eq 0
        echo >&2 'cachecmd: expected a command'
        return 2
    end

    # $XDG_CACHE_HOME may be unset here: this is reachable from an autoloaded completion in
    # a shell that never sourced conf.d/_init.fish, and the path would become /fish/...
    set -l cachedir $XDG_CACHE_HOME/fish/cachecmd
    test -n "$XDG_CACHE_HOME"; or set cachedir $HOME/.cache/fish/cachecmd

    # slugify the whole argv into a filename, so `fzf --fish` and `fzf --zsh` differ:
    # `starship init fish --print-full-init` -> starship_init_fish_print_full_init.fish
    set -l slug (string join _ -- $argv | string replace -ar '[^a-zA-Z0-9]+' _ | string trim -c _ | string lower)
    set -l cachefile $cachedir/$slug.fish

    set -q _flag_clear; and command rm -f $cachefile

    # invalidate when any input is newer than the cache — this is what makes `brew upgrade`
    # take effect instead of serving a stale init forever.
    # ⚠ `command -s` yields nothing for a fish function and resolves the *wrong* binary for
    # `command`, so --depends is the escape hatch for a generator that is not a plain binary
    # or that reads a config file (e.g. atuin reads ~/.config/atuin/config.toml).
    set -l deps $_flag_depends (command -s $argv[1])
    set -l stale 0
    test -s $cachefile; or set stale 1
    for dep in (path filter -- $deps)
        if test $dep -nt $cachefile
            set stale 1
            break
        end
    end

    if test $stale -eq 1
        command mkdir -p $cachedir
        # write to a temp file and rename: a concurrent shell never sources a half-written
        # cache, and a command that produced nothing never becomes a 0-byte cache that
        # `test -s` would then accept forever. stderr is deliberately not swallowed — the
        # miss path runs about once per upgrade, and a silent failure is worse than noise.
        set -l tmp $cachefile.$fish_pid.part
        if $argv >$tmp; and test -s $tmp
            command mv -f $tmp $cachefile
        else
            command rm -f $tmp
            # a stale cache beats no cache: a transient tool failure must not cost you your
            # prompt or your history bindings for the rest of the session.
            if test -s $cachefile
                echo >&2 "cachecmd: '$argv' failed; keeping the previous cache"
            else
                echo >&2 "cachecmd: '$argv' produced nothing; not caching"
                return 1
            end
        end
    end

    # ⚠ `source` with no argument reads *stdin*, hits EOF and returns 0 under every
    # redirected check, and errors only on a real tty. guard rather than trust the path.
    test -s $cachefile; or return 1
    if set -q _flag_source
        builtin source $cachefile
    else
        # `command`: functions/grc/ may define wrappers that are autoloadable during
        # conf.d sourcing, exactly like the functions/brew.fish trap.
        command cat $cachefile
    end
end
