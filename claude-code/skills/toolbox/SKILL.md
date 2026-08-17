---
name: toolbox
description: "Per-domain depth behind the always-on toolbox rule: builds, media, images, network, Cloudflare, Linode, Go, git, containers, secrets, macOS, Homebrew autoupdate, and MCP-vs-CLI routing. Load for a domain task the rule's tables do not settle."
disable-model-invocation: true
---

# The toolbox, in depth

The always-on `toolbox.md` rule answers "what do I reach for" with its tables. This skill carries
the per-domain guidance and the longer traps. Everything named here is installed and verified
present unless the rule's *Not installed* list says otherwise; the rule's manifest comment is what
`brewfile-audit.sh` checks.

## By task

- **Benchmark a command** → `hyperfine` (warmup, mean/median/σ, `--export-json`). ⚠ Never time
  something once and call it a result.
- **Diff two files structurally** → `difft` (difftastic). `delta` (git-delta) is already wired into
  git and pages its line diffs; `difft` compares syntax trees.
- **Run something on file change** → `watchexec`. `fswatch` reports changes; `watchexec` acts on them.
- **Format or lint a shell script** → `shellcheck` *and* `shfmt` on every bash script you write.
- **Lint prose** → `vale` when a project supplies Vale configuration and styles.
- **Format or lint GDScript** → `gdformat` / `gdlint` (gdtoolkit, via uv). ⚠ These work **headless**;
  the `godot-lsp` MCP needs the editor open. Use both — the MCP has full project context, gdtoolkit
  does not, but gdtoolkit runs anywhere.
- **Build or lint a C++ engine (hogdot / Godot)** → installed 2026-08-06 for `~/Projects/hogdot`.
  ⚠ **Load the `build-export` skill before running any of this** — it owns the exact commands, and
  every item below is a summary of something written up there at length.
  `ccache` (4.13) is XDG-native, configured at `~/.config/ccache/ccache.conf`, cap raised to 30G
  because the 5 GiB stock default thrashes on an engine build. ⚠ **It is NOT automatic — an earlier
  version of this file said "picked up automatically, nothing to pass" and that was wrong.** SCons
  rebuilds `env["ENV"]` from scratch and passes the compiler **only** what `import_env_vars` names, so
  ccache runs without `HOME`, silently uses `~/Library/Caches/ccache` and never touches the configured
  cache. You need the launcher option **and** `export CCACHE_DIR=… CCACHE_CONFIGPATH=…` **and**
  `import_env_vars=HOME,CCACHE_DIR,CCACHE_CONFIGPATH`. The same trap applies to `EM_CACHE` on web
  builds and to every other env var a build-spawned tool reads.
  `pre-commit` (4.6) is the **only** way to run Godot's own `.pre-commit-config.yaml` gates.
  ⚠ **`clang-format` is deliberately not installed as a formula** — that config vendors
  `mirrors-clang-format` **v21.1.7** and pre-commit fetches it itself; a Homebrew `clang-format` would
  be a different version and reformat the whole engine. Always go through `pre-commit run`, never a
  bare `clang-format`. `emscripten` (6.0.5) builds web export templates; ⚠ `EM_CACHE` is redirected to
  `$XDG_CACHE_HOME/emscripten` in `conf.d/xdg-apps.fish` because the stock cache lives *inside the
  Cellar* and dies on every `brew upgrade` — and 6.0.5 is one major past the 5.0.0 GodotWebGPU shipped
  on, so suspect the toolchain before the port when a web-only build breaks (it has already cost one
  Dawn callback-signature fix).
  `glslang` (16.5.0, added 2026-08-06) is a hard dependency of **`webgpu=yes` builds only** —
  `drivers/webgpu/wgsl_precompile.py` shells out to `glslangValidator`. ⚠ Its version skew against
  Godot's vendored 16.1.0 is **fine and not a clang-format-style trap**: the two never meet in one
  process. ⚠ A missing `glslangValidator` reports **`Permission denied`, not "not found"** — check
  `command -v` before chasing a permissions bug.
  ⚠ **Pass `num_jobs=4` and `nice -n 10` for `webgpu=yes` web builds.** SCons defaults to `-j9` here
  and nine concurrent `em++` processes on the Tint/SPIRV-Tools sources exhaust 24 GB and drive the
  machine into swap. The tell is a pegged machine with **quiet fans** — swap thrash is I/O-bound.
  `num_jobs` and `nice` both reach spawned children; environment variables do not.
