# Android test and private-test preparation

## Current artifact

- Debug APK: `build/holo-debug.apk` (generated locally; ignored by Git).
- Package ID: `com.example.holotactics` (placeholder; replace with the publisher's permanent ID before release).
- Export preset: `Android Debug APK`; minimum API 24, target API 36.
- The APK is debug-signed. It is for device smoke tests, not Google Play upload.

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

Local Android export and APK signature verification pass. Physical Android 10+ startup, touch/UI behavior, frame-rate targets, release AAB signing, and Play Console private-test distribution are pending external device/account access.
