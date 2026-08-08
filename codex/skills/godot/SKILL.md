---
name: godot
description: Build, edit, diagnose, and verify Godot projects and files, including GDScript, shaders, scenes, resources, project.godot, addons, nodes, signals, autoloads, input maps, and editor/runtime control. Use for any Godot or GDScript task and for .gd, .gdshader, .tscn, .scn, .tres, .res, .import, .godot, or .gdextension files.
---

# Work on Godot projects

Make sound architectural decisions about scene structure, filesystem layout, composition, inheritance, and reusable components. Explain material choices in the handoff.

## Version and tooling

- Assume this machine often runs Godot development builds. Verify version-sensitive or obscure APIs against current official Godot documentation.
- Author text resources through normal filesystem edits. Use available Godot editor/runtime tools to observe, drive, and verify; do not assume a particular MCP server name is installed.
- The editor can overwrite files it already has open. Reload a changed `.tscn` from disk. After editing `project.godot`, check for editor/disk divergence and restart the editor if required.
- Prefer structured runtime state and node/property inspection over screenshots. Use screenshots only when pixels are the actual question.

## GDScript law

- Treat warnings as errors. Statically type members, parameters, locals when useful, and return values.
- Use explicit `: Type =` when inference would trigger `inferred_declaration`.
- Explicitly discard a non-void result with `_ = call()`.
- Prefer `%UniqueName as TypeName` over long `get_node()` chains.
- Load resources with `preload()` or `@onready`; never load them in `_process()` or `_physics_process()`.
- Prefer the CLog addon over bare `print()` when the project provides it.
- Use modern idioms when they improve the design: typed arrays/dictionaries, resources, callables, signals, properties, `@tool`, `@export_tool_button`, `@abstract`, `await`, static/lambda/variadic functions, and tightly scoped warning suppressions.

Naming:

| Element | Convention |
| --- | --- |
| Files | `snake_case` |
| Classes, nodes, `class_name` | `PascalCase` |
| Functions and variables | `snake_case` |
| Private and virtual members | `_snake_case` |
| Signals | past-tense `snake_case` |
| Constants | `CONSTANT_CASE` |
| Enums | `PascalCase` with `CONSTANT_CASE` members |

Formatting:

- Use tabs, UTF-8, LF endings, a final newline, and no semicolons.
- Keep lines at or below 100 columns when practical.
- Use text operators: `and`, `or`, `not`.
- Put two blank lines around function and class definitions, one between logical blocks, and no more than two consecutive blank lines.
- Use one space around binary operators and after commas; use `{ key = value }` for one-line dictionaries.
- Put one entry per line and a trailing comma in multiline arrays, dictionaries, and enums.
- Write concise lowercase implementation comments. Use `##` documentation comments for public APIs.

Order declarations as follows: annotations, `class_name`, `extends`, class documentation, signals, enums, constants, static variables, exports, regular variables, `@onready` variables, static methods, built-in virtuals, custom overrides, remaining methods, then inner classes.

## Verification

1. Run the project's formatter and linter when configured; on this machine `gdformat` and `gdlint` are available.
2. Get static diagnostics for every touched GDScript file. Run a workspace scan after a broad refactor.
3. Run the relevant scene once, then inspect both editor-process messages and the game's console/stderr when those channels are available.
4. Use deterministic frame stepping or a predicate-based wait for timing-sensitive work. Do not use arbitrary sleeps.
5. Stop after the cheapest evidence that proves the change. Ask the user about a subjective visual outcome instead of accumulating screenshots.