- **Size up an unfamiliar repo** → `tokei` for the language/LOC breakdown.
- **Media** → `ffmpeg`/`ffprobe` for any transcode, trim, concat or probe. `sox`/`soxi` for raw audio
  sample-rate work. `yt-dlp` for any media URL. ⚠ Never read or pass `~/.config/yt-dlp/cookies.txt`.
- **Images** → `magick` (imagemagick 7) **to produce or transform an image file**. ⚠ Never to *look*
  at one — you see images natively, and converting a screenshot to text throws away the information
  you wanted. The legacy `convert` still resolves but is deprecated. `rsvg-convert` (librsvg) gives
  `magick` SVG input, `gs` (ghostscript) PDF/PostScript.
- **Fonts** → `woff2_compress` / `woff2_decompress` (woff2).
- **Reach Ethan away from the terminal** → `cc-notify` — the always-on `notify` rule owns when it
  fires and its hold/clear/attention contract. Do not hand-roll `osascript display notification`.
- **Network** → `caddy file-server` for an instant static server or reverse proxy; `wget` to mirror
  recursively; `nmap` to scan ports; `iperf3` for bandwidth, `dnsperf` for DNS. `ssh` is openssh's.
  `mkcert` (+`nss`) issues locally-trusted dev certs — ⚠ good enough for ordinary HTTPS, **not** for
  browser WebTransport: Chrome accepts an mkcert leaf over TCP TLS and rejects the same cert over
  QUIC (measured 2026-08-05). Pin a short-lived self-signed cert instead.
- **Cloudflare** → `cloudflared` for Tunnel (installed 2026-08-06). ⚠ Its real value here is that it
  is the way *around* the mkcert/QUIC gap above: a named tunnel puts a local origin behind a genuine
  Cloudflare-issued cert on a real hostname, which a browser trusts over QUIC as well as TCP. Config
  and credentials live in `~/.cloudflared` (not XDG, no override). ⚠ **`wrangler` is deliberately
  NOT installed globally** — Cloudflare's own skill pins it per project (`npm install -D
  wrangler@latest`), and a global copy skews against the version a project's `wrangler.jsonc`
  targets; run it as `bunx wrangler` or from the project's `node_modules`. `conf.d/cloudflare.fish`
  exports `CLOUDFLARE_ACCOUNT_ID`, forces `CLOUDFLARE_AUTH_USE_KEYRING` (⚠ otherwise `wrangler login`
  writes a plaintext OAuth token into `~/.config/.wrangler/`, i.e. inside the public dotfiles repo)
  and opts out of telemetry. `cf` (0.6.0 technical preview, installed globally from npm) is
  Cloudflare's new account-wide CLI and the preview of Wrangler's successor; use it for supported
  Cloudflare resources, inspect `cf --help` before each task, and expect incomplete/changing coverage.
  It is declared as an `npm "cf"` Brewfile entry so fresh machines install the upstream-supported
  package into Homebrew's global Node prefix, which is on every agent and shell `$PATH`. For the
  COMMONGROUNDS zone, use the scoped `op://Development/cloudflare commongrounds acme/credential`
  token as `CLOUDFLARE_API_TOKEN` inside one `op run` command. ⚠ `cf auth whoami` in 0.6.0 reports
  `tokenValid: false` for that scoped token even when an authenticated `cf zones list` succeeds;
  test the intended read operation instead.
- **Linode** → the official `linode-cli` (installed 2026-08-08). Humans authenticate through
  `functions/wrappers/linode-cli.fish` and its 1Password shell plugin. Claude Code and Codex launch
  wrappers resolve `LINODE_CLI_TOKEN` once, then keep it in a session-scoped memory broker because
  both current agents strip it from shell tools. Agents use bare `linode-cli`; a session-local shim
  reaches the official binary through the broker. The CLI config contains defaults only. Read
  `~/.config/claude-code/skills/linode-cli/SKILL.md` before using it.
  ⚠ Never pass a PAT on the command line, run `linode-cli --debug` (headers may be logged), or
  create any Linode or other billable resource without Ethan's explicit permission.
- **Go** → `go` (1.26) is installed for one reason: the COMMONGROUNDS WebTransport relay in
  `server/relay/`. ⚠ `GOPATH` is not exported globally — a shell that did not inherit fish's
  environment may need `GOPATH="$HOME/.local/share/go"`.
