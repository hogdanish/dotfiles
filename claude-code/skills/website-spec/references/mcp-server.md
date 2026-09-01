# The Website Spec MCP server, as wired on this machine

The spec ships a read-only MCP server. It is **declared in the global user configuration for both
agents and switched on per project** — live today in `~/Projects/hogdot` and
`~/Projects/commongrounds`. Everywhere else it is off by design, and that is deliberately
harmless: the whole checklist is vendored in [checklist.md](checklist.md), so an audit never
depends on this server being connected.

## The server

| | |
|---|---|
| Endpoint | `https://mcp.specification.website/mcp` |
| Transport | Streamable HTTP, stateless, wide-open CORS |
| Auth | **none** — nothing for 1Password to hold, no `op://` reference, no token |
| Protocol | `2026-07-28`; also answers `2025-11-25`, `2025-06-18`, `2025-03-26` via `initialize`, under a published Deprecation/Sunset |
| Server card | `https://specification.website/.well-known/mcp/server-card.json` |
| Source | <https://github.com/jdevalk/specification.website> — code MIT, content CC BY 4.0 |

Tools — `search` · `list_topics` · `get_topic` · `get_checklist` · `get_categories` ·
`get_changes`. Prompt — `audit_url(url, focus?)`. Full argument contract:
[upstream-skill.md](upstream-skill.md).

⚠ `list_topics` and `get_checklist` return **all** statuses by default; pass `status` to filter.
`audit_url` is the exception — with no `focus` it defaults to required + recommended.

## Where it is declared

**Claude Code.** Claude Code reads MCP *definitions* only from `~/.claude.json` (untracked state)
or a project's `.mcp.json` — there is no `mcpServers` key in `settings.json`, so a tracked
user-level definition is not possible. The tracked halves are therefore:

- `~/.config/claude-code/mcp/website-spec.json` — the canonical declaration and copy-source.
  Drop it in as a project's `.mcp.json`, or merge its one `mcpServers` entry into an existing
  one, to switch the server on there.
- `~/.config/claude-code/settings.json` — `"enabledMcpjsonServers": ["website-spec"]`, a
  user-level pre-approval. That is the global half: the name is trusted machine-wide, so the
  server connects with no prompt wherever a `.mcp.json` declares it, and nowhere it does not.

**Codex.** `~/.config/codex/config.toml` carries `[mcp_servers.website-spec]` with
`enabled = false` — the same shape as the `--infra`-gated `cloudflare-api` entry above it. Each
live project's `.codex/config.toml` overrides it with `enabled = true`.

**The live projects.** `hogdot` and `commongrounds` each track their own `.mcp.json` and
`.codex/config.toml`. `~/.config/scripts/audit-config.fish` asserts both halves of the gate —
enabled in each, disabled in an unrelated directory — so a project that silently stops loading
it fails the audit rather than degrading quietly.

## Turning it on in another project

```sh
# claude code — a project with no .mcp.json yet
cp ~/.config/claude-code/mcp/website-spec.json <project>/.mcp.json
# ...otherwise merge the one entry into the existing mcpServers object by hand
```

```toml
# <project>/.codex/config.toml — codex
[mcp_servers.website-spec]
enabled = true
```

Claude Code needs nothing further; `enabledMcpjsonServers` already covers the name. Codex reads a
project `config.toml` only in a **trusted** repository, so a first run there will prompt for trust.

## When it is not connected — the fallback

Every surface is plain Markdown over HTTPS, no auth, so `WebFetch` covers all of it:

| Want | Fetch |
|---|---|
| One spec page | `https://specification.website/spec/<category>/<slug>.md` |
| The full checklist | already vendored — [checklist.md](checklist.md) |
| Every page, one file | `https://specification.website/llms-full.txt` |
| Index of every page | `https://specification.website/llms.txt` |
| What changed | `https://specification.website/changelog/rss.xml` (entries tagged added/changed/status/removed) |
| Every machine-readable endpoint | `https://specification.website/.well-known/api-catalog` (RFC 9727) |

Content negotiation works too: `Accept: text/markdown` on the canonical slash-terminated URL
returns the Markdown body with `200`, `Content-Location` pointing at the `.md` path and
`Vary: Accept`. There is no redirect to follow.

Markdown responses carry RFC 9530 `Content-Digest` / `Repr-Digest` (`sha-256=:<base64>:`) over the
exact bytes received. `Want-Content-Digest: sha-512=10` asks for SHA-512 instead. HTML responses
carry no digest. `scripts/website-spec-sync.sh` uses this to verify what it vendored.

## Verifying it by hand

```sh
curl -s -X POST https://mcp.specification.website/mcp \
  -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | python3 -m json.tool | head -40
```

Inside a session, `/mcp` lists what actually connected — that, not this file, is the proof.
