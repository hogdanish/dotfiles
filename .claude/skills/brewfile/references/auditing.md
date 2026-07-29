# Auditing installed software against the Brewfile

How to work out what is *actually* installed on purpose, diff it against `Brewfile`, and classify the
result. Every command here was run and verified on this machine (Homebrew 6.0.13, macOS 27).

`scripts/brewfile-audit.sh` implements all of this. Read this file when the script's output needs
interpreting, when it needs changing, or when auditing something it does not cover.

---

## 1. The core problem: "installed" ≠ "wanted"

`brew list` reports ~200 formulae on a typical machine; ~50 of them were asked for and the rest are
dependencies. A Brewfile must contain **only the intentionally-installed set**, because `brew bundle
install` reinstalls dependencies automatically, and listing them pins transitive detail that will rot.

## 2. Formulae — getting the requested set

**Use this:**

```sh
brew info --json=v2 --installed \
  | jq -r '.formulae[] | select(.installed[0].installed_on_request) | .full_name' | sort
```

`installed_on_request` is a per-install boolean Homebrew records when *you* named the package.

**`brew leaves --installed-on-request` is the common shortcut and is subtly narrower.** `brew leaves` means
"not a dependency of any other installed formula", and the flag intersects that with on-request. So a
formula you explicitly installed **and** which later became some other package's dependency silently drops
out of `leaves` while remaining in the JSON query.

> On this machine the two lists are currently identical (49 entries each), so the difference is latent, not
> active. It will appear the first time you install something that depends on a package you already asked
> for — `node`, `python`, `make` and `coreutils` are the usual triggers.

⚠ **Use `.full_name`, not `.name`.** For a tapped formula `.name` is bare (`pinentry-touchid`) while
`.full_name` is qualified (`jorgelbg/tap/pinentry-touchid`). `brew leaves` and `brew bundle dump` both emit
the qualified form, so `.name` produces a phantom missing/stale pair for every tapped formula.

`installed_on_request` and `installed_as_dependency` are **independent booleans** — both can be true at
once, for a package you asked for that something else also needs.

## 3. Casks — there is no `installed_on_request`

Cask installs record no request flag. Every installed cask is a candidate. The only entries to drop are
casks that another installed cask declares as a dependency:

```sh
brew info --json=v2 --installed | jq -r '[.casks[]? | .depends_on.cask // empty] | flatten | .[]' | sort -u
```

Subtract those from `brew list --casks`. On this machine that set is empty — `kekaexternalhelper` is a
*separate* cask, not a declared dependency of `keka`, which is why both must be listed explicitly.

⚠ **jq lexing trap:** `.app?//empty` fails to parse — jq reads `?//` as the destructuring-alternative
operator. Write `.app? // empty` with spaces. (`.cask//empty` is fine because the preceding token is not
`?`.) This bites specifically on `.artifacts[]? | .app? // empty`.

## 4. Taps

```sh
brew tap                                    # installed
brew bundle list --tap --file=Brewfile      # declared
```

A tap with no remaining entries should be removed from both. `brew tap` lists taps that exist locally,
including ones auto-tapped as a side effect of installing something — those are still worth declaring if a
package needs them.

## 5. App Store apps

```sh
mas list                                    # "<id>  <Name>  (<version>)"
brew bundle list --mas --file=Brewfile      # NAMES ONLY — not ids
```

⚠ **`brew bundle list --mas` prints names, not ids.** Diffing on that name is unsafe because Apple renames
apps between releases — on macOS 27 the App Store still calls it `Keynote` while the bundle on disk is
`Keynote Creator Studio.app`. **Always diff on the numeric id**, pulling declared ids straight out of the
file:

```sh
grep -oE '^[^#]*\bid:[[:space:]]*[0-9]+' Brewfile | grep -oE '[0-9]+$' | sort
```

The `^[^#]*` guard keeps commented-out entries from counting as declared.

### The Apple denylist

