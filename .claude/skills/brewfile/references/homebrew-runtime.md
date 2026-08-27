# Homebrew runtime — unattended updates and the environment brew actually sees

How Homebrew is configured to run on this machine, as opposed to what the `Brewfile` declares. None
of it is re-derivable from this repo, which is why it is written down.

⚠ `brew config | rg HOMEBREW_` is the only proof of what brew **actually** has set. A config file
saying otherwise is a hypothesis.

---

## 1. Unattended updates

The `domt4/autoupdate` tap is declared with **command-scoped** trust
(`trusted: {command: "autoupdate"}`, not `trusted: true`) — it permits only `brew autoupdate`, not
every present and future formula, cask and command in the tap. A launchd agent runs
update/upgrade/cleanup **every 12 h, AC power only**, notifying only on failure. Logs:
`brew autoupdate logs`; status: `brew autoupdate status`.

⚠ **It runs without `--sudo` on purpose.** That flag raises a pinentry password dialog with no Touch
ID path at unpredictable times. The price is that the `pkg` casks **`temurin@25`** and
**`font-sf-pro`** cannot upgrade in the background; upgrade them by hand
(`brew upgrade --cask temurin@25`), where Touch ID covers `sudo`.

⚠ **The state is not re-derivable from this repo** — the plist and the generated script live under
`~/Library`. To change a flag: `brew autoupdate delete` **then** `start`. A bare `start` silently
reuses the old script.

⚠ **`start` bakes a snapshot** of `PATH`, `HOMEBREW_CACHE`, `HOMEBREW_LOGS`, `HOMEBREW_DEVELOPER`,
`HOMEBREW_NO_ANALYTICS`, `HOMEBREW_CASK_OPTS` and `SUDO_ASKPASS` into that script. Run it from a
shell whose environment you want; nothing else is inherited.

## 2. The App Store is off-limits to agents

`mas update` requires root and hangs without a GUI session, so no agent and no timer touches it.
`fish/functions/brewup.fish` is the human path: `brew update`/`upgrade` → `sudo mas upgrade` **only**
when `mas outdated` is non-empty → `brew cleanup`. It replaced the `brewup` abbreviation, because an
abbr cannot hold the conditional.

⚠ **Never "fix" this with a `NOPASSWD` sudoers rule for `mas`.** It lives in user-writable
`/opt/homebrew/bin`, so that rule is a trivial root escalation.

## 3. Only fish exports `XDG_CONFIG_HOME` — and brew reads user config from it

A brew launched by **launchd, cron or a GUI app** looked in `~/.homebrew`, found no `trust.json`,
and silently treated every third-party tap as untrusted.

**Fix:** `/opt/homebrew/etc/homebrew/brew.env` holds
`HOMEBREW_XDG_CONFIG_HOME=/Users/ethan/.config`, written by `scripts/bootstrap.sh` step 2 — which
must run **before** `brew bundle`.

⚠ That file accepts only `HOMEBREW_*`, `SUDO_ASKPASS` and proxy variables. A plain
`XDG_CONFIG_HOME=` line is dropped silently, and `HOMEBREW_USER_CONFIG_HOME` is on brew's forbidden
list.

⚠ Verify with `env -u XDG_CONFIG_HOME brew trust`, **never** plain `brew trust` — a fish-launched
brew passes either way and proves nothing.

## 4. npm had the identical failure (closed 2026-07-30)

Only fish exports `NPM_CONFIG_USERCONFIG`, so npm outside fish never read `npm/npmrc` and fell back
to `~/.npm`.

**Floor:** the global config `/opt/homebrew/etc/npmrc` holds `cache=` (bootstrap step 4) and is read
regardless of launch context. npm's precedence means it can only ever be the fallback, never an
override. `logs-dir` follows the cache. The path is not owned by the `node` formula, so upgrades
keep it.

## 5. `HOMEBREW_*` booleans

⚠ **Never write `set -gx HOMEBREW_<X> 0`.** Every `HOMEBREW_*` variable used here is `boolean: :set`
— `0` *enables* it. That is how `HOMEBREW_DEVELOPER 0` silently ran developer mode until
2026-07-30. The only "off" is omitting the line, and `brew config` proves it.

⚠ `HOMEBREW_VERIFY_ATTESTATIONS` is deliberately **not** set: it needs a GitHub token and would
break the unattended autoupdate job. See the `auth` skill for why `fish/functions/brew.fish` was
removed and must not come back.
