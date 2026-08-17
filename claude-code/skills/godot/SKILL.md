---
name: godot
description: Godot engine work — GDScript, scenes and nodes, shaders, resources, project settings, and driving the editor through the Godot MCP servers. Load for any Godot file (.gd, .gdshader, .tscn, .tres, project.godot, .gdextension) or any mention of Godot, nodes, or signals.
---

Apply these conventions to all Godot work. Be autonomous: make sound architectural calls on your own (inheritance, scene-tree shape, filesystem layout, component-based/DRY design) rather than dumping logic into the nearest script — then disclose the decisions and reasoning in your reply.

## Rules

- **Versioning**: We run the current **release build** — `4.7.1.stable` as of 2026-08-10 — and the 4.x surface moves fast. Pin lookups to the engine: Context7 **`/websites/godotengine_en_4_7`**. ⚠ Bump that ID when the engine's minor version changes; `/godotengine/godot-docs` tracks `master` and describes a build we do not run. Do NOT trust training data for 4.x — it skews to 3.x and early 4.x.
- **When to look something up** — do not gauge your own confidence; it is not reliable, and it is highest exactly where the training data is oldest. Use the split instead:
  - **Shape** (does this method exist, what arguments, what return type) — the LSP catches this for free, so do not look it up first. **Guess at most once.** The first `get_diagnostics` rejection of an engine symbol spends a Context7 query, never a second guess and never a third.
  - **Semantics** (when a signal fires, node lifecycle and `_ready`/`_process` order, what a subsystem actually does) — query **before** you design around it, once per subsystem per session. Nothing catches a wrong mental model here: the code compiles, runs, and is still wrong. Physics and interpolation, navigation, multiplayer sync, rendering and input are the recurring cases.
  - ⚠ Writing a scratch scene or a test to discover what a built-in class, annotation or keyword *does* is a lookup you skipped. Test *your* code, not the engine's.
- **Which docs tool**: Context7 **queries** documentation — the default for any Godot API or behaviour question. Built-in **WebSearch/WebFetch** win when you need a whole page, a GitHub issue, PR or proposal, or engine **source**; use them when Context7 returns nothing useful, or the question is about an unreleased change. Neither replaces reading the project's own code.
- **Organization**: Treat filesystem structure as first-class. Group files by scope/feature in sensible locations; mirror scene structure where it helps.
- **Comments as docs**: Comment where it aids understanding, concise and technical, **all lowercase**. Don't over-comment. Use `##` doc comments (with bbcode where it improves readability) for the public API.
- **Logging**: Add logging wherever it aids future debugging via the **CLog addon** if available
- **Be a GDScript wizard**: Reach for idiomatic, modern patterns (the `gdscript.md` rule is the authoritative style/idiom reference) over verbose/legacy equivalents, such as (but not limited to) resource files, typed dictionaries, typed arrays, abstract classes/methods, finite state machines, super(), await/yield/asserts, %SceneUniqueNodes, @export annotations, ## Formatted documentation [b]comments[/b], #region/#endregion, @tool, @warning_ignore, @tool, callables, static variables, @static_unload, casting, abstract/lambda/static/variadic functions, class constructors, classes as resources, setters and getters (properties), free()/queue_free() memory management, et cetera. 
- Assume the **Godot editor is open** on the desktop and the Godot MCP is usable. ⚠ Authoring is **filesystem work** — the MCP observes and drives, it does not create nodes/scripts/scenes — so the editor-clobbers-open-files risk is real: a write to a file the editor holds open is silently reverted. After editing a `.tscn`, force a reload-from-disk (`godot_scene reload`); after editing `project.godot`, check for divergence (`godot_project check_stale`) and restart the editor if it diverged.
- **Verify lean, then stop** — a human checks most changes in ~30 s; don't out-spend that with Godot MCP round-trips (this budget is about *runtime* verification and does not apply to docs lookups). Spend the cheapest tier that proves the change:
  - **Static first**: LSP diagnostics on the touched file (`godot-lsp get_diagnostics`) catch parse errors *and* warnings with no run, with full project context. A new `class_name`/autoload needs an editor **restart** before the editor's own analyzer registers it; the running game already resolves it, so a stale "class doesn't exist / shadows a global" complaint right after adding one is cosmetic — verify via a clean run, not by restarting repeatedly.
  - **One run, two log reads**: run the scene **once** (`godot_editor_edit run`, `frozen: true` when timing matters), then pull **both** error channels once each — `godot_editor_read get_log_messages` is the *editor* process only, and the *game's* console (`print`/CLog/stderr) comes from `godot-lsp get_console_output`. One channel sees half the picture. No clear→wait→recheck loops; express waits as `godot_game_time step_until`, never a fixed sleep.
  - **Prefer structured state over pixels**: `godot_runtime_state digest` and `godot_node_read` answer most "did it work?" questions for free.
  - **Visual is the expensive last resort**: every screenshot persists in context for the whole session and never decays. Take **~1–2** at most, drop `max_width` to 640 when fine print isn't the question, and **never** re-capture to "dial in" a shot. If the visual outcome is unclear, **ask the user** (they see it instantly). For a genuinely multi-frame visual check, dispatch a subagent so the frames die with its context.
