# Android test and private-test preparation

## Current artifact

- Debug APK: `build/holo-debug.apk` (250,223,794 bytes; SHA-256 `FFBFB6814DDF661DB214E72B560731E9CBE8D4D30AA2F1910600A3CFE9C5DDFA`; debug-signed, API37 launch verified).
- Test AAB: `build/ci-local-check.aab` (86,248,046 bytes; SHA-256 `5A611E84AB2A00D087E05F10A327F78FEFC27E58EFD5855DDD2117552D43B154`; required entries present, unsigned and not uploadable to Play).
- Package ID: `com.rhstudio.holotactics` (user-confirmed; Play Console availability still needs checking).
- Export preset: `Android Debug APK`; minimum API 29, target API 36. `Android Play AAB` uses Gradle with the same API levels.
- The APK is debug-signed. It is for device smoke tests, not Google Play upload.

## Release AAB export

`scripts/export_android_aab.ps1` installs the Godot Android Gradle template, exports `build/holo-release.aab`, and verifies its JAR signature. Provide a publisher-owned release key through the process environment variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` (key alias), and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. The script does not print their values. Never commit the key or password.

The application ID is now set to `com.rhstudio.holotactics`. The debug APK installs and launches under this ID on the API37 AVD. Existing installs under the previous sample ID `com.example.holotactics` are a separate Android app and will not update in place.

## Device smoke test

On Windows, `run_android_emulator_test.bat` starts the configured `MaDangStage6_API37` AVD when available (otherwise the first configured AVD), waits for Android boot, then installs `build/holo-debug.apk` and launches the app. Export the `Android Debug APK` preset first if the ignored build artifact is absent.

Use a physical Android 10+ device with USB debugging enabled. Record device model, Android version, display size, and Godot build with the result.

```powershell
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adbPath devices -l
$deviceSerial = Read-Host 'Enter the Galaxy S25 Ultra serial from adb devices'
& $adbPath -s $deviceSerial shell getprop ro.build.version.release
& $adbPath -s $deviceSerial shell getprop ro.product.model
& $adbPath -s $deviceSerial install -r .\build\holo-debug.apk
& $adbPath -s $deviceSerial logcat -c
& $adbPath -s $deviceSerial shell monkey -p com.rhstudio.holotactics 1
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
& $adbPath -s $deviceSerial logcat -d | Select-String 'Godot|AndroidRuntime|FATAL EXCEPTION'
```

## Frame-rate measurement

Measure on at least one representative lower-tier Android 10+ device and one current mid-range device. Connect Godot's remote profiler for the engine frame time; use Android system frame stats as a cross-check:

```powershell
& $adbPath -s $deviceSerial shell dumpsys gfxinfo com.rhstudio.holotactics reset
# Play the named scenario for at least 60 seconds, including combat and effects.
& $adbPath -s $deviceSerial shell dumpsys gfxinfo com.rhstudio.holotactics framestats | Tee-Object -FilePath .\build\device-gfxinfo.txt
```

Record scenario, device, room temperature/power mode, run duration, average and 95th-percentile frame time, worst sustained interval, and profiler CPU/GPU frame times. Compare normal combat against a high-load wave with multiple units, facilities, and effects. Acceptance targets from the project brief are 60 FPS in normal combat (16.67 ms/frame) and at least 30 FPS under high load (33.33 ms/frame). Do not infer engine FPS from a single `dumpsys` summary.

The debug APK also prints a Godot frame sample every 10 seconds during unpaused preparation/combat: `[PERF] stage=... frames=... avg_fps=... p50_ms=... p95_ms=... max_ms=...`. Capture it from a connected device after the play session:

```powershell
# Play the scenario for at least 60 seconds, then:
& $adbPath -s $deviceSerial logcat -d -v time | Select-String '\[PERF\]|Godot|AndroidRuntime|FATAL EXCEPTION' | Tee-Object -FilePath .\build\device-perf.txt
```

These samples come from Godot's debug `_process` delta; use the Remote Profiler/device GPU profiler for CPU/GPU attribution. Do not use emulator measurements for physical-device acceptance.

After the S25 Ultra run, send `build/device-perf.txt`, `build/device-gfxinfo.txt`, the Android version/model printed above, and the pass/fail notes for the exercised flows. If more than one Android device is listed, keep using the same `$deviceSerial` so the AVD does not receive the commands.

## Google Play private test readiness

- The debug APK and its debug certificate are not a release upload.
- User confirmed application ID `com.rhstudio.holotactics`; Play Console availability, release/upload keystore, and Play Console access have not been verified or provided. Never put signing credentials in this repository.
- Before private testing, verify the ID is available in the publisher's Play Console, configure a protected release signing credential outside Git, export and verify a signed release AAB, then upload through the authorized Play Console account. Store listing, privacy declarations, and tester access still need publisher-owned information.
- Korean listing copy, draft icon/feature graphic, compliant 2:1 AVD screenshots and account-owner checklist are in `PLAY_PRIVATE_TEST_PREPARATION.md`; replace/confirm the emulator captures on physical hardware before submission.

## Current verification state

The user-confirmed ID is `com.rhstudio.holotactics`. Current Godot tests/content validation and GitHub Actions Godot+AAB jobs pass. The debug APK is debug-signed and installed on API37 AVD. Earlier API37.2 runs produced black captures after scene changes while emulator graphics services crashed; after reconnecting the AVD and setting 1080×2160, the current app entered M1 from campaign, accepted unit placement, and rendered the active wave. Treat AVD scene-transition behavior as intermittent until physical testing; this is not S25 validation or FPS evidence. API29 AVD Vulkan presentation still fails, and the SDK lacks an Android 36 system image. Galaxy S25 Ultra install/startup is user-confirmed, but physical combat/FPS and Android 10 hardware remain unverified. The current test AAB is unsigned; publisher signing and Play Console access are still missing.


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

## API29 compatibility-renderer probe (2026-11-12)

A temporary APK exported with Godot Compatibility/OpenGL was installed on the API29 AVD. It selected `opengl3` but failed EGL startup (`_start_success`) on the GL thread and returned to the launcher. The project config was restored; the normal Android preset remains Mobile/Vulkan. Thus both Vulkan and Compatibility fail on this AVD. This does not establish behavior on physical Android 10 devices.

## Current export revalidation (2026-11-12)

Re-exported with the restored Mobile/Vulkan Android renderer after the temporary API29 Compatibility probe. APK v2 signature verification and AAB ZIP structure (`BundleConfig.pb`, base manifest, dex) pass. API29/API37 AVDs were offline at this check, so there is no fresh installation/render smoke result for these exact artifact hashes.
- Fresh API37 smoke for the current official APK hash `E0B817428BEC235CEAC51950794658D88C92FA42E7AC89494C3F2C46A6D033EC` (2026-11-12): after ADB server restart and cold-start delay, campaign menu and M1 defense board rendered; tapped M1 and confirmed the board, unit sprites, core HUD, and controls. No script, Vulkan-present, or fatal exception was logged during the short smoke. This is emulator-only.

## Latest AVD reconnection and recheck (2026-11-12)

- Located ADB under `%LOCALAPPDATA%\Android\Sdk\platform-tools`; `adb reconnect offline` brought `MaDang_API29` (Android 10/API 29) and `MaDangStage6_API37` (Android 17/API 37) online.
- Installed the exact APK SHA-256 above on both AVDs. API 37 resumed the Godot launcher and rendered the campaign menu; Vulkan initialized on SwiftShader. Current ADB touch injection did not change the menu, so this pass did not reconfirm M1 entry.
- API 29 resumed the activity but repeatedly logged `Couldn't present to Vulkan queue (VkResult error 5)`. No physical Android device was attached; API 29 support and FPS acceptance remain unverified.

