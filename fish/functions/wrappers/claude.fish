function claude --wraps claude --description 'claude code with 1password secrets; --firefox/--safari add browser control'
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
    # ⚠ the firecrawl plugin (enabled for every session as of 2026-08-28) rests on that
    # inheritance: its ten skills shell out to `firecrawl`, which reads FIRECRAWL_API_KEY off this
    # process. the fish wrapper of the same name is invisible to an agent, so without the
    # environment every one of them fails on a missing key.
    #
    # both guards warn and fall through rather than refusing to run. launching claude without the
    # environment is degraded, but refusing to launch it at all would be worse.
    #
    # the cloudflare plugin (skills + cloudflare-api mcp) is enabled for every session in
    # claude-code/settings.json as of 2026-08-28 and is no longer gated. --infra is still
    # swallowed here so muscle memory — and the codex wrapper, where the flag still means
    # something — never reaches claude as an unknown option. the credential broker below
    # serves `cf` and `linode-cli` in every session either way.
    #
    # --firefox / --safari load a browser-control mcp server for THIS LAUNCH ONLY, via
    # --mcp-config. both are off by default on purpose: firefox-devtools is 45 tool descriptions
    # in the `developer` preset and safari is 17, and almost no session drives a browser. nothing
    # is added to enabledMcpjsonServers and neither belongs in a project .mcp.json — the flag is
    # the whole enable mechanism, so an ordinary session pays nothing.
    # ⚠ neither is headless. headless firefox resolves requestAdapter() to NULL on this machine,
    # so a window has to appear for webgpu to exist at all. see claude-code/mcp/*.json.
    set -l args
    set -l mcp
    for a in $argv
        switch $a
            case --infra
                echo >&2 'claude: --infra is a no-op — the cloudflare plugin is enabled by default'
            case --firefox
                set -a mcp "$XDG_CONFIG_HOME/claude-code/mcp/firefox-devtools.json"
            case --safari
                set -a mcp "$XDG_CONFIG_HOME/claude-code/mcp/safari.json"
            case '*'
                set -a args $a
        end
    end

    for f in $mcp
        if not test -r $f
            echo >&2 "claude: missing mcp declaration $f"
            return 1
        end
    end
    # appended, never prepended: --mcp-config is variadic, so anything following it on the command
    # line would be swallowed as another config path.
    test (count $mcp) -gt 0; and set -a args --mcp-config $mcp

    # deferred tools: tool names go into context up front and a schema is fetched only when it is
    # actually needed, instead of every mcp/plugin schema being inlined every turn. this is claude
    # code's default as of 2.1.250 (unset => mode "tst"), so the pin only guards the default from
    # flipping under us — `false`/`0`/`no`/`off` is what turns it off, and so does
    # CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS.
    set -fx ENABLE_TOOL_SEARCH true

    if not type -q op
        echo >&2 'claude: op is not installed — starting without 1password-provided secrets'
        command claude $args
        return
    end
    if not set -q __op_claude_env; or test -z "$__op_claude_env"
        echo >&2 'claude: $__op_claude_env is unset — starting WITHOUT the 1password environment.'
        echo >&2 '        set it in conf.d/op.fish: 1Password > Developer > View Environments >'
        echo >&2 '        Manage environment > Copy environment ID'
        command claude $args
        return
    end

    # resolve cli credentials once. the broker keeps them out of the agent and in memory.
    if set -q __op_linode_pat_ref; and test -n "$__op_linode_pat_ref"
        set -fx LINODE_CLI_TOKEN "$__op_linode_pat_ref"
    end
    if set -q __op_cloudflare_api_ref; and test -n "$__op_cloudflare_api_ref"
        set -fx CLOUDFLARE_API_TOKEN "$__op_cloudflare_api_ref"
    end

    # ⚠ --no-masking is REQUIRED here, not an optimization.
    # masking works by intercepting the child's stdout/stderr to scan them for secret values, which
    # replaces those fds with pipes. claude code checks for a tty to decide whether it can draw a
    # TUI; with a piped stdout it silently switches to --print mode and dies with
    #   "Input must be provided either through stdin or as a prompt argument when using --print"
    # stdin is left alone, which is why `op run -- /usr/bin/tty` reports a real device and looks
    # like a passing test. masking buys nothing here: claude never echoes these tokens.
    op run --no-masking --environment $__op_claude_env -- \
        /opt/homebrew/bin/bun "$XDG_CONFIG_HOME/scripts/internal/agent-credential-broker.mjs" \
        supervise claude $args
end
