# Session handoff (2026-11-16)

Continue the active M0–M6 Godot Android MVP objective. The current project is not complete: real-device/FPS and Closed-test owner gates remain.

## Current repository and validation

- `master` HEAD is `9b9ea4f` (`Record API37 M2 and M3 campaign validation`), pushed to `origin/master`; worktree is clean.
- GitHub Actions run [43785020191](https://github.com/rkwkkh/holo-tactics/actions/runs/43785020191) passed Godot validation and Android AAB export/structure verification for `9b9ea4f`.
- On 2026-11-16, local `run_godot_tests.bat` passed all suites on Godot 4.7.2: core, content validation, 8/8 campaign simulations, preview isolation, result UI, and editor panels. The panel test reported its pass sentinel; Godot emitted known RID/ObjectDB cleanup diagnostics afterward, but the batch exited 0.
- API37 emulator continuation cleared M2 3/3 (+43), M3 3/3 (+47), M4 4/4 (+51), M5 4/4 (+56), and M6 4/4 (+64); saved progress contains all six main stages and permanent currency 421. M3 and M5/M6 `진격` auto-advance were observed. M4/M5/M6 unlock progression was confirmed on screen. See `TEST_REPORT.md` and `ANDROID_TESTING.md`.
- Clean clone of source commit `64632e2` passed `run_godot_tests.bat` from a checkout without `.godot` cache. The batch performs an initial editor import; all suites passed, content errors 0, campaign simulations 8/8.
- No gameplay source changed in this continuation. API37 AVD is connected as `emulator-5554`; the app is back at the village after M6. No physical Android device is connected. The latest local debug APK is test-only and ignored by Git.

## Latest M5 check

- Retried visual Warning-row selection on 2026-11-16. Godot editor and content dock opened, but refreshed UI coordinates were mapped onto `Memoit.exe` by the Windows UI bridge. No click, JSON edit, or save was performed; the Warning-row visual test remains unverified. Headless Error/Warning routing still passes.
- A later Computer Use retry listed the Godot editor but failed twice to activate its window; no UI input was sent. The Warning-row visual test remains unverified.
- Godot rewrote `project.godot` on open. Restored that generated-only rewrite and verified the committed `renderer/rendering_method.mobile="mobile"`; catalog and scenes are untouched.

## Remaining gates and resume actions

1. Wait for the user's Galaxy S25 Ultra gameplay/FPS logs and inspect `ANDROID_TESTING.md` results.
2. Verify Android 10 on physical hardware; API29 AVD black Vulkan output is not hardware evidence.
3. Closed testing still needs owner Play Console access, a publisher upload key, app-ID availability, approved developer/contact details, public privacy-policy URL, in-app policy link, final Data safety answers, listing content, and testers.
4. Physical Android performance targets remain unverified; prior API37 AVD M1 measurements were below 60 FPS and do not establish device acceptance.
5. Retry the M5 Warning-row visual click only when the UI bridge can reliably target the Godot window. No need to rerun the full suite unless source changes.

GitHub pre-release `v0.1.0-preview.1` exists with an older debug APK uploaded 2026-11-12 (SHA-256 `6823ca453156ed7ab8b157c2c4ae65fbe6c98c6c89e3c29f9bc132356a4a5cb2`). It was not updated in this continuation; local tested APK hash is `C55E2E73AE38C043CCE052DEEE24E2931176812FC7E2648AD7C0B542911F54F7`. No signed Play AAB, Play upload, or Closed test has been completed. Keep the M6/MVP goal active and incomplete.

---
# Historical handoff notes through 2026-11-13

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
- The AVD was stopped after capture. No game source/settings or catalog changed. The diagnostic was committed as `f394684` and CI run [43379665892](https://github.com/rkwkkh/holo-tactics/actions/runs/43379665892) passed both jobs.
- Continue with remaining M5 Warning-row visual check if useful, then wait for user-provided S25 Ultra logs and owner Play Console/publisher signing access. Keep M6 incomplete.


## Latest local verification (2026-11-13)

The Warning-row visual click attempt failed because the native Godot window could not be activated through Computer Use. The application was closed afterward; generated-only `project.godot` changes were restored and the worktree is clean. Full `run_godot_tests.bat` passed, including the Error/Warning signal regression and 0-error content validation. Resume with physical-device evidence and account-dependent Closed-test gates; M6 stays incomplete.

## Latest test coverage update (2026-11-13)

`tests/editor_panels.gd` now covers Inspector dynamic field edit/import plus catalog non-persistence. Both standalone panel run and full Godot batch passed on 4.7.2. GUI Warning-row click remains unverified; actual signal behavior is headless-tested. Device list currently has no connected Android target, so user-provided S25 Ultra logs remain pending.

## Current M6 gate check (2026-11-13)

No Android device is attached to ADB. A local release-mode APK export preflight was attempted but could not sign without an owner release keystore; no artifact was produced. Keep the debug APK/AAB labeled test-only. Remaining final acceptance requires Galaxy S25 Ultra logs, physical Android 10 evidence, and owner Play Console/release signing access.

## Play policy update (2026-11-13)

Before the owner sets up Console, note the current target API 36 requirement (already configured) and the conditional 12 testers/14 consecutive days requirement for post-2023-11-13 personal accounts applying for production access. It is not a gate to begin the MVP Closed test. Verify account type and creation date with owner access; sources are in `PLAY_PRIVATE_TEST_PREPARATION.md`.

## Closed-test policy/data handling checkpoint (2026-11-13)

- Current build preflight: no manifest permissions, no project network/ads/analytics SDK integration found, local progress/checkpoint `user://` storage. This is preliminary; recheck final signed AAB and SDK behavior before Data safety declaration.
- Play Closed testing requires Data safety plus a public privacy policy URL and policy text/link in-app even if no personal/sensitive data is collected. Draft at `PRIVACY_POLICY_DRAFT.md`; app in-app link/text remains unimplemented.
- Await owner developer/display name, public contact email, and final policy/hosting URL. App account type and creation date remain owner-only checks for conditional production-access tester policy.

## Current pause checkpoint (2026-11-13)

- Android Debug APK and Play AAB export presets now exclude `store_assets/**` and `tools/**`. This prevents draft store images and the asset-generation script from shipping with the game.
- Latest local regression: `run_godot_tests.bat` passed on Godot 4.7.2; content validation had 0 errors. `build/holo-debug.apk` was re-exported; `apksigner` verified its v2 debug signature, `aapt` confirmed package/min/target SDK metadata, and the APK sparse PCK was scanned for store-draft/tool markers (none found).
- Export completion was printed and the APK written, but the Godot console process did not exit by itself; it was interrupted after the artifact checks. Treat the artifact checks as successful and the process exit code as interrupted.
- The export/config + documentation update is committed and pushed as `14d43aa` (`Exclude store drafts from Android exports`); worktree was clean. GitHub Actions run [43385072374](https://github.com/rkwkkh/holo-tactics/actions/runs/43385072374) passed both Godot validation and Android AAB export/structure verification.
- Still open: Galaxy S25 Ultra gameplay/FPS logs; physical Android 10; GUI Warning-row click; final owner-approved privacy policy/in-app link; release signing and Play Console access. M6/MVP remains incomplete. A preview GitHub release exists; its APK is not the newer local debug APK. No signed Play AAB or Play upload was made.

## Manual test launcher update (2026-11-13)

- Use `run_godot_game.bat` to start the visible Windows game; it locates the Godot 4.7.2 GUI binary and opens the project main scene. `run_godot_tests.bat` is still the separate headless automated suite.
- Use `run_android_emulator_test.bat` to start the preferred `MaDangStage6_API37` AVD, install the local debug APK, and launch the game. This path was run successfully; the AVD showed the campaign screen. Keep using `ANDROID_TESTING.md` for the user gameplay/FPS checklist.
- Launchers are validated for startup only, not full gameplay or hardware acceptance. The Android shell invocation produced harmless stdin-redirection notices despite successful install/launch.
## Source portability audit (2026-11-13)

- README now documents fresh checkout, Windows game/test launchers, Android SDK/JDK prerequisites, build template install/export, and the confirmed package ID.
- `run_godot_tests.bat` now imports the project before tests so a new checkout registers global GDScript classes. `tests/results_view.gd` now uses SceneTree metadata and isolated in-memory completion state instead of relying on the local save.
- The current checkout full suite passes after these changes. Before calling the source snapshot ready, rerun the same test batch in a newly cloned `master` checkout and verify CI. Do not add generated `.godot/`, `android/`, or `build/` artifacts.
## Full source push verification (2026-11-13)

- README now includes clean-checkout and Android setup, and the stale placeholder package ID text is corrected.
- Commit `64632e2` includes the fresh-checkout test initialization and deterministic result-view test. A new clone of pushed `master` (without `.godot` cache) passed `run_godot_tests.bat` with exit code 0.
- CI run [43398664085](https://github.com/rkwkkh/holo-tactics/actions/runs/43398664085) passed Godot validation and Android AAB export/structure checks. Android template/cache and local APK/AAB artifacts remain intentionally untracked and are regenerated from the committed presets.
