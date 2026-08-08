<!-- toolbox-manifest — verified by .claude/skills/brewfile/scripts/brewfile-audit.sh in the
     dotfiles repo. block html comments are stripped before this file enters context, so this
     costs nothing to carry. update both lists whenever the prose below changes.

verify-present: fish starship atuin fzf zoxide eza bat fd rg sd yq gron sponge ts less micro btop
  fastfetch grc gum gls gdate gsort git git-lfs delta git-filter-repo difft ast-grep hyperfine tokei
  gh act lefthook node bun uv gdformat gdlint rustup rustc cargo rust-analyzer cargo-nextest
  cargo-audit cargo-deny sccache make gmake scons shellcheck shfmt curl xh wget ssh
  nmap iperf3 dnsperf doge caddy ffmpeg ffprobe magick yt-dlp sox soxi gs rsvg-convert
  woff2_compress woff2_decompress betterleaks gpg pinentry-touchid pinentry-mac mas duti fswatch
  watchexec jq trash java python3 code-insiders godot blender op
verify-absent: docker docker-compose podman go mvn gradle gsed prettier eslint tre
  chafa AtomicParsley macos-defaults pip
-->

# The toolbox on this machine

**One file, one question: *if* I am about to run a shell command, what do I reach for?** Everything
named below is **installed and verified present** unless the final *Not installed* section says
otherwise.

**This is an inventory, not an obligation.** Its whole job is to spare you from checking what exists
and from settling for a clumsier tool out of caution. It has no opinion on whether shelling out is
the right move at all — that call comes first, and nothing here applies until you have made it.

⚠ **Never let this file invent work.** Your own capabilities come first, every time:

- **You read images, screenshots, PDFs and diagrams natively.** Never pipe one through `magick`,
  `sips`, `qlmanage` or an ASCII converter to "analyze" it — just look at it. Shell out for an image
  only when a transformed *file* is the deliverable.
- **Read/Edit/Grep/Glob beat `bat`, `cat`, `sed -n` and `head`** for getting file content into your
  own context, and the reason is mechanical rather than aesthetic: `Read` numbers the lines and
  registers the file with the harness, which is what makes a later `Edit` legal. A `bat` dump does
  neither. ⚠ Need part of a large file? That is `Read` with `offset`/`limit` — never
  `sed -n '95,115p'`. ⚠ Batching several file reads into one `bash` call to save a round trip is a
  false economy; it buys one turn and costs the line numbers and the registration. `bat` is for
  showing a file to **the user**.
- **Reasoning, writing and judgement are not tool-shaped.** Nothing below substitutes for thinking.

What this file *does* license, so you never have to ask:

1. **Don't check whether something below exists, and don't offer to install it** — it is here.
2. **When you were already going to write a shell loop, a multi-step pipeline or a throwaway
   script**, look here first for something that does the whole job in one invocation. Reinventing
   `jq`, `ffmpeg`, `hyperfine` or `ast-grep` in forty lines of bash is the expensive mistake.

Everything below is a **default, not a rule**. A concrete reason to go elsewhere — a flag only the
other tool has, a script that must run on another machine, the user asked for it that way — outranks
any table here and needs no justification. Reaching for `grep` over `rg` is a rounding error; never
make it a discussion, and never rewrite a working command just to comply.

`~/.config/Brewfile` is the complete inventory — GUI apps included, with a one-line *why* per entry.
Read it when you need something not named here, or before recommending a new tool.

## Better defaults for shell work

When a job below genuinely comes up *in a shell*, the middle column is the better tool here. This is
a preference, not a ban on the right column.

| Job | Use | Instead of |
| --- | --- | --- |
| Find files by name | `fd` | `find` |
| Search file contents | `rg` (ripgrep) | `grep` |
| Find/replace in text | `sd` | `sed` |
| Structural code search or rewrite | `ast-grep` (`sg`) | regex over source |
| Query/edit JSON | `jq` | manual parsing |
| Query/edit YAML, TOML, XML, CSV | `yq` | manual parsing |
| Spelunk unfamiliar JSON | `gron` \| `rg` | guessing `jq` paths |
| List a directory | `eza` (`--tree`, icons) | `ls` |
| Show a file to a human | `bat` (`-pp` for no pager/decoration) | `cat` |
| Delete something | `trash` (recoverable) | `rm` |
| HTTP request | `xh` | `curl` |
| DNS lookup | `doge` | `dig` |
| Watch processes | `btop` | `top` |
| Edit in a terminal | `micro` | `nano`/`vim` |
| Run/install Python | `uv run`, `uv tool install` | `pip`, `venv` |
| Run/install JS | `bun` (`node` is also present) | `npm`/`npx` |
| Edit a file in its own pipeline | `… \| sponge file` (moreutils) | `cmd file > file` (truncates!) |
| Jump to a directory | `z` (zoxide — interactive fish only) | `cd` |

