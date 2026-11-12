# Implementation plan

기준 문서: `docs/PRODUCT_SPEC.md`, `docs/PLANNING_COVERAGE.md`, `docs/DECISIONS.md`, `docs/REQUIREMENTS.md` (기획 v12.8, 2026-11-11).

## 정책 상태

- **확정(LOCKED):** Godot 4/GDScript, 세로형 2D, Android 10+, 오프라인 싱글플레이, 수성·공성, 8개 스테이지(메인 6+선택 2), 26웨이브 제작 목표, 안정 ID와 INV-01~13, 체크포인트/보상 무결성, 자동 검증 및 편집 도구 범위.
- **시험 초기값(SEED):** 능력치·비용·보상·AI 가중치·타이머·진화 수치 및 예시 스테이지 배치. 데이터와 테스트에서 `BALANCE_SEED`로 표시하며 사용자 확정 정책처럼 취급하지 않는다.
- **미결정(OPEN):** 일부 스킬 상호작용 및 증원 안전 종료의 세부 UX. 게임 규칙에 영향이 큰 선택은 필요 시 사용자에게 묻는다.
- **후속(DEFERRED):** PvP, 보스전, iOS 출시, 클라우드 저장, 광고·과금, 원격 콘텐츠 서비스.

## 충돌·위험

네 원문에서 최신 결정과 명시적 대체를 기준으로 정합성을 확인했으며 직접적인 규칙 충돌은 발견하지 못했다. `DECISIONS.md`의 C 섹션은 시작 유닛·건물·HP 복구·공성 패배 등 과거 제안을 최신 정책으로 대체한다. `PRODUCT_SPEC.md`의 8개 스테이지/26웨이브 조합과 밸런스 숫자는 승인된 규칙이 아닌 초안/목표다. 주요 위험은 저장/보상 중복, 콘텐츠 ID 변경, 증원 출현 실패, 불가침 장애물의 경로 차단, 모바일 성능이다.

## 단계와 의존성

| 단계 | 의존성 | 범위 | 인수 증거 |
|---|---|---|---|
| M0 기반/계약 | 기획 4종 | Godot 프로젝트, 데이터 경계·버전, INV 검증, headless 테스트, CI | Godot 실행, 기본 테스트 통과, Error 검증 실패 |
| M1 수성 슬라이스 | M0 | 타일 전장, 검사/궁수, 선택·이동·공격, 수성 핵심·웨이브·재정비·전투 자원·체크포인트/UI | 수성 승패·저장·정산 테스트와 플레이 가능한 1스테이지 |
| M2 공성/경로 | M1 | FSM+Utility AI+A*, 공성 핵심/시설, 증원, 방어벽·장애물, 안전 종료 | 공성/경로/증원 예외 통합 테스트 |
| M3 전투 성장 | M2 | 아군 5/적 6/시설 4, 강화 20, 진화 6, 스킬·상태이상·연구 기반 | 성장의 전투 반영 및 AI/전투 테스트 |
| M4 마을/캠페인 | M3 | 마을 건물 4, 영구 재화/연구/해금, 8개 스테이지·목표 웨이브 콘텐츠 | 메인 진행 및 선택 분기 플레이, 보상/진행 저장 |
| M5 제작 도구 | M0·M3·M4 | 스테이지·웨이브/진화/강화 Godot 편집 패널, Inspector 속성 편집, 격리된 미리보기 | 편집기·CI 공통 검증, 테스트 데이터 격리; GUI 상호작용과 시각 검증은 미완료 |
| M6 품질/배포 준비 | M1~M5 | 자동·통합 검증, 저장 마이그레이션, Android 패키지, 성능·비공개 테스트 자료 | 자동 테스트·콘텐츠 Error 0, AAB 및 실기기 측정 기록 |

각 단계는 자동 테스트 및 진행 문서를 갱신한 뒤 다음 단계로 진행한다. 실기기/스토어 권한이 필요한 결과는 실제로 확인되기 전까지 미검증으로 남긴다.

## M0 구현 선택

기존 프로젝트가 없으므로 Godot 표준 프로젝트와 GDScript headless 테스트를 사용한다. 의존성 없는 JSON 카탈로그와 공통 검증기로 안정 ID/참조부터 검사하고, 전투 데이터가 추가될 때 INV 세부 규칙을 단계적으로 확장한다. Godot 4.7.2와 로컬 Android SDK/Java 17을 재사용한다.

## 현재 진척 기록

