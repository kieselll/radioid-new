# Radioid

Radioid is a Godot 4 game project. Open `project.godot` with the Godot editor to run or edit it.

The repository is organized by gameplay feature instead of by file type:

- `core/` contains global services, debugging support, transitions, and reusable utilities.
- `features/` contains gameplay domains; each feature owns its scripts, scenes, data, and assets.
- `content/` contains authored content shared across gameplay domains, such as localization and effects.
- `shared/` contains genuinely cross-feature assets such as shaders and editor icons.
- `addons/` contains third-party Godot plugins.
- `docs/` contains project and architecture documentation.

See [`docs/project-structure.md`](docs/project-structure.md) before adding or moving files.
