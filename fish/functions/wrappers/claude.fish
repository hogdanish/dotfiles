function claude --wraps claude --description 'claude code, with secrets from a 1password environment'
    # why the whole process is wrapped rather than each mcp server:
    # the github plugin ships an HTTP mcp server whose config interpolates
    # `Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}` from the *claude process environment*,
    # and context7's stdio server reads CONTEXT7_API_KEY the same way. neither config is ours to
    # rewrite, so the values have to be present on this process. one prompt per session, nothing
    # on disk. the environment id is an opaque identifier, not a secret — see conf.d/op.fish.
    #
    # claude code's bash tool inherits this environment, which is what makes gh/brew/firecrawl work
    # inside a session; fish functions and `op plugin` aliases never reach it (non-interactive zsh).
    #
    # both guards warn and fall through rather than refusing to run. launching claude without the
    # environment is degraded, but refusing to launch it at all would be worse.
    if not type -q op
        echo >&2 'claude: op is not installed — starting without 1password-provided secrets'
        command claude $argv
        return
    end
    if not set -q __op_claude_env; or test -z "$__op_claude_env"
        echo >&2 'claude: $__op_claude_env is unset — starting WITHOUT the 1password environment.'
        echo >&2 '        set it in conf.d/op.fish: 1Password > Developer > View Environments >'
        echo >&2 '        Manage environment > Copy environment ID'
        command claude $argv
        return
    end

    # ⚠ --no-masking is REQUIRED here, not an optimization.
    # masking works by intercepting the child's stdout/stderr to scan them for secret values, which
    # replaces those fds with pipes. claude code checks for a tty to decide whether it can draw a
    # TUI; with a piped stdout it silently switches to --print mode and dies with
    #   "Input must be provided either through stdin or as a prompt argument when using --print"
    # stdin is left alone, which is why `op run -- /usr/bin/tty` reports a real device and looks
    # like a passing test. masking buys nothing here: claude never echoes these tokens.
    op run --no-masking --environment $__op_claude_env -- claude $argv
end
