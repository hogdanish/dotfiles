# laramie — per-tool bindings

Layer 2: config key → token, for every file that carries a colour. **Decide nothing here at edit
time — this table is the decision.** Values are in `spec.md`; never inline a hex that isn't there.

⚠ **Format traps differ per file and have caused real bugs.** Read the *Format* line before editing.

## Coverage

Fourteen files carry hexes. Five more consume colour but must stay on **ANSI names** (`SKILL.md`
doctrine 3): `starship.toml`, `LS_COLORS`/`EZA_COLORS` and `LESS_TERMCAP_*` (both in `colours.fish`),
`git/.gitconfig`'s `[pretty] lg` / `branches` formats, and `fastfetch/config.jsonc`. ⚠ Do not
hex-code these.

---

## ghostty/themes/laramie

**Format:** `palette = N=#rrggbb` (the `#` is required); standalone keys accept bare or `#`-prefixed.
⚠ A theme file can set *any* Ghostty option, not just colours. **Reload:** `cmd+r`.

ANSI 0–15 come verbatim from `spec.md` §4. Beyond those:

| key | token |
| --- | --- |
| `background` | `surface.base` |
| `foreground` | `text.base` |
| `cursor-color` | `text.base` |
| `selection-background` | `ui.select.bg` (`surface.overlay`) |
| `selection-foreground` | `text.loud` |

## fish/themes/laramie.fish

**Format:** `set -g theme_<token> '#rrggbb'` — hex **with** `#`. Global, not exported. Sourced by
`conf.d/colours.fish` *above* the interactive guard, because `$theme_*` is a cross-file contract that
`fzf.fish` also reads.

**The keystone.** Carries all 28 core primitives (the 4 diff surfaces are not needed in fish), named `theme_surface_<step>`, `theme_text_<step>`,
`theme_<hue>_<tier>` (fish variable names cannot contain `.`). No semantic aliases here — consumers
apply meaning.

## fish/themes/laramie.theme

**Generated — never hand-edit.** Regenerate with `claude-code/skills/fish/scripts/gen-fish-theme.fish`.
⚠ **Bare hex, no `#`** — a `.theme` file is tokenised, so `#` starts a comment and the line silently
does nothing. ⚠ It is a *superset* of `colours.fish`, harvesting fish's own defaults too.

## fish/conf.d/colours.fish

**Format:** `set -g fish_color_* $theme_*` — `set_color` **does** accept a leading `#`. Interactive
block only. ⚠ Do not touch the `LESS_TERMCAP_*`, `LS_COLORS` or `EZA_COLORS` blocks — ANSI on purpose.

⚠ **The fish command line is a syntax surface**, so the doctrine applies — with one adaptation: the
*command* is the analogue of a definition (it is what you scan history for), so it keeps a colour.

| variable | token | | variable | token |
| --- | --- | --- | --- | --- |
| `normal` | `text.base` | | `error` | `state.error` |
| `command` | `syntax.definition` | | `status` | `state.error` |
| `keyword` | `text.base` ⚠ plain | | `cwd` | `accent.blue.base` |
| `param` | `text.base` ⚠ plain | | `cwd_root` | `state.error` |
| `option` | `text.muted` | | `user` | `accent.cyan.base` |
| `quote` | `syntax.literal` | | `host` | `accent.cyan.base` |
| `escape` | `accent.green.loud` | | `host_remote` | `state.warn` |
| `comment` | `syntax.comment` ⚠ bright | | `search_match` | `text.loud` + bg `ui.select.bg` |
| `operator` | `syntax.punctuation` | | `selection` | `text.loud` + bg `ui.select.bg` |
| `redirection` | `syntax.punctuation` | | `end` | `syntax.punctuation` |

⚠ `keyword` and `param` **must be set explicitly** — unset, they fall back to `command`/`param` and
would inherit the definition colour, defeating the doctrine.

Pager: `progress` `text.muted` · `prefix` `text.loud` · `completion` `text.base` · `description`
`text.dim` · `selected_background` `ui.select.bg` · `selected_prefix` `accent.cyan.loud` ·
`selected_completion` `text.loud` · `selected_description` `text.muted` · `secondary_background`
`ui.highlight.bg` · `secondary_prefix` `accent.cyan.base` · `secondary_completion` `text.base` ·
`secondary_description` `text.dim`. ⚠ `fish_pager_color_background` stays **erased** (`set -e`) so
Ghostty's opacity shows through.

## fish/conf.d/fzf.fish

**Format:** `--color=key:$theme_*` inside `FZF_DEFAULT_OPTS`. ⚠ Must sort before `tools.fish`.

