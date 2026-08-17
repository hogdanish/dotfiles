<!-- toolbox-manifest — verified by .claude/skills/brewfile/scripts/brewfile-audit.sh in the
     dotfiles repo. block html comments are stripped before this file enters context, so this
     costs nothing to carry. update both lists whenever the prose here or in the toolbox
     skill changes.

verify-present: fish starship atuin fzf zoxide eza bat fd rg sd yq gron sponge ts less micro btop
  fastfetch grc gum gls gdate gsort git git-lfs delta git-filter-repo difft ast-grep hyperfine tokei
  gh act lefthook node bun uv gdformat gdlint rustup rustc cargo rust-analyzer cargo-nextest
  cargo-audit cargo-deny sccache make gmake scons ccache pre-commit emcc shellcheck shfmt vale
  curl xh wget ssh linode-cli cf
  nmap iperf3 dnsperf doge caddy cloudflared docker docker-compose orb orbctl go ffmpeg ffprobe
  magick yt-dlp sox soxi gs rsvg-convert
  woff2_compress woff2_decompress betterleaks gpg pinentry-touchid pinentry-mac mas duti fswatch
  watchexec jq trash java python3 code-insiders godot blender op
verify-absent: podman mvn gradle gsed prettier eslint tre
  chafa AtomicParsley macos-defaults pip wrangler clang-format
-->

# The toolbox on this machine

**One question: *if* I am about to run a shell command, what do I reach for?** Everything named
here and in the **toolbox skill** is installed and verified present unless *Not installed* says
otherwise — do not check, and do not offer to install it. Before writing a shell loop, a multi-step
pipeline, or a throwaway script, look here first: reinventing `jq`, `ffmpeg`, `hyperfine`, or
`ast-grep` in forty lines of bash is the expensive mistake.

⚠ **Never let this file invent work.** Your own capabilities come first:

- **You read images, screenshots, PDFs and diagrams natively.** Never pipe one through `magick`,
  `sips`, `qlmanage`, or an ASCII converter to "analyze" it. Shell out for an image only when a
  transformed *file* is the deliverable.
- **Read/Edit/Grep/Glob beat `bat`, `cat`, `sed -n`, and `head`** for getting file content into
  your own context: `Read` numbers the lines and registers the file, which is what makes a later
  `Edit` legal. Part of a large file is `Read` with `offset`/`limit`, never `sed -n '95,115p'`;
  batching file reads into one `bash` call buys one turn and costs the registration. `bat` is for
  showing a file to **the user**.
- **Reasoning, writing, and judgement are not tool-shaped.**

Everything here is a **default, not a rule**. A concrete reason to go elsewhere — a flag only the
other tool has, a script that must run on another machine, the user asked — outranks any table and
needs no justification. Never rewrite a working command just to comply.

**Per-domain depth — builds, media, images, network, Cloudflare, Linode, Go, git, containers,
secrets, macOS, Homebrew, GUI-app CLIs, MCP-vs-CLI routing — is the toolbox skill: Read
`~/.config/claude-code/skills/toolbox/SKILL.md`** before picking a tool for a domain task these
tables do not settle. `~/.config/Brewfile` is the complete inventory — GUI apps included, one line
of *why* per entry — for anything neither names.

## Better defaults for shell work

A preference for shell work, not a ban on the right column.

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

## Docs / API lookup — Context7, always first

`resolve-library-id` then `query-docs` for **any** named library, framework, SDK, API, CLI tool, or
cloud service — including ones you think you know, because your training data lags.
Version-sensitive or obscure makes it mandatory; stable well-known basics can come from your own
knowledge. ⚠ There is deliberately **no** Context7 plugin or local stdio server (removed
2026-07-30) — do not reinstall one.
⚠ **An experiment to learn how a documented API behaves — a probe script, a throwaway test, a
compile-and-see loop — means you skipped the lookup.** One query costs less than one build.
Experiment on *your* code's behaviour, not the library's. Ceiling: 3 `resolve-library-id` + 3
`query-docs` per question, one concept per call. Fall back to built-in search/fetch only when
Context7 has no entry. Context7 answers *documentation* questions; extracting page content is
`firecrawl` (toolbox skill).

## macOS system binaries — present, and routinely forgotten

`plutil` (plists) · `defaults` (app preferences) · `launchctl` (launchd agents — how you inspect
the `brew autoupdate` job) · `log show --predicate` (unified logging; the only way to see why a
background agent failed) · `mdfind` (Spotlight, faster than `fd` over a whole volume) · `sqlite3` ·
`sips` (quick image convert/resize) · `textutil` (rtf/doc/html/txt) · `codesign` · `xxd` ·
`pbcopy`/`pbpaste` · `caffeinate` · `sw_vers` · `system_profiler` · `open` · `networksetup` ·
`qlmanage`.

## Traps

- ⚠ **GNU coreutils are `g`-prefixed** — `gls`, `gdate`, `gsort`. Plain `ls`, `date`, and `sed`
  are **BSD**, and there is no `gsed`. Prefer `sd`, `rg`, or fish's `string replace` over BSD-safe
  `sed -i ''` expressions.
- ⚠ `make` *is* GNU make — its gnubin precedes `/usr/bin` (`gmake` is the same binary).
- ⚠ `jq` and `trash` are **macOS 27 system binaries** in `/usr/bin`, not Homebrew.
- ⚠ `curl` is Homebrew's keg-only build and `~/.config/curl/curlrc` sets `fail`, so a 404 exits
  **22**, not 0. `python3` is Homebrew's; prefer `uv run` for anything project-scoped.
- ⚠ `java` is the `/usr/bin/java` stub dispatching to the `temurin@25` cask.
- ⚠ **`uv tool` shims live in `~/.local/bin`**, on `$PATH` only via `fish/conf.d/uv.fish` — a shell
  that did not inherit fish's environment will not see `gdformat`/`gdlint`.
- ⚠ Your Bash tool runs under **zsh** — fish functions and abbreviations do not exist for you,
  including the 1Password shell-plugin wrapper for `gh`. Invoke binaries directly.

## Not installed

Do not assume these, and do not write a command or example against one: `podman`, `mvn`/`gradle`,
`gsed`, `prettier`, `eslint`, `tre`, `chafa`, `AtomicParsley`, `macos-defaults`, `pip`,
`clang-format`. ⚠ `clang-format` is absent **on purpose**: Godot pins v21.1.7 through
`pre-commit`, which fetches its own copy — a formula would shadow it at a different version and
reformat the entire engine; run `pre-commit run clang-format`. `pip3` resolves only as an artefact
of Homebrew's python — never install with it. If one of these genuinely is the right answer, say so
and say it is not installed. Absence here is not evidence for deliberately untracked classes:
VS Code extensions and `bun`/`uv`/`npm` globals are recorded nowhere.

## Keeping this file true

⚠ **Declared intent is not verified state.** `command -v` reports "missing" for keg-only formulae
(`curl`), prefixed ones (`make` → `gmake`), and formulae shipping no binary (`pam-reattach`) — use
`brew list --versions <formula>` for those. **If you install something while working, add it to the
`Brewfile`, this file's manifest, and the toolbox skill in the same change** — that is the
`brewfile` skill, and `brewfile-audit.sh` checks both directions.
