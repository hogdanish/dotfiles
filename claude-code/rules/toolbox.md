<!-- toolbox-manifest — verified by .claude/skills/brewfile/scripts/brewfile-audit.sh in the
     dotfiles repo. block html comments are stripped before this file enters context, so this
     costs nothing to carry. update both lists whenever the prose below changes.

verify-present: fish starship atuin fzf zoxide eza bat fd rg less micro btop macchina grc gum gls
  gdate gsort git git-lfs delta git-filter-repo gh act lefthook node bun uv make gmake scons
  shellcheck curl xh wget ssh nmap iperf3 dnsperf doge caddy ffmpeg ffprobe magick yt-dlp sox soxi
  gs rsvg-convert woff2_compress woff2_decompress betterleaks gpg pinentry-touchid pinentry-mac mas
  duti fswatch jq trash java python3 code-insiders godot blender op
verify-absent: docker docker-compose podman cargo rustup go mvn gradle yq gsed shfmt prettier
  eslint tre chafa AtomicParsley macos-defaults pip
-->

# The CLI toolbox on this machine

Every command named below is **installed and verified present** (`command -v`, 2026-07-29) unless the
final *Not installed* section says otherwise. **Do not check whether one exists before using it, and
never offer to install it — just use it.** When you run
a shell command, or write a script or example for Ethan, reach for the tool in the *Use* column
rather than the default it replaces. ⚠ This is about *shell* work: for reading and editing files your
Read/Edit/Grep tools still beat piping `bat` or `sed` into context.

`~/.config/Brewfile` is the complete inventory — GUI apps included, with a one-line *why* per entry.
Read it only when you need something not named below.

## Use instead of the default

| Job | Use | Instead of |
| --- | --- | --- |
| Find files by name | `fd` | `find` |
| Search file contents | `rg` (ripgrep) | `grep` |
| List a directory | `eza` (`--tree`, icons) | `ls` |
| Show a file to a human | `bat` (`-pp` for no pager/decoration) | `cat` |
| Delete something | `trash` (recoverable) | `rm` |
| HTTP request | `xh` | `curl` |
| DNS lookup | `doge` | `dig` |
| Watch processes | `btop` | `top` |
| Edit in a terminal | `micro` | `nano`/`vim` |
| Run/install Python | `uv run`, `uv tool install` | `pip`, `venv` |
| Run/install JS | `bun` (`node` is also present) | `npm`/`npx` |
| Diff and blame paging | `delta` (git-delta — already wired into git) | — |
| Prompt or print for a human | `gum` (the `gum` skill) | `read`/`echo`/`tput` |
| Jump to a directory | `z` (zoxide — interactive fish only) | `cd` |

## Reach for these without asking

- **Media** — `ffmpeg`/`ffprobe` for any transcode, trim, concat or probe. `sox`/`soxi` for raw audio
  sample-rate and format work. `yt-dlp` for any media URL. ⚠ Never read or pass
  `~/.config/yt-dlp/cookies.txt`.
- **Images** — `magick` (imagemagick 7). ⚠ The legacy `convert` still resolves but is deprecated;
  write `magick`. `rsvg-convert` (librsvg) gives it SVG input and `gs` (ghostscript) PDF/PostScript.
- **Fonts** — `woff2_compress` / `woff2_decompress` (woff2).
- **Network** — `caddy file-server` for an instant local static server or reverse proxy; `wget` to
  mirror recursively; `nmap` to scan ports; `iperf3` for bandwidth and `dnsperf` for DNS benchmarks;
  `ssh` is openssh's, ahead of Apple's.
- **Git and GitHub** — `gh` (but the GitHub MCP server comes first), `git-lfs`, `git-filter-repo` for
  history rewriting, `lefthook` for hooks.
- **Homebrew and the App Store** — ⚠ Homebrew **updates and upgrades itself** every 12 h via a
  launchd agent (`brew autoupdate`; logs at `brew autoupdate logs`). Do not propose `brew update` as
  a fix, and do not treat an out-of-date package as drift. ⚠ The agent deliberately cannot `sudo`,
  so two things are outside it: the `pkg`-installer casks `temurin@25` and `font-sf-pro`, and
  **every `mas` app** (`mas update` requires root — `mas help update`). All of that is what the
  **`brewup`** fish function is for; suggest it rather than a raw command chain. ⚠ Plain `brew` is
  **not** wrapped in `op`; invoke it directly.
- **Correctness and secrets** — `shellcheck` every bash script you write, `betterleaks` to scan
  content for credentials, `op` for every credential (the `auth` skill), `jq` for JSON.
- **System** — `fswatch` to watch paths, `duti` for default-app associations, `mas` for the App Store,
  `macchina` for system info, `make` (GNU) and `scons` to build, `less` as pager, `grc` to colourise.
  `fish`, `starship`, `atuin`, `fzf` are the shell furniture and are already configured.
- **GUI apps with a CLI** — `code-insiders`, `godot`, `blender`.

## Traps

- ⚠ **GNU coreutils are `g`-prefixed and not on `$PATH` under their own names** — `gls`, `gdate`,
  `gsort`. Plain `ls`, `date` and `sed` are **BSD**, and there is no `gsed`: write BSD-safe
  expressions (`sed -i ''`) or use `rg` / fish's `string replace` instead.
- ⚠ `make` *is* GNU make — its gnubin precedes `/usr/bin` (`gmake` is the same binary).
- ⚠ `jq` and `trash` are **macOS 27 system binaries** in `/usr/bin`, not Homebrew.
- ⚠ `curl` is Homebrew's keg-only build and `~/.config/curl/curlrc` sets `fail`, so a 404 exits
  **22**, not 0. `python3` is Homebrew's; prefer `uv run` for anything project-scoped.
- ⚠ `java` is the `/usr/bin/java` stub dispatching to the `temurin@25` cask.
- ⚠ **`act` cannot run.** It needs a container runtime and none is installed. `pam-reattach` ships a
  PAM module with no binary — check that class of formula with `brew list --versions`, not
  `command -v`. `gnupg`'s `gpg` uses `pinentry-touchid` (`pinentry-mac` is the fallback).
- ⚠ Your Bash tool runs under **zsh**, so fish functions and abbreviations do not exist for you —
  including the 1Password shell-plugin wrappers for `gh` and `brew`. Invoke binaries directly.

## Not installed

Do not reach for, propose, or write examples against: `docker`/`docker-compose`, `podman`,
`rustup`/`cargo`, `go`, `mvn`/`gradle`, `yq`, `gsed`, `shfmt`, `prettier`, `eslint`, `tre`, `chafa`,
`AtomicParsley`, `macos-defaults`, `pip`. (`pip3` resolves only as an artefact of Homebrew's python —
never use it to install anything.) Absence here is not evidence for deliberately untracked classes:
VS Code extensions and `bun`/`uv`/`npm` globals are recorded nowhere.