- 2026-11-12: 마을 건물 배치 최소 경로(본부 자동 배치, 세 건물 구매·해금·배치, 이동/보관 모델, 화면)를 M3/M4 진행 항목으로 추가. 사용자 승인 정책이 아닌 초기 영구 재화 100 및 비용 75/100은 SEED. 자동 검증 통과 후 다음으로 연구/영구 성장 연결을 진행한다.
- 2026-11-12: 5종 기본 공격 영구 연구를 데이터·구매·마을 UI·전투 능력치·체크포인트까지 연결했다. 다음 순서는 결정 대기 중인 진화 세부 규칙과 무관한 M5 콘텐츠 제작 패널의 공통 검증/데이터 편집 기반이다. 연구 효과/가격은 `ISSUES.md`의 SEED다.
- 2026-11-12: M5 3탭 EditorPlugin의 기존 레코드 편집/공통 검증/원자 저장, Inspector 동기화, 오류 ID 레코드 이동, 초안 보존, 격리된 스테이지·웨이브 런처를 구현했다. headless 회귀는 통과했고 진화 데이터/패널 채우기, GUI 상호작용과 필드 위치 안내가 남아 있다.
- 2026-11-12: 진화 편집 패널을 비워 두지 않도록 제품 초안의 여섯 형태를 SEED 카탈로그로 추가하고 Validator에 기본 유닛/강화 ID·조건 단계·양수 비용·특수 스킬 필드 검사를 연결했다. 편집 데이터 검증은 통과했다. 연구 해금·전투 실행은 궁수 분기/재진화 정책 결정을 받은 뒤 진행한다.
- 2026-11-12: M4 캠페인 시뮬레이션이 8개 스테이지를 의존 순서대로 실행하고 `ProgressStore` 승리 정산·완료 저장·중복 보상 방지를 확인한다. 플레이어 이동과 웨이브 사이 증원을 포함한 시드 전술로 모든 웨이브 승리를 재현해 CI에 연결했다. 마을 UI 수동 흐름 및 밸런스 인수는 별도 검증이 남는다.
- 2026-11-12: 선택 레코드를 임시 Resource로 노출해 Inspector에서 편집하고 JSON 패널로 가져오는 경로를 추가했다. 검증 오류 목록에서 콘텐츠 ID 기준 관련 레코드로 이동하고, 선택을 바꿔도 JSON 초안을 유지한다. 동적 속성 및 오류 ID 해석 테스트는 통과했지만 GUI 조작/필드 위치는 미검증이라 M5 완료로 보지 않는다.
- 2026-11-12: M4 결과 오버레이를 추가해 승패/안전 종료/포기, 완료 웨이브, 정산 재화를 표시한다. 정산 실패 때 저장 성공 전까지 복귀를 막으며, 안전 종료는 체크포인트 보존 안내와 복귀를 허용한다. headless UI-state 테스트 및 전체 회귀 통과.

- 2026-11-12: M0 검증 반복 통과. M1 수성 플레이 슬라이스는 수성 전멸 규칙 OPEN 때문에 미완료. M2는 공성 규칙, A*/적 AI, 순차 증원, 비활성 초기 배치 적/시설, 적 시설 공격·웨이브 교체, 파괴 가능 방어벽, 시설 4종의 단일/광역 공격·치유/파괴/저장·복원을 구현 중이다. M3는 5/6종 역할, stage별 배치 해금, 강화 20종, 기본 스킬 10종과 버전된 영구 진행 저장 기반을 구현 중이다. 스킬 효과·쿨타임·비용은 임시 SEED. 시설 수리는 정책 미결정으로 보류했다. 진화·연구·영구 성장 연동·마을/캠페인/툴은 남아 있다. 최신 테스트 및 Android export 증거는 `TEST_REPORT.md`.
- 2026-11-12 사용자 결정: 기본 5종은 모두 한 시점에 풀지 않고, 스토리 진행 시점에 따라 단계적으로 해금한다. `DECISIONS.md`의 C2 순서를 구현 기준으로 삼는다. 원본 기획 문서는 변경하지 않았다.
- 2026-11-12: M4 campaign seed 8개(메인 6+선택 2) 및 26개 wave 연결. 메뉴 진입 제한은 `ProgressStore.completed_stages` 의존 관계로 구현. 자원·맵·보상은 조정 가능한 설계초안 SEED. M4 인수에는 마을/연구 및 전체 캠페인 플레이 테스트가 남아 있다.

- 2026-11-12 M6 Android packaging: Gradle APK/AAB presets use min API 29 and target API 36. APK manifest/v2 signature and unsigned AAB structure verified. Publisher signing and real-device validation remain open.