## What is here, by task

Use any of these without asking permission when the task actually calls for it. That is not the same
as needing to find a use for them.

- **Benchmark a command** → `hyperfine` (warmup, mean/median/σ, `--export-json`). ⚠ Never time
  something once and call it a result.
- **Diff two files structurally** → `difft` (difftastic). `delta` (git-delta) is already wired into
  git and pages its line diffs; `difft` compares syntax trees.
- **Run something on file change** → `watchexec`. `fswatch` reports changes; `watchexec` acts on them.
- **Format or lint a shell script** → `shellcheck` *and* `shfmt` on every bash script you write.
- **Format or lint GDScript** → `gdformat` / `gdlint` (gdtoolkit, via uv). ⚠ These work **headless**;
  the `godot-lsp` MCP needs the editor open. Use both — the MCP has full project context, gdtoolkit
  does not, but gdtoolkit runs anywhere.
- **Size up an unfamiliar repo** → `tokei` for the language/LOC breakdown.
- **Media** → `ffmpeg`/`ffprobe` for any transcode, trim, concat or probe. `sox`/`soxi` for raw audio
  sample-rate work. `yt-dlp` for any media URL. ⚠ Never read or pass `~/.config/yt-dlp/cookies.txt`.
- **Images** → `magick` (imagemagick 7) **to produce or transform an image file**. ⚠ Never to *look*
  at one — you see images natively, and converting a screenshot to text throws away the information
  you wanted. The legacy `convert` still resolves but is deprecated. `rsvg-convert` (librsvg) gives
  `magick` SVG input, `gs` (ghostscript) PDF/PostScript.
- **Fonts** → `woff2_compress` / `woff2_decompress` (woff2).
- **Network** → `caddy file-server` for an instant static server or reverse proxy; `wget` to mirror
  recursively; `nmap` to scan ports; `iperf3` for bandwidth, `dnsperf` for DNS. `ssh` is openssh's.
- **Git and GitHub** → `gh` (but the GitHub MCP server comes first), `git-lfs`, `git-filter-repo` for
  history rewriting, `lefthook` for hooks.
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

## macOS system binaries — present, and routinely forgotten

No install needed, and usually the *right* answer on this machine:

`plutil` (read/convert/edit plists) · `defaults` (app preferences) · `launchctl` (launchd agents —
this is how you inspect the `brew autoupdate` job) · `log show --predicate` (unified logging; the only
way to see why a background agent failed) · `mdfind` (Spotlight from the CLI, faster than `fd` over a
whole volume) · `sqlite3` · `sips` (quick image convert/resize) · `textutil` (rtf/doc/html/txt) ·
`codesign` · `xxd` · `pbcopy`/`pbpaste` · `caffeinate` · `sw_vers` · `system_profiler` · `open` ·
`networksetup` · `qlmanage`.

## Non-CLI tools — MCP servers, connectors, plugins

The same question, different transport. When the work *is* documentation lookup, GitHub, Godot or web
extraction, these beat a shell command or the built-in web tools:

- **Docs / API lookup → Context7, always first.** A claude.ai **connector**, not a plugin —
  account-level, so the same server backs Claude Code, Desktop and claude.ai, with nothing installed
  locally. ⚠ There is deliberately **no** `context7` plugin: it was the same upstream server reached a
  worse way (`npx -y @upstash/context7-mcp` respawned every session), removed 2026-07-30. Do not
  reinstall it. Use `resolve-library-id` then `query-docs` for **any** named library, framework, SDK,
  API, CLI tool or cloud service — including ones you think you know, because your training data
  lags. Version-sensitive or obscure makes it *mandatory*; for stable, well-known basics your own
  knowledge is fine, and a lookup you would not have needed is just latency.
  ⚠ Cap: 3 `resolve-library-id` and 3 `query-docs` per question; one concept per `query-docs` call.
  Fall back to built-in search/fetch only when Context7 has no entry.
- **GitHub → the GitHub MCP server first**, then `gh` CLI, then manual.
- **Godot → load the `godot` skill.** Two MCP servers back it: `godot-mcp` (editor + running-game
  control, deterministic playtesting, runtime state) and `godot-lsp` (static GDScript diagnostics +
  the game console). Neither authors content — writing `.gd`/`.tscn`/`.tres` is normal filesystem
  work, and `gdformat`/`gdlint` above cover the headless checks.