`fg` `text.base` · `bg` **`-1`** ⚠ keep, terminal default so blur shows through · `hl`
`accent.cyan.base` · `fg+` `text.loud` · `bg+` `ui.select.bg` · `hl+` `accent.cyan.loud` · `info`
`text.muted` · `prompt` `ui.label` · `pointer` `ui.accent` · `marker` `state.ok` · `spinner`
`accent.violet.base` · `header` `text.dim` · `border` `surface.border`

## fish/conf.d/gum.fish

**Format:** `set -gx GUM_<CMD>_<KEY>_FOREGROUND '#rrggbb'` — bare `#rrggbb`, single-quoted. Guarded by
`type -q gum; or return`. ⚠ Deliberately **not** interactive-guarded. ⚠ Never export the unprefixed
`$FOREGROUND`/`$BORDER`/`$PADDING` — they restyle every `gum style` machine-wide.

Cursors, indicators, spinners and selected rows → `ui.accent`. Headers and prompts → `ui.label`.

| var | token | | var | token |
| --- | --- | --- | --- | --- |
| `CHOOSE_CURSOR_FG` | `ui.accent` | | `INPUT_PLACEHOLDER_FG` | `text.faint` |
| `CHOOSE_SELECTED_FG` | `accent.cyan.base` | | `WRITE_CURSOR_FG` | `ui.accent` |
| `CHOOSE_HEADER_FG` | `ui.label` | | `WRITE_HEADER_FG` | `ui.label` |
| `FILTER_INDICATOR_FG` | `ui.accent` | | `CONFIRM_PROMPT_FG` | `ui.label` |
| `FILTER_MATCH_FG` | `state.warn` | | `CONFIRM_SELECTED_BG` | `ui.accent` |
| `FILTER_HEADER_FG` | `ui.label` | | `CONFIRM_SELECTED_FG` | `surface.base` |
| `FILTER_PROMPT_FG` | `text.muted` | | `CONFIRM_UNSELECTED_BG` | `surface.overlay` |
| `FILTER_PLACEHOLDER_FG` | `text.faint` | | `CONFIRM_UNSELECTED_FG` | `text.base` |
| `INPUT_CURSOR_FG` | `ui.accent` | | `SPIN_SPINNER_FG` | `ui.accent` |
| `INPUT_PROMPT_FG` | `ui.label` | | `FILE_DIRECTORY_FG` | `ui.label` |
| `TABLE_SELECTED_FG` | `ui.accent` | | `FILE_SELECTED_FG` | `ui.accent` |
| | | | `FILE_SYMLINK_FG` | `accent.cyan.base` |

`GUM_FORMAT_THEME` is a **path**, not a colour → `$XDG_CONFIG_HOME/glamour/laramie.json`.

## git/themes.gitconfig — `[delta "laramie"]`

**Format:** `"<fg>" "<bg>" <attrs>` — hex **must be double-quoted** or gitconfig reads `#` as a
comment. Attrs: `bold` `ul` `box`, keywords `syntax`/`none`, ANSI names.

⚠ **This block reaches delta only because `~/.config/git/config` is a symlink to `.gitconfig`.**
Delta is libgit2-backed and **ignores `GIT_CONFIG_GLOBAL`**, reading only `$XDG_CONFIG_HOME/git/config`
or `~/.gitconfig`. Before that symlink existed (2026-07-30) delta saw no global config at all and
rendered its built-in defaults — the feature had *never* applied. Verify with
`delta --show-config | rg plus-style`; if it reports `syntax "#002800"` the symlink is gone.

| key | token |
| --- | --- |
| `file-style` | `text.loud` + `bold` |
| `file-decoration-style` | `surface.border` + `ul` |
| `plus-style` | `state.ok` on `ui.highlight.bg` |
| `plus-emph-style` | `surface.base` on `state.ok` |
| `minus-style` | `state.error` on `ui.highlight.bg` |
| `minus-emph-style` | `surface.base` on `state.error` |
| `line-numbers-left-style` / `-right-style` / `-zero-style` | `text.faint` |
| `line-numbers-minus-style` / `-plus-style` | `state.error` / `state.ok` |
| `whitespace-error-style` | `surface.base` on `state.error` |
| `blame-palette` | `surface.base` `surface.raised` `surface.overlay` `surface.border` |
| `merge-conflict-*-diff-header-style` | `state.warn` + `bold` |
| `merge-conflict-*-decoration-style` | `surface.border` + `box` |

