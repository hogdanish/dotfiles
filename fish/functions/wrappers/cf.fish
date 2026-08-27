function cf --wraps cf --description 'cloudflare cli, with agent session authentication'
    if set -q AGENT_INFRA_BROKER_SOCKET; and test -S "$AGENT_INFRA_BROKER_SOCKET"
        command "$XDG_CONFIG_HOME/scripts/agent-bin/cf" $argv
        return
    end

    command cf $argv
end
