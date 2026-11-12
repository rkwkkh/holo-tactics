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
- Android device smoke, frame-rate measurement, and private-test readiness steps are in [ANDROID_TESTING.md](ANDROID_TESTING.md).
- The main menu exposes the seeded 6-main/2-optional campaign. Village management includes the four growth buildings and a scrollable permanent-research screen. Base-stat amounts and evolution research prices are balance seeds; evolution purchase unlocks are persisted, but combat transformation still awaits the branch/re-evolution policy. Battle controls expose only units and facilities available in the selected stage.
- The Android presets use Gradle so the manifest minimum is API 29 (Android 10); target API is 36. Install the Android build template and export the debug APK with:

  ```powershell
  New-Item -ItemType Directory -Force build | Out-Null
  & $godot --headless --path . --install-android-build-template --export-debug "Android Debug APK" build/holo-debug.apk
  ```

- For a signed Play-format AAB, set `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` in the process environment, then run `scripts/export_android_aab.ps1`. Keep the keystore and passwords outside Git. The checked-in package ID is still a placeholder.
- `assets/icon.svg` is temporary project art; replace it before store publication. No release keystore or store credentials belong in this repository.

## Data boundaries

`data/catalog.json` contains bundled content definitions. Runtime battle state, permanent player progress, and editor preview data will be kept separate as their owning systems are added. Content, schema, and save versions are independent constants in `scripts/project_versions.gd`. No numeric balance seed is a locked game rule.


진화 형태 6종은 마을 연구로 영구 해금되며 연구 결과는 체크포인트에 저장된다. 연구 비용은 임시 초기값이다. 실제 전투 변신은 분기·재진화 정책 결정 후 연결한다.