`mas list` includes apps macOS ships and silently reinstalls: GarageBand `682658836`, iMovie `408981434`,
Keynote `361285480`, Numbers `361304891`, Pages `361309726`. These are excluded by the standing decision in
[style-guide.md](style-guide.md) §8. The list lives in `scripts/brewfile-audit.sh` (`APPLE_MAS_IDS`).

⚠ These are the **macOS** product ids. The iOS/iPadOS listings for the same apps carry different ids, so do
not copy ids from a phone or from a web search — read them off `mas list` on this machine.

## 6. Finding software installed outside brew entirely

Apps that arrived by drag-and-drop are invisible to both `brew` and `mas` and are the main source of
Brewfile drift.

**Do not slug-match app names against cask tokens.** It produces false positives in both directions:
`AltTab.app` → `alt-tab`, `Prism Launcher.app` → `prismlauncher`, `Visual Studio Code - Insiders.app` →
`visual-studio-code@insiders`. None of those survive naive normalisation.

**Authoritative approach** — ask each cask what `.app` it installs:

```sh
brew info --json=v2 --installed \
  | jq -r '.casks[]? | (.artifacts[]? | .app? // empty | .[]? | select(type=="string"))' | sort -u
```

**And detect App Store apps by receipt, not by name:**

```sh
[ -e "/Applications/Some App.app/Contents/_MASReceipt/receipt" ]   # true ⇒ came from the App Store
```

Anything in `/Applications` that matches neither test (excluding `Safari.app`, which ships with macOS) was
installed manually. On this machine that is exactly one app: **CARROT.app**.

For a manually-installed app, the audit should ask the user rather than decide: it may have a cask
available (`brew search --cask <name>`), it may be intentionally outside brew (licensing, a beta channel
brew does not track), or it may be forgotten cruft.

## 7. Classifying drift

| Class | Signal | Default action |
| --- | --- | --- |
| **Untracked** | installed, absent from Brewfile | Add it — with a purpose comment and a category. Ask the user only if the purpose is not inferable. |
| **Stale** | in Brewfile, not installed | Ask before removing. It may be a *deliberate* declaration for a machine that has not converged yet. |
| **Misqualified** | bare name for a tapped formula | Rewrite to `owner/tap/name`. Not a real add/remove — the audit script folds this pair into one note. |
| **Redundant trust** | `trusted:` on `brew`/`cask` under an already-trusted tap | Remove the entry-level one; keep tap-level. |
| **Duplicate channel** | `figma` and `figma@beta` both present | Report, do not act. Usually intentional. |
| **Unmanaged app** | in `/Applications`, no cask artifact, no MAS receipt | Report and ask. |
| **Dependency leak** | a formula in the file with `installed_on_request: false` | Remove — it will be reinstalled as a dependency anyway. |

## 8. Validating a change

```sh
ruby -c Brewfile                                 # ruby syntax (Brewfiles are eval'd ruby)
brew bundle list --file=Brewfile >/dev/null      # brew can parse and resolve every entry
brew bundle check --file=Brewfile --verbose      # everything declared is actually installed
```

⚠ `ruby -c` catches syntax errors only. A typo'd *package name* is valid Ruby and only surfaces at
`brew bundle list`/`check` time. The `PostToolUse` hook in `.claude/hooks/brewfile-validate.sh` runs both.

⚠ `brew bundle check` passing does **not** mean the Brewfile is complete — it only verifies that what is
declared is installed. The stub 3-line Brewfile in this repo passed `check` while missing 90 packages.
Completeness is what the audit diff is for.

## 9. Never do this

- **`brew bundle dump --force` over `Brewfile`.** It destroys every comment, category, banner and blank
  line the style guide exists to maintain. Dump to a *scratch* path and diff instead:

  ```sh
  brew bundle dump --file=/tmp/brewfile-dump --force --no-vscode
  ```

- **`brew bundle cleanup --force`** without showing the user the dry run first (`brew bundle cleanup`
  alone). It uninstalls everything not in the file — and, per [brew-bundle.md](brew-bundle.md) §3, also
  resets Homebrew's tap-trust file to match.
