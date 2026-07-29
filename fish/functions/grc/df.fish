function df --wraps df --description 'df, colourised by grc when stdout is a terminal'
    # autoloaded, so there is no startup guard to hang a `type -q` on — check per call.
    # `isatty 1` is what keeps pipes and command substitutions free of ANSI escapes, so
    # `set -l x (df)` still parses.
    # ⚠ `grc df`, not `grc command df`: grc picks its config file by the command NAME, so
    # `grc command df` would look for conf.command and silently emit no colour. no recursion
    # results — grc is a separate process and resolves df from $PATH, where this fish
    # function does not exist.
    if isatty 1; and type -q grc
        grc --colour=on df $argv
    else
        command df $argv
    end
end
