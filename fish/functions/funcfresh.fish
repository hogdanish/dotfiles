function funcfresh --description 'reload a function from its file without restarting the shell'
    argparse c/cache -- $argv; or return

    # --cache: drop the cachecmd store so the next shell regenerates every tool init.
    # useful after a `brew upgrade` that a mtime comparison somehow missed (homebrew bottles
    # preserve build-machine mtimes, so a *downgrade* can install a binary older than the cache).
    if set -q _flag_cache
        set -l cachedir $XDG_CACHE_HOME/fish/cachecmd
        test -n "$XDG_CACHE_HOME"; or set cachedir $HOME/.cache/fish/cachecmd
        command rm -rf $cachedir
        echo "cleared $cachedir"
        test (count $argv) -eq 0; and return 0
    end

    if test (count $argv) -ne 1
        echo >&2 'funcfresh: expected exactly one function name'
        return 2
    end

    # `functions --details` reports the defining file — the whole trick.
    set -l file (functions --details $argv[1])
    if test -f "$file"
        source $file; and echo "reloaded $argv[1] from $file"
        return
    end

    # not loaded yet (or defined interactively): fall back to scanning the autoload path
    for dir in $fish_function_path
        if test -f $dir/$argv[1].fish
            source $dir/$argv[1].fish; and echo "reloaded $argv[1] from $dir/$argv[1].fish"
            return
        end
    end

    echo >&2 "funcfresh: no file found for '$argv[1]'"
    return 1
end