⚠ `line-numbers-*-style` used to hold a **surface-ramp** value at 1.4:1, used as text. `zero-style`
and `blame-code-style` stay `syntax`. `syntax-theme = laramie` resolves to the bat tmTheme.

## bat/themes/laramie.tmTheme

**Format:** plist XML, hex **with** `#`; `#rrggbbaa` alpha is supported. `fontStyle` takes
`italic`/`underline`/`bold`. ⚠ **`bat cache --build` after every edit**, or bat silently falls back
*and* `delta.syntax-theme = laramie` breaks with it.

Globals: `background` `surface.base` · `foreground` `text.base` · `caret` `ui.accent` · `selection`
`ui.select.bg` · `inactiveSelection` / `lineHighlight` / `guide` `ui.highlight.bg` · `activeGuide` /
`stackGuide` / `invisibles` / `selectionBorder` `surface.border` · `gutterForeground` `text.faint` ·
`findHighlight` `state.warn` · `findHighlightForeground` `surface.base`.
⚠ `shadow` is the only 8-digit value: `surface.sunken` + `30` alpha. Tinting it with a spec colour
rather than pure black is what keeps "every hex is in the spec" literally true, with no exemption.

Scopes — **the doctrine is enforced by deleting rules, not by adding them.** tmTheme falls back to
the global `foreground`, so a scope with no rule renders plain. That is the desired outcome for
keywords, calls, types-in-position, tags and attributes.

| scope | token |
| --- | --- |
| `comment`, `punctuation.definition.comment` | `syntax.comment` + `italic` |
| `string`, `string.regexp`, `constant.numeric`, `constant.language`, `constant.character`, `support.constant`, `variable.other.constant` | `syntax.literal` |
| `constant.character.escape` | `accent.green.loud` |
| `entity.name.function`, `entity.name.class`, `entity.name.type`, `entity.name.namespace` | `syntax.definition` |
| `punctuation` | `syntax.punctuation` |
| `markup.heading` | `syntax.definition` |
| `markup.underline.link`, `string.other.link` | `state.info` |
| `markup.bold` | `text.loud` + `bold` |
| `markup.error` / `markup.warning` | `state.error` / `state.warn` |
| **delete outright** | `keyword.*`, `storage.*`, `support.function`, `support.class`, `variable`, `meta.class`, `entity.name.tag`, `entity.other.attribute-name` |

⚠ `support.function` and `markup.heading` each appeared in **two** rules; the earlier lost silently.
One rule per scope.

## micro/colorschemes/laramie-tc.micro

**Format:** `color-link <group> "[attrs ]fg[,bg]"` — hex **with** `#`. ⚠ **No space after the comma**;
`"#737aa2, #5f6996"` does not parse. Selected by `micro/settings.json` → `"colorscheme": "laramie-tc"`.

| group | token | | group | token |
| --- | --- | --- | --- | --- |
| `default` | `text.base` | | `statement` | `text.base` ⚠ plain |
| `comment` | `syntax.comment` | | `identifier` | `text.base` ⚠ plain |
| `constant`, `constant.number`, `constant.string`, `constant.bool` | `syntax.literal` | | `identifier.macro`, `type`, `preproc` | `text.base` ⚠ plain |
| `constant.specialChar` | `accent.green.loud` | | `identifier.class`, `identifier.function` | `syntax.definition` |
| `symbol`, `symbol.brackets`, `symbol.operator`, `special` | `syntax.punctuation` | | `todo` | `syntax.comment` + `bold` |
| `error`, `tab-error`, `trailingws` | `state.error` (+`bold` on `error`) | | `underlined` | `text.base` + `underline` |
| `diff-added` / `-deleted` / `-modified` | `state.ok` / `state.error` / `state.warn` | | `line-number` | `text.faint` |
| `gutter-error` / `gutter-warning` | `surface.base,state.error` / `,state.warn` | | `current-line-number` | `text.loud` ⚠ fg only |
| `hlsearch` | `surface.base,state.warn` | | `cursor-line`, `scrollbar` | `ui.highlight.bg` |
| `match-brace` | `text.loud,ui.select.bg` | | `divider`, `indent-char` | `surface.border` |
| `statusline`, `tabbar` | `text.base,ui.highlight.bg` | | `color-column` | `""` ⚠ keep empty |

⚠ **micro cannot express the full doctrine.** Its group model has no usage-vs-declaration split
outside `identifier.class`/`identifier.function`, and whether those match *declarations* depends on
each language's syntax file. Expect micro to land at effectively two syntax colours. That is
acceptable; do not invent groups to compensate.

