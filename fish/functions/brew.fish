function brew --wraps brew --description 'brew with a github pat supplied by the 1password shell plugin'
    # the token only affects github api access (rate limits on search, tap updates, bundle), so a
    # missing op is a soft failure, not a hard one.
    # ⚠ conf.d/brew.fish must never call bare `brew` — this function is autoloadable during
    # conf.d sourcing, and would turn every shell start into a 1password prompt. use `command brew`.
    if not type -q op
        command brew $argv
        return
    end
    op plugin run -- brew $argv
end
