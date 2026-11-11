# Holo Tactics

Portrait 2D strategy game built with Godot 4 and GDScript. Design source of truth is in `docs/`.

## Local development

- Godot: 4.7.2 stable (any Godot 4 build pinned in CI should be matched locally).
- Headless tests: `godot --headless --path . --script res://tests/run.gd`
- Content gate: `godot --headless --path . --script res://scripts/validate_content.gd`
- Open `project.godot` in the Godot editor to run the portrait project.
- Android SDK on this workstation: `%LOCALAPPDATA%/Android/Sdk`; configure Godot Editor > Editor Settings > Export > Android to use it. Android export templates and signing credentials are not stored in this repository.

## Data boundaries

`data/catalog.json` contains bundled content definitions. Runtime battle state, permanent player progress, and editor preview data will be kept separate as their owning systems are added. Content, schema, and save versions are independent constants in `scripts/project_versions.gd`. No numeric balance seed is a locked game rule.