## glamour/laramie.json

**Format:** JSON, `"color"` / `"background_color"` hex **with** `#`; also `bold`, `italic`,
`underline`, `crossed_out` and layout keys. ⚠ Read by **two** variables: `GUM_FORMAT_THEME`
(`gum.fish`) and `GLAMOUR_STYLE` (`xdg-apps.fish`, for `gh`). ⚠ gum does **not** read `GLAMOUR_STYLE`.

Chrome: `document`/`paragraph` `text.base` · `list` `text.muted` · `heading`/`h1` `syntax.definition`
+ bold · `h2` `accent.cyan.base` · `h3` `state.info` · `h4`–`h6` `text.loud` · `strong` `text.loud`
+ bold · `emph` italic, no colour · `strikethrough` `text.faint` · `hr` `surface.border` · `link` /
`image` `state.info` + underline · `link_text` `text.loud` · `image_text` `text.muted` · `code`
`text.loud` on `ui.highlight.bg` · `code_block` `text.base`.

`code_block.chroma` — the second syntax surface, same doctrine:

| token | binding | | token | binding |
| --- | --- | --- | --- | --- |
| `text`, `punctuation`… see right | `text.base` | | `keyword`, `keyword_reserved`, `keyword_namespace`, `keyword_type` | `text.base` ⚠ plain |
| `comment` | `syntax.comment` | | `name`, `name_builtin`, `name_tag`, `name_attribute`, `name_decorator`, `comment_preproc` | `text.base` ⚠ plain |
| `literal_string`, `literal_number`, `name_constant` | `syntax.literal` | | `name_function`, `name_class` | `syntax.definition` |
| `literal_string_escape` | `accent.green.loud` | | `operator`, `punctuation` | `syntax.punctuation` |
| `generic_deleted` / `generic_inserted` | `state.error` / `state.ok` | | `generic_subheading` | `accent.cyan.base` |
| `error` | `surface.base` on `state.error` | | `background` | `surface.sunken` |

⚠ **The `chroma` block always renders in 256-colour, never truecolour** — verified 2026-07-30 against
gum 0.17.0 with `COLORTERM=truecolor` correctly exported. The markdown *chrome* in the same render
emits `38;2;…` truecolour; only the code-block path quantizes, so `syntax.comment` `#ffc55b` arrives as
xterm 221, `syntax.literal` `#86c452` as 113, `syntax.definition` `#49ebf0` as 81, `syntax.punctuation`
`#9099be` as 103. This is inside glamour's chroma integration and is **not** a config error — do not
chase it, and do not "fix" the hexes to compensate. The doctrine survives the quantization; the exact
values do not.

## atuin/themes/laramie.toml

