# Android test and private-test preparation

## Current artifact

- Debug APK: `build/holo-debug.apk` (249,823,557 bytes; generated locally; ignored by Git; debug-signed).
- Test AAB: `build/holo-test.aab` (86,231,323 bytes; generated locally; ignored by Git; unsigned packaging artifact, not uploadable to Play).
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
2. Training-hall build, free move/store/redeploy, M1 research purchase, evolution research unlock availability/persistence, research-list scrolling, and currency persistence after relaunch.
3. M1 unit placement, movement, attacks, both waves, intermission, victory settlement, and return to village.
   - On a 360×640-class portrait viewport, confirm the full 8×10 board stays fixed/visible, pause remains pinned outside the scroller, and lower controls scroll without clipping or horizontal scrolling; verify safe-area placement on a notched device.
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

Local Gradle Android debug APK export, API 29 manifest, and v2 signature verification pass. The latest test AAB was validated with bundletool 1.18.3 and its API 29/36 manifest, but it is unsigned. After switching the Android-only renderer to Godot Mobile/Vulkan, API 37 AVD (1080×2400) displayed the campaign menu and M1 defense board; ADB taps entered the stage, placed two swordsmen, and visibly reduced combat resources from 160 to 60. API 29 AVD installed and entered the Activity but logged Vulkan present `VkResult error 5`; that virtual GPU run failed rendering. Physical Android 10+ startup/touch behavior and FPS targets remain pending. The API 37 startup-only gfxinfo sample was 17 frames (11 janky, p50 61ms/p90 300ms), too short to establish performance. Publisher-key release AAB and Play Console private-test distribution also remain pending.


Latest local exports (2026-11-12): Debug APK 249,828,829 bytes; unsigned test AAB 86,236,623 bytes. Both use min API 29 / target API 36. APK v2 signature and AAB bundletool 1.18.3 validation pass. The API 37 AVD visual check is only an emulator smoke test, not a physical-device performance result.

## Latest emulator gameplay evidence

On API 37 AVD, manual taps entered M1, placed two swordsmen (resource 160→60), and started the wave. After all allies were gone, the game advanced into wave 2 while core HP remained 300, continued combat as core HP fell (188, then 76), and showed defeat only at core HP 0. The result panel showed 1/2 completed waves and +5 partial reward (balance 105). This verifies the core-survival rule and basic defense UI on an emulator; it does not establish physical-device compatibility, victory flow, or FPS.

- API 37 AVD supplement: force-stop/relaunch during M1 combat returned directly to the same active battle; HUD/core and surviving combat state were visible. The settled permanent balance 105 also survived a separate app relaunch. Repeat checkpoint restoration and schema migration checks on physical Android devices before release.

## 2026-11-12 status-effect Android export

- Re-exported after status-effect runtime changes: `build/holo-debug.apk` (249,829,245 bytes) and `build/holo-test.aab` (86,237,040 bytes).
- APK manifest: `com.example.holotactics`, min API 29, target API 36. `apksigner verify` passed with one signer (debug key).
- AAB: `bundletool 1.18.3 validate` passed; base manifest reports the same application ID and API levels. The AAB is unsigned and not Play-upload ready.
- SHA-256: APK `60067B5D69CF2AD4B812BD3E1B00E68D2222C27D0B8836D4E492B2FE53096F3`; AAB `CE0EFCBA65218F42553F341CB794076E6089B9E7D4AA08D3651EFAC0D9AE7B66`.
- adb currently reports both installed AVDs offline. No post-change device smoke or FPS measurement was possible; the prior API 29 Vulkan-render failure and physical-device verification remain open.

## Latest emulator smoke after status-effect rebuild (2026-11-12)

- ADB server restart recovered both existing AVDs. Installed the freshly exported APK on API 29 and API 37 emulator images.
- API 37 (Android 17, 1080x2400, density 420): app resumed successfully; campaign menu and M1 defense board rendered. Latest M1 screenshot is `build/emulator-5556-status-effect-m1c.png` (local ignored artifact). No game script/render error appeared in the short smoke window.
- API 29: install and launcher activity succeeded, but captured frame was fully black and Godot repeatedly logged `Couldn't present to Vulkan queue (VkResult error 5)`.
- This is emulator-only and does not establish physical Android 10 compatibility, playthrough correctness for this APK, or FPS targets. API 29 Vulkan rendering is an active release risk requiring a physical Android 10 device or a validated renderer fallback.

- API 29 renderer isolation follow-up: restarted `MaDang_API29` without wiping AVD data, first with its original host GPU mode and again with `-gpu swiftshader_indirect`. Both runs installed/launched the latest APK but captured black frames and logged Vulkan queue present `VkResult error 5`. API 37 SwiftShader still renders. The issue is specific to this API29 emulator image/driver path until checked on physical Android 10 hardware; no Android 10 compatibility claim is made.

- 2026-11-12: Current API37 AVD with the latest sprite-atlas build shows M1 battle and deployed swordsman sprite. API29 smoke remains black with Vulkan present error 5. The asset is a temporary atlas; FPS/physical device remain unverified.
- Latest build hashes: APK `95DDFF7E99F5E30946B9626DC96A25B5E5F9B605E40EA55D5F8AFFF271A1EBA3`; AAB `90FE8D18CAB772A69E6E01305E053228D3471EFB19793CF746DC9E640FD11856`.

## AVD FPS sampling limitation (2026-11-12)

Tried Android system frame collectors during an active API37 AVD M1 wave. `dumpsys gfxinfo com.example.holotactics` reported zero ViewRoot frames (the Godot Vulkan game is rendered through a native SurfaceView); percentile defaults were 4950ms and are invalid. `dumpsys SurfaceFlinger --latency` returned only the display refresh period (16,666,666ns), without frame timestamps for the Godot layer. These commands cannot establish game FPS or frame-time targets on this build. Use Godot's Remote Profiler on a connected target or a physical-device GPU/frame profiler; keep 60/30 FPS acceptance pending.

## Debug frame sample (2026-11-12)

A debug-only sampler logs `[PERF]` every 10 seconds during combat/preparation. On the API37 SwiftShader AVD, an M1 wave produced two windows: 25.9/25.4 average FPS, p95 41.67/41.31ms, max 50ms. This is under the 60 FPS regular / 30 FPS high-load targets and reflects a software-rendered emulator, not a representative phone; do not use it to claim device performance. Repeat on physical Android 10+ hardware with the Godot Remote Profiler or a device GPU/frame profiler.
