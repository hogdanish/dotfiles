# Herdr in Ghostty

Herdr keeps project terminals together and shows the state of each coding agent.
A **workspace** groups terminals for one project. A **tab** holds a screen layout.
A **pane** is one terminal within that layout.

## Start working

1. Open Ghostty.
2. Change to your project with `cd ~/Projects/commongrounds`.
3. Run `herdr`.
4. Run `claude` or `codex` inside Herdr.

Herdr opens your saved session. For another project, create a workspace and change
its terminal directory. Agents in other Ghostty windows do not appear automatically.

## Shortcuts

Press **Ctrl+B**, release both keys, then press the key below.
Uppercase means **Shift** plus that letter.

| Key | Action |
| --- | --- |
| `v` | Split side by side |
| `-` | Split top and bottom |
| `h`, `j`, `k`, `l` | Focus left, down, up, or right |
| `z` | Enlarge the current pane, or restore its size |
| `c` | Create a tab |
| `n`, `p` | Select the next or previous tab |
| `N` | Create a workspace |
| `w` | Select a workspace |
| `q` | Leave Herdr and keep its terminals running |
| `s` | Open Herdr configuration |
| `Q` | Open quota configuration |
| `u` | Refresh quota figures |
| `R` | Reload the configuration file |
| `?` | Show all shortcuts |

Run `herdr` again to return. Closing a pane ends the program inside it.
A Mac restart ends running processes. Herdr restores the layout and can resume
supported agent conversations through its installed integrations.

## Installation choices

- Homebrew installs native Apple Silicon Herdr 0.9.0; `Brewfile` records it.
- Login fish preserves the existing Claude and Codex 1Password wrappers.
- Ghostty supplies the Laramie palette. Selected rows use a dark background.
- The sidebar sorts agents by attention and uses distinct state symbols.
- Quota rows show the model, context use, and remaining five-hour and weekly quotas.
- Active work refreshes every 60 seconds. Unknown quota values stay unknown.
- Ghostty handles desktop notifications. Sound is off.
- Herdr worktrees use `~/Projects/herdr-worktrees/<repo>/<branch>`.
- Startup is manual. No login service or Ghostty startup replacement is installed.
- Additional saved pane history is off. Runtime files and caches remain untracked.

`herdr-agent-quota` 1.5.2 comes from `levi-qiao/herdr-agent-quota`, commit
`3d0e87c8f70c392e38de52d765c2776204b673b8`. The files under
`plugins/config/herdr-agent-quota/` record its preferences.
It reads Claude's status line and Codex's app-server usage report, without sending
model prompts. Available figures depend on what each agent reports.

Clauth is installed as of 2026-09-12, and its herdr plugin runs alongside the quota
plugin rather than replacing it. The earlier note here said clauth was not installed
because its credential handling conflicted with the config-dir arrangement; that
conflict was real and was resolved by retiring `$CLAUDE_CONFIG_DIR` in favour of a
`~/.claude` symlink, which is what let both tools agree on one config dir and one
Keychain item. See `.claude/CLAUDE.md`. The two plugins report different things:
agent-quota renders model, TTL, context and the 5h/7d windows; clauth renders which
account the pane is spending, plus delegate state.

## Theme

`[theme.custom]` in `config.toml` sets all 19 Herdr palette tokens to Laramie values.
The `laramie` skill's `references/bindings.md` holds the table and the reasons.
Two facts decide the rest, and both come from Herdr 0.9.0's own source:

**Text on a coloured button comes from `panel_bg`.** Herdr draws the focused tab,
the active settings section, a selected choice, the `apply` button, and selected
worktree rows with `accent` behind and `panel_bg` in front. If `panel_bg` is
`reset`, it uses `surface_dim` instead. Herdr does not calculate that colour.
Before this change both resolved to terminal defaults, which put grey text on a
light blue button at 1.59:1. That is why buttons were unreadable. `surface_dim` is
now `#161925`, which gives 8.09:1.

**`panel_bg` stays `reset` on purpose.** Ghostty uses 0.92 opacity and glass blur.
A hex value here would make the sidebar, the tab bar, and every modal an opaque
block on that glass. `reset` keeps Herdr's own surfaces as clear as the panes.

The four text tokens step down by lightness: `text` at 10.48:1, `subtext0` at
7.37:1, `overlay1` at 5.54:1, `overlay0` at 4.53:1. All four pass WCAG AA.
Row backgrounds rise instead of sink: the active row is `surface.raised` and the
navigate cursor row is `surface.overlay`. They were both ANSI black before, so the
cursor row was invisible and the active row looked disabled.

Herdr's own theme tests require five things of any palette. They skip the
`terminal` theme, so they never covered this file. Check all five after a change:

