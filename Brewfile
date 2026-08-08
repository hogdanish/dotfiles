#
# ethan's global brewfile
#
# comments describe *why* something is installed, not what it is.
# tools that replace, extend, or serve another are written '<original>: <purpose>'.
# a commented-out entry is wanted but deliberately not installed yet — the comment
# says what it is waiting on. leave it; it is not drift.
#
# audit with: .claude/skills/brewfile/scripts/brewfile-audit.sh Brewfile
#

# ===============================
# 🚰 taps
# ===============================

# touch id support for gpg
tap "jorgelbg/tap", trusted: true

# unattended `brew update && upgrade && cleanup` on a launchd timer.
# command-scoped trust, not `trusted: true` — this permits only `brew autoupdate`,
# not every present and future formula, cask and command in the tap.
tap "domt4/autoupdate", trusted: {command: "autoupdate"}

# ===============================
# 🧪 formulae
# ===============================

## shell & terminal
brew "fish"       # main shell
brew "starship"   # prompt
brew "atuin"      # ctrl-r: searchable shell history
brew "fzf"        # fuzzy finder
brew "zoxide"     # cd: frecency-ranked jumping
brew "eza"        # ls: dir listing with icons
brew "bat"        # cat: syntax-highlighted viewer
brew "fd"         # find: simpler file search
brew "ripgrep"    # grep: fast recursive search
brew "sd"         # sed: literal-by-default find & replace, no bsd/gnu split
brew "yq"         # jq: the same for yaml, toml, xml and csv
brew "gron"       # jq: flattens json to greppable lines for rg
brew "less"       # pager
brew "micro"      # nano: terminal editor
brew "btop"       # top: resource monitor
brew "fastfetch"  # neofetch: system info
brew "grc"        # command output colouriser
brew "gum"        # interactive prompts in shell scripts
brew "coreutils"  # gnu versions of the bsd core utils
brew "moreutils"  # coreutils: sponge, ts, errno, ifne — the ones unix never shipped

## development
brew "git"              # source control
brew "git-lfs"          # git: large file storage
brew "git-delta"        # less: git diff pager
brew "git-filter-repo"  # git: history rewriting
brew "difftastic"       # diff: structural, ast-aware diff (delta still pages git's)
brew "ast-grep"         # rg: structural search and rewrite by syntax tree, not regex
brew "hyperfine"        # time: statistical benchmarking with warmup and medians
brew "tokei"            # wc: language and loc breakdown for orienting in a repo
brew "gh"               # git: github cli
brew "act"              # gh: run github actions locally
brew "lefthook"         # git: hook manager — runs the pre-commit/pre-push gates in lefthook.yml
brew "node"             # js runtime
brew "bun"              # node: fast js runtime and package manager
brew "uv"               # pip: python package manager
brew "rustup"           # rust toolchain manager
brew "cargo-nextest"    # cargo: parallel test runner
brew "cargo-audit"      # cargo: vulnerability scanner
brew "cargo-deny"       # cargo: dependency policy checks
brew "sccache"          # rustc: shared compilation cache
brew "go"               # go toolchain — runtime for the COMMONGROUNDS webtransport relay (server/relay/)
brew "make"             # build tool
brew "scons"            # make: python-based build system
brew "ccache"           # scons: compiler cache — godot's sconstruct picks it up automatically.
#                         highest-leverage install for ~/Projects/hogdot, a godot fork rebuilt
#                         after every ported hunk. xdg-native since 4.0; conf at ~/.config/ccache
brew "pre-commit"       # lefthook: godot's own .pre-commit-config.yaml — the ONLY way to run its
#                         gates. it vendors clang-format v21.1.7 itself, which is why no
#                         clang-format formula is installed: brew's would be a different version
#                         and would reformat the whole engine
brew "emscripten"       # llvm: c/c++ -> wasm. builds hogdot's web export templates (webgpu=yes,
#                         --use-port=emdawnwebgpu). 6.0.5; godotwebgpu shipped on 5.0.0 and its
#                         floor is 4.0.10, so this is one unverified major ahead — if a web build
#                         breaks, suspect the toolchain before the port
brew "glslang"          # emscripten: khronos glsl->spir-v reference compiler. hard dependency of
#                         hogdot's `webgpu=yes` builds ONLY: drivers/webgpu/wgsl_precompile.py
#                         shells out to `glslangValidator` for 70 shader files to generate
#                         wgsl_precompiled.gen.h. ⚠ unlike clang-format, the version skew is fine —
#                         brew ships 16.5.0 and godot vendors 16.1.0, but they never meet in one
#                         process; the precompiled table is keyed on a spir-v hash, so a mismatch
#                         costs cache hits, never correctness
brew "shellcheck"       # bash: static analysis for hook scripts
brew "shfmt"            # shellcheck: the formatter half, for the same hook scripts
brew "vale"             # prose style linter

