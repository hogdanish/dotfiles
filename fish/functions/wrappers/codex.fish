function codex --wraps codex --description 'codex, with development secrets from 1password'
    set -l codex_args
    set -l infra_mode 0
    for arg in $argv
        if test "$arg" = --infra
            set infra_mode 1
        else
            set -a codex_args "$arg"
        end
    end

    # codex itself keeps its chatgpt oauth login. this environment supplies credentials to
    # tools the agent launches, without writing them to shell config or codex config.
    if not type -q op
        if test $infra_mode -eq 1
            echo >&2 'codex: --infra requires op; refusing to start an unauthenticated infrastructure session'
            return 127
        end
        echo >&2 'codex: op is not installed — starting without 1password-provided secrets'
        command codex $codex_args
        return
    end
    if not set -q __op_codex_env; or test -z "$__op_codex_env"
        echo >&2 'codex: $__op_codex_env is unset — starting without the 1password environment'
        if test $infra_mode -eq 1
            return 1
        end
        command codex $codex_args
        return
    end

    # agent subprocesses cannot see the interactive fish shell plugin. resolve the official cli
    # credential for every session while keeping the large mcp schema catalogue opt-in.
    if set -q __op_linode_pat_ref; and test -n "$__op_linode_pat_ref"
        set -lx LINODE_CLI_TOKEN "$__op_linode_pat_ref"
    end

    if test $infra_mode -eq 1
        if not set -q __op_linode_pat_ref; or test -z "$__op_linode_pat_ref"
            echo >&2 'codex: --infra requested, but $__op_linode_pat_ref is unset'
            return 1
        end
        set -lx LINODE_API_TOKEN "$__op_linode_pat_ref"
        set -p codex_args infra
        set -p codex_args --profile
    end

    # masking replaces stdout and stderr with pipes, which breaks the interactive tui.
    op run --no-masking --environment $__op_codex_env -- codex $codex_args
end