- **Git and GitHub** → `gh` (but the GitHub MCP server comes first), `git-lfs`, `git-filter-repo` for
  history rewriting, `lefthook` for hooks.
- **Containers** → `docker` (CLI, compose v2, buildx) plus `orb`/`orbctl`, all from the `orbstack`
  cask — OrbStack, not Docker Desktop, is the VM backend here: same Docker API, built on Apple's
  Virtualization.framework with its own VirtioFS-equivalent tuning, on-demand RAM, and Rosetta
  instead of QEMU for amd64 emulation — verified faster and lighter than Docker Desktop, and a
  better fit than Apple's own `container` CLI (WWDC 2025), which has no compose/registry ecosystem.
  ⚠ `DOCKER_CONFIG` is redirected to `$XDG_CONFIG_HOME/docker` in `conf.d/xdg-apps.fish`, but
  OrbStack.app itself is launched by launchd/Finder and never sees that export. ⚠ OrbStack's
  first-run setup (admin-granted CLI tools) writes a `source ~/.orbstack/shell/init2.fish` line
  straight into `fish/config.fish`, which this repo keeps intentionally empty — moved to
  `conf.d/orbstack.fish` instead; see that file for the current state. Docker Desktop was
  uninstalled 2026-08-06 — OrbStack is the sole backend. **Read
  `~/.config/claude-code/skills/orbstack/SKILL.md`** for the `orb`/`orbctl` CLI (machine lifecycle,
  `.orb.local` networking, the `orb` SSH host, config keys) and for the container-vs-VM call
  between `docker run` and `orb create`.
- **Secrets** → `op` for every credential (the `auth` skill); `betterleaks` to scan content.
- **System** → `duti` for default-app associations, `mas` for the App Store, `fastfetch` for system
  info, `make` (GNU) and `scons` to build, `less` as pager, `grc` to colourise. `fish`, `starship`,
  `atuin`, `fzf` are the shell furniture and are already configured.
- **Homebrew and the App Store** → ⚠ Homebrew **updates and upgrades itself** every 12 h via a launchd
  agent (`brew autoupdate`; logs at `brew autoupdate logs`). Do not propose `brew update` as a fix,
  and do not treat an out-of-date package as drift. ⚠ The agent deliberately cannot `sudo`, so the
  `pkg` casks `temurin@25` and `font-sf-pro` and **every `mas` app** are outside it — that is what the
  **`brewup`** fish function is for. ⚠ Plain `brew` is **not** wrapped in `op`; invoke it directly.
- **GUI apps with a CLI** → `code-insiders`, `godot`, `blender`.
- **Driving a browser** → launch **`claude --chrome`** to opt into Chrome and the built-in
  `claude-in-chrome` MCP tools (installed 2026-08-05). Normal Claude launches keep them unloaded.
  Prefer them over Safari-by-AppleScript: they expose console messages, network requests and direct
  JavaScript, where Safari needs "Allow JavaScript from Apple Events" and returns far less. ⚠ Safari
  is still the only way to check WebKit-specific behaviour.

## Non-CLI tools — MCP servers, connectors, plugins

The same question, different transport. When the work *is* GitHub, Godot, Cloudflare or web
extraction, these beat a shell command or the built-in web tools. Documentation lookup is Context7,
whose mandate lives in the always-on rule.

- **GitHub → the GitHub MCP server first**, then `gh` CLI, then manual.
- **Cloudflare account/API work → the official Cloudflare plugin, gated behind `--infra`**
  (2026-08-16). A default launch loads neither its skills nor its MCP server; relaunch as
  `claude --infra` (or `codex --infra`) when the task touches the Cloudflare account or zone. The
  `cf` CLI still works in every session through the credential broker. When loaded, the plugin's
  `cloudflare-api` server is **Code Mode**: three tools (`docs`, `search`, `execute`) covering all
  ~2,500 API endpoints for ~1.1k tokens, because you write JavaScript against the spec server-side
  instead of loading 2,500 tool schemas (the same surface as native MCP tools costs ~244k). Use
  `search` to find an endpoint, then `execute` with `cloudflare.request()`. GraphQL Analytics works
  through `execute` too.
  ⚠ **The plugin ships five MCP servers and four are denied** in `claude-code/settings.json`
  (`deniedMcpServers`): `cloudflare-docs`, `-bindings`, `-builds`, `-observability` are the older
  one-tool-per-endpoint generation and are a strict subset of what code mode already does. Do not
  "re-enable" them to fix a missing capability — reach for `search`/`execute` first.
  ⚠ `deniedMcpServers` is documented as managed-settings-only; it was **verified working in user
  settings** on 2026-08-06 via `claude mcp list`.