## networking
brew "curl"         # data transfer
brew "xh"           # curl: ergonomic http client
brew "wget"         # recursive downloader
brew "openssh"      # ssh client and server
brew "nmap"         # port scanner
brew "iperf3"       # bandwidth benchmark
brew "dnsperf"      # dns benchmark
brew "doge"         # dig: dns client
brew "caddy"        # web server and reverse proxy
brew "mkcert"       # locally-trusted dev certs — ⚠ NOT sufficient for browser WebTransport over QUIC
brew "nss"          # mkcert: firefox/chromium trust-store support
brew "cloudflared"  # cloudflare tunnel: real https/quic hostname for a local origin — mkcert's gap
brew "linode-cli"   # linode: official cloud control-plane cli; credentials supplied by 1password

## multimedia & graphics
brew "ffmpeg"       # video and audio processing
brew "imagemagick"  # image processing
brew "yt-dlp"       # media downloader
brew "sox"          # audio sample conversion
brew "ghostscript"  # imagemagick: postscript and pdf rendering
brew "librsvg"      # imagemagick: svg rendering
brew "woff2"        # web font conversion

## security & privacy
brew "betterleaks"   # gitleaks: secret scanner — blocks a credential reaching this public repo
brew "gnupg"         # encryption and commit signing
brew "pinentry-mac"  # gnupg: pinentry for macos
brew "pam-reattach"  # sudo: touch id inside tmux and screen
brew "jorgelbg/tap/pinentry-touchid"  # gnupg: touch id pinentry

## macos & system
brew "mas"        # mac app store cli
brew "duti"       # default app associations by file type
brew "fswatch"    # file change monitor
brew "watchexec"  # fswatch: runs a command on change, instead of just reporting it

# ===============================
# 📦 javascript tools
# ===============================
#
# `npm` entries are reserved for upstream-supported global clis that need to resolve from every
# shell and agent. project tools remain project-local and bun remains the default package manager.

npm "cf"             # cloudflare: account-wide cli technical preview
npm "firecrawl-cli"  # web extraction for the firecrawl agent plugin

# ===============================
# 🐍 uv tools
# ===============================
#
# `brew bundle` installs these with `uv tool install` (homebrew 6 dsl; options are `with:` and
# `source:`). they are here rather than outside the file because this is the machine's inventory
# and a python cli is still declared software — brew bundle check/cleanup cover them like any
# formula.
#
# ⚠ the shims land in ~/.local/bin, which no shell had on $PATH until fish/conf.d/uv.fish was
# added 2026-07-30. an installed uv tool is not automatically a reachable one.

uv "gdtoolkit"  # gdformat/gdlint: the only headless gdscript formatter and linter

# ===============================
# 🛢️ casks
# ===============================

## development
cask "visual-studio-code@insiders"  # main ide (insiders channel)
cask "ghostty"                      # terminal emulator
cask "godot"                        # game engine
cask "claude-code@latest"           # terminal ai coding agent
cask "codex"                        # openai terminal coding agent
cask "temurin@25"                   # java runtime (prism launcher)
cask "orbstack"                     # docker desktop: containers/vms, lighter and faster on apple silicon
cask "google-chrome"                # browser — driven by the claude-in-chrome extension for web/devtools work

## fonts
cask "font-commit-mono"            # editor font
cask "font-commit-mono-nerd-font"  # commit mono patched with nerd icons, for the terminal
cask "font-sf-pro"                 # apple system font

## design & creative
cask "figma"       # design tool (stable)
cask "figma@beta"  # design tool (beta channel)
cask "blender"     # 3d creation suite

## productivity & utilities
cask "1password@beta"      # password manager (beta channel)
cask "1password-cli@beta"  # 1password: cli and shell plugins
cask "raycast"             # spotlight: launcher
cask "alt-tab"             # macos app switcher: windows-style switching
cask "stats"               # activity monitor: menu bar system monitor
cask "betterdisplay"       # macos display settings: hidpi, virtual displays and brightness
# cask "thaw"              # ice: menu bar manager — held until stable on macos 27 golden gate
cask "cleanshot"           # macos screenshots: capture and annotate
cask "appcleaner"          # uninstaller that clears leftover files
cask "keka"                # archive utility: file archiver
cask "kekaexternalhelper"  # keka: registers it as the default archive handler
cask "obsidian"            # markdown knowledge base
cask "claude"              # ai assistant desktop app
cask "chatgpt"             # openai assistant and codex desktop app

## media
cask "iina"          # quicktime: media player
cask "obs"           # screen recording and live streaming
cask "transmission"  # bittorrent client

## communication & network
cask "discord"    # voice and text chat
cask "protonvpn"  # vpn client

## games
cask "steam"          # game distribution platform
cask "epic-games"     # game distribution platform
cask "prismlauncher"  # minecraft launcher

# ===============================
# 🍎 app store
# ===============================

## safari extensions
mas "1Password for Safari", id: 1569813296  # 1password: safari integration
mas "Wipr", id: 1662217862                  # safari: content blocker
mas "Consent-O-Matic", id: 1606897889       # safari: auto-answers cookie consent dialogs
mas "SponsorBlock", id: 1573461917          # safari: skips youtube sponsor segments

## apps
mas "Passepartout", id: 1433648537  # wireguard/openvpn client
mas "Yoink", id: 457622435          # drag-and-drop file shelf