## API 29 에뮬레이터 추가 격리 검사 (2026-11-12)

- Android Emulator를 37.1.11에서 37.2.13으로 갱신하고, Android 10/API 29 Google Play 시스템 이미지의 임시 AVD에서도 현재 Mobile/Vulkan APK를 실행했다. 앱 Activity는 시작했지만 SwiftShader Vulkan queue present error 5와 검은 프레임이 재현됐다.
- 같은 AVD에서 임시 Compatibility/OpenGL APK는 GLES 2 컨텍스트 생성 실패로 GL thread가 종료됐다. 기존 API29 Google APIs AVD에서도 Vulkan 오류가 최신 Emulator와 host GPU 설정에서 재현됐다.
- 따라서 검사한 두 API29 AVD 구성에서는 두 렌더러 경로 모두 동작하지 않았다. 이는 Android 10 실기기 호환 실패를 뜻하지 않는다. 임시 Google Play 이미지와 AVD는 검사 후 제거했고, 기존 AVD 데이터는 유지했다. Emulator 37.2.13은 유지.
- 기기: API29 Vulkan 렌더링, Android 10 실기기 호환성, FPS는 검증 대기.

## Latest API37 fresh install smoke (2026-11-12)

- Started `MaDangStage6_API37` on Emulator 37.2.13/API 37, installed `build/holo-debug.apk` (249,834,691 bytes, exported 2026-11-12 20:58 KST), and launched `com.example.holotactics`.
- Vulkan initialized on Goldfish GFXStream/SwiftShader. The campaign menu rendered in the captured 1080x2400 frame; no Godot script or AndroidRuntime error appeared in the captured log window.
- ADB tap injection did not navigate into M1, so this smoke verifies launch/menu only, not combat. This API37 result does not establish Android 10 compatibility or FPS acceptance.

