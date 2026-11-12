# Android test and private-test preparation

## Current artifact

- Debug APK: `build/holo-debug.apk` (generated locally; ignored by Git; latest local build includes read-only pause; unit/facility contextual panels included).
- Test AAB: `build/holo-test.aab` (unsigned packaging artifact only; latest local build includes read-only pause; unit/facility contextual panels included; unsigned and not uploadable to Play).
- Package ID: `com.example.holotactics` (placeholder; replace with the publisher's permanent ID before release).
- Export preset: `Android Debug APK`; minimum API 29, target API 36. `Android Play AAB` uses Gradle with the same API levels.
- The APK is debug-signed. It is for device smoke tests, not Google Play upload.

## Release AAB export

`scripts/export_android_aab.ps1` installs the Godot Android Gradle template, exports `build/holo-release.aab`, and verifies its JAR signature. Provide a publisher-owned release key through the process environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` (key alias), and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. The script does not print their values. Never commit the key or password.

The repository's application ID is a placeholder and must be replaced by the publisher's permanent unique ID before Play upload. A locally generated throwaway key can validate packaging but its AAB is not upload-ready.

## Device smoke test

Use a physical Android 10+ device with USB debugging enabled. Record device model, Android version, display size, and Godot build with the result.

```powershell
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adbPath devices
& $adbPath install -r .\build\holo-debug.apk
& $adbPath logcat -c
& $adbPath shell monkey -p com.example.holotactics 1
```

Check each flow and record pass/fail plus a short note:

1. Portrait startup, safe-area placement, campaign stage locks, and opening the village.
2. Training-hall build, free move/store/redeploy, M1 research purchase, and currency persistence after relaunch.
3. M1 unit placement, movement, attacks, both waves, intermission, victory settlement, and return to village.
   - Select a deployed unit and confirm its upgrade/skill panel appears beside it and remains inside the screen; select a facility and confirm its HP/move hint appears beside it.
   - Before the stage's first clear, verify 2× is unavailable; clear it, re-enter, and verify 2× changes battle and intermission cadence together.
   - Pause during preparation and combat: verify units, enemies, cooldowns, and countdown stop; tile taps show information without selecting, moving, building, spending, or queuing commands. Resume and confirm the remaining timer continues.
4. Explicit abandon and defeat partial rewards; relaunch the same run to confirm rewards are not duplicated.
5. Close/relaunch during preparation and combat; confirm checkpoint restoration is not treated as an abandon.
6. M2 siege: issue an order into the enemy half, fight through all waves, and destroy the enemy core.
7. Progress through all 8 campaign stages, including the M4 opening test setup (swordsman, archer, spearman, arrow tower in front of the core).

Collect logs after each run:

```powershell
& $adbPath logcat -d | Select-String 'Godot|AndroidRuntime|FATAL EXCEPTION'
```

## Frame-rate measurement

Measure on at least one representative lower-tier Android 10+ device and one current mid-range device. Connect Godot's remote profiler for the engine frame time; use Android system frame stats as a cross-check:

```powershell
& $adbPath shell dumpsys gfxinfo com.example.holotactics reset
# Play the named scenario for at least 60 seconds, including combat and effects.
& $adbPath shell dumpsys gfxinfo com.example.holotactics framestats
```

Record scenario, device, room temperature/power mode, run duration, average and 95th-percentile frame time, worst sustained interval, and profiler CPU/GPU frame times. Compare normal combat against a high-load wave with multiple units, facilities, and effects. Acceptance targets from the project brief are 60 FPS in normal combat (16.67 ms/frame) and at least 30 FPS under high load (33.33 ms/frame). Do not infer engine FPS from a single `dumpsys` summary.

## Google Play private test readiness

- The debug APK and its debug certificate are not a release upload.
- A permanent application ID, release/upload keystore, and Play Console access have not been provided. Do not reuse the placeholder package ID or put signing credentials in this repository.
- Before private testing, set the publisher-owned package ID, configure a protected release signing credential outside Git, export and verify a release AAB, then upload through the authorized Play Console account. Store listing, privacy declarations, and tester access still need publisher-owned information.

## Current verification state

Local Gradle Android debug APK export, API 29 manifest, and v2 signature verification pass. The latest test AAB was validated with bundletool 1.18.3, its API 29/36 manifest and required bundle entries were checked, but it is unsigned. Physical Android 10+ startup, touch/UI behavior, frame-rate targets, publisher-key release AAB, and Play Console private-test distribution remain pending device/account access.