- 2026-11-12: M1/M4 battle HUD gained the story-gated 1×/2× control from R-GAME-005, with headless UI-state regression. The pause/read-only requirement was subsequently completed and verified (see progress record).

- 2026-11-12: R-UI-003 일시정지/조회 전용 동작 구현 완료. UI 회귀 테스트에서 전투 및 재정비 타이머 보존, 명령 차단과 정보 조회를 확인했으며 전체 회귀 및 콘텐츠 검증 통과. 실제 Android 터치 레이아웃 확인은 M6 기기 검증 잔여 항목.

- 2026-11-12: R-UI-002 유닛 강화/수동 스킬 플로팅 패널과 시설 정보/이동 힌트를 구현하고 화면 경계 자동 검사를 추가. 시설 강화·수리 및 실제 기기 화면 확인은 잔여 항목으로 유지.

- 2026-11-12: 문서 기본 즉시 해금 규칙을 대체한 최신 사용자 정책(단계별 스토리 해금)을 `tests/campaign_playability.gd`에 회귀 계약으로 추가. 원본 기획 문서는 변경하지 않았고 8-stage 캠페인 시뮬레이션 통과.

- 2026-11-12: 시설 주변 이동 도움말을 재정비/전투 단계 규칙에 맞춰 수정하고 두 상태 UI 회귀 통과.

- 2026-11-12: 최신 시설 안내 UI 소스로 Android APK/AAB를 재생성하고 API manifest 및 APK v2/AAB 구조를 재검증. 실기기와 release signing은 별도 미검증.

- 2026-11-12: 전투 공통 조작 영역을 세로 스크롤로 분리해 360×640급 화면에서 지도 고정을 우선하고 모든 하단 조작에 접근 가능하게 했다. headless overflow 회귀 통과, 실제 화면은 M6 기기 점검 대기.

- 2026-11-12: 고정 보드+세로 스크롤 조작 UI를 포함한 APK/AAB 재생성 및 API/서명/구조 검증 완료. 실기기 화면 검증은 대기.

- 2026-11-12: pause 푸터 고정 UI를 추가하고 테스트용 360×640 viewport에서 스크롤 영역/고정 버튼을 자동 확인. 최신 APK/AAB를 다시 export해 manifest/API와 서명/번들 상태를 검사.

- 2026-11-12: R-UNIT-004 중 진화별 영구 연구 해금/구매/저장/복원 연결을 진행. 콘텐츠 참조 무결성, 연구 화면 스크롤, 체크포인트 해금 복원을 회귀 검증한다. 전투 변신은 OPEN 분기/재진화 결정 이후.

- 2026-11-12 이어하기: 기존 미커밋 진화 연구 해금 변경을 재검증하고 APK/AAB를 재생성. 전투 변신 정책은 승인 대기 상태를 유지한다.

- 2026-11-12 이어하기: R-SAVE-008 저장 교체 중단 경로를 점검해 진행 데이터 .bak 복구 누락을 수정하고 회귀 테스트/Android 재빌드를 완료.

- 2026-11-12 이어하기: R-0004/R-DATA-014의 Warning 경로를 구현. 26웨이브 목표를 hard error로 취급하던 Validator 충돌을 수정하고 편집기·CLI 경고 전달 및 회귀 테스트를 추가.

- 2026-11-12 이어하기: 모바일 산출물에서 테스트·편집기 전용 자원을 제외하고 실제 sparse PCK의 경로 부재로 확인. Android SDK adb 장치는 모두 offline이라 실기기 검증은 대기.

- 2026-11-12 이어하기: 콘텐츠 EditorPlugin이 원자 저장 중단 후 .bak을 복구하도록 추가하고 핵심 headless 테스트에 실패 시나리오를 포함.

- 2026-11-12 이어하기: R-UI-005/R-SAVE-003 앱 재시작 자동 복원 진입 경로를 연결. `CheckpointStore`가 스테이지별 경로와 최신 체크포인트 탐색을 제공하고 Main이 이를 찾아 BattleView의 기존 3초 복원을 재사용.

- 2026-11-12 후속 보완: 재시작 체크포인트 탐색은 final 파일 부재 시 .bak을 먼저 복구한 뒤 스테이지를 선택하도록 하고, 백업 전용 복구를 테스트.

- 2026-11-12 이어하기: Android 세로 화면비의 작은/기준/큰 viewport에 대해 headless 경계 회귀를 추가하고 전체 자동 테스트를 재검증.

- 2026-11-12 이어하기: 작은 portrait 폭에서 메인 캠페인 2열 버튼의 overflow를 줄이고 320/360/412 너비 회귀 및 최신 Android 패키지 검증.

