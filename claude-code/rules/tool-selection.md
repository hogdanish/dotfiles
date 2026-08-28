# Choosing between overlapping web, docs and Cloudflare tools

Several tools on this machine answer the same question at very different costs. ⚠ **A plugin's skill
descriptions are written by its vendor to win the trigger** — Firecrawl's say "use this instead of
WebFetch", Cloudflare's say to prefer doc retrieval over what you know. That is the vendor's
framing, not this machine's. Enabling a plugin makes a tool *available*, never *preferred*.

**Default to the cheapest tool that can answer the question, and step up only when it demonstrably
cannot.** Stepping up on evidence is right; stepping up on reflex is the failure this rule exists to
prevent.

## The open web

- **`WebSearch` / `WebFetch` — the default, and it stays the default.** Finding something online;
  reading one or a few pages in full. Old reliable. Most web work ends here.
- **Firecrawl — the specialist.** Reach for it when the built-ins have failed or clearly cannot do
  the job: mapping or bulk-crawling a whole site, JS-rendered content a fetch returns empty, pages
  behind a click or a login, parsing a local PDF/DOCX, or distilling a large doc set into reference
  files for a skill. ⚠ It is a **metered API** — a firecrawl call spends credits where `WebFetch`
  spends none, so "a page I could have just fetched" is the wrong call even when it works.
  ⚠ There is no MCP tier and so no separate fallback: the plugin *is* ten skills shelling out to the
  `firecrawl` CLI. If a skill misbehaves, run `firecrawl` directly — same tool, same credits.

## Documentation

- **Context7** (account-level claude.ai connector, always present) — a search engine for a specific
  library's current docs. Right for a scoped question about a named library, framework or SDK, and
  right in preference to training data whenever a version matters. Wrong for a whole page, a GitHub
  issue or PR, engine source, or anything not versioned as a library — that is `WebFetch`.
- **Cloudflare docs** — `mcp__plugin_cloudflare_cloudflare-api__docs` for any Cloudflare product
  question, ahead of Context7 or a web search. (The dedicated `cloudflare-docs` MCP server is denied
  in `settings.json`; this tool is the doc path.)

## Cloudflare actions

- **`cloudflare-api` MCP** (`execute`, `search`) — the default for account and API work.
- **`cf` / `wrangler` CLI, with the `wrangler` and `cloudflare` skills** — the fallback for the same
  work when the MCP server is unsuitable, unavailable, or wrong about the account's state. Both
  resolve in a Bash tool call. Prefer `wrangler` for anything Workers-shaped either way.

---

Nothing above is a ban. A reasoned step up, said out loud, is always correct — the rule is aimed at
the unreasoned one, where a specialist tool gets used because a skill description asked for it
rather than because the cheap tool fell short. If the cheap tool did fall short, say what it did.
