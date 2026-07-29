function gh --wraps gh --description 'gh with a github pat supplied by the 1password shell plugin'
    # `op plugin run` resolves the real binary from $PATH in a fresh process, so this does not
    # recurse. claude code's bash tool runs zsh and never sees this function — it gets GH_TOKEN
    # from the 1password environment instead (see functions/claude.fish).
    if not type -q op
        echo >&2 'gh: op is not installed; falling back to an unauthenticated gh'
        command gh $argv
        return
    end
    op plugin run -- gh $argv
end