- **Linode account/API inspection → the official `linode-cli` in any normal agent session.**
  The third-party Linode MCP was removed because its schema cost outweighed its narrow `instances`
  coverage. Use SSH for work inside a host. Treat all CLI mutations as consequential, and never
  create a billable resource without Ethan's explicit permission in the current request.
- **Godot → load the `godot` skill.** It owns the two Godot MCP servers (`godot-mcp` for the editor
  and running game, `godot-lsp` for static diagnostics and the game console) and their split.
  Editor-backed calls require an open Godot project, and the editor bridge serves one client at a
  time. Neither authors content — writing `.gd`/`.tscn`/`.tres` is normal filesystem work, and
  `gdformat`/`gdlint` cover headless checks.
- **JS-heavy or multi-page web extraction → the `firecrawl` CLI** (installed and authenticated —
  `firecrawl --status` is the check; `FIRECRAWL_API_KEY` is already on the environment when `claude`
  is launched from fish, so a bare `firecrawl …` works: do not wrap it in `op run`, do not pass
  `--api-key`). ⚠ The Firecrawl *plugin* is disabled in `enabledPlugins` — the CLI does the same
  work with nothing to keep alive. ⚠ **Never run `firecrawl init`, `firecrawl setup
  skills|workflows`, or `firecrawl login`** — here they write 31 bundles to `~/.agents/` linked with
  a prefix that only resolves under `~/.claude/skills` (so every link dangles), spray copies into
  every other agent/IDE they detect, and open a second credential store under
  `~/Library/Application Support/firecrawl-cli`.
- ⚠ **Context7 vs Firecrawl:** Context7 answers *documentation* questions; Firecrawl *extracts page
  content* (scraping, crawling, mapping, monitoring). Wanting to know how an API works is always
  Context7 — do not scrape a docs site Context7 already indexes.
- **Local / execution work** → terminal commands and filesystem tools.

## Longer traps

- **Rust** uses Homebrew's keg-only `rustup`, with the stable toolchain and `rust-analyzer`,
  `rust-src`, Clippy, and rustfmt managed by rustup. `RUSTUP_HOME` and `CARGO_HOME` live under
  `$XDG_DATA_HOME`; `SCCACHE_DIR` lives under `$XDG_CACHE_HOME`. Cargo reads the tracked
  `cargo/config.toml` through `$CARGO_HOME/config.toml` and uses `sccache` as its compiler wrapper.
  Prefer `cargo nextest run` for local suites; `cargo audit` and `cargo deny` cover vulnerability
  and dependency-policy checks. Do not add global `RUSTFLAGS` or `CARGO_TARGET_DIR`.
- ⚠ **`act` can run now** — it needs a container runtime and OrbStack supplies one (2026-08-06).
  The old "no container runtime" note is retired. `pam-reattach` ships a PAM module with no binary —
  check that class of formula with `brew list --versions`, not `command -v`. `gnupg`'s `gpg` uses
  `pinentry-touchid` (`pinentry-mac` is the fallback).

## Keeping the toolbox true

⚠ **Declared intent is not verified state**, and it has failed in both directions here. Pick the
right liveness check for the artefact: `command -v` only finds things on `$PATH`, so it reports
"missing" for keg-only formulae (`curl`), prefixed ones (`make` → `gmake`) and formulae shipping no
binary at all (`pam-reattach`). Use `brew list --versions <formula>` for those. GUI-backed tools
can live outside brew and `$PATH` entirely (Aseprite ships inside its Steam app bundle) — before
declaring one unavailable, check `/Applications`, `~/Applications`, the Steam library, **and** the
consumer's own config (Godot's `aseprite/general/command_path` held the right path all along), and
state which check you ran.

**If you install something while working, add it to the `Brewfile`, the rule's manifest comment,
and this skill in the same change** — that is the `brewfile` skill, and `brewfile-audit.sh` checks
the manifest's claims and that every declared package is mentioned in the rule or this skill.