- **Use nodes and scenes** rather than implementing everything procedurally in scripts unless there's a compelling reason not to. Favor composition and inheritance when they make sense. Always consider scene tree structure and filesystem organization as you work, and don't be afraid to refactor if it will lead to a cleaner design.
- **Proactively consider component-based design and DRY principles**: if you find yourself writing similar code or patterns, consider abstracting them into reusable components or utility scripts rather than copying and pasting. Consider future maintainability and extensibility as you design your solutions.
- **Don't hesitate to make autonomous decisions** about architecture, design patterns, or best practices as you work — just be sure to disclose those decisions and your reasoning in your response so I'm aware of the changes and can provide feedback if needed.

## Take advantage of newer Godot 4.6 / 4.7 features that may not be in training data, such as but not limited to:

- [DrawableTextures](https://docs.godotengine.org/en/latest/tutorials/rendering/drawable_textures.html), a type of Texture2D with additional functions for modifying the texture via the GPU. This can be used for procedural texturing, real-time effects, and much more. 
- [AreaLight3D](https://docs.godotengine.org/en/4.7/classes/class_arealight3d.html)
- [Offset transforms for control nodes](https://docs.godotengine.org/en/latest/classes/class_control.html#class-control-property-offset-transform-enabled)
- [HDR output](https://docs.godotengine.org/en/latest/tutorials/rendering/hdr_output.html)
- [Path3D points can now snap to colliders](https://docs.godotengine.org/en/4.7/classes/class_path3d.html)
- [Automatic smoothing option for CSG nodes](https://github.com/godotengine/godot/pull/116749)
- [One-way collision support for CollisionShape2D](https://docs.godotengine.org/en/4.7/classes/class_collisionshape2d.html#class-collisionshape2d-property-one-way-collision-direction)
- [Conic gradients](https://docs.godotengine.org/en/4.7/classes/class_gradienttexture2d.html)
- [Font-size aware RichTextLabel images](https://docs.godotengine.org/en/4.7/classes/class_richtextlabel.html)
- [Landmark navigation for enhanced accessibility](https://github.com/godotengine/godot/pull/114449)
- [New nearest-neighbor scaling option for viewports](https://github.com/godotengine/godot/pull/79731)
- [Tile AtlasTextures in TextureRect nodes](https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html)

## Tooling

Two MCP servers, complementary — assume both are available and the Godot editor is open:

- **`godot-mcp`** (`@satelliteoflove/godot-mcp`) — 21 action-dispatch tools over a WebSocket to the live editor (the `godot_mcp` addon must be installed **and enabled**), plus the running game over Godot's debugger wire. Reach for it to:
  - **Observe** — `godot_node_read` (scene tree, properties, `find` that targets the *running* game), `godot_editor_read` (editor state, log messages, stack traces, screenshots), `godot_project`, `godot_scene3d` (resolved transforms/AABBs), `godot_resource`, `godot_docs`.
  - **Drive the game** — `godot_editor_edit run/stop` (`frozen: true` = deterministic playtest from frame 0), `godot_game_time` (freeze / `step` / `step_until` a GDScript predicate, with an input timeline riding inside the window), `godot_exec` (GDScript inside the live game for scenario setup — `return` a value, no `await`, `print` output is not returned), `godot_input`, `godot_profiler` (reads the *game* process), `godot_runtime_state` (structured entity state; tag nodes into `mcp_watch` and implement `_mcp_state()` to make it rich).
  - **Edit what files can't express** — `godot_node_edit` (update properties, reparent), `godot_tilemap_*`/`godot_gridmap_*` (cell data is base64 in the `.tscn`), `godot_animation_*`, `godot_scene` (open/save/reload).
  - ⚠ It does **not** author: no create-node/script/scene/shader, no `set_project_setting`, no editor-side script execution.
- **`godot-lsp`** (`@ryanmazzolini/minimal-godot-mcp`) — no addon; talks to the editor's own LSP/DAP. `get_diagnostics` (one file) and `scan_workspace_diagnostics` for static GDScript errors *and warnings*; `get_console_output` for the running game's console and stderr.
- **Edit/Write** for everything else — `.gd`, `.gdshader`, `.tres`, `.tscn` and `project.godot` are text, and writing them directly is the normal path. Mind the open-file clobber rule above.