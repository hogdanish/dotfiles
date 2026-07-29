# Ghostty keybindings — triggers, prefixes, sequences, key tables, and every action

Verified against **Ghostty 1.3.2-main**: `ghostty +list-actions --docs` (85 actions) and
`ghostty +list-keybinds --default` (93 default binds). Explain one action with
`ghostty +explain-config --keybind=<action>`.

---

## 1. Syntax

```ini
keybind = <trigger>=<action>
keybind = <trigger>=<action>:<parameter>
```

Duplicate triggers **overwrite** — the last one wins. `keybind = clear` removes **all** bindings
including every default (⚠ that includes copy/paste and `reload_config` — you are rebuilding from
nothing).

## 2. Triggers

A trigger is zero or more modifiers plus exactly one key, joined with `+`:
`a`, `ctrl+a`, `ctrl+shift+a`, `up`.

**Modifiers:** `shift` · `ctrl` (alias `control`) · `alt` (aliases `opt`, `option`) · `super`
(aliases `cmd`, `command`). Aliases are accepted on input; debug output always prints the canonical
name.
⚠ The **fn / globe key is not supported** as a modifier — an OS and toolkit limitation, not a Ghostty
one.

Rules: modifiers cannot repeat (`ctrl+ctrl+a` invalid) · order is free (`shift+a+ctrl` is weird but
valid) · exactly one key (`ctrl+a+b` invalid).

### Three ways to name the key

| Form | Example | Matches |
| --- | --- | --- |
| **Unicode codepoint** | `a`, `ö` | whatever the layout produces — `a` hits `q` on AZERTY |
| **W3C physical code** | `KeyA`, `key_a`, `f1` | the physical key regardless of layout |
| **`catch_all`** | `ctrl+catch_all` | any key not otherwise bound |

- Codepoint matching compares modifiers against the **unmodified** (case-folded) codepoint, so
  `ctrl+A` in config matches `ctrl+a` pressed. ⚠ This makes some combinations **impossible**:
  `ctrl+_` can't fire on a US layout because `_` is `shift+-`, and `ctrl+shift+-` ≠ `ctrl+_`.
- Any key not in Ghostty's key list can be given as a bare Unicode codepoint — useful on non-US
  layouts: `keybind = ctrl+ö=action`.
