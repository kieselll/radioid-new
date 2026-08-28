# Project structure

## Directory map

```text
radioid-new/
|-- addons/                    # Third-party Godot plugins
|-- content/
|   |-- effects/               # Shared authored visual effects
|   |-- environment/           # Environment content and light scenes
|   `-- localization/          # Translation sources
|-- core/
|   |-- autoloads/             # General-purpose global services
|   |-- debug/                 # Debug UI and drawing support
|   |-- scene_transition/      # Transition scene and its scripts
|   `-- utilities/             # Dependency-light reusable helpers
|-- features/
|   |-- building/              # Placement, tile data, buildable content and assets
|   |-- entities/              # Pawns, entity data, components and character assets
|   |-- items/                 # Item data, registries, inventories and item assets
|   |-- jobs/                  # Work assignment and job coordination
|   |-- ui/                    # Menus, HUD, controls, themes and UI assets
|   `-- world/                 # Main game scene, chunks, pathfinding and simulation
|-- shared/
|   |-- editor_icons/          # Icons referenced by multiple script features
|   `-- shaders/               # Cross-feature shaders and shader resources
|-- docs/
|-- project.godot
`-- README.md
```

## Placement rules

1. Put a file in the feature that owns its behavior. Keep that feature's scenes, scripts, data resources, and exclusive assets together.
2. Move a file to `shared/` only after more than one feature depends on it. Shared code should not depend on feature code.
3. Use `core/` for project-wide lifecycle services and low-level helpers, not as a miscellaneous folder.
4. Keep third-party code isolated in `addons/`; do not mix project code into plugin directories.
5. Use `snake_case` for new GDScript and scene filenames. Existing art filenames may retain source names to avoid needless import churn.
6. Move `.uid` files together with their GDScript files. After any move, update every affected `res://` path and run a headless Godot import/check.
7. Do not commit `.godot`, temporary scenes, recovery output, runtime logs, or exported builds.

## Feature dependency direction

Feature code may depend on `core/` and `shared/`. Cross-feature dependencies should be explicit and kept narrow. If several features need to coordinate, prefer a focused service or signal over reaching into another feature's internal scene tree.
