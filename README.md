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
- The enabled **Holo Content Editor** dock has stage/wave, evolution, and combat-upgrade JSON panels. Stage/wave preview runs from saved catalog data in an isolated checkpoint and does not settle rewards.
- The main menu exposes the seeded 6-main/2-optional campaign. Village management includes the four growth buildings and a separate permanent-research screen; research effects are still balance seeds. Battle controls expose only units and facilities available in the selected stage.
- Android SDK and OpenJDK 17 are installed and configured in the local Godot editor settings. Export templates are installed. The local debug preset exports with `--export-debug "Android Debug APK" build/holo-debug.apk` (create the ignored `build/` directory first).
- `assets/icon.svg` is temporary project art; replace it before store publication. No release keystore or store credentials belong in this repository.

## Data boundaries

`data/catalog.json` contains bundled content definitions. Runtime battle state, permanent player progress, and editor preview data will be kept separate as their owning systems are added. Content, schema, and save versions are independent constants in `scripts/project_versions.gd`. No numeric balance seed is a locked game rule.
