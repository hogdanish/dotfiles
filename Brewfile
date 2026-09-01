#
# ethan's global brewfile
#
# tools that replace, extend, or serve another are written '<original>: <purpose>'.
#

# ===============================
# 🚰 taps
# ===============================

# touch id support for gpg
tap "jorgelbg/tap", trusted: true

# homebrew autoupdate
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
brew "sd"         # sed: literal-by-default find & replace
brew "yq"         # jq: the same for yaml, toml, xml and csv
brew "gron"       # jq: flattens json to greppable lines
brew "less"       # pager
brew "micro"      # nano: terminal editor
brew "btop"       # top: resource monitor
brew "fastfetch"  # neofetch: system info
brew "grc"        # command output colouriser
brew "gum"        # interactive prompts in shell scripts
brew "coreutils"  # gnu versions of the bsd core utils
brew "moreutils"  # coreutils: sponge, ts, errno, ifne
brew "bash"       # bash: gnu 5.x — macos ships 3.2, which mis-runs `set -u` array refs

## development
brew "git"              # source control
brew "git-lfs"          # git: large file storage
brew "git-delta"        # less: git diff pager
brew "git-filter-repo"  # git: history rewriting
brew "difftastic"       # diff: structural, ast-aware diff
brew "ast-grep"         # rg: structural search and rewrite by syntax tree
brew "age"              # gpg: file encryption; decrypts the commongrounds db backups
brew "hyperfine"        # time: statistical benchmarking
brew "tokei"            # wc: language and loc breakdown
brew "gh"               # git: github cli
brew "act"              # gh: run github actions locally
brew "lefthook"         # git: hook manager
brew "rumdl"            # markdown linter/formatter; aligns tables (commongrounds .rumdl.toml)
brew "node"             # js runtime
brew "bun"              # node: fast js runtime and package manager
brew "uv"               # pip: python package manager
brew "rustup"           # rust toolchain manager
brew "cargo-nextest"    # cargo: parallel test runner
brew "cargo-audit"      # cargo: vulnerability scanner
brew "cargo-deny"       # cargo: dependency policy checks
brew "sccache"          # rustc: shared compilation cache
brew "go"               # go toolchain
brew "make"             # build tool
brew "scons"            # make: python-based build system
brew "ccache"           # scons: c/c++ compiler cache
brew "pre-commit"       # lefthook: for upstream repos that use it
brew "emscripten"       # llvm: c/c++ -> wasm
brew "glslang"          # emscripten: glsl -> spir-v shader compiler
brew "shellcheck"       # bash: static analysis for hook scripts
brew "shfmt"            # shellcheck: the formatter half

## networking
brew "curl"                 # data transfer
brew "xh"                   # curl: ergonomic http client
brew "wget"                 # recursive downloader
brew "openssh"              # ssh client and server
brew "nmap"                 # port scanner
brew "iperf3"               # bandwidth benchmark
brew "dnsperf"              # dns benchmark
brew "doge"                 # dig: dns client
brew "caddy"                # web server and reverse proxy
brew "mkcert"               # locally-trusted dev certs
brew "nss"                  # mkcert: firefox/chromium trust-store support
brew "cloudflared"          # cloudflare tunnel: https/quic hostname for a local origin
brew "cloudflare-wrangler"  # wrangler: cloudflare workers cli
brew "linode-cli"           # linode: official cloud control-plane cli

## multimedia & graphics
brew "ffmpeg"       # video and audio processing
brew "vorbis-tools" # audio encoding
brew "imagemagick"  # image processing
brew "yt-dlp"       # media downloader
brew "sox"          # audio sample conversion
brew "ghostscript"  # imagemagick: postscript and pdf rendering
brew "librsvg"      # imagemagick: svg rendering
brew "woff2"        # web font conversion

## security & privacy
brew "betterleaks"   # gitleaks: secret scanner
brew "gnupg"         # encryption and commit signing
brew "pinentry-mac"  # gnupg: pinentry for macos
brew "pam-reattach"  # sudo: touch id inside tmux and screen
brew "jorgelbg/tap/pinentry-touchid"  # gnupg: touch id pinentry

## macos & system
brew "mas"        # mac app store cli
brew "duti"       # default app associations by file type
brew "fswatch"    # file change monitor
brew "watchexec"  # fswatch: runs a command on change

# ===============================
# 📦 node
# ===============================

npm "cf"             # cloudflare: account-wide cli technical preview
npm "firecrawl-cli"  # web extraction for the firecrawl agent plugin

# ===============================
# 🐍 python
# ===============================

uv "gdtoolkit"  # gdformat/gdlint: headless gdscript formatter and linter

# ===============================
# 🛢️ casks
# ===============================

## development
cask "visual-studio-code@insiders"  # main ide (insiders channel)
cask "rider"                        # .net ide: c# and unity
cask "ghostty"                      # terminal emulator
cask "godot"                        # game engine
# ⚠ claude code is deliberately NOT a cask — do not add one back. the cask hardcodes a
# `version` + sha256 that a bot must bump per release, so it trails the real channel by days
# (it was pinned to 2.1.252 while `latest` served 2.1.257 on 2026-09-01) and no amount of
# `brew upgrade` closes the gap. the native installer self-updates instead — `claude doctor`
# reports install method native, auto-updates enabled, channel latest. to reinstall:
#   curl -fsSL https://claude.ai/install.sh | bash -s latest
cask "codex"                        # openai terminal coding agent
cask "temurin@25"                   # java runtime (prism launcher)
cask "orbstack"                     # docker desktop: containers and linux vms
cask "google-chrome"                # browser: driven by the claude-in-chrome extension
cask "google-chrome@canary"         # browser (canary channel)
cask "perforce"                     # perforce cli (p4): version control
cask "p4v"                          # perforce gui client (with p4merge)

## fonts
cask "font-commit-mono"            # editor font
cask "font-commit-mono-nerd-font"  # commit mono: nerd icons, for the terminal
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
cask "betterdisplay"       # macos display settings: hidpi and virtual displays
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
cask "crossover"      # wine: runs windows apps and games

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