- `text` against `active_row_bg`, and `text` against `selection_bg`: 3.0 or more.
- `panel_bg` against `active_row_bg`, and against `selection_bg`: 1.05 or more.
- `selection_bg` and `active_row_bg` must differ.

## Maintenance

Homebrew updates Herdr with `brew upgrade herdr`. A compatible running server keeps
its old binary until its next restart. Close your work before stopping that server.

Install or refresh native integrations from fish:

```fish
herdr integration install claude
herdr integration install codex
herdr integration status
```

To reproduce the quota plugin installation:

```fish
herdr plugin install levi-qiao/herdr-agent-quota --ref 3d0e87c8f70c392e38de52d765c2776204b673b8 --yes
herdr plugin action invoke herdr-agent-quota.configure
```

Repair requires a running Herdr server started from a fresh fish shell.
`fish/conf.d/herdr.fish` exports `CLAUDE_SETTINGS_FILE` because the plugin reads
neither `CLAUDE_CONFIG_DIR` nor Claude's own `--settings`, and it replaces its
target file atomically. Since 2026-09-12 that variable points straight at the
tracked `claude-code/settings.json`: there is no `settings.json` in the Claude
config dir any more, because clauth rewrites that path on every account switch.
Native integration scripts live in the agents' runtime directories; tracked Claude
settings and Codex hooks contain their declarations.

Quota repair and layout changes restore the plugin's own quota colors. Sidebar
token `fg` accepts hex only, never an ANSI name, so the Laramie severity colors are
written out. Review `git diff -- herdr/config.toml` afterward and restore them:
green `#86c452`, yellow `#e0a332`, red `#fc8697`. This happened once already, on
2026-09-12.
The custom `prefix+u` refresh binding survives repair and leaves native reload free.

To reproduce the clauth plugin installation:

```fish
clauth herdr install --no-config --yes
```

⚠ `--no-config` is not optional here. Without it clauth appends its own
`[ui.sidebar.agents.rows_by_agent]` with `claude = [["state_icon", "workspace",
"tab"], ["terminal_title_stripped"], ["agent", "$clauth"]]`, and `rows_by_agent`
*replaces* the generic `rows` for that agent — so every herdr-agent-quota token
would silently vanish from Claude panes, which is the half that shows usage. The
two plugins complement each other: agent-quota renders model/TTL/context/5h/7d,
clauth renders which account the pane is spending.

Both config blocks are therefore hand-written in `herdr/config.toml`: the
`prefix+a` binding for `clauth.open`, and a `rows_by_agent.claude` template that
is the generic `rows` verbatim plus `$clauth` on the model row. Codex panes are
deliberately absent from `rows_by_agent`, so they keep the generic `rows`.

⚠ Maintenance: agent-quota's `configure --apply` rewrites only the line it marks
`# herdr-agent-quota-row`, and clauth only rewrites blocks it marked itself.
Neither will ever update the merged template. After a quota-plugin update that
renames or adds a token, re-copy `rows` into `rows_by_agent.claude` and re-add
`$clauth`. `scripts/audit-config.fish` fails if the two drift apart.

Run `herdr config check` and `herdr server reload-config` after manual changes.
Run `scripts/audit-config.fish` after an installation change.

## Validation, 2026-09-08

- Herdr configuration passes; live reload reports no diagnostics.
- Herdr reports current Claude v9 and Codex v8 integrations.
- Codex's live hooks API reports the Herdr hook enabled and trusted.
- Codex's live quota API returns a usage report without a model prompt.
- Quota installation and startup actions exit successfully.
- Claude, Codex, and hook configuration symlinks remain intact.
- Fish syntax, formatting, zero universal variables, and Git whitespace checks pass.
- Fish plus PTY startup medians: 18.53 ms before, 18.28 ms after, over 12 measured runs.
- Live Claude quota and full agent restore still require a real interactive session.
- The supplied screenshot showed the initial shell and selection contrast issues;
  the configuration addresses both. Computer-use access to Ghostty was denied,
  so final visual inspection was unavailable.

The broader audit still reports four unrelated issues: Simple English vendor drift
and three COMMONGROUNDS hook-name checks. The software inventory also reports
existing undeclared `cloc`, CapCut, and Xcode installations. Those files and
installations were left untouched by this setup.

## References

- [Herdr documentation](https://herdr.dev/docs/): configuration, integrations,
  agents, restore, keyboard, plugins, automation, CLI, socket API, remote machines,
  troubleshooting, and the agent guide.
- [Quota plugin documentation](https://github.com/levi-qiao/herdr-agent-quota).
- [Clauth security](https://github.com/uwuclxdy/clauth/blob/mommy/SECURITY.md) and
  [Herdr integration](https://github.com/uwuclxdy/clauth/blob/mommy/wiki/Herdr-Plugin.md).

For agent-driven pane control, ask the agent to read `herdr --skill` inside Herdr.
This prints the instructions shipped with the installed release.
