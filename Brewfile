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
brew "less"       # pager
brew "micro"      # nano: terminal editor
brew "btop"       # top: resource monitor
brew "macchina"   # neofetch: system info
brew "grc"        # command output colouriser
brew "gum"        # interactive prompts in shell scripts
brew "coreutils"  # gnu versions of the bsd core utils

## development
brew "git"              # source control
brew "git-lfs"          # git: large file storage
brew "git-delta"        # less: git diff pager
brew "git-filter-repo"  # git: history rewriting
brew "gh"               # git: github cli
brew "act"              # gh: run github actions locally
brew "lefthook"         # git: hook manager — runs the pre-commit/pre-push gates in lefthook.yml
brew "node"             # js runtime
brew "bun"              # node: fast js runtime and package manager
brew "uv"               # pip: python package manager
brew "make"             # build tool
brew "scons"            # make: python-based build system
brew "shellcheck"       # bash: static analysis for hook scripts

## networking
brew "curl"     # data transfer
brew "xh"       # curl: ergonomic http client
brew "wget"     # recursive downloader
brew "openssh"  # ssh client and server
brew "nmap"     # port scanner
brew "iperf3"   # bandwidth benchmark
brew "dnsperf"  # dns benchmark
brew "doge"     # dig: dns client
brew "caddy"    # web server and reverse proxy

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
brew "mas"      # mac app store cli
brew "duti"     # default app associations by file type
brew "fswatch"  # file change monitor

# ===============================
# 🛢️ casks
# ===============================

## development
cask "visual-studio-code@insiders"  # main ide (insiders channel)
cask "ghostty"                      # terminal emulator
cask "godot"                        # game engine
cask "claude-code@latest"           # terminal ai coding agent
cask "temurin@25"                   # java runtime (prism launcher)

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

## media
cask "iina"          # quicktime: media player
cask "transmission"  # bittorrent client

## communication & network
cask "discord"    # voice and text chat
cask "protonvpn"  # vpn client

## games
cask "steam"          # game distribution platform
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
