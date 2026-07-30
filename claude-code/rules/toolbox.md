<!-- toolbox-manifest — verified by .claude/skills/brewfile/scripts/brewfile-audit.sh in the
     dotfiles repo. block html comments are stripped before this file enters context, so this
     costs nothing to carry. update both lists whenever the prose below changes.

verify-present: fish starship atuin fzf zoxide eza bat fd rg sd yq gron sponge ts less micro btop
  macchina grc gum gls gdate gsort git git-lfs delta git-filter-repo difft ast-grep hyperfine tokei
  gh act lefthook node bun uv gdformat gdlint make gmake scons shellcheck shfmt curl xh wget ssh
  nmap iperf3 dnsperf doge caddy ffmpeg ffprobe magick yt-dlp sox soxi gs rsvg-convert
  woff2_compress woff2_decompress betterleaks gpg pinentry-touchid pinentry-mac mas duti fswatch
  watchexec jq trash java python3 code-insiders godot blender op
verify-absent: docker docker-compose podman cargo rustup go mvn gradle gsed prettier eslint tre
  chafa AtomicParsley macos-defaults pip
-->

# The toolbox on this machine

**One file, one question: what do I reach for?** Everything named below is **installed and verified
present** unless the final *Not installed* section says otherwise. Two standing imperatives:

1. **Never check whether one of these exists, and never offer to install it — just use it.**
2. **Before writing a shell loop, a multi-step pipeline, or a throwaway script, look here for a tool
   that does the whole job in one invocation.** Reinventing `jq`, `ffmpeg`, `hyperfine` or `ast-grep`
   in forty lines of bash is the expensive mistake, not picking `grep` over `rg`.

⚠ This is about *shell* work. For reading and editing files your Read/Edit/Grep tools still beat
piping `bat` or `sd` into context.

`~/.config/Brewfile` is the complete inventory — GUI apps included, with a one-line *why* per entry.
Read it when you need something not named here, or before recommending a new tool.

## Use instead of the default

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

## Reach for these without asking — by task

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
- **Images** → `magick` (imagemagick 7). ⚠ The legacy `convert` still resolves but is deprecated.
  `rsvg-convert` (librsvg) gives it SVG input, `gs` (ghostscript) PDF/PostScript.
- **Fonts** → `woff2_compress` / `woff2_decompress` (woff2).
- **Network** → `caddy file-server` for an instant static server or reverse proxy; `wget` to mirror
  recursively; `nmap` to scan ports; `iperf3` for bandwidth, `dnsperf` for DNS. `ssh` is openssh's.
- **Git and GitHub** → `gh` (but the GitHub MCP server comes first), `git-lfs`, `git-filter-repo` for
  history rewriting, `lefthook` for hooks.
- **Secrets** → `op` for every credential (the `auth` skill); `betterleaks` to scan content.
- **System** → `duti` for default-app associations, `mas` for the App Store, `macchina` for system
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

The same question, different transport. Prefer these over a shell command or built-in web tool:

- **Docs / API lookup → Context7, always first.** A claude.ai **connector**, not a plugin —
  account-level, so the same server backs Claude Code, Desktop and claude.ai, with nothing installed
  locally. ⚠ There is deliberately **no** `context7` plugin: it was the same upstream server reached a
  worse way (`npx -y @upstash/context7-mcp` respawned every session), removed 2026-07-30. Do not
  reinstall it. Use `resolve-library-id` then `query-docs` for **any** named library, framework, SDK,
  API, CLI tool or cloud service — including ones you think you know. Version-sensitive or obscure
  makes it *mandatory*. Never answer an API question from memory when a lookup would settle it.
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
- ⚠ **`act` cannot run.** It needs a container runtime and none is installed. `pam-reattach` ships a
  PAM module with no binary — check that class of formula with `brew list --versions`, not
  `command -v`. `gnupg`'s `gpg` uses `pinentry-touchid` (`pinentry-mac` is the fallback).
- ⚠ Your Bash tool runs under **zsh**, so fish functions and abbreviations do not exist for you —
  including the 1Password shell-plugin wrapper for `gh`. Invoke binaries directly.

## Not installed

Do not reach for, propose, or write examples against: `docker`/`docker-compose`, `podman`,
`rustup`/`cargo`, `go`, `mvn`/`gradle`, `gsed`, `prettier`, `eslint`, `tre`, `chafa`,
`AtomicParsley`, `macos-defaults`, `pip`. (`pip3` resolves only as an artefact of Homebrew's python —
never use it to install anything.) Absence here is not evidence for deliberately untracked classes:
VS Code extensions and `bun`/`uv`/`npm` globals are recorded nowhere.

## Keeping this file true

⚠ **Declared intent is not verified state**, and it has failed in both directions here. Pick the right
liveness check for the artefact: `command -v` only finds things on `$PATH`, so it reports "missing"
for keg-only formulae (`curl`), prefixed ones (`make` → `gmake`) and formulae shipping no binary at
all (`pam-reattach`). Use `brew list --versions <formula>` for those.

**If you install something while working, add it to the `Brewfile` *and* to this file in the same
change** — that is the `brewfile` skill, and `brewfile-audit.sh` checks both directions.
