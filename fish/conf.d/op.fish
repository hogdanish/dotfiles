# 1password — the ssh agent socket and cli wiring.
#
# the shell-plugin credentials live in ~/.config/op/plugins/*.json and need no wiring here.
# ⚠ do NOT source ~/.config/op/plugins.sh — `op plugin init` writes posix shell functions
# (`gh() { ... }`) regardless of the invoking shell, and it does not parse as fish. the fish side
# is one autoloaded function per cli in functions/wrappers/. `gh` and `linode-cli` are live; the brew
# wrapper was removed 2026-07-30 because HOMEBREW_GITHUB_API_TOKEN buys nothing post-homebrew-4 and
# cost a prompt per session. brew.json is therefore orphaned plugin state.

# ssh agent
# ~/.ssh/config sets IdentityAgent, which covers ssh(1) and everything that reads ssh_config.
# this is for the clients that only honour the environment variable — without it they get
# apple's launchd agent, which holds no keys.
set -l op_agent_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
test -S "$op_agent_sock"; and set -gx SSH_AUTH_SOCK "$op_agent_sock"

# claude code
# the "Claude Code" 1password environment, read by functions/wrappers/claude.fish. an environment id is an
# opaque identifier, not a credential — safe to commit. -g, not -gx: only fish reads it.
set -g __op_claude_env uiba73phjvsgnivopa7bujlpbq

# codex inherits the same development-tool credentials as claude code. this does not
# replace codex's chatgpt oauth login; the wrapper only supplies child-process variables.
set -g __op_codex_env uiba73phjvsgnivopa7bujlpbq

# the linode shell plugin serves humans. agents cannot inherit fish functions, so their parent
# wrappers export this reference for `op run` to resolve as the cli token. `--infra` additionally
# exposes the same value to the mcp, whose large tool catalogue remains opt-in.
# the reference is a locator, not a credential; keep the resolved value out of shell state and files.
set -g __op_linode_pat_ref 'op://Development/Linode PAT/token'