- **JS-heavy or multi-page web extraction → Firecrawl**, via the official `firecrawl` plugin
  (11 `firecrawl:*` skills driving the `firecrawl` CLI). ⚠ The plugin ships **no MCP server** and none
  is wanted — the CLI does the same work with nothing to keep alive. ⚠ `FIRECRAWL_API_KEY` is already
  on the environment when `claude` is launched from fish, so a bare `firecrawl …` is authenticated:
  do not wrap it in `op run`, do not pass `--api-key`. ⚠ **Never run `firecrawl init`,
  `firecrawl setup skills|workflows`, or `firecrawl login`,** even though the plugin's own
  `install.md` recommends all three: here they write 31 bundles to `~/.agents/` linked with a prefix
  that only resolves under `~/.claude/skills` (so every link dangles), spray copies into every other
  agent/IDE they detect, and open a second credential store under
  `~/Library/Application Support/firecrawl-cli`. The CLI is installed and authenticated;
  `firecrawl --status` is the check.
- ⚠ **Context7 vs Firecrawl:** Context7 answers *documentation* questions; Firecrawl *extracts page
  content* (scraping, crawling, mapping, monitoring). Wanting to know how an API works is always
  Context7 — do not scrape a docs site Context7 already indexes.
- **Local / execution work** → terminal commands and filesystem tools.

## Traps

- ⚠ **GNU coreutils are `g`-prefixed and not on `$PATH` under their own names** — `gls`, `gdate`,
  `gsort`. Plain `ls`, `date` and `sed` are **BSD**, and there is no `gsed`. Prefer `sd`, `rg` or
  fish's `string replace` over writing BSD-safe `sed -i ''` expressions.
- ⚠ `make` *is* GNU make — its gnubin precedes `/usr/bin` (`gmake` is the same binary).
- ⚠ `jq` and `trash` are **macOS 27 system binaries** in `/usr/bin`, not Homebrew.
- ⚠ `curl` is Homebrew's keg-only build and `~/.config/curl/curlrc` sets `fail`, so a 404 exits
  **22**, not 0. `python3` is Homebrew's; prefer `uv run` for anything project-scoped.
- ⚠ `java` is the `/usr/bin/java` stub dispatching to the `temurin@25` cask.
- ⚠ **`uv tool` shims live in `~/.local/bin`**, which reaches `$PATH` only via
  `fish/conf.d/uv.fish` (added 2026-07-30). An installed uv tool is not automatically a reachable
  one, and a shell that did not inherit fish's environment will not see `gdformat`/`gdlint`.
- **Rust** uses Homebrew's keg-only `rustup`, with the stable toolchain and `rust-analyzer`,
  `rust-src`, Clippy, and rustfmt managed by rustup. `RUSTUP_HOME` and `CARGO_HOME` live under
  `$XDG_DATA_HOME`; `SCCACHE_DIR` lives under `$XDG_CACHE_HOME`. Cargo reads the tracked
  `cargo/config.toml` through `$CARGO_HOME/config.toml` and uses `sccache` as its compiler wrapper.
  Prefer `cargo nextest run` for local suites; `cargo audit` and `cargo deny` cover vulnerability
  and dependency-policy checks. Do not add global `RUSTFLAGS` or `CARGO_TARGET_DIR`.
- ⚠ **`act` cannot run.** It needs a container runtime and none is installed. `pam-reattach` ships a
  PAM module with no binary — check that class of formula with `brew list --versions`, not
  `command -v`. `gnupg`'s `gpg` uses `pinentry-touchid` (`pinentry-mac` is the fallback).
- ⚠ Your Bash tool runs under **zsh**, so fish functions and abbreviations do not exist for you —
  including the 1Password shell-plugin wrapper for `gh`. Invoke binaries directly.

## Not installed

Don't assume these are available, and don't write a command or example against one: `docker`/
`docker-compose`, `podman`, `go`, `mvn`/`gradle`, `gsed`, `prettier`, `eslint`, `tre`,
`chafa`, `AtomicParsley`, `macos-defaults`, `pip`. (`pip3` resolves only as an artefact of
Homebrew's python — never use it to install anything.) If one of them genuinely *is* the right answer
to something, say so and say it is not installed — this list is a fact about the machine, not a
prohibition on the topic. Absence here is not evidence for deliberately untracked classes:
VS Code extensions and `bun`/`uv`/`npm` globals are recorded nowhere.

## Keeping this file true

⚠ **Declared intent is not verified state**, and it has failed in both directions here. Pick the right
liveness check for the artefact: `command -v` only finds things on `$PATH`, so it reports "missing"
for keg-only formulae (`curl`), prefixed ones (`make` → `gmake`) and formulae shipping no binary at
all (`pam-reattach`). Use `brew list --versions <formula>` for those.

**If you install something while working, add it to the `Brewfile` *and* to this file in the same
change** — that is the `brewfile` skill, and `brewfile-audit.sh` checks both directions.
