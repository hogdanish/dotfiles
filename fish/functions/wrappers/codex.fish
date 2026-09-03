function codex --wraps codex --description 'codex with 1password secrets; --infra, --firefox, --safari'
    # codex itself keeps its chatgpt oauth login. this environment supplies credentials to
    # tools the agent launches, without writing them to shell config or codex config.
    # --infra re-enables the cloudflare plugin and the cloudflare-api mcp server, which
    # codex/config.toml disables by default to keep their weight out of ordinary sessions.
    # `-c` overrides outrank the config file. the credential broker below serves `cf`
    # and `linode-cli` in every session either way.
    # --firefox / --safari flip the two browser-control mcp servers on for this launch only.
    # codex/config.toml declares both with `enabled = false` — the same gating shape as
    # cloudflare-api — because firefox-devtools is 45 tool descriptions and safari 17, and almost
    # no session drives a browser. ⚠ neither runs headless: headless firefox resolves
    # requestAdapter() to NULL on this machine, so a window has to appear for webgpu to exist.
    set -l args
    set -l overlay
    for a in $argv
        switch $a
            case --infra
                set -a overlay -c 'plugins."cloudflare@openai-curated".enabled=true' \
                    -c 'mcp_servers.cloudflare-api.enabled=true'
            case --firefox
                set -a overlay -c 'mcp_servers.firefox-devtools.enabled=true'
            case --safari
                set -a overlay -c 'mcp_servers.safari.enabled=true'
            case '*'
                set -a args $a
        end
    end

    if not type -q op
        echo >&2 'codex: op is not installed — starting without 1password-provided secrets'
        command codex $overlay $args
        return
    end
    if not set -q __op_codex_env; or test -z "$__op_codex_env"
        echo >&2 'codex: $__op_codex_env is unset — starting without the 1password environment'
        command codex $overlay $args
        return
    end

    # resolve cli credentials once. the broker keeps them out of the agent and in memory.
    if set -q __op_linode_pat_ref; and test -n "$__op_linode_pat_ref"
        set -fx LINODE_CLI_TOKEN "$__op_linode_pat_ref"
    end
    if set -q __op_cloudflare_api_ref; and test -n "$__op_cloudflare_api_ref"
        set -fx CLOUDFLARE_API_TOKEN "$__op_cloudflare_api_ref"
    end

    # masking replaces stdout and stderr with pipes, which breaks the interactive tui.
    op run --no-masking --environment $__op_codex_env -- \
        /opt/homebrew/bin/bun "$XDG_CONFIG_HOME/scripts/internal/agent-credential-broker.mjs" \
        supervise codex $overlay $args
end