- 2026-11-12 이어서 작업: M5 카탈로그 저장 중단 후 남은 .bak 처리 보완 및 회귀 테스트. 편집기 검증 오류가 없는 주 카탈로그만 현재본으로 인정하여 오래된 백업을 정리; 오류 시 백업 보존. 다음은 미결 사용자 결정/기기 검증 대기 항목을 유지하며 이어서 진행.

- 2026-11-12 사용자 결정 반영: 수성 핵심 생존 시 아군 전멸만으로 패배하지 않음, 진화는 선택 후 재진화 불가, 시설은 전투 중에도 수리 허용. M1/M2 구현 및 테스트를 연결하고, 진화 전투 적용은 다음 단위로 진행한다. 수리 단가 5 HP/자원 1은 테스트용 SEED.
## 2026-11-12 사용자 결정 후 진화 시스템

- 수성 핵심 생존 시 계속 진행, 진화는 1회 선택 후 고정, 전투 중 시설 수리를 허용하기로 결정됐다.
- 전투 진화와 특수 스킬, 진화 체크포인트, SaveVersion 1 비진화 저장 호환을 구현했다. 자동 회귀와 8개 스테이지 시뮬레이션이 통과했다.
- 수리 비용은 5 HP당 전투 자원 1의 미승인 SEED다. APK/AAB 최신 런타임 export는 다음 확인 단계다.
- M3 전투 진화 구현과 자동 검증 완료. 현재 남은 인수 작업은 M1/M2/M3 실기기 플레이 밸런스, M5 EditorPlugin GUI 직접 확인, M6 실제 Android/FPS 및 서명/Play 비공개 테스트 준비다. 계정/패키지 ID/keystore/실기기 권한은 제공되지 않았다.

## Android 렌더링 재검증

- 2026-11-12: API 37에서 기존 GL Compatibility의 uniform 초과 검정 화면을 재현한 뒤, Android 모바일 렌더러를 Godot Mobile(Vulkan)로 전환했다. 새 APK는 API 37 AVD에서 메뉴/전투 화면 표시와 기본 터치 경로를 통과했다.
- API 29 AVD는 Vulkan present error 5로 실패해 Android 10 실기기 인수는 열려 있다. 시작 구간 frame stats로 목표 FPS를 판정하지 않는다.
- 다음 독립 단계: 편집기 GUI 실사용 및 status-effect OPEN 규칙 결정 필요성, 실기기/FPS 측정, release signing/Play 자료는 credential 및 장치 접근이 제공될 때 검증한다.

## Status-effect policy follow-up (2026-11-12)

- User decisions recorded in ISSUES.md and implemented: shield then mitigation for bleed/burn; longer remaining freeze/stun lock. Core tests and content/campaign regressions pass.
- Continue with pending M5 GUI verification and M6 Android device/FPS/signing readiness; previous environment blockers remain in ISSUES.md.

## M6 rebuild update (2026-11-12)

Status-effect changes are now included in fresh APK/AAB exports; manifest and package validation passed. Device/FPS validation is pending because both AVDs are offline, and Play release readiness remains gated on publisher package ID and release signing credentials. Continue when device or publisher environment is available; proceed with remaining M5 GUI validation in parallel.

- M6 update: ADB reconnect enabled fresh APK smoke on API 37 and API 29 AVDs. API 37 renders menu/M1; API 29 remains black due Vulkan present error 5. Investigate Android 10 renderer support while seeking physical-device validation; don't treat AVD as performance evidence.

- M6 next action: keep the API29 Vulkan present failure open after both host and SwiftShader AVD paths failed; validate on actual Android 10 hardware before choosing any renderer/configuration change.

## Pixel sprite atlas implementation (2026-11-12)

M1 battle view now shows temporary nearest-filtered pixel sprites for the roster, facilities, core, walls and obstacles. Tests enforce atlas-region size and catalog coverage. Refreshed APK/AAB pass package checks; API37 emulator visually confirms battle-board and deployed unit sprites. Next replace placeholder art with production assets and continue M5 GUI + M6 physical-device/performance/signing validation. Android 10 AVD currently fails Vulkan presentation.

- M6 performance collection attempt returned invalid AVD data for Godot's native SurfaceView; retain the FPS blocker and switch to Godot Remote Profiler/physical-device instrumentation.

## M5 editor follow-up (2026-11-12)

Error-blocking and Warning-only catalog save behavior, stable-ID protection, atomic temp/backup cleanup, and field-focused error navigation are implemented and covered in headless tests. Remaining M5 gate is hands-on Godot dock/Inspector/panel interaction and preview launch through the GUI.
