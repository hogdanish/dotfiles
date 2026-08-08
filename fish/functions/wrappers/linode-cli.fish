function linode-cli --wraps linode-cli --description 'linode cli with its 1password shell plugin'
    # claude and codex resolve this once in their parent `op run`, with or without the linode mcp.
    # Reuse the inherited value so a nested fish shell does not raise another Touch ID prompt.
    # An unresolved op:// locator is not a credential and must still go through 1Password.
    if set -q LINODE_CLI_TOKEN; and test -n "$LINODE_CLI_TOKEN"; and not string match -q 'op://*' -- "$LINODE_CLI_TOKEN"
        command linode-cli $argv
        return
    end

    if not type -q op
        echo >&2 'linode-cli: op is not installed; no api token available'
        return 127
    end

    op plugin run -- linode-cli $argv
end
