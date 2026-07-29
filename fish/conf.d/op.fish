# 1password — the ssh agent socket and cli wiring.
#
# the shell-plugin credentials for gh and brew live in ~/.config/op/plugins/*.json and need no
# wiring here. ⚠ do NOT source ~/.config/op/plugins.sh — `op plugin init` writes posix shell
# functions (`gh() { ... }`) regardless of the invoking shell, and it does not parse as fish.
# the fish side is functions/gh.fish and functions/brew.fish instead.

# ssh agent
# ~/.ssh/config sets IdentityAgent, which covers ssh(1) and everything that reads ssh_config.
# this is for the clients that only honour the environment variable — without it they get
# apple's launchd agent, which holds no keys.
set -l op_agent_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
test -S "$op_agent_sock"; and set -gx SSH_AUTH_SOCK "$op_agent_sock"

# claude code
# the "Claude Code" 1password environment, read by functions/claude.fish. an environment id is an
# opaque identifier, not a credential — safe to commit. -g, not -gx: only fish reads it.
set -g __op_claude_env uiba73phjvsgnivopa7bujlpbq
