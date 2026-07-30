#!/bin/sh
#
# bootstrap.sh — bring a fresh macOS machine up to this configuration.
#
# ⚠ POSIX sh on purpose. At the moment this runs, fish, gum, brew and op may none of them
#   exist yet — this is the script that installs them. It uses gum when gum is present and
#   plain printf otherwise, and it checks every dependency before using it.
#
# Safe to re-run: every step is idempotent and skips work that is already done.
#
#   curl -fsSL https://raw.githubusercontent.com/hogdanish/dotfiles/main/scripts/bootstrap.sh | sh
#   # ...or, once the repo is already present:
#   ~/.config/scripts/bootstrap.sh

set -eu

REPO_URL="${DOTFILES_REPO:-git@github.com:hogdanish/dotfiles.git}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BREW_PREFIX=/opt/homebrew

# ── output ──────────────────────────────────────────────────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }

say() {
    if have gum; then gum log --level "$1" -- "$2"; else printf '%s: %s\n' "$1" "$2" >&2; fi
}
die() { say error "$1"; exit 1; }

step() {
    if have gum; then
        gum style --bold --foreground '#7aa2f7' "▸ $1"
    else
        printf '\n▸ %s\n' "$1"
    fi
}

# ask() — yes/no. ⚠ gum confirm defaults to YES, so anything destructive passes
# --default=false explicitly. Falls back to `read` when gum is absent, and answers "no"
# when there is no tty at all, so a piped run never destroys anything unattended.
ask() {
    if [ ! -t 0 ]; then return 1; fi
    if have gum; then
        gum confirm --default=false "$1"
    else
        printf '%s [y/N] ' "$1"
        read -r reply
        case "$reply" in [yY]*) return 0 ;; *) return 1 ;; esac
    fi
}

# ── 1. xcode command line tools ─────────────────────────────────────────────────
step 'Xcode command line tools'
if xcode-select -p >/dev/null 2>&1; then
    say info 'already installed'
else
    say warn 'installing — accept the GUI prompt, then re-run this script'
    xcode-select --install || true
    exit 0
fi

# ── 2. homebrew ─────────────────────────────────────────────────────────────────
step 'Homebrew'
if have brew; then
    say info "already installed ($(brew --version | head -1))"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x "$BREW_PREFIX/bin/brew" ] || die "expected brew at $BREW_PREFIX/bin/brew"
eval "$("$BREW_PREFIX/bin/brew" shellenv sh)"

# ── 3. seed the repo into ~/.config ─────────────────────────────────────────────
# ⚠ `git clone` refuses a non-empty directory, and ~/.config is never empty on a machine
#   that has been booted. `reset --mixed` sets HEAD and the index from the remote while
#   leaving the working tree untouched, so `git status` shows exactly what differs BEFORE
#   anything is overwritten. `checkout -f` would silently clobber with no recovery.
step 'Dotfiles repo'
mkdir -p "$CONFIG"
if [ -d "$CONFIG/.git" ]; then
    say info "already a repo: $CONFIG"
else
    git init -b main "$CONFIG"
    git -C "$CONFIG" remote add origin "$REPO_URL"
    git -C "$CONFIG" fetch origin main
    git -C "$CONFIG" reset --mixed origin/main
    git -C "$CONFIG" branch --set-upstream-to=origin/main main 2>/dev/null || true

    say warn 'the files below already exist locally and differ from the repo:'
    git -C "$CONFIG" status --short
    if ask 'Overwrite them with the repo version?'; then
        git -C "$CONFIG" checkout -- .
        say info 'working tree now matches the repo'
    else
        say warn 'left as-is — resolve by hand, then: git -C ~/.config checkout -- .'
    fi
fi

# ── 4. packages ─────────────────────────────────────────────────────────────────
step 'Packages (brew bundle)'
if [ -f "$CONFIG/Brewfile" ]; then
    brew bundle install --file="$CONFIG/Brewfile" || say warn 'some packages failed — see above'
else
    die "no Brewfile at $CONFIG/Brewfile"
fi

# ── 5. git hooks ────────────────────────────────────────────────────────────────
# ⚠ .git/hooks is never version-controlled and never arrives via clone. This is required
#   once per clone or the secret gate silently does not exist.
step 'Git hooks'
if have lefthook; then
    (cd "$CONFIG" && lefthook install)
else
    say warn 'lefthook missing — the pre-commit secret gate is NOT active'
fi

# ── 6. home-level dotfiles ─────────────────────────────────────────────────────
step 'Link home-level dotfiles'
if have fish; then
    fish "$CONFIG/scripts/link-home.fish" || say warn 'some links need attention (--force to replace real files)'
else
    say warn 'fish missing — skipping; re-run scripts/link-home.fish once fish is installed'
fi

# ── 7. 1password ────────────────────────────────────────────────────────────────
# No secret is ever written to disk here. The shell plugins store only opaque account/vault
# ids under ~/.config/op, which is deliberately NOT tracked — it is machine state and would
# be wrong on another machine. Credentials are resolved at use time by `op run`.
step '1Password'
if have op; then
    if op account list >/dev/null 2>&1; then
        say info 'already signed in'
    else
        say warn 'run "op signin" in your own terminal, then: op plugin init gh brew'
    fi
else
    say warn 'op missing — install the 1password-cli@beta cask'
fi

# ── 8. tool caches that must be built once ──────────────────────────────────────
step 'Tool caches'
# ⚠ without this, bat falls back silently AND delta's syntax-theme = laramie breaks with it.
# ⚠ each line ends in `|| true`. under `set -e`, an AND-OR list whose LAST command fails
#   still exits the script — so a missing tool here would abort the bootstrap silently.
have bat && bat cache --build >/dev/null 2>&1 && say info 'bat theme cache built' || true
have fish && fish -c 'fish_update_completions' >/dev/null 2>&1 && say info 'fish completions generated' || true
have duti && [ -f "$CONFIG/duti/defaults.duti" ] && duti "$CONFIG/duti/defaults.duti" 2>/dev/null && say info 'file associations applied' || true

# ── 9. fish as the interactive shell ────────────────────────────────────────────
# ⚠ The login shell is deliberately left as /bin/zsh — Ghostty launches fish explicitly.
#   fish still needs to be in /etc/shells for `chsh` to be an option later.
step 'Shell registration'
FISH_BIN="$BREW_PREFIX/bin/fish"
if [ -x "$FISH_BIN" ]; then
    if grep -qxF "$FISH_BIN" /etc/shells 2>/dev/null; then
        say info 'fish already registered in /etc/shells'
    elif ask "Add $FISH_BIN to /etc/shells? (needs sudo)"; then
        echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
        say info 'registered'
    fi
else
    say warn 'fish not installed'
fi

# ── done ────────────────────────────────────────────────────────────────────────
step 'Done'
say info 'verify with: ~/.config/scripts/audit-config.fish'
say info 'remaining manual steps: op signin · Touch ID for sudo (see the auth skill)'
