# Holo Tactics

Portrait 2D strategy game built with Godot 4 and GDScript. Design source of truth is in `docs/`.

## Local development

- Godot: 4.7.2 stable (any Godot 4 build pinned in CI should be matched locally). On the inspected Windows workstation, run commands with:

  ```powershell
  $godot = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
  $test_output = & $godot --headless --path . --script res://tests/run.gd
  $test_output
  if ($test_output -notmatch "All headless project tests passed") { throw "Godot tests failed" }
  & $godot --headless --path . --script res://scripts/validate_content.gd
  ```

- Open `project.godot` in the Godot editor to run the portrait project.
- The main menu exposes the M1 defense slice and an M2 siege test entry; the siege button is a development path, not a campaign unlock.
- Android SDK and OpenJDK 17 are installed and configured in the local Godot editor settings. Export templates are installed. The local debug preset exports with `--export-debug "Android Debug APK" build/holo-debug.apk` (create the ignored `build/` directory first).
- `assets/icon.svg` is temporary project art; replace it before store publication. No release keystore or store credentials belong in this repository.

## Data boundaries

`data/catalog.json` contains bundled content definitions. Runtime battle state, permanent player progress, and editor preview data will be kept separate as their owning systems are added. Content, schema, and save versions are independent constants in `scripts/project_versions.gd`. No numeric balance seed is a locked game rule.
