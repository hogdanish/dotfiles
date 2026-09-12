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

Clauth is not installed. Its account switching writes credential copies and changes
Claude's login state. That conflicts with the current credential arrangement and
adds no benefit unless multiple Claude accounts need management.

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
`fish/conf.d/herdr.fish` exports the real Claude settings path because the plugin
ignores `CLAUDE_CONFIG_DIR` and replaces its target file atomically.
Native integration scripts live in the agents' runtime directories; tracked Claude
settings and Codex hooks contain their declarations.

Quota repair and layout changes restore upstream quota colors. Review
`git diff -- herdr/config.toml` afterward and restore the Laramie severity colors:
green `#86c452`, yellow `#e0a332`, red `#fc8697`.
The custom `prefix+u` refresh binding survives repair and leaves native reload free.

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
