# Holo Tactics

Portrait 2D strategy game built with Godot 4 and GDScript. Design source of truth is in `docs/`.

## Local development

- Clone this repository, install Godot 4.7.2 stable, and open `project.godot`. No external Godot addons are required for the desktop game.
- Double-click `run_godot_game.bat` to start the visible Windows game, or open the project in Godot and press F6/F5. Use `run_godot_tests.bat` for the separate headless regression suite.
- Godot: 4.7.2 stable (any Godot 4 build pinned in CI should be matched locally). On the inspected Windows workstation, run commands with:

  ```powershell
  $godot = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
  $test_output = & $godot --headless --path . --script res://tests/run.gd --quit-after 2
  $test_output
  if ($test_output -notmatch "All headless project tests passed") { throw "Godot tests failed" }
  & $godot --headless --path . --script res://scripts/validate_content.gd --quit-after 2
  ```

- Open `project.godot` in the Godot editor to inspect/edit the portrait project.
- On Windows, double-click `run_godot_tests.bat` to run the headless core, content, campaign, battle-UI, and editor-panel checks.
- After exporting the `Android Debug APK` preset to `build/holo-debug.apk`, double-click `run_android_emulator_test.bat` to boot the preferred API 37 AVD, install the APK, and launch the game.
- The enabled **Holo Content Editor** dock has stage/wave, evolution, and combat-upgrade JSON panels. Stage/wave preview runs from saved catalog data in an isolated checkpoint and does not settle rewards.
- Android device smoke, frame-rate measurement, and private-test readiness steps are in [ANDROID_TESTING.md](ANDROID_TESTING.md).
- The main menu exposes the seeded 6-main/2-optional campaign. Village management includes the four growth buildings and a scrollable permanent-research screen. Base-stat amounts and evolution research prices are balance seeds. Combat evolution is implemented; each unit locks its first selected form. Battle controls expose only units and facilities available in the selected stage.
- Android export on a new workstation also needs Android Studio SDK command-line components/platform 36, build-tools 36.x, platform-tools, and JDK 17. Set the Android SDK and Java paths in Godot Editor Settings, install the Android build template, then export the debug APK with:

  ```powershell
  New-Item -ItemType Directory -Force build | Out-Null
  & $godot --headless --path . --install-android-build-template --export-debug "Android Debug APK" build/holo-debug.apk
  ```

- The Android presets use Gradle and Godot Mobile (Vulkan); the desktop project uses GL Compatibility. Minimum Android API is 29; target API is 36. Create/start an API 37 AVD in Android Studio, then double-click `run_android_emulator_test.bat` to install and launch `build/holo-debug.apk`.

- Android exports exclude automated tests, the editor plugin, and the editor-only preview runner. These remain available in the Godot project and CI.

- The checked-in Android package ID is `com.rhstudio.holotactics`. For a signed Play-format AAB, set `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` in the process environment, then run `scripts/export_android_aab.ps1`. Keep the keystore and passwords outside Git.
- `assets/icon.svg` is temporary project art; replace it before store publication. No release keystore or store credentials belong in this repository.

## Data boundaries

`data/catalog.json` contains bundled content definitions. Runtime battle state/checkpoints, permanent campaign progress, and one-shot editor preview requests use separate files and systems. Content, schema, and save versions are independent constants in `scripts/project_versions.gd`. No numeric balance seed is a locked game rule.
