# cloudflare: wrangler (workers cli) and cloudflared (tunnel client).
#
# ⚠ wrangler is deliberately NOT installed globally — cloudflare's own skill pins it per project
# (`npm install -D wrangler@latest`), and a global copy silently skews against the version a
# project's wrangler.jsonc was written for. so this file only sets variables the project-local
# binary reads; there is nothing here to `type -q` against.

# the one cloudflare account on this machine (FRACTAL COUNTY). not a secret — it is in every
# dashboard url and in committed wrangler.jsonc files. exported so wrangler, terraform and the
# cloudflare mcp all resolve it without a per-project flag.
set -q CLOUDFLARE_ACCOUNT_ID; or set -gx CLOUDFLARE_ACCOUNT_ID 4c654424a3d22dfe63090cd9bc4db45a

# ⚠ this is a guardrail, not a preference. `wrangler login` defaults to writing its OAuth access
# AND refresh token as PLAINTEXT toml — and wrangler resolves its global config dir from
# XDG_CONFIG_HOME, which on this machine is ~/.config, i.e. *inside this public repo's working
# tree* (~/.config/.wrangler/config/default.toml). forcing the keyring backend makes it write an
# aes-256-gcm `default.enc` instead, with the key in the macos keychain via /usr/bin/security.
# .gitignore's `/*` already excludes the directory; this removes the plaintext copy as well.
# ⚠ set to `true`, wrangler ERRORS rather than falling back if the keychain is unreachable —
# that is intended, and safe here because /usr/bin/security is always present on macos.
set -q CLOUDFLARE_AUTH_USE_KEYRING; or set -gx CLOUDFLARE_AUTH_USE_KEYRING true

# opt out of wrangler's telemetry. both default to on/undefined upstream.
set -q WRANGLER_SEND_METRICS; or set -gx WRANGLER_SEND_METRICS false
set -q WRANGLER_SEND_ERROR_REPORTS; or set -gx WRANGLER_SEND_ERROR_REPORTS false

# ⚠ WRANGLER_CACHE_DIR is deliberately unset. it defaults to `node_modules/.cache/wrangler`,
# which is per-project and correct; redirecting it to XDG_CACHE_HOME would make every project
# share one cache directory.
