function claude --wraps claude --description 'claude code, with secrets from a 1password environment'
    set -l claude_args
    set -l infra_mode 0
    for arg in $argv
        if test "$arg" = --infra
            set infra_mode 1
        else
            set -a claude_args "$arg"
        end
    end

    # why the whole process is wrapped rather than each mcp server:
    # the github plugin ships an HTTP mcp server whose config interpolates
    # `Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}` from the *claude process environment*.
    # that config is not ours to rewrite, so the value has to be present on this process. one prompt
    # per session, nothing on disk. the environment id is an opaque identifier, not a secret — see
    # conf.d/op.fish.
    #
    # ⚠ context7 needs nothing here since 2026-07-30. it used to be a plugin spawning
    # `npx -y @upstash/context7-mcp`, a local stdio server reading CONTEXT7_API_KEY off this
    # environment; it is now a claude.ai connector, authenticated server-side and account-level.
    # do not reintroduce that plugin — see claude-code/CLAUDE.md.
    #
    # claude code's bash tool inherits this environment, which is what makes gh/firecrawl work inside
    # a session; fish functions and `op plugin` aliases never reach it (non-interactive zsh). linode
    # uses the direct item reference below because its pat is not duplicated into the environment.
    #
    # both guards warn and fall through rather than refusing to run. launching claude without the
    # environment is degraded, but refusing to launch it at all would be worse.
    if not type -q op
        if test $infra_mode -eq 1
            echo >&2 'claude: --infra requires op; refusing to start an unauthenticated infrastructure session'
            return 127
        end
        echo >&2 'claude: op is not installed — starting without 1password-provided secrets'
        command claude $claude_args
        return
    end
    if not set -q __op_claude_env; or test -z "$__op_claude_env"
        echo >&2 'claude: $__op_claude_env is unset — starting WITHOUT the 1password environment.'
        echo >&2 '        set it in conf.d/op.fish: 1Password > Developer > View Environments >'
        echo >&2 '        Manage environment > Copy environment ID'
        if test $infra_mode -eq 1
            return 1
        end
        command claude $claude_args
        return
    end

    # make the official cli available without loading linode's large mcp schema catalogue.
    if set -q __op_linode_pat_ref; and test -n "$__op_linode_pat_ref"
        set -lx LINODE_CLI_TOKEN "$__op_linode_pat_ref"
    end

    if test $infra_mode -eq 1
        if not set -q __op_linode_pat_ref; or test -z "$__op_linode_pat_ref"
            echo >&2 'claude: --infra requested, but $__op_linode_pat_ref is unset'
            return 1
        end
        set -l linode_mcp_config "$XDG_CONFIG_HOME/claude-code/mcp/linode.json"
        if not test -f "$linode_mcp_config"
            echo >&2 "claude: linode mcp config is missing: $linode_mcp_config"
            return 1
        end
        set -lx LINODE_API_TOKEN "$__op_linode_pat_ref"
        # --mcp-config accepts multiple values greedily, so keep it last or it consumes the prompt
        # and subcommand as more config paths.
        set -a claude_args --mcp-config "$linode_mcp_config"
    end

    # ⚠ --no-masking is REQUIRED here, not an optimization.
    # masking works by intercepting the child's stdout/stderr to scan them for secret values, which
    # replaces those fds with pipes. claude code checks for a tty to decide whether it can draw a
    # TUI; with a piped stdout it silently switches to --print mode and dies with
    #   "Input must be provided either through stdin or as a prompt argument when using --print"
    # stdin is left alone, which is why `op run -- /usr/bin/tty` reports a real device and looks
    # like a passing test. masking buys nothing here: claude never echoes these tokens.
    op run --no-masking --environment $__op_claude_env -- claude $claude_args
end
