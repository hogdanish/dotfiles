---
name: website-spec
description: "The Website Specification (specification.website) — 168 items across ten categories, each tagged required/recommended/optional/avoid, vendored here in full. Load before writing, reviewing, auditing or shipping ANY web front-end: HTML, CSS, a page <head>, robots.txt, sitemaps, meta/Open Graph tags, favicons, security headers, /.well-known/ paths, llms.txt, accessibility, Core Web Vitals, i18n, 404s and redirects. Also the source of truth when asked 'what should this site have', 'is X required', or 'audit this URL'."
---

# The Website Specification

**specification.website** is a platform-agnostic specification of the technical features a good
website should have — 168 items in ten categories, every one tagged with a status that says how
hard the requirement is. It is the standing answer on this machine to *what should a website do*,
in place of guessing or citing vendor blog posts.

**This is an always-on convention.** Any web development work on this system — a new page, a
`<head>` edit, a static site, a docs site, a web export, a landing page, a review of someone
else's markup — is measured against this spec. You do not need to be asked to audit for it.

Author: Joost de Valk. Code MIT, content CC BY 4.0. Canonical site: <https://specification.website>.

## The whole checklist is already here

[references/checklist.md](references/checklist.md) is the complete, unabridged checklist —
all 168 items, verbatim from `https://specification.website/checklist.md`, with each item's
canonical URL, status and summary. **Read it rather than fetching the network** when you need
the full picture. It is 392 lines; do not distil it, do not work from memory of it, and do not
re-derive a subset you think is relevant.

Item counts by status: **36 required · 81 recommended · 45 optional · 6 avoid**.
`scripts/website-spec-sync.sh` reprints these from the vendored file, so they are checkable
rather than remembered.

[references/upstream-skill.md](references/upstream-skill.md) is the spec author's own agent
skill, kept whole: the MCP tool contract, the status definitions, the per-page Markdown
endpoints with their RFC 9530 digests, the MDN pairing, and how to re-audit only what changed.
Read it whenever you go past the checklist — it is the upstream contract, not a summary of one.

[references/mcp-server.md](references/mcp-server.md) is how the MCP server is wired **on this
machine**, which projects it is live in, and the exact fallback when it is not connected.

## The four statuses are the contract

| Status | Meaning | How to treat it |
|---|---|---|
| **required** | The platform contract breaks without it. | A missing one is a defect. Lead with these. |
| **recommended** | A modern site should do it. | Flag every gap; the user decides. |
| **optional** | Depends on context. | Mention only where the context applies. |
| **avoid** | Outdated or harmful. | If the site does it, flag it as a defect. |

⚠ **Never silently promote `recommended` to `required`.** The bar for `required` is *the platform
breaks*, not *this is a good idea*. Report the spec's status, then your own opinion separately if
you have one.

## The ten categories

`foundations` · `seo` · `accessibility` · `security` · `well-known` · `agent-readiness` ·
`performance` · `privacy` · `resilience` · `i18n`

The category slug is part of every spec URL: `https://specification.website/spec/<category>/<slug>/`.

## Auditing with it

1. **Scope.** Pick the categories the work actually touches. A `<head>` change is `foundations`
   plus `seo`; a deploy config is `security`, `performance`, `resilience`.
2. **Walk the checklist.** Open [references/checklist.md](references/checklist.md) and check the
   target against every item in scope, `required` first. Verify against the artefact — the served
   HTML, the response headers, the file on disk — never against an assumption about the framework.
3. **Go deep only where it fails.** For a failing or ambiguous item, fetch the full page:
   `https://specification.website/spec/<category>/<slug>.md` (or `get_topic` over MCP). Each page
   carries 2–4 primary sources (WHATWG, W3C, IETF RFCs, IANA, WCAG) — **cite those, not the spec
   page**.
4. **Report by status.** Group findings as required-failing, recommended-failing, avoid-present.
   Give the item's canonical URL so the claim is checkable.
5. **Implementation detail is MDN's job.** This spec says *what* and *whether it is required*; it
   does not say how a feature works or whether it is Baseline. For that, pair with MDN. Keep the
   roles distinct.

## Interaction with the always-on tool rules

- The vendored checklist here beats a network fetch. Reach for the network only for a specific
  item's full page, or to check what has changed.
- The MCP server (see [references/mcp-server.md](references/mcp-server.md)) is the best surface
  when it is connected, but it is deliberately **not** on in every project. Its absence is never
  a reason to skip the audit — everything needed for one is vendored in this skill.
- Per the global tool rules: built-in `WebFetch` for the `.md` endpoints. Firecrawl is metered and
  buys nothing here — these pages are plain Markdown over HTTP.

## Keeping it current

The spec moves, especially `agent-readiness`, and a status promotion can turn a passing site into
a failing one. `scripts/website-spec-sync.sh` re-fetches `checklist.md` and the upstream skill,
diffs them against the vendored copies, and verifies the upstream digest:

```sh
claude-code/skills/website-spec/scripts/website-spec-sync.sh          # report drift, exit 1 if any
claude-code/skills/website-spec/scripts/website-spec-sync.sh --write  # ...and update the copies
```

⚠ A vendored copy of someone else's document goes stale silently — that is the whole reason the
sync script exists. Run it at the start of any substantial audit, and monthly otherwise. After a
`--write`, commit the refreshed references in their own commit so the diff is legible.