- [W3C UI Events codes](https://www.w3.org/TR/uievents-code/) are case-sensitive, but snake_case is
  also accepted (`key_a` = `KeyA`). Function keys are the exception: `f1`, not `f_1`.
- **Physical keys always beat codepoints**, whatever the config order.
- `catch_all` lookup tries the modified form first, then falls back to bare `catch_all`.

### Trigger prefixes

Combinable, written before the whole trigger: `global:unconsumed:ctrl+a=reload_config`.
⚠ Prefixes are **not** part of the trigger's identity — `ctrl+a` and `global:ctrl+a` are the *same*
keybind, and the later definition replaces the earlier.

**`all:`** *(1.0.0)* — apply to every terminal surface, not just the focused one. No effect on
already-global actions such as `quit`.

**`global:`** *(macOS 1.0.0, GTK 1.2.0)* — work system-wide, even when Ghostty is unfocused. Implies
`all:`.
⚠ macOS requires **Accessibility permission** (System Settings → Privacy & Security → Accessibility).
Ghostty requests it on launch/reload when a `global:` bind exists; without it the bind silently does
nothing.
Linux (1.4.0+): `vicinae-hotkey-v1` where available (Hyprland ≥0.56.0), otherwise XDG Global Shortcuts
(KDE Plasma ≥5.27 with `xdg-desktop-portal-kde`, GNOME ≥48 with `xdg-desktop-portal-gnome`, Hyprland
<0.56 with `xdg-desktop-portal-hyprland` plus manual DBus setup). wlroots compositors (Sway) and COSMIC
support neither.

**`unconsumed:`** *(1.0.0)* — also send the key's normal encoding to the running program. `global:` and
`all:` binds always consume, since they aren't tied to a surface and are never encoded.

**`performable:`** *(1.1.0)* — consume the input **only if the action actually runs**. `copy_to_clipboard`
with no selection then falls through as if unbound. In a key sequence, a non-performable action resets
the sequence.
⚠ Performable binds **do not appear as menu shortcuts** — menu items force the action regardless of
state. The bind still works; it just has no label in the menu.

## 3. Key sequences (leader keys / chords)

Separate triggers with `>`:

```ini
keybind = ctrl+a>n=new_window
```

⚠ On the CLI, quote it — `>` is shell redirection: `ghostty --keybind='ctrl+a>n=new_window'`.

- Ghostty waits **indefinitely** for the next key; there is no timeout and no way to set one. To emit
  the prefix itself, bind it explicitly (`ctrl+a>ctrl+a=text:foo`) or press an unbound key, which sends
  both keys through.
- An unbound key mid-sequence normally flushes the whole sequence to the program. If a `catch_all`
  binding would `ignore` that input, the sequence is dropped silently instead.
- Binding a sequence **shadows its prefix**: with `ctrl+a=new_window` and `ctrl+a>n=new_tab`, pressing
  `ctrl+a` alone does nothing.
- Conversely, binding a prefix directly **unbinds every sequence under it** — binding `ctrl+a` after
  `ctrl+a>n` and `ctrl+a>t` destroys both.
- ⚠ Sequences are **not allowed** with `global:` or `all:`.
- `end_key_sequence` flushes the keys so far *excluding* the triggering key — e.g.
  `ctrl+w>escape=end_key_sequence` sends `ctrl+w` and leaves the sequence.

## 4. Chained actions *(1.3.0)*

`chain=` appends an action to the **most recently defined** keybind:

```ini
keybind = ctrl+a=new_window
keybind = chain=goto_split:left
keybind = chain=toggle_fullscreen
```

All chained actions run in order. ⚠ `chain` entries take **no prefixes** — the original keybind's
flags govern the whole chain. Chains work with sequences (attaching to the most recent binding in the
sequence) and inside key tables (⚠ `chain` is **never** prefixed with the table name — it always
attaches to the most recent binding in any table).

## 5. Key tables (modal input) *(1.3.0)*

A named binding set that must be activated explicitly — copy mode, vim mode, etc.

```ini
keybind = foo/ctrl+a=new_window          # define binding in table "foo"
keybind = ctrl+space=activate_key_table:foo
```

Syntax is `<table>/<binding>`. Table names may contain anything except `/`, `=`, `+`, `>`.

- Lookup runs **innermost table outward**, so default-table binds stay available unless explicitly
  unbound in an inner table.
- `<name>/` with no binding **defines and clears** the table, resetting its binds and settings.
- You cannot activate the table that is already innermost (ignored), but the same table may appear
  more than once in the stack if not adjacent: `A→B→A→B` is fine, `A→B→B` is not.
- `activate_key_table_once:<name>` auto-deactivates after the first non-`catch_all` binding fires. The
  "once" check only applies while it is the active table.
- Sequences work inside tables (`foo/ctrl+a>ctrl+b=new_window`); an invalid key ends the sequence but
  **leaves the table active**.
- Prefixes work inside tables: `foo/global:ctrl+a=new_window`.

---

# Action reference (85)

Parameters are written `action:param`. ⚠ The parameter is taken **verbatim** after the `:` — quotes are
*not* parsed away. To include spaces, quote the whole trigger/action:
`--keybind="up=csi:A B"`.

## Input passthrough and raw sequences

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `ignore` | — | Swallow the combination. Not processed by Ghostty, not forwarded to the child; the OS or other apps may still see it. |
| `unbind` | — | Remove the binding so the key passes through to the child if printable. Removes any matching trigger, including `physical:`-prefixed ones, without naming the prefix. ⚠ Cannot unbind OS/other-app bindings. |
| `csi` | sequence | Send a CSI sequence **without** the `ESC [` header. `csi:0m` resets all styles; `csi:A` is cursor-up. |
| `esc` | sequence | Send an `ESC` sequence. `esc:d` deletes to the end of the next word. |
| `text` | string | Send text using **Zig string-literal syntax** — `text:\x15` sends Ctrl-U. ⚠ Not validated; a bad escape only surfaces in the log. |
| `cursor_key` | — | Send data depending on whether cursor-key mode is `application` or `normal`. |
| `reset` | — | Full terminal reset, equivalent to `reset(1)`. ⚠ Will break a running TUI such as vim; in a shell you may need to press enter for a new prompt. |

## Clipboard

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `copy_to_clipboard` | `plain` \| `vt` \| `html` \| `mixed` *(default)* | `vt` preserves escape sequences; `html` renders colours/styles as markup; `mixed` puts several representations on the clipboard at once, each content-typed, so the receiver picks. |
| `paste_from_clipboard` | — | Paste the default clipboard. |
| `paste_from_selection` | — | Paste the selection clipboard. |
| `copy_url_to_clipboard` | — | Copy the URL under the cursor. |
| `copy_title_to_clipboard` | — | No-op if the title is unset or empty. |

## Font size

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `increase_font_size` | points | `increase_font_size:1.5` |
| `decrease_font_size` | points | `decrease_font_size:1.5` |
| `set_font_size` | points | `set_font_size:14.5` |
| `reset_font_size` | — | Back to the configured `font-size`. |

## Search

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `search` | text | Start a search. Empty text **cancels** it but leaves the search UI up — use `end_search` to hide it. Replaces any active search. |
| `search_selection` | — | Search for the current selection; no-op with no selection. Retargets an active search. |
| `start_search` | — | Open the search UI without setting terms. |
| `navigate_search` | `previous` \| `next` | No-op without an active search. |
| `end_search` | — | End the search and hide the UI. |

## Screen, scrolling and selection

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `clear_screen` | — | Clear the screen **and all scrollback**. |
| `select_all` | — | Select everything on screen. |
| `scroll_to_top` / `scroll_to_bottom` | — | |
| `scroll_to_selection` | — | |
| `scroll_to_row` | row | Absolute row, 0-based. |
| `scroll_page_up` / `scroll_page_down` | — | |
| `scroll_page_fractional` | fraction | Positive = down. `0.5` = half a page down, `-1.5` = 1½ pages up. |
| `scroll_page_lines` | lines | Positive = down. `3` / `-10`. |
| `adjust_selection` | `left`\|`right`\|`up`\|`down`\|`page_up`\|`page_down`\|`home`\|`end`\|`beginning_of_line`\|`end_of_line` | Extend the existing selection relative to the cursor. ⚠ Does **not** create a selection — no-op when none exists. |
| `jump_to_prompt` | ±count | Move the viewport by whole prompts; positive = down. **Requires shell integration** (OSC 133). |

## Dumping to a file

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `write_scrollback_file` | `copy` \| `paste` \| `open` | Write the whole scrollback to a temp file, then copy the path / paste the path / open it in the OS text editor (`open` on macOS, `xdg-open` on Linux). |
| `write_screen_file` | same | Just the visible screen. |
| `write_selection_file` | same | Just the selection; no-op with no selection. |

*(Defaults also pass a format: `write_screen_file:copy,plain`.)*

## Windows and tabs

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `new_window` | — | Brings the app to the front if unfocused. |
| `new_tab` | — | |
| `previous_tab` / `next_tab` / `last_tab` | — | |
| `goto_tab` | index | 1-based; an index past the end goes to the last tab. |
| `move_tab` | ±offset | Positive = forwards; **wraps cyclically**. |
| `toggle_tab_overview` | — | Linux only, libadwaita ≥1.4 (check `ghostty +version`). |
| `goto_window` | `previous` \| `next` | |
| `close_surface` | — | Close whatever the surface is (window/tab/split). May confirm per `confirm-close-surface`. |
| `close_tab` | `this` *(default)* \| `other` \| `right` | |
| `close_window` | — | Window plus all its tabs and splits. |
| `close_all_windows` | — | ⚠ **Deprecated and inert** on both platforms. Use `all:close_window`. |

## Titles

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `prompt_surface_title` | — | Pop-up prompt for the focused surface's title. |
| `prompt_tab_title` | — | Pop-up prompt for the tab title. Overrides any terminal-set title and persists across focus changes within the tab. |
| `set_surface_title` | title | Empty resets to an empty title. |
| `set_tab_title` | title | Empty clears the tab title override. |

## Splits

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `new_split` | `right`\|`down`\|`left`\|`up`\|`auto` | `auto` splits along the larger dimension. |
| `goto_split` | `right`\|`down`\|`left`\|`up`\|`previous`\|`next` | `previous`/`next` follow creation order. |
| `toggle_split_zoom` | — | Zoomed split fills the tab; the tab/tab-bar shows a zoom icon. |
| `resize_split` | `<dir>,<px>` | Both joined by a comma: `resize_split:up,10`. |
| `equalize_splits` | — | |
| `reset_window_size` | — | Back to the new-window default size. macOS only; no effect in fullscreen. |

## Window state

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `toggle_maximize` | — | No effect on macOS (no maximize concept). |
| `toggle_fullscreen` | — | |
| `toggle_window_decorations` | — | Linux only. |
| `toggle_window_float_on_top` | — | macOS only. Windows always start un-floated. |
| `toggle_background_opacity` | — | macOS only. No-op when `background-opacity` ≥ 1. |
| `toggle_visibility` | — | macOS only. Show/hide all windows; showing also focuses Ghostty, hiding yields focus to the next app. ⚠ No-op while the focused surface is fullscreen. |

## Modes and panels

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `toggle_readonly` | — | No input reaches the pty (keys or mouse); selection, copy/paste keybinds and scrolling still work. Warn-before-quit is forced on while active. |
| `toggle_mouse_reporting` | — | Runtime equivalent of `mouse-reporting`. |
| `toggle_secure_input` | — | macOS only. **Application-wide**, not per-surface — you must untoggle it or quit to disable. |
| `toggle_command_palette` | — | Linux needs libadwaita ≥1.5. |
| `toggle_quick_terminal` | — | See below. |
| `inspector` | `toggle` \| `show` \| `hide` | Terminal inspector. |
| `show_gtk_inspector` | — | No effect on macOS. |
| `show_on_screen_keyboard` | — | Linux/GTK. On GNOME requires Settings → Accessibility → Typing → Screen Keyboard. |

### `toggle_quick_terminal`

The Quake-style drop-down. State persists between appearances (re-showing returns the same window).
⚠ **No default keybind** — best bound globally: `keybind = global:cmd+backquote=toggle_quick_terminal`.

Limitations: only one instance ever exists · not restored by macOS window restoration · Linux requires
Wayland with `wlr-layer-shell-v1` (so **not GNOME**) · slide-in animation on Linux is KDE-only and needs
the "Sliding Popups" KWin plugin (System Settings → Apps & Windows → Window Management → Desktop
Effects), then a full Ghostty restart · **tabs are Linux-only** (macOS tabs need a title bar) ·
on macOS a fullscreened quick terminal is always non-native fullscreen.

## Config and lifecycle

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `open_config` | — | Open the config in the OS default editor. ⚠ Fails silently to the log if no default editor is configured. |
| `reload_config` | — | Re-read and apply. Not everything can be applied at runtime. |
| `check_for_updates` | — | macOS only. |
| `quit` | — | |
| `crash` | `main` \| `io` \| `render` | ⚠ **Hard panic — data can be lost.** Exists to test crash reporting. |

## Undo / redo *(macOS only)*

| Action | Behaviour |
| --- | --- |
| `undo` | Undo the last undoable action for the focused surface. |
| `redo` | Redo it. |

Only new/close of **window, tab and split** are undoable. Everything expires after `undo-timeout`
(default `5s`) — this bounds memory, stops closed surfaces running forever in the background, and frees
the keybinds for terminal programs.

## Key tables

| Action | Parameter | Behaviour |
| --- | --- | --- |
| `activate_key_table` | name | Stays active until deactivated. No-op (and reports non-performable) if the table doesn't exist or is already innermost. |
| `activate_key_table_once` | name | Deactivates after the first valid binding from that table fires, including `catch_all`. The check only applies while it is the active table. |
| `deactivate_key_table` | — | Pop back to the previously active table. |
| `deactivate_all_key_tables` | — | Reports non-performable if none are active. |
| `end_key_sequence` | — | Flush the sequence so far, excluding the triggering key. |

---

## Default keybindings (macOS, `super` = cmd)

Regenerate with `ghostty +list-keybinds --default`.

| Keys | Action |
| --- | --- |
| `super+,` / `super+shift+,` | `open_config` / `reload_config` |
| `copy` / `paste` *(media keys)* | `copy_to_clipboard:mixed` / `paste_from_clipboard` |
| `super+c` / `super+v` / `super+shift+v` | copy / paste / `paste_from_selection` |
| `super+=` `super++` / `super+-` / `super+0` | font size +1 / −1 / reset |
| `super+shift+j` / `super+ctrl+shift+j` / `super+alt+shift+j` | `write_screen_file:` paste / copy / open (`,plain`) |
| `shift+arrows` `shift+page_up/down` `shift+home/end` | `adjust_selection:*` |
| `ctrl+tab` / `ctrl+shift+tab` | next / previous tab |
| `super+1`…`super+8` (and `super+digit_N`) | `goto_tab:N` |
| `super+9` | `last_tab` |
| `super+shift+[` / `super+shift+]` | previous / next tab |
| `super+t` / `super+n` | `new_tab` / `new_window` |
| `super+w` / `super+alt+w` / `super+shift+w` | `close_surface` / `close_tab:this` / `close_window` |
| `super+d` / `super+shift+d` | `new_split:right` / `new_split:down` |
| `super+[` / `super+]` | `goto_split:previous` / `:next` |
| `super+alt+arrows` | `goto_split:<dir>` |
| `super+ctrl+arrows` | `resize_split:<dir>,10` |
| `super+ctrl+=` | `equalize_splits` |
| `super+enter` / `super+shift+enter` | `toggle_fullscreen` / `toggle_split_zoom` |
| `super+ctrl+f` | `toggle_fullscreen` |
| `super+shift+p` | `toggle_command_palette` |
| `super+k` / `super+a` | `clear_screen` / `select_all` |
| `super+z` `super+shift+t` / `super+shift+z` | `undo` / `redo` |
| `super+home` / `super+end` | scroll to top / bottom |
| `super+page_up` / `super+page_down` | scroll page up / down |
| `super+j` | `scroll_to_selection` |
| `super+arrow_up` / `super+arrow_down` | `jump_to_prompt:-1` / `:1` |
| `super+shift+arrow_up` / `super+shift+arrow_down` | `jump_to_prompt:-1` / `:1` |
| `super+f` / `super+e` / `super+shift+f` / `escape` | `start_search` / `search_selection` / `end_search` / `end_search` |
| `super+g` / `super+shift+g` | `navigate_search:next` / `:previous` |
| `super+alt+i` | `inspector:toggle` |
| `super+q` | `quit` |
| `super+arrow_right` / `super+arrow_left` / `super+backspace` | `text:\x05` / `text:\x01` / `text:\x15` (readline end/start/kill-line) |
| `alt+arrow_left` / `alt+arrow_right` | `esc:b` / `esc:f` (word-back / word-forward) |
| `super+alt+shift+w` | `close_all_windows` ⚠ deprecated & inert |

⚠ `super+arrow_up/down` and `super+shift+arrow_up/down` are both bound to `jump_to_prompt` by default.
