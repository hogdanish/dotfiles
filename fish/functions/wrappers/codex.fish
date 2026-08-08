function codex --wraps codex --description 'codex, with development secrets from 1password'
    # codex itself keeps its chatgpt oauth login. this environment supplies credentials to
    # tools the agent launches, without writing them to shell config or codex config.
    if not type -q op
        echo >&2 'codex: op is not installed — starting without 1password-provided secrets'
        command codex $argv
        return
    end
    if not set -q __op_codex_env; or test -z "$__op_codex_env"
        echo >&2 'codex: $__op_codex_env is unset — starting without the 1password environment'
        command codex $argv
        return
    end

    # masking replaces stdout and stderr with pipes, which breaks the interactive tui.
    op run --no-masking --environment $__op_codex_env -- codex $argv
end
