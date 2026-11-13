# Session handoff (2026-11-13)

Continue the active Godot MVP objective; this is not an MVP completion record.

## Current repository state

- Branch `master`, current preceding commit `40330c4` (`Record current development pause checkpoint`), pushed. Worktree is clean after this GUI verification and automatic Godot config rewrite was restored.
- Latest Actions evidence before this documentation update: run [43377880342](https://github.com/rkwkkh/holo-tactics/actions/runs/43377880342), both Godot and Android AAB jobs passed.
- Do not repeat full regression without source changes; `run_godot_tests.bat` passed on Godot 4.7.2, with 0 content validation errors, all eight campaign simulations, preview isolation, result UI, and editor panel checks.

## Latest M5 result

- Visible stage/evolution/upgrade tabs, invalid-save blocking, Error-field focus, and Warning presentation were already verified.
- This continuation verified Inspector dynamic field display and edit/import synchronization using a temporary reversible `start_resource` value. Restored 160 and closed with “저장하지 않음”. No catalog save occurred.
- Remaining M5 GUI check: visually click a Warning row after another record is active. The signal behavior is already covered by `tests/editor_panels.gd`.
- Godot rewrote `project.godot` on launch; restored only that generated diff. Confirmed catalog and main scene clean and no Godot process remains.

## M6 open gates and next work

1. User will perform Galaxy S25 Ultra gameplay/FPS testing and provide logs. Review using `ANDROID_TESTING.md` for normal/high-load performance, touch/safe area, abandon/reward, and checkpoint behavior.
2. Verify Android 10 on physical hardware or a known-good API29 Vulkan setup. Existing API29 AVD black screen/present error 5 is inconclusive; do not change production renderer on that evidence alone.
3. Finish the M5 Warning-row visual check if practical.
4. Closed testing requires owner Play Console access, publisher signing, package availability, and final listing/tester materials. User previously said Console and upload key are not available. No secret should be requested in chat.
5. Current emulated renderer A/B improved mean FPS 23.7→52.66 but remains below the 60 FPS target and is not representative-device acceptance. Keep M6/MVP incomplete until hardware and Closed-test gates have evidence.

No release APK, GitHub Release, Play upload, or Closed test has been created. After any source change, run relevant tests, update evidence docs, commit/push, and inspect the CI run.

## Resume after API29 diagnostic (2026-11-13)

- Latest committed source remains `be29ac6`; docs now record Inspector GUI check. CI run [43379150514](https://github.com/rkwkkh/holo-tactics/actions/runs/43379150514) passed both jobs.
- New API29 evidence: `MaDang_API29` booted with SwiftShader, installed/started the app, but screenshot is black and emulator warns Vulkan unsupported. Treat as AVD limitation; physical Android 10 remains unverified.
- The AVD was stopped after capture. No game source/settings or catalog changed; only documentation is pending commit.
- Continue with remaining M5 Warning-row visual check if useful, then wait for user-provided S25 Ultra logs and owner Play Console/publisher signing access. Keep M6 incomplete.
