# Session handoff checkpoint (2026-11-13)

The user requested that the current work be completed and documented, then paused. Keep the original M0–M6 objective intact; this checkpoint does not mean MVP completion.

## Repository and validation state

- Repository: `master`, latest work commit at checkpoint `71ccf9a` (`Record Android 10 emulator renderer recheck`), pushed to `origin/master`.
- Latest Actions run: [43371542368](https://github.com/rkwkkh/holo-tactics/actions/runs/43371542368), both Godot and Android AAB jobs succeeded. The AAB is an unsigned CI artifact, not a Play upload.
- Worktree was clean before this checkpoint documentation edit. Do not repeat the full suite unless source changes: `run_godot_tests.bat` passed on Godot 4.7.2 (core, content validation 0 errors, 8-stage seeded campaign simulation, editor preview isolation, result UI, and editor panels). Editor-headless shutdown prints RID/ObjectDB cleanup warnings after success; exit code is 0.
- Latest debug APK: ignored local file `build/holo-debug.apk`, 250,223,794 bytes, SHA-256 `FFBFB6814DDF661DB214E72B560731E9CBE8D4D30AA2F1910600A3CFE9C5DDFA`, debug-signed, package `com.rhstudio.holotactics`, min API 29 / target API 36. It is not a release APK.

## Recent work and evidence

- Commit `acbf984` optimizes `scripts/battle_view.gd` board refresh by indexing obstacle/wall occupancy once and applying sprites by entity passes. The matched API37 emulated-EGL M1 A/B (three allies, two waves) improved mean FPS from 23.7 to 52.66 and mean P95 from 57.13ms to 22.08ms; both builds won 2/2 waves. The result remains below the 60 FPS goal and is not physical-device acceptance. Exact setup and hashes are in `TEST_REPORT.md`.
- Commit `71ccf9a` records the latest API29 `MaDang_API29` AVD check: install/process startup succeeds, but screen stays black and logcat reports Vulkan queue present error 5. This reproduces an emulator issue only; do not infer physical Android 10 incompatibility or alter production renderer settings based on this alone.
- API37 AVD combat and campaign navigation were previously demonstrated; emulator frame rates varied, so use controlled A/B only as a relative diagnostic.
- M0–M4 implementation and automated campaign playability checks are recorded in `PROGRESS.md`. M5 has three editor panels, validator-gated persistence, and headless regression. Panel/dock/Inspector visible smoke is recorded; visible Error/Warning focus-navigation usability remains unverified.

## Decisions and external limits

- User-selected rules already captured in `ISSUES.md`/`DECISIONS.md`: progressive story unit unlocks; defense continues while the core survives; one fixed evolution choice; repair and facility upgrades allowed during combat and preparation; DoT consumes shield before mitigation; freeze/stun use the longer remaining duration; siege advance starts combat plus automatic advance, with individual move orders only.
- User confirmed Galaxy S25 Ultra APK install/launch, and said they will perform M1/combat/FPS checks and provide logs. No physical-device logs have arrived. User reports no Play Console access and no publisher upload key.
- No credentials were created or shared. No GitHub Release, APK release, Play upload, or Closed test was made.

## Ordered resume actions

1. Check `git status`, `git log`, and the latest Actions run. If it is still `71ccf9a`, the two CI jobs above passed.
2. Ask for/use the user's Galaxy S25 Ultra Android version, gameplay results, and `ANDROID_TESTING.md` profiler/logcat files. Verify regular combat and high-load FPS/P95, touch/safe-area, battle abandon/reward, and checkpoint flows from that evidence.
3. Verify Android 10 compatibility on a physical device or a known-good Vulkan-capable API29 setup; the current API29 AVD black screen is inconclusive for physical hardware.
4. Finish remaining M5 visual checks: click the Warning row after selecting another record and verify it does not switch; interact with Inspector field controls. Error-row navigation and Warning rendering are now visually confirmed; Warning non-navigation remains headless-only.
5. Resume Closed-test preparation only after owner access and publisher signing setup are available. Verify package ID availability, prepare a signed AAB and final approved listing/privacy/contact/tester materials, then upload with the authorized account. Never ask for secret key material in chat.
6. Update `TEST_REPORT.md`, `ISSUES.md`, and `PROGRESS.md` with evidence; run relevant checks, commit and push. Do not claim M6/MVP complete until physical performance/compatibility and Closed-test gates are proven.