## API37 M1 touch gameplay smoke (2026-11-12)

- After correcting for the screenshot viewer's downscaled coordinates, ADB touch entered M1 and deployed a swordsman on the board. On Emulator 37.2.13/API37, HUD resource changed 160→110 after the 50-cost deployment.
- Started wave 1; the game changed to combat state, enemies moved into the defense area, and core HP changed 300→280 after an enemy attack. Battle board, sprites, core HUD, build controls, and combat controls rendered in the 1080x2400 capture (`build/mvp-followup-api37-wave.png`, ignored artifact).
- This is a short SwiftShader AVD gameplay smoke. It does not verify full stage completion, Android 10 physical compatibility, or FPS targets.
- Exact installed APK SHA-256: `E0B817428BEC235CEAC51950794658D88C92FA42E7AC89494C3F2C46A6D033EC`.

## API37 Android checkpoint relaunch reproduction (2026-11-12)

- On the current installed APK (SHA-256 `E0B817428BEC235CEAC51950794658D88C92FA42E7AC89494C3F2C46A6D033EC`), entered M1, deployed a swordsman (combat resource 160→110), and started wave 1.
- Direct `run-as` inspection confirmed `files/battle_checkpoint.json` existed. It contained stage M1, wave 1, phase `preparation` (the deliberate pre-wave checkpoint), core HP 300, combat resource 110, and the deployed unit.
- Force-stopped and relaunched the app. The new process reopened M1 with the same deployed unit and active enemies (`build/mvp-repro-restart3.png`, ignored local capture), confirming automatic route-to-checkpoint and resume. The unattended test battle then reached core HP 0, showed the defeat result, left permanent currency at 115, and removed the settled checkpoint as expected. This is a restart/resume and defeat-settlement smoke, not a victory test.
- SwiftShader profiler windows during this battle: average 25.2 / 24.5 / 23.7 / 24.4 FPS; p95 frame time 43.45 / 43.75 / 45.68 / 42.80 ms. These AVD values miss targets and are not representative hardware measurements; physical-device acceptance remains open.

## API37 M1 victory repeat smoke (2026-11-12)

Installed updated APK on `MaDangStage6_API37`, replayed the two-wave M1 defense, and confirmed the victory panel now reports 2/2 waves with repeat reward +10. Updated artifact hashes and signature/AAB validation are in `TEST_REPORT.md`. This does not replace physical-device Android 10 or FPS validation.

## Facility upgrades and updated Android artifacts (2026-11-13)

User selected facility upgrades during both preparation and combat. The latest APK/AAB hashes, content/upgrade SEEDs, regression coverage, and export checks are recorded in `TEST_REPORT.md`. API37 AVD launch/menu smoke passed; touch entry to M1 was not reproduced. This is not physical-device or FPS acceptance.

## Latest physical-device note (2026-11-13)

The user confirmed the refreshed APK downloaded, installed, and launched on Galaxy S25 Ultra. This supersedes prior notes that the device install result was unknown, but is not a gameplay or performance measurement. Run the numbered device smoke flows above and record Android version and frame-profiler results before treating M6 device acceptance as complete.

## Latest current-APK API37 M1 smoke (2026-11-13)

- Reconnected the existing API37 x86_64 phone AVD (1080×2400, density 420); the current debug APK opened the campaign, entered M1, placed one swordsman (resource 160→110), and began wave 1. Enemies rendered and core HP fell 300→240.
- Six in-game sampler windows measured 18.1–23.8 average FPS, P95 54.40–99.63 ms, max 73.34–138.45 ms on `ro.hardware.egl=emulation`. These values are below the 60 FPS normal / 30 FPS high-load targets and are not physical-device evidence. Use S25 Ultra and representative lower-tier hardware logs for acceptance.
- The ADB error scan returned no fatal exception, Godot script error, or Vulkan/renderer error in the inspected log buffer. This was only a short wave-1 smoke.

## A/B renderer measurement (2026-11-13)

- The current debug APK contains a board refresh optimization. Against the prior-commit APK on the same API37 x86_64 AVD and matched three-unit/two-wave M1 scenario, five 10-second windows averaged 52.66 FPS (mean P95 22.08ms, mean max 38.07ms), versus baseline 23.7 FPS (57.13ms, 79.21ms). Both runs won 2/2 waves.
- This is a relative improvement signal on emulated EGL, not an FPS acceptance pass; the 60 FPS ordinary-combat goal remains unmet/unverified on representative physical hardware. User Galaxy S25 Ultra combat logs are pending. Android 10 physical compatibility, signing, and Closed testing also remain open.
