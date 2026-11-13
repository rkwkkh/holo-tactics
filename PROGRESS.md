# Progress

## 환경

- 저장소 시작 상태: `master`, 초기 커밋 `992e251`; 게임 소스 없음. 기획 원본 4종은 시작 시 Git 미추적 상태였고 변경하지 않는다.
- Godot `4.7.2-stable` 발견: `%LOCALAPPDATA%/Programs/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- Android Studio/SDK 발견: `%LOCALAPPDATA%/Android/Sdk`; 설치된 플랫폼 API 35/36/37.0, 빌드 도구 35.0.0/35.0.1/36.0.0/36.1.0. Java 17 발견.
- Godot 사용자 설정에 JDK 17/Android SDK 경로가 이미 연결되어 있고, Android 4.7.2 내보내기 템플릿도 설치됨. Godot/adb는 PATH에 없으므로 로컬 명령에서 전체 경로 사용.
- 2026-11-12 재확인: SDK 내 ADB로 API29/API37 AVD offline 상태를 재연결. Windows 로컬 Godot 콘솔 test/export 실행 뒤 오래된 headless 프로세스 49개를 확인·종료했고, 동기 테스트와 콘텐츠 validator는 `--quit-after 2` 실행 뒤 잔류 프로세스가 없음을 확인.
- Android API 29 및 37 AVD 확인. 최신 Android 모바일 렌더러는 Vulkan이다. API 37 AVD에서 메뉴/M1 보드 및 두 유닛 배치/자원 차감을 화면으로 확인했다. API 29 AVD는 Vulkan present error 5로 렌더링 실패. Android 실기기/FPS, GitHub 원격 및 Actions hosted run 권한은 확인하지 않음.

## 마일스톤

- [x] M0: Godot 프로젝트 골격, 안정 ID/참조/버전 검증기, headless 테스트, GitHub Actions 검증 작성. 엔진 검증 결과는 `TEST_REPORT.md` 참조.
- [x] M1: completed. API37 AVD manual M1 defense reached deployment and combat; unit loss while core survived continued the stage, core HP 0 produced defeat/partial reward. Unit movement, attack, wave/intermission, checkpoint and reward invariants pass headless regression. Evidence: `TEST_REPORT.md` M1/API37 entries.
- [x] M2: completed. Siege/defense outcomes, A*/FSM+Utility AI, reinforcements and safe termination, walls/obstacles, four facilities, repair, status effects and checkpoint restore are covered by core/integration tests; all campaign stages simulate to victory. Repair cost remains a documented SEED.
- [x] M3: completed. Five ally/six enemy kinds, 20 unit upgrades plus four facility upgrades, six fixed evolutions, 10 skills, four village buildings, research unlocks and persistent battle effects are implemented and covered by regression tests.
- [x] M4: completed. Main 6 + optional 2 stages and 26 waves are wired through story locks, rewards and progress persistence; `tests/campaign_playability.gd` wins all 8 stages and checks idempotent rewards/unlocks. Content balance remains SEED; a full manual playthrough is still useful QA.
- [x] M5: three EditorPlugin tabs, Inspector resource sync, validator-gated atomic saves, error navigation, and isolated full-stage/direct-wave preview are implemented and automated. GUI smoke confirms named dock, all three populated panels, Inspector properties, and full-stage launch; direct-wave isolation test passes.
- [ ] M6: local tests and Mobile/Vulkan Android exports pass; confirmed package `com.rhstudio.holotactics` APK installs/launches on API37 AVD. Corrected GitHub Actions run `43351099459` passed Godot checks and uploaded an unsigned debug AAB artifact. AVD basic combat measured 33.9–34.8 FPS, below the regular 60 FPS target and not representative-device evidence. API29 AVD renderer failure, physical Android/FPS, publisher signing, Play Console ID availability, and private-test setup remain open.

재검증 (2026-11-12): Godot 4.7.2 headless import/테스트/콘텐츠 검사/메인 씬 통과. APK 재생성 통과. API 29 AVD는 GLES2 한계로 Godot Android 렌더 컨텍스트 생성에 실패했고, API 37 AVD에서는 앱 프로세스가 실행됐으나 GLES3 셰이더 uniform 한도 오류 로그가 있어 시각 스모크 테스트는 미통과/미확정이다. 세부 결과는 `TEST_REPORT.md`.

재검증 (2026-11-12): 5/6종 유닛을 카탈로그 검증, 실제 배치·전투 대상으로 확장했다. 상세는 `TEST_REPORT.md`. 당시 OPEN이던 M1 승패 정책과 시설 수리 시점은 이후 사용자 결정 및 구현으로 해결됐다. 실기기 확인은 미완료다.

재검증 (2026-11-12): stage.available_units를 배치 UI·전투 모델·validator에서 공통으로 사용한다. M1은 검사/궁수, M2는 창병까지 허용한다. headless 전체 테스트와 APK export 통과; 실기기 화면 검증은 미완료다.

M3 기본 스킬 진행 (2026-11-12): 다섯 기본 아군마다 자동 1개·수동 1개를 등록했다. 효과 디스패치(단일 공격/범위 공격/치유/보호막), 고정 모드, 수동 선택 유닛 버튼, 개별 쿨타임, 자원 부족/유효 대상 없음 시 발동 실패와 무차감, 재정비 중 쿨타임 정지 및 체크포인트 저장 검증을 구현했다. 각 스킬의 명칭·효과 수치·쿨타임·비용은 임시 SEED이며 제품 밸런스 확정이 아니다. 당시 미구현이던 진화 스킬은 이후 사용자 결정 및 M3 후속 구현으로 완료됐다.

해금 정책 확인 (2026-11-12): 사용자가 기본 5종의 단계별 스토리 해금을 선택했다. 현재 stage별 제한을 유지하고 캠페인 콘텐츠에서 순서대로 연결한다.

마을 최소 기능 (2026-11-12): 본부 자동 배치 및 훈련소/공방/마법 연구소 배치, 재화 차감, 선행 클리어 잠금, 배치 이동/보관 모델과 6x6 간단 화면을 추가했다. 이전 저장의 본부 마이그레이션과 손상 저장 보호를 검증했다. 시작 영구 재화 100, 건물 비용 75/100은 배치 테스트를 위한 임시 SEED다. Godot headless 전체 테스트, 콘텐츠 validator, 마을 씬 로드 및 `git diff --check` 통과. M3/M4 완료는 아니며 건물 효과·연구 UI는 미구현이다.

영구 기본 연구 (2026-11-12): 5종 아군별 공격력 연구를 추가했다. 건물 활성 여부, 요구 스테이지 완료, 재화, 중복 구매 여부를 검사하고 영구 저장한다. 전투 배치와 체크포인트에 연구 ID/효과를 연결했다. 연구 가격·증가량은 SEED이며 모든 연구와 새 화면의 headless 테스트·콘텐츠 검증을 통과했다. 진화 연구는 아직 없다.

결과 이후 흐름 정합화 (2026-11-12): 승리·패배·명시적 포기 종료 후 “마을로 돌아가기” 버튼이 캠페인 화면을 열던 경로를 문서 흐름에 맞춰 마을 씬으로 변경했다. 전용 결과 패널은 별도 구현 항목으로 남긴다.

M5 편집기 진행 (2026-11-12): `addons/content_editor`의 세 탭에 검증 후 원자 저장과 전체 스테이지/선택 웨이브 미리보기 버튼을 구현했다. 미리보기 ID별 체크포인트를 사용하고 결과 정산을 막는다. 통합 테스트에서 2번째 웨이브 시작, 요청 프로필 소비, 체크포인트 격리 및 영구 진행 바이트 불변을 확인했다. 편집기 GUI 상호작용/시각 검증은 남아 있다.

공성 전진 및 M4 수직 시뮬레이션 (2026-11-12): 아군 이동 명령/저장 복원이 y≥5에 갇혀 공성 적 진영을 공격할 수 없던 제한을 제거하고 A* 도달 불가 목적지를 거부하도록 수정했다. 회귀 테스트가 y<5 명령 허용, 불가능 경로 거부, 체크포인트 복원을 확인한다. M4의 간단 기본 유닛 전술 실패를 바탕으로 시드 시작 자원을 220→260으로 올렸다. 검사/궁수/창병+핵심 앞 화살탑의 M4 4웨이브 전투가 수동 스킬/강화 없이 승리함을 `tests/run.gd`에 고정했다. 전체 플레이 밸런스는 계속 검증해야 한다.

M4 정산 기반 진행 (2026-11-12): 영구 진행 저장을 결과 처리에 연결했다. 승리 시 반복 보상과 최초 클리어 추가 보너스를 적용하고, 패배/명시적 포기는 완료 웨이브 수로만 부분 보상한다. 실행 ID를 체크포인트에 보존해 재개 시 같은 플레이의 보상이 중복되지 않게 하고, 저장 성공 전에는 전투 체크포인트를 지우지 않는다. 보상 수치는 SEED이며 캠페인 결과/연구 경제는 미완성.

M4 결과 화면 진행 (2026-11-12): 전투 종료 시 승리/패배/포기/안전 종료, 완료 웨이브와 영구 재화 결과를 전체 화면 패널로 표시한다. 보상 저장 실패 동안 복귀 버튼을 잠그고, 안전 종료는 체크포인트 보존 안내와 복귀를 허용한다. `tests/results_view.gd`에서 승리/안전 종료/저장 실패 상태를 검증한다. GUI 렌더링은 미확인.

validator 회귀 검사 (2026-11-12): 잘못된 해금 유닛과 비정상 stage references에서 충돌 없이 Error를 반환함을 검증했다. 전체 headless 테스트 및 카탈로그 검증 통과.

M3 전투 강화 진행 (2026-11-12): 아군 5종에 확정된 강화 4개씩(총 20개)을 등록했다. 선택 유닛 버튼에서 강화별 최대 3단계 구매가 가능하고, 전투 자원을 소모한다. 기본 공격 변형, 관통/다중 대상/광역, 밀치기/반격/도발/방어, 지속 피해·빙결, 광역 치유·보호막·공격 버프·해제 효과를 연결했다. 개체 강화는 웨이브 체크포인트에 저장·복원하며 재정비 동안 유지한다. 상세 테스트·임시 밸런스는 `TEST_REPORT.md`와 `ISSUES.md`.

M4 캠페인 콘텐츠 진행 (2026-11-12): main 6개 + optional 2개를 26개 웨이브로 구성하고 스토리 선행 조건을 연결했다. 시작 메뉴는 완료한 stage ID를 기준으로 진입 버튼을 잠금/해금한다. 8개 각 stage 모델이 생성되고 첫 웨이브 초기 배치가 되는 것을 headless smoke로 검사했다. 맵·배치·자원과 보상은 설계초안 SEED이며 마을/연구/전체 밸런스는 미완료.

최종 재검증 (2026-11-12 11:04 KST): 전체 headless 테스트·콘텐츠 검증·메인/전투 씬 실행 통과. APK 86,313,754 bytes 생성 및 서명 v2/v3 검증 통과. GUI helper가 연결되지 않아 화면 검증은 미완료.

- 2026-11-12 이어하기: 기존 M0–M4 회귀 상태를 headless로 재검증했다. M5 패널에 선택 레코드 Inspector 편집/값 가져오기를 추가했고, 모델 속성 테스트가 통과했다. GUI 상호작용, 저장 UX, 오류 위치 이동은 미검증 또는 미구현이라 M5는 진행 중이다.

- 2026-11-12 M6 이어하기: 5개 주요 씬 smoke 및 현재 소스 Android Debug APK 재생성/서명(v2/v3) 통과. Editor GUI 검증은 computer-use native pipe 연결 불가로 진행되지 않았다. 실기기/성능/release AAB/Play 배포는 검증 대기이며 M6 완료가 아니다.

- 2026-11-12 M5 보강: Validator Error 목록을 클릭하면 해당 콘텐츠 레코드가 있는 도구 탭으로 이동하고, 다른 레코드로 이동할 때 미저장 JSON 초안을 보존한다. Error→ID 추출과 전역 오류/잘못된 categories 입력을 회귀 검사했다. 실제 GUI 사용과 필드별 위치는 미검증이다.
# 2026-11-12 이어서 작업

- M5 Validator 오류에 가능한 콘텐츠 ID와 필드 경로를 표시하도록 보강. 연구 데이터 검사도 `research_id.amount` 등 개별 필드로 분리하고 회귀 테스트 추가.
- 확인: Godot 4.7.2 headless 프로젝트 import, validator parse, `tests/run.gd`, `tests/editor_preview.gd`, `tests/results_view.gd`, 콘텐츠 검증 및 diff 공백 검사 통과.
- M5 편집기 GUI 상호작용 검증 및 M6 Android 실기기 검증은 여전히 미완료. 기존 Android AVD 렌더링 제한은 `ISSUES.md` 참조.

## 2026-11-12 불가침 장애물 수직 기능

- `obstacle.barricade`를 독립 카탈로그 범주로 추가하고 M2 갈림길에 보유 3/배치 2 제한을 연결했다. 모델과 UI에서 유료 최초 설치, 저장 중인 동일 개체 무료 재설치, 재정비 중 이동·회수, 전투 중 신규 설치·보관 개체 배치를 지원한다.
- 장애물은 경로 탐색과 점유 검사에 포함된다. 설치·이동은 각 웨이브 초기 출현/예정 증원의 경로를 모두 남길 때만 허용하며 실패 시 재화/상태를 변경하지 않는다. 체크포인트는 배치/보관 상태를 저장하고 복원한다.
- 데이터 계약의 이동 유형도 명시했다. 현행 11종은 모두 `ground`이고 바리케이드는 이를 차단한다. Validator는 미지원 이동 유형을 거부하며, 경로 유지 검사는 웨이브/증원 적의 유형별 차단 규칙을 적용한다.
- 검증 통과: 전체 모델 회귀, 콘텐츠 오류/한도 검사, M2 BattleView 배치·회수·재설치 UI 상태, 편집기 미리보기 격리, 결과 화면, 5개 씬 smoke 및 `git diff --check`.
- 바리케이드 비용 20, 보유 3, 동시 배치 2는 테스트용 SEED이며 승인 밸런스가 아니다.
- 최신 데이터 계약 포함 Android Debug APK 재생성 및 v2/v3 서명 검사 통과. 파일 크기/시간은 `TEST_REPORT.md`에 기록.

## 2026-11-12 Validator 입력 오류 안전성

- 시설 `damage`가 문자열인 카탈로그에서 Validator가 문자열-정수 비교로 중단되는 결함을 재현하고, 숫자 형식 검증을 통과한 경우에만 관계 검사를 수행하도록 수정했다. `damage`, `heal`, `splash_radius`, `range`, `attack_time` 문자열 오류 테스트를 추가했다.
- 전체 headless 테스트, Validator 검사, 콘텐츠 검증, 5개 씬 smoke 통과. 런타임 Validator 수정 포함 Android Debug APK 재생성 및 apksigner v2/v3 검사 통과.
- M5 GUI 확인은 Computer Use 네이티브 연결 오류로 미실행, ADB의 두 AVD는 offline. M6 실기기/FPS는 미검증으로 유지한다.

- 2026-11-12 Android export 재검증: Gradle APK/AAB 프리셋의 minimum API를 Android 10(API 29), target API 36으로 맞췄다. 최신 APK manifest와 v2 서명 확인 통과, AAB 패키징 생성 및 구조 확인 통과. AAB는 unsigned 테스트 산출물이다. release key 서명, Play 업로드, 실기기/FPS 검증은 미완료.

- 2026-11-12 재검증: 현재 커밋에서 headless editor import, 전체 모델 테스트, editor preview, results view, 8-stage 캠페인 플레이어빌리티, 콘텐츠 검증이 모두 통과했다. Android export 설정 검증 결과는 `TEST_REPORT.md` 참조.

- 2026-11-12 M6 저장 복원 안전성 수정: 거부할 체크포인트가 영구 연구/밸런스를 미리 변경하지 않도록 검증 상태를 분리했다. 잘못된 schema와 유닛 스탯 회귀 테스트 통과.

- 2026-11-12: 저장 복원 수정 소스를 포함한 Android Debug APK 재생성 완료. API 29/36 manifest와 v2 서명 확인 통과; v3 서명은 없다. 실기기/FPS와 release AAB는 여전히 검증 대기.

- 2026-11-12: 손상된 진행 저장 파일 로드 거부 시 디스크 원본과 기존 메모리 진행 데이터가 보존되는 회귀 검증을 추가했다.

- 2026-11-12: 최신 체크포인트 복원 수정이 포함된 Android Debug AAB 패키징과 필수 번들 엔트리 검증을 수행했다. 번들은 unsigned이며 release artifact가 아니다.

- GitHub Actions에 `android-aab` job을 추가했다: JDK 17/Android SDK API 36/Godot 4.7.2 export templates를 설치하고 Gradle template로 Debug AAB를 export, 필수 bundle entry를 검증한 뒤 unsigned smoke artifact를 7일 보관한다. 로컬 actionlint v1.7.12 검증 통과. 원격 Actions 실행은 저장소/권한 미확인으로 대기 중이다.

- M6 manifest 검증 추가: bundletool로 최신 Android Debug AAB 내부 manifest의 min API 29/target API 36을 직접 확인했다. AAB는 unsigned 테스트 산출물이다.

- R-GAME-005 일부 구현: 전투 화면에 1×/2× 버튼을 추가했다. 현재 스테이지 최초 클리어 전과 테스트 미리보기에서는 2×가 잠기며, 완료 stage 재진입에서만 해제된다. 고정 전투 tick은 유지하고 호출 주기와 재정비 countdown을 함께 배속한다.
- R-UI-003 조회 전용 일시정지는 아래 2026-11-12 기록에서 구현·검증 완료.

- 2026-11-12 R-UI-003 조회 전용 일시정지 구현: 전투/재정비 타이머의 남은 시간을 보존해 정지·재개하며, 일시정지 중 전투 명령 버튼을 비활성화하고 핸들러에서도 실행을 차단한다. 타일을 누르면 유닛·시설·적·핵심·장애물 정보를 표시한다. `tests/results_view.gd`로 전투 상태 불변, 핵심 조회, 양 타이머 재개를 검사했다.
- 재검증: Godot 4.7.2 headless editor import, `tests/results_view.gd`, `tests/run.gd`, `tests/editor_preview.gd`, `tests/campaign_playability.gd`, 콘텐츠 validator, `git diff --check` 통과.

- 2026-11-12: 일시정지 변경을 포함해 Android Debug APK를 다시 내보냈다 (`build/holo-debug.apk`, 249,875,578 bytes). manifest min API 29/target API 36 및 APK v2 서명 확인 통과. Debug 빌드이며 실기기 실행·FPS 검증은 미완료다.

- 2026-11-12: R-UI-003 반영 소스의 Android Debug AAB를 다시 생성했다 (`build/holo-test.aab`, 86,284,601 bytes). bundletool 1.18.3 검증과 필수 bundle/dex/manifest 항목, manifest min API 29·target API 36을 확인했다. 테스트 번들은 unsigned이며 Play 업로드용 배포본이 아니다.

- 2026-11-12 R-UI-002 진행: 선택 아군 유닛의 강화·수동 스킬을 타일 주변 플로팅 패널로 표시하고 화면 경계 안으로 위치를 보정한다. 선택 시설은 HP와 재배치 안내를 표시한다. headless UI 검사에서 표시 대상·부모 관계·화면 경계와 일시정지 조회를 확인했다. 시설 강화/수리 조작은 별도 정책/기능 미완료라 R-UI-002 전체 완료로 보지 않는다.

- 2026-11-12: R-UI-002 플로팅 패널까지 포함해 Android Debug APK/AAB를 갱신했다. APK `build/holo-debug.apk` 249,877,422 bytes (min API 29/target API 36, v2 signature true); AAB `build/holo-test.aab` 86,286,445 bytes (bundletool 1.18.3 validation pass, same API levels, unsigned). 실기기/성능 및 Play 서명 미검증.

- 2026-11-12 정책 회귀: 최신 사용자 결정인 기본 5종 단계별 스토리 해금을 `tests/campaign_playability.gd`에서 직접 assert한다. M1 시작 검사/궁수, M2 이후 창병, M4 숲 지원병, M5 성채 마법사 시점을 확인하고 8-stage 승리 시뮬레이션도 통과했다. 원본 기획 문서는 수정하지 않았다.

- R-UI-002 상태 안내 수정: 시설 컨텍스트 패널은 재정비 중 이동 안내, 전투 중 이동 불가 안내를 구분한다. headless UI 회귀 및 editor import 통과.

- 2026-11-12: 상태별 시설 안내 포함 최신 커밋의 Android APK/AAB 재생성. Debug APK `build/holo-debug.apk` 249,877,946 bytes; manifest API 29/36, apksigner v2 pass. Test AAB `build/holo-test.aab` 86,286,970 bytes; bundletool 1.18.3 validate, 필수 bundle entries 및 API 29/36 manifest pass. AAB unsigned.

- 2026-11-12: 전투 화면 보드 아래의 공통 조작부를 세로 스크롤 영역에 넣고 시설 건설 버튼을 2열로 배치했다. 보드 자체는 고정 부모에 유지된다. headless UI 테스트에서 보드/스크롤 영역 분리와 실제 세로 overflow를 확인했다. 좁은 화면·노치 실기기 확인은 미검증.

- 2026-11-12: 세로 스크롤 전투 레이아웃 포함 최신 Android Debug APK `build/holo-debug.apk` 249,879,210 bytes(API29/36 manifest, v2 서명 pass) 및 Debug AAB `build/holo-test.aab` 86,288,227 bytes(bundletool 1.18.3 검증, 필수 항목·API29/36 manifest pass) 생성. AAB는 unsigned.

- 2026-11-12: 고정 pause 푸터를 스크롤 영역 밖에 분리해 작은 세로 화면에서 항상 접근 가능하게 했다. 360×640 회귀/전체 headless/validator 통과. 최신 APK 249,879,286 bytes(API29/36, v2), AAB 86,288,306 bytes(bundletool 검증, API29/36, unsigned) 재생성.

- M3 진화 연구 진행: 6개 진화 형태마다 연구소/기본 유닛/해당 스토리 해금 조건을 연결한 영구 연구를 추가했다. 구매는 기존 `unlocked_research` 저장/중복 방지와 비용 검증을 사용하고, `BattleModel`에서 `unlocked_evolutions`로 복원 가능하게 했다. 콘텐츠 검증은 형태별 정확히 하나의 연구와 일치 유닛/참조를 요구한다. 영구 비용 100은 임시 SEED. 전투 변신/특수 스킬 적용은 분기·재진화 정책 대기.
- 마을 연구 화면에 세로 스크롤과 48px 연구 버튼을 추가했다. 테스트는 360×640에서 11개 연구 항목의 스크롤 접근성을 확인한다.

- 2026-11-12: 진화 6종 영구 연구 해금 구현 및 검증 완료(연구 구매·중복 차단·체크포인트 복원·콘텐츠 참조 검증, 360×640 연구 목록 스크롤). 실제 전투 변신/분기/재진화 규칙은 계속 미결정. Android APK/AAB도 최신 코드로 재생성했으나 실기기 검증은 대기.

- 2026-11-12: 영구 진행 저장의 원자 교체 중 앱 종료로 메인 파일이 없고 .bak만 남는 경우, load_progress()가 백업을 복구하도록 수정했다. 회귀 테스트에서 기존 재화·진행 복원과 파일 이동을 확인. EditorPlugin headless 초기화 및 주요 5개 씬 smoke도 통과.

- 2026-11-12: 콘텐츠 검증을 Error/Warning으로 분리. 필수 6 메인+2 선택 스테이지는 Error 유지, 26웨이브는 조정 가능한 제작 목표로 Warning 처리한다. EditorPlugin은 경고만 있어도 저장하고 CI 검증기는 Warning 출력 후 성공 종료하도록 연결. 27웨이브 변형 테스트에서 Error 0/Warning 1 확인.

- 2026-11-12: Android APK/AAB export에서 테스트, EditorPlugin, editor-preview 씬/런처를 제외하도록 설정. 생성된 APK sparse PCK를 검사해 해당 경로 부재와 런타임 ContentValidator 포함을 확인. APK v2/API29/36 및 AAB bundletool/manifest 검증 통과.

- 2026-11-12: adb server 재시작 후 API29/API37 AVD를 online으로 복구. 최신 APK를 API37(1080×2400, density 420)에 설치·실행했고 앱 프로세스가 foreground에 유지됨. 화면 캡처는 검정이며 SwiftShader에서 GLES3 fragment uniform 261 오류 재현; AVD 실행 검증은 실패로 유지.

- 2026-11-12: M5 카탈로그 백업 복구를 추가했다. EditorPlugin 원자 저장 중 본 JSON이 사라지고 .bak만 남은 복구 시나리오를 core 회귀에서 확인. plugin headless 초기화, editor preview 격리, 콘텐츠 validator 통과. 도구 스크립트는 Android export 제외 대상이어서 Android 런타임 산출물 재생성은 필요하지 않음.

- 2026-11-12: 재시작 시 메인 메뉴가 저장된 전투 체크포인트를 찾지 못해 자동 복원으로 진입하지 않던 흐름을 수정. 스테이지별 checkpoint path/latest save 검색을 공용화하고, 발견 시 메인 생성 전에 해당 전투 씬으로 이동시켜 기존 3초 복원을 사용한다. 분리된 테스트 경로에서 스테이지별 파일 이름/발견을 검증했다.

- 2026-11-12: 재시작 체크포인트 탐색이 `.bak`만 남은 원자 저장 중단도 복구하도록 보완. Android 최신 APK/AAB 재생성 및 API/서명/번들 검증 통과.

- 2026-11-12: R-UI-001 headless 레이아웃 테스트를 SubViewport 기반 320×568, 360×640, 412×915로 확장. 각 크기에서 유닛 문맥 메뉴·고정 pause·전투 컨트롤 스크롤 영역이 viewport 안에 있는지 검사. 5개 필수 headless 테스트와 콘텐츠 검증 모두 통과.

- 2026-11-12: Main 캠페인 2열 버튼의 폭을 viewport 기반 120–168px로 계산해 320px에서 합계 폭 초과를 방지. 320/360/412 너비 함수 테스트, 메인 씬 smoke, 전체 5종 테스트 통과. Android APK/AAB 최신화 및 API/서명/번들 검증 완료.

## 2026-11-12 카탈로그 백업 정리

- 유효한 주 카탈로그와 함께 남은 오래된 .bak을 읽을 때 정리하도록 수정. 검증 오류가 있는 주 카탈로그에서는 백업을 보존함.
- 재현 회귀 테스트 및 전체 headless 검사 통과. Android 패키징 변경 없음.

## 2026-11-12 사용자 규칙 결정 반영

- 수성: 아군 전멸/핵심 생존 시 계속 진행, 핵심 파괴 시 패배. 전멸 중에도 적 웨이브는 진행한다.
- 시설: 전투 중 수리 버튼/모델 경로를 추가. 5 HP당 1 전투 자원으로 최대 HP까지 회복하는 임시 SEED이며 파괴 시설 수리는 허용하지 않는다.
- 검증: core 생존 무아군 방어 진행, 전투 중 수리 자원 차감/회복, 선택 시설 UI 회귀 통과.
- 진화 정책은 기록 완료, 전투 변신 구현은 다음 단위. 물리기기/GUI는 여전히 미검증.
## 2026-11-12 규칙 결정 및 M3 진화

- 수성: 아군 전멸만으로 패배하지 않고 핵심이 생존하면 웨이브를 계속한다. 핵심이 파괴되면 패배한다.
- 시설: 전투와 재정비 중 수리 가능. 누락 HP 5당 전투 자원 1로 최대 HP까지 복구하는 임시 SEED. 파괴 시설 복구는 미지원.
- 진화: 해금/강화 조건/비용 충족 시 개체를 한 번 진화시키고 동일 개체·위치·강화를 유지한다. 선택 형태는 고정되고 재진화 불가. 자동·수동 특수 스킬과 쿨타임을 저장/복원.
- SaveVersion 2. v1 비진화 체크포인트는 호환 복원 후 v2로 저장.
- 회귀 테스트와 8개 캠페인 시뮬레이션 통과. Android 실기기/FPS 및 Godot GUI는 미검증.
- 2026-11-12 M3 진화 정책 반영 후 Android Debug APK/AAB를 다시 내보냈다. APK v2/API29/36과 bundletool 1.18.3 AAB 구조/manifest 검증 통과. API37 AVD는 설치/Activity 실행까지만 성공했고 검은 화면 및 shader-link 오류로 렌더 확인 실패.

## Android 렌더러 및 AVD 재검증 (2026-11-12)

- Android 전용 Godot 렌더러를 Mobile(Vulkan)로 설정하고 Debug APK/AAB를 다시 빌드했다. 데스크톱 renderer는 GL Compatibility 유지.
- API 37 AVD (1080×2400, density 420): Vulkan SwiftShader 초기화, 캠페인 메뉴/수성 보드 화면 렌더링, 터치로 M1 진입, 검사 2기 배치 및 전투 자원 160→60 차감까지 확인. AVD 시작 구간 `gfxinfo`는 17 frames / 11 janky / p50 61ms / p90 300ms였으며 시작 프레임만 포함한 짧은 샘플이라 60FPS 인수로 사용하지 않는다.
- API 29 AVD: 앱은 foreground까지 열렸으나 Vulkan present가 `VkResult error 5`를 기록하고 정상 화면 검증은 통과하지 못했다. Android 10 실기기 검증과 FPS 측정은 대기.
- 전체 headless core/UI/editor-preview/campaign/content validator 및 5개 주요 씬 smoke 통과. APK API29/36, v2 서명; AAB bundletool 1.18.3 구조 검증 통과, unsigned.

- API 37 AVD 수동 전투 추가 검증: 터치로 M1 진입·유닛 2기 배치/자원 차감·웨이브 시작. 유닛 전멸 후 핵심 HP가 생존한 채 2웨이브로 진행했고, 핵심 HP 0에서만 패배/부분 보상 화면을 확인했다. 수성 생존 결정은 에뮬레이터 화면에서도 검증됐다. 실기기/FPS는 미검증.

- API 37 AVD 재시작 복원 추가 확인: M1 진행 중 force-stop/재실행 후 캠페인 메뉴가 아닌 기존 웨이브 전투로 복귀했고 core HP·아군·남은 적 상태로 진행했다. 이전 패배 정산 영구 잔액 105도 재실행 뒤 유지됐다. 실제기기/버전 업그레이드 마이그레이션은 별도 미검증.

## 2026-11-12 status-effect policy implementation

User-confirmed rules: bleed/burn damage consumes shield first, then applies armor/damage reduction; freeze/stun incapacitation duration is the longer remaining time. Incapacitated units cannot move, use skills, or attack. Fractions near zero are clamped so locks expire reliably.

Verified with Godot 4.7.2 headless core, editor startup, results view, seeded 8-stage campaign, editor preview isolation, and content validator. See TEST_REPORT.md. Android export/device performance were not rerun for this logic-only change.

- 2026-11-12 M6 follow-up: Rebuilt APK/AAB after status-effect fixes; API29/36, APK debug signature, and bundletool validation pass. AVDs currently offline; no post-change device/FPS result. Publisher key/package ID remain unavailable.

- 2026-11-12 M6 device follow-up: ADB server recovery brought API29/API37 AVDs online. Latest APK smoke: API37 campaign/M1 screen displays, API29 black screen with Vulkan present error 5. This improves the previous stale-device state but leaves Android 10 rendering unresolved; see ANDROID_TESTING.md/ISSUES.md.

- M6 renderer follow-up: repeated API29 test in host-GPU and software-GPU modes; both black-screen with Vulkan present error 5. API37 SwiftShader renders. Recorded as unresolved emulator/device-path risk; no project renderer change made without real-device evidence.

## Temporary battle pixel sprites (2026-11-12)

Replaced battle-cell text glyphs for units, facilities, core, walls, and obstacles with a nearest-filtered 16px SVG pixel-art atlas. Mapped all 11 unit kinds and campaign facility IDs; unknown IDs continue to fall back to cell text. Selected friendly entities are tinted. The atlas is explicitly temporary and requires final art replacement before release.

Verified every atlas region and every catalog unit/facility mapping in `tests/run.gd`. Godot 4.7.2 editor import, core/results/campaign/editor-preview/content tests and main/battle/village headless scene starts pass. Refreshed APK/AAB validate; API37 AVD rendered the M1 board and a placed swordsman sprite. APK SHA-256 `95DDFF7E99F5E30946B9626DC96A25B5E5F9B605E40EA55D5F8AFFF271A1EBA3`; AAB SHA-256 `90FE8D18CAB772A69E6E01305E053228D3471EFB19793CF746DC9E640FD11856`.

- 2026-11-12 M6 perf follow-up: Android system frame collectors cannot observe the Godot native SurfaceView in current API37 AVD (gfxinfo 0 frames; SurfaceFlinger query only refresh period). FPS target verification remains open; next use Godot Remote Profiler or physical-device GPU profiler.

## M5 catalog editing safety (2026-11-12)

Catalog writes now pass through a testable save path: stable IDs cannot change, any Validator Error blocks persistence without touching the source file, Warning-only edits save atomically, and error-list selection opens the record at the reported nested JSON key. Added regression cases for invalid wave reference, ID change, 27-wave warning-only edit, temp/backup cleanup, and simple/nested field selection.

All headless core/results/campaign/editor-preview/content tests pass. The editor GUI itself remains unverified because the native Computer Use connection is unavailable.

- 2026-11-12 M6: added debug-only battle frame sampling (10-second windows) with average FPS and p50/p95/max frame times; core tests cover the percentile calculation. Fresh Android APK/AAB exported. API37 SwiftShader AVD showed M1 gameplay at 25.9 and 25.4 average FPS (p95 41.67/41.31ms, max 50ms); this software-emulated result misses the numeric target and is not representative of physical hardware. Physical-device FPS remains unverified.

- 2026-11-12 Android 10 renderer probe: a temporary Compatibility/OpenGL APK also failed EGL startup on the API29 AVD; `project.godot` was restored and the current Mobile/Vulkan setting retained. Both AVD renderer paths are documented in `ANDROID_TESTING.md`; physical hardware remains the decisive check.

- 2026-11-12 current-source verification: full Godot CI-equivalent test set passed (8/8 seeded campaign stages; content Error 0; all five scene starts). Official Mobile/Vulkan APK/AAB re-exported; APK v2 signature and AAB structure verified. Current artifacts recorded in `ANDROID_TESTING.md`; AVDs were offline, so no fresh device smoke.

## 2026-11-12 status-effect decision reconfirmation

The user reconfirmed shield-first then armor for bleed/burn and longest remaining time for overlapping freeze/stun. Existing BattleModel behavior matches; `tests/run.gd` passes. No gameplay code changed. M5 GUI and M6 real-device/FPS/signing checks remain open.

## M5 editor panels structural validation (2026-11-12)

Added `tests/editor_panels.gd` and wired it into GitHub Actions. Godot 4.7.2 editor-headless check creates all three EditorPlugin tabs and confirms they load stages/waves, six evolutions, 20 upgrades, and both stage/wave preview controls. Core suite, content validation, and actionlint pass. GUI interaction remains unverified; editor-headless shutdown emits renderer/object cleanup leak diagnostics despite exit code 0.

## M6 current AVD recheck (2026-11-12)

Recovered the offline API29/API37 AVDs using the local Android SDK's ADB and installed current APK SHA `E0B817...`. API37 rendered the campaign menu with Vulkan/SwiftShader. API29 resumed the activity but repeated Vulkan present error 5. Headless ADB touch injection did not navigate to M1, so this run is only a launch/render smoke. No physical device was present; details in `ANDROID_TESTING.md`.

## Full local CI-equivalent revalidation (2026-11-12)

Godot 4.7.2 import, core, editor-preview isolation, editor-panel construction, results UI, 8/8 campaign wins, content validation, five scene starts, and actionlint all pass. Content validation has zero Errors. Stopped four additional stale `results_view.gd` workers; no new headless Godot process remained after the suite.

## External validation access check (2026-11-12)

The computer-use native pipe again failed before listing Windows apps, so M5 GUI interaction could not be attempted. The connected GitHub account lists no repository corresponding to this project, and the local repository has no remote; hosted Actions remain unavailable. Local CI-equivalent results remain the available validation.

## API 29 에뮬레이터 경로 추가 확인 (2026-11-12)

- Emulator 37.2.13과 임시 Android 10 Google Play AVD를 이용해 재검증했다. Vulkan APK는 present error 5, Compatibility APK는 GLES 2 EGL 컨텍스트 실패로 실행 화면을 표시하지 못했다. API29 Google APIs AVD에서도 최신 Emulator로 Vulkan 오류가 재현됐다.
- 임시 Play AVD/이미지는 정리했고 기존 AVD 사용자 데이터는 보존했다. Android 10 실기기 검증 및 대표 기기 FPS 측정은 여전히 남아 있다. 상세 결과는 `ANDROID_TESTING.md`.

## M6 fresh API37 launch check (2026-11-12)

Reinstalled the current local Debug APK on `MaDangStage6_API37` with Emulator 37.2.13/API 37. The campaign menu rendered and no Godot/AndroidRuntime error was captured. ADB tap injection did not enter M1, so the check is limited to launch/menu; Android 10 and FPS remain unverified. Screenshot artifact is ignored under `build/mvp-followup-api37.png`.

## API37 M1 touch gameplay smoke (2026-11-12)

Corrected ADB coordinates entered M1 on `MaDangStage6_API37`/Emulator 37.2.13. The board and controls rendered; deploying a swordsman charged 50 (resource 160→110), and wave 1 combat reduced core HP 300→280 after an enemy hit. This confirms a short deploy/start/attack path on the emulator only. Full campaign, Android 10 physical device, and FPS acceptance remain separate. Screenshot: ignored `build/mvp-followup-api37-wave.png`.

## Godot build-output scan exclusion (2026-11-12)

Added tracked `build/.gdignore`. Godot 4.7.2 headless editor initialization now skips the ignored output directory, including generated emulator PNGs and Android packages; the import log no longer scans those artifacts. The editor-panel script still passes, but its standalone editor shutdown continues to print renderer/ObjectDB cleanup diagnostics (exit code 0), so that existing test-harness warning remains open.

## API37 checkpoint reboot path (2026-11-12)

Reproduced on the current APK: verified the M1 wave-start checkpoint JSON directly in Android app storage, force-stopped/relaunched the app, then observed the same stage/unit in resumed combat. The resumed unattended battle ended in a normal core-zero defeat; settlement kept permanent currency 115 and cleared the checkpoint. This validates routing, restore, and defeat cleanup on API37, not a win path. Four SwiftShader profiler windows averaged 23.7–25.2 FPS (p95 42.80–45.68ms); physical-device performance remains unknown.

## M1 victory result count fix (2026-11-12)

API37 emulator repeat-play smoke completed the two-wave M1 defense. The result panel now reports `웨이브 2 / 2 완료`; the prior count incorrectly displayed 1/2 after victory. This was a presentation/counting defect; reward settlement did not depend on that count. Updated APK SHA-256: `B8845B0ECDA245D51EA6234D898C19B925982FB92C470111E3E141D806F0A5BA`. Updated test AAB SHA-256: `3941E299153244DB5BD4698DA95C6F2A9D9B6AD86C52A1E1CB038F8A8CED59E0`.

## Acceptance snapshot reconciliation (2026-11-12)

- M0–M4 implementation is in place; the 8-stage/26-wave seeded campaign simulation passes, while full manual campaign UX and balance acceptance remain distinct.
- M5 panel construction/content checks pass in editor-headless mode. Visible dock/Inspector interaction remains unverified because the local computer-use host exposes no apps.
- M6 debug APK/test AAB and local validations pass; API37 emulator victory is observed. Physical Android 10/FPS, release signing/package identity, and Play private-test upload remain pending.
- See the current acceptance snapshot in `IMPLEMENTATION_PLAN.md`; immutable source-spec conflicts are resolved by the user-policy addenda in `ISSUES.md`.

- 2026-11-12 full local Godot revalidation repeated: core, preview isolation, editor panels, results, 8-stage playability, content validator, and five scene starts pass. Current ADB has no attached device; release signing environment remains unset, so M6 external gates are still open.

## Facility upgrade policy and implementation (2026-11-13)

- Resolved R-FAC-003/R-UI-002 timing per the user: upgrades may be purchased in preparation and combat. Added four three-level facility upgrades, runtime stat application, resource cost, context-panel button, validator rules, checkpoint persistence/defaults, and unit/integration/UI regression tests.
- Current values/costs are SEED; details and latest APK/AAB validations are in `TEST_REPORT.md`. 24 total upgrade records (20 unit + 4 facility) are covered by the editor panel structure check.
- Latest local Godot test suite and API37 launch/menu check pass. Physical Android 10, device FPS, GUI dock/Inspector interaction, package ID/signing, and Play upload remain unverified.

## Device update (2026-11-13)

- Galaxy S25 Ultra: user confirmed the refreshed APK installs and launches. Treat as a device startup smoke pass only. Full gameplay, touch/safe-area, save/reward, and regular/high-load performance checks are still needed on-device.
- MVP acceptance is not down to gameplay testing alone: M5 editor GUI usability and M6 Android performance/Android 10 and publisher-signed Play package gates remain as listed in `ISSUES.md`.

## 2026-11-13 사용자 관찰 이슈 수정

- 완료: 유닛 정보창 닫기 동작 추가, 일시정지 메뉴에 확인형 전투 포기 추가.
- 완료: 전투 중 해금 유닛 신규 배치 가능; 재정비 중 즉시 개별 재배치, 공성 전투 중 개별 목적지 보행 후 자동 진격 재개.
- 완료: 공성 시작 버튼을 `진격`으로 표시. 진격 시 적 웨이브 활성화와 전체 아군 자동 진격이 함께 시작됨. 별도 전체 이동 명령은 없음.
- UX 보완: 공성 준비 화면에 `진격`이 전투 시작과 전체 자동 진격을 함께 실행한다고 표시. UI 회귀 테스트가 버튼과 안내 문구를 확인한다.
- 자동 확인: 배치/이동/버튼 상태, 사용자 인터페이스 닫기·포기 확인창 및 승리/패배 테스트가 통과.
- 사용자 확인 대기: 일시정지 메뉴에서 포기 후 실제 부분 보상 액수와 마을 복귀 흐름은 사용자의 게임 내 재확인 필요.

## 2026-11-13 정책 문서 정합화

- 사용자 결정으로 확정된 규칙이 기획 원문 일부에 오래된 OPEN/초안 표기로 남아 있어 네 기획 문서와 Issues 기록을 현재 정책에 맞춤: 단계별 유닛 해금, 핵심 생존 수성 지속, 개체당 1회 진화 고정, 전투/재정비 시설 수리, DoT/행동불가 규칙.
- 테스트 보강: 시설 수리의 재정비 단계 경로도 비용 차감과 최대 HP 복원을 확인하도록 회귀 케이스 추가. 나머지 세 규칙은 기존 테스트에서 이미 검증.

## Policy reconciliation and M5 verification attempt (2026-11-13)

- Reconciled the four design documents to prior user decisions and corrected the obsolete “all five units immediately unlocked” summary. Current status is in `PLANNING_COVERAGE.md`.
- Godot 4.7.2 full local test batch passed after adding preparation-phase facility repair regression; combat-phase repair remains covered.
- M5 visual editor inspection attempted again, but Computer Use reported native pipe unavailable (OS error 2). Treat GUI usability as unverified.

## Abandon UI viewport fix (2026-11-13)

- Fixed the Android portrait confirmation dialog: Korean wrapping text, localized title and action buttons, concise explanation. Added UI assertions and re-ran full Godot test batch successfully.
- Re-exported local debug APK and manually exercised API37 AVD pause→confirm abandon→zero-wave result (+0/unchanged 165 currency)→village. No GitHub APK release. User-device positive partial-reward flow remains an acceptance check.

## 2026-11-13 공성 조작 안내 및 Android 빌드 사전검사

- 확정 조작을 재확인: 공성 `진격`은 전투 시작과 전 유닛 자동 진격을 동시에 실행한다. 개별 이동은 선택 유닛만 대상으로 하며, 준비 단계에서는 그 자리에 재배치·대기하고 전투 중에는 목적지까지 보행 후 자동 진격을 재개한다. 전체 이동 명령은 제공하지 않는다.
- 준비 화면 안내와 UI 회귀 assertion을 추가했다. `run_godot_tests.bat` 전체 통과(core, 콘텐츠 Errors 0, 8/8 캠페인, 전투 UI, 편집기 패널 24 강화); 편집기 headless 종료 시 기존 RID/ObjectDB 정리 경고는 출력된다.
- `export_android_aab.ps1`이 WinGet Godot 경로도 찾고, 샘플 앱 ID와 API36 사전조건을 검사하도록 보완했다. 임시 검증 값으로 사전검사 중단을 확인했으며 실제 서명/릴리즈 내보내기는 하지 않았다.
- 현재 코드의 로컬 테스트 AAB: 86,248,032 bytes, SHA-256 `7A484105D3329C389D858111EC35BF8949E187C2AEE5C1796BCBE0921448F32D`. ZIP 필수 엔트리는 확인했고 서명되지 않았다. 실행형 bundletool을 확보하지 못해 AAB 매니페스트/번들 validator 검사는 대기.
- 소스만 커밋·푸시한다. APK/AAB GitHub 릴리즈는 하지 않는다.

## M5 Godot GUI 재점검 (2026-11-13)

- Godot 4.7.2 GUI에서 프로젝트와 `Holo Content Editor` 플러그인 활성화를 확인했다. 우측 도크는 접근성 트리에 내부명 `@TabContainer...`로 표시되어 찾기 어려웠다.
- 도크 컨트롤 이름을 `콘텐츠 편집기`로 지정하고 기존 EditorPlugin 테스트에 이름 assertion을 추가했다. 전체 `run_godot_tests.bat` 재실행 통과(core, validator, 8/8 캠페인, battle UI, editor panels 24 upgrades).
- 변경 후 GUI 재시작/패널·Inspector·미리보기 버튼 직접 조작은 아직 확인하지 않았다. Editor headless 테스트 종료 시 기존 RID/ObjectDB 정리 진단이 출력된다.

## M5/M6 확인사항 갱신 (2026-11-13)

- Godot GUI 재시작으로 도크 표시, 세 콘텐츠 패널, Inspector 리소스, 격리된 전체 스테이지 미리보기를 확인했다. Editor preview test를 Windows 테스트 배치에 추가했고 전체 배치가 통과해 M5를 완료 처리했다.
- M6는 API37 AVD 스모크를 추가했으나 성능 목표는 아직 통과 판정할 수 없다. 상세 FPS와 한계는 `TEST_REPORT.md`/`ISSUES.md` 참조.

## 2026-11-13 Godot GUI/API37 retest

- Reopened Godot GUI and confirmed the named `콘텐츠 편집기` dock, all three populated tabs, stage JSON draft, Inspector resource property view, and isolated M1 stage preview. Direct-wave preview and mutation/rejection UI were not manually clicked; their automated tests remain the evidence for those paths.
- API37 x86_64 AVD installed and launched the current local debug APK; campaign and M1 battlefield rendered. Short sampler windows show 33.9–34.8 average FPS on the emulated renderer. This is below the ordinary 60 FPS goal and does not satisfy device acceptance; actual Galaxy S25 Ultra and a lower-tier Android 10+ device still require profiler runs.
- Ran existing `tests/editor_preview.gd` directly (selected wave 2, progress/request isolation passed) and added it to `run_godot_tests.bat`; the expanded full local batch passes.

## Android CI AAB job correction (2026-11-13)

- Six recent push workflows were all blocked at the same Android step: standalone `--install-android-build-template`; Godot 4.7.2 help specifies this option is used with `--export-debug`/`--export-release`.
- Combined template installation with the AAB export and added a 20-minute job timeout. Cancelled the six stale runs after confirming they were stuck on the same step.
- The exact combined export command succeeded locally: AAB 86,248,032 bytes, SHA-256 `7A484105D3329C389D858111EC35BF8949E187C2AEE5C1796BCBE0921448F32D`; required BundleConfig/manifest/dex entries present. `jarsigner` confirms it is unsigned; this is only a test bundle, not Play-ready.
- The later corrected workflow run `43351099459` passed both jobs and uploaded the unsigned AAB test artifact; see the subsequent CI retest entry.

## Android package identity (2026-11-13)

- User confirmed permanent package ID `com.rhstudio.holotactics`. Updated both Android export presets, the AAB preflight guard, emulator test launcher, and current device-test instructions.
- Existing APK/AAB installations using `com.example.holotactics` keep their old identity; the confirmed ID creates a separate app until rebuilt. Play Console availability and publisher signing remain unverified.

## Android package rebuild and smoke (2026-11-13)

- Re-exported debug APK and test AAB after applying the confirmed ID. `aapt` reports `com.rhstudio.holotactics`, min API 29, target API 36; APK v2 signature verifies. AAB required BundleConfig/manifest/dex entries are present; `jarsigner` confirms it is unsigned.
- API37 AVD briefly reported `device offline`; `adb reconnect offline` restored it. New APK installed successfully beside (without deleting) the old sample-ID app, launched with the new ID, reached the campaign screen, and showed no matching fatal/shader errors in the inspected log window.
- Release-key path, alias, and password environment variables remain unset. The package ID is user-selected but its availability in Play Console is not established.

## Corrected GitHub Android export (2026-11-13)

- Commit `b425bf8` CI run `43351099459` completed successfully: Godot import/tests/content/scene smoke all passed, Android debug AAB export and required-entry verification passed, and artifact `holo-debug-aab-unsigned` uploaded with 7-day retention.
- This is an unsigned CI test artifact, not a GitHub Release or Play-uploadable bundle. No APK/AAB release was created.
