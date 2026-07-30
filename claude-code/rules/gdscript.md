---
paths:
  - "**/*.gd"
---

# GDScript rules

## 1. Follow strict mode (warnings = errors)

- **Statically type everything**: `var x: int = 0`, `func foo(n: int) -> void:`. Annotate params, returns, and members.
- No bare `:=` where it trips `inferred_declaration`; use explicit `: Type =` when the type isn't obvious from the right-hand side.
- Discarding a non-void return must be explicit: `_ = risky_call()`.
- Prefer `%UniqueName as TypeName` over `get_node(...)` chains.
- Load resources with `preload()` / `@onready` — **never** load inside `_process` / `_physics_process` or other hot paths.
- Avoid bare `print()` — log via the **CLog addon** if available.
- **How this is checked**: a clean run does *not* mean clean warnings — GDScript warnings never reach the game's Output log. Pull them statically from Godot's LSP (`godot-lsp` `get_diagnostics` on the touched file; `scan_workspace_diagnostics` after a broad refactor), which reports errors and warnings with full project context. The editor-process channel (`godot-mcp` `godot_editor_read get_log_messages severity="warning"`) covers `@tool`/import/addon failures. Where a project raises warnings to level 2, they become hard errors that block the run outright. Either way, treat a warning as a defect to fix, not ignore.

## 2. Reach for modern idioms and synactic sugar.

Don't neglect newer / more advanced GDScript features that can make our code cleaner, more efficient, and more robust. Here are just some examples:

- Prefix signals with `_` to hide them from auto-completion and generated docs.
- bbcode in `##` doc comments for richer rendering.
- Typed dictionaries and typed arrays.
- `@export_tool_button` for inspector-driven editor actions.
- `@warning_ignore_start` / `@warning_ignore_restore` / `@warning_ignore("code")` to scope suppressions tightly.
- `@abstract` classes and methods.
- Variadic functions; lambda and `static` functions.
- Exporting plain `Variant` properties when genuinely needed.
- `%UniqueNode` access names; `@export` annotation family for inspector config.
- `#region` / `#endregion` code regions for navigation.
- Property setters/getters (`var x: int: set = _set_x, get = _get_x`).
- `@tool` mode features; `signal` + `assert()` for contracts and editor-time guards.

## 3. Naming

| Element                         | Convention                                 | Example                                    |
| ------------------------------- | ------------------------------------------ | ------------------------------------------ |
| Files                           | `snake_case`                               | `yaml_parser.gd`                           |
| Classes / nodes / `class_name`  | `PascalCase`                               | `class_name Weapon`                        |
| Functions / variables           | `snake_case`                               | `func load_level()`, `var particle_effect` |
| Private funcs / vars / virtuals | `_`-prefixed `snake_case`                  | `func _recalculate_path()`, `var _counter` |
| Signals                         | past-tense `snake_case`                    | `signal health_changed`                    |
| Constants                       | `CONSTANT_CASE`                            | `const MAX_SPEED = 200`                    |
| Enums                           | `PascalCase` name, `CONSTANT_CASE` members | `enum Tile { BRICK, FLOOR }`               |

A file's name should be the `snake_case` form of its `class_name`.

## 4. Formatting

- **Indentation**: tabs, not spaces. Continuation lines of a wrapped statement get an **extra** indent level to distinguish them from the body.
- **Line length**: keep ≤ 100 columns.
- **One statement per line**; no semicolons. Ternary expression is the lone exception.
- **Blank lines**: two around function and class definitions; one to separate logical sections inside a function. Never more than two consecutive blank lines.
- Avoid unnecessary parentheses in conditions.
- Prefer the **text** boolean operators `and` / `or` / `not` over `&&` / `||` / `!`.
- **Comments**: one space after `#` (`# like this`); no space when commenting out code (`#var disabled = 1`). Doc comments use `##`.
- Encoding: UTF-8, no BOM, LF line endings, trailing newline.

## 5. Whitespace

- One space around binary operators and after commas; none before a comma.
- Arrays: no inner padding — `[4, 5, 6]`.
- Dictionaries: pad single-line braces to distinguish from arrays — `{ key = "value" }`.
- No space between a call/identifier and its `(` — `print("foo")`, `dict["key"]`.
- Type hints: space after the colon, none before — `var health: int = 0`.
- `=` in default/keyword args: **no** spaces when untyped (`func f(arg = 0)` → `func f(arg=0)`), spaces when typed (`func f(arg: int = 0)`).
- Multi-line arrays/dicts/enums: one entry per line, **trailing comma** on the last entry.

## 6. Code order

```text
01. @tool, @icon, @static_unload
02. class_name
03. extends
04. ## doc comment

05. signals
06. enums
07. constants
08. static variables
09. @export variables
10. remaining regular variables
11. @onready variables

12. _static_init()
13. remaining static methods
14. overridden built-in virtuals: _init() → _enter_tree() → _ready() → _process() → _physics_process() → remaining
15. overridden custom methods
16. remaining methods
17. inner classes
```

## 7. Reference shape

```gdscript
class_name Player
extends CharacterBody2D
## brief [b]player[/b] controller.

signal _died

const MAX_HEALTH := 100

@export var speed: float = 300.0
var _health: int = MAX_HEALTH

@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	_health = MAX_HEALTH


func take_damage(amount: int) -> void:
	_health = max(0, _health - amount)
	if _health == 0:
		_died.emit()
```