**Format:** TOML, hex **with** `#`, double-quoted. Fixed key names (atuin's `Meaning` enum) — colours
only. Activated by `atuin/config.toml` `[theme] name = "laramie"`.

`Base` `text.base` · `Title` `syntax.definition` · `Annotation` `text.muted` · `Guidance`
`text.faint` · `AlertInfo` `state.info` · `AlertWarn` `state.warn` · `Important` `ui.accent`

⚠ **`AlertError` is overloaded in atuin** — it colours the *selected entry name* as well as genuine
errors. Bind it to `ui.accent`, not `state.error`, or every selected history row renders red.
Verify against the live file's comments before changing.

## btop/themes/laramie.theme

**Format:** `theme[key]="#rrggbb"` (bash-array syntax), double-quoted. The only file supporting
**3-stop gradients** (`_start`/`_mid`/`_end`). Activated by `btop.conf` `color_theme = "laramie"`.
⚠ btop rewrites `btop.conf` on exit — expect churn there.

⚠ **`main_bg` must stay EMPTY (`""`)**. With `theme_background = False` that is what lets Ghostty's
opacity and blur show through instead of an opaque rectangle.

`main_fg` `text.base` · `title` `text.loud` · `hi_fg` `accent.cyan.base` · `selected_bg`
`ui.select.bg` · `selected_fg` `text.loud` · `inactive_fg` `text.faint` · `graph_text` `text.muted` ·
`meter_bg` `ui.highlight.bg` · `proc_misc` `accent.cyan.base` · `cpu_box`/`mem_box`/`net_box`/
`proc_box`/`div_line` `surface.border`

Gradients follow one of two shapes:

- **Severity** (`temp`, `cpu`, `used`, `process`) — `state.ok` → `state.warn` → `state.error`.
- **Intensity** (`free`, `available`, `cached`, `download`, `upload`) — one hue's `deep` → `base` →
  `loud`, so brightness rises with the value: `free` green, `available` cyan, `cached` blue,
  `download` cyan, `upload` violet.

## fastfetch/config.jsonc

**Format:** JSONC. ⚠ **ANSI names only — this file carries no hexes and must not gain any.** It
replaced `macchina/themes/laramie.toml` on 2026-07-30, which did hex-code its two values.
⚠ fastfetch has **no include/import directive** and reads exactly one config
(`fastfetch --list-config-paths`), so a separate `themes/laramie.jsonc` could only ever be loaded via
an explicit `-c` on every invocation. Doctrine 3 makes that a non-issue: every colour is a name, so
the readout inherits `ghostty/themes/laramie` for free. **Verify:** run `fastfetch`.

`display.color.keys` `ui.label` (blue) · `.title` `ui.accent` (magenta) · `.separator` `text.dim`
(light_black) · `title.user`/`.host` `ui.accent` · `title.at` `text.dim` · `bar.color.total`
`text.dim` · module headings `ui.accent` + `text.dim`.

⚠ `percent.color` uses the **base** accents (`green`/`yellow`/`red`), not the brights fastfetch
defaults to — base is what `state.ok`/`state.warn`/`state.error` alias, and bright is reserved for
emphasis on a coloured ground. ⚠ The builtin `macos` logo's colours are deliberately **unset**: the
art already emits bare ANSI 31–35/91 and is laramie-coloured with zero configuration.

The trailing `colors` module is a live 16-slot preview — the standing check that laramie's brights
are not byte-identical to its normals.

## claude-code/themes/laramie.json

**Format:** JSON, three optional fields — `name`, `base`, `overrides`. Values accept `#rrggbb`,
`#rgb`, `rgb(r,g,b)`, `ansi256(n)` and `ansi:<name>`. ⚠ Unknown tokens and invalid values are
**silently ignored**, so a typo cannot break rendering — and cannot be detected by eye either.
Requires Claude Code ≥ 2.1.118 (2.1.220 here). Selected by `"theme": "custom:laramie"` in
`claude-code/settings.json`; the slug is the filename. Claude Code hot-reloads the file on change.

⚠ **Authored at `claude-code/themes/`, symlinked to `$CLAUDE_CONFIG_DIR/themes/` by
`scripts/link-claude.fish`** — `$CLAUDE_CONFIG_DIR` is `$XDG_STATE_HOME/claude`, not `~/.claude`, so
the path in Anthropic's docs is wrong for this machine. Linked as a whole directory (unlike `skills/`)
because nothing else writes into it.

**`base` is `dark-ansi` on purpose — this is doctrine 3 in action.** Every semantic token (success,
error, warning, `planMode`, `autoAccept`, `bashBorder`, `promptBorder`, `text`, `permission`…) is left
to fall through to the ANSI preset, where it resolves against `ghostty/themes/laramie` and stays
correct for free. Only tokens the 16 colours genuinely **cannot** express are overridden:

| override | token | why ANSI cannot do it |
| --- | --- | --- |
| `claude` / `claudeShimmer` | `ui.accent` / `accent.violet.loud` | the brand accent should match gum/fzf's violet, not an arbitrary ANSI slot |
| `inactive` / `subtle` / `suggestion` | `text.dim` / `text.faint` / `text.muted` | ⚠ ANSI has exactly **one** dim grey (slot 8). The palette has three gradations and these tokens want different ones |
| `diffAdded` / `diffRemoved` | `surface.add` / `surface.remove` | backgrounds. An ANSI red or green as a background fill is blinding |
| `diffAddedWord` / `diffRemovedWord` | `surface.add.emph` / `surface.remove.emph` | ditto, one step brighter |
| `diffAddedDimmed` / `diffRemovedDimmed` | `ui.highlight.bg` | unchanged context is neutral by design |
| `userMessageBackground` etc. | surface ramp | fullscreen fills need surface values, absent from ANSI |
| `rate_limit_fill` / `_empty` | `accent.cyan.base` / `surface.border` | a meter, not a status |

⚠ **Do not "complete" this by overriding every token.** Each hex added here is one more value that
stops tracking the ANSI-16 automatically. If a colour looks wrong, first check whether the ANSI slot
behind it is right.

## glamour/tui.json

⚠ **Deleted 2026-07-30.** It was a full 213-line copy of the palette that **nothing read** — zero
references repo-wide. Do not recreate it; `laramie.json` is the only glamour style, and two variables
(`GUM_FORMAT_THEME`, `GLAMOUR_STYLE`) point at it.
