# Test report

## 마을 최소 기능 (2026-11-12)

- Godot 4.7.2 headless editor import, `tests/run.gd`, `scripts/validate_content.gd`, `scenes/village.tscn` 실행 스모크, `git diff --check` 통과.
- 검사 항목: 신규 저장 기본값, 훈련소 비용 차감/이동/보관 후 무료 재배치, 공방 선행 스테이지 잠금 및 해금 후 구매, 건물 필드 없는 이전 세이브의 본부 마이그레이션, 저장 유효성.
- 마을 추가 안전성 검사: 손상된 형식의 진행 저장을 읽지 못할 때 건설을 차단하고 원본 바이트를 보존한다.
- CI workflow에 메인/전투/마을 씬 headless smoke 단계를 추가하고 로컬 Godot 4.7.2에서 3개 씬 모두 기동 통과.
- 시작 재화와 가격은 SEED. 터치 화면 레이아웃, Android 실기기 및 FPS는 이번 변경에서 검증하지 않았다.
- 최신 마을 UI·저장 보호 포함 Android Debug APK 재생성: `build/holo-debug.apk`, 86,326,570 bytes (2026-11-12 12:49 KST); APK Signature v2/v3 검증 통과, min API 24/target API 36. 기기 실행과 실제 성능은 미검증.

## 영구 연구 연결 (2026-11-12)

- 영구 연구 데이터 5건의 유닛·건물·스테이지 참조 및 가격/효과 검증, 활성 훈련 건물 필요, 스토리 해금, 재화 차감, 중복 구매 차단을 검사한다.
- 구매한 연구의 공격력 증가가 새 전투 유닛에 적용되고, 같은 연구 ID와 효과가 체크포인트 복원 후에도 유지되는 단위 테스트 통과.
- `tests/run.gd`, 콘텐츠 validator, battle/village/research 씬 headless 기동 및 `git diff --check` 통과. 연구 수치는 SEED다.
- 영구 연구 포함 Android Debug APK 재생성: `build/holo-debug.apk`, 86,335,165 bytes (2026-11-12 13:01 KST); APK Signature v2/v3 검증 통과, min API 24/target API 36. 실기기 UI/FPS는 미검증.

## 결과 화면 후 이동 (2026-11-12)

- 전투 결과 상태에서 “마을로 돌아가기” 버튼의 목적지를 캠페인 메뉴에서 마을 화면으로 수정했다. headless 전투 씬 기동 및 전체 테스트/콘텐츠 검증 통과. 터치 기반 전환은 실기기 미검증.

## M5 편집기 패널 기반 (2026-11-12)

- Godot 4.7.2 `--headless --editor --quit`에서 활성화된 EditorPlugin 초기화 통과. 프로젝트 기본 import에 편집기 도구 스크립트 로드가 포함된다.
- 세 탭의 선택 레코드 JSON 수정 및 공통 `ContentValidator` Error 차단, 안정 ID 변경 차단, 임시 파일·백업 기반 원자 저장 코드를 추가했다.
- `tests/editor_preview.gd`: 격리 런처가 요청을 소비하고 지정된 2번째 웨이브를 전투 씬에 로드하며 전투 종료 처리에도 영구 진행 저장 파일을 변경하지 않는 것 통과. 미리보기 전용 체크포인트도 고유 ID 경로를 사용한다.
- 편집기 GUI에서 패널 렌더링/저장 버튼 상호작용과 실시간 게임 실행은 직접 클릭하지 않아 미검증이다. Error 필드 클릭 탐색과 Inspector 통합은 미구현.
- M5 preview 포함 Android Debug APK 재생성: `build/holo-debug.apk`, 86,348,202 bytes (2026-11-12 13:18 KST); APK Signature v2/v3 검증 통과, min API 24/target API 36. 실기기 실행과 성능은 미검증.

## 공성 전진 및 캠페인 시뮬레이션 (2026-11-12)

- 수정 전에는 아군 이동/복원 목적지가 y≥5로 제한되어 적 진영 전진이 불가능했다. 제한 해제 후 적 진영(y<5) 이동, 방벽으로 완전히 막힌 이동 명령 거부, 재정비 체크포인트 복원을 자동 테스트한다.
- 탐색용 headless 자동 전투(제한된 단순 전술, 수동 스킬/강화 미사용)는 8개 중 7개 승리했다. M4 숲 W4 패배는 `ISSUES.md`에 플레이 밸런스 검증 위험으로 남겼다. 해당 진단은 정식 인수 테스트가 아니며 모든 경로·플레이스타일의 승리를 증명하지 않는다.
- 후속 M4 전략 검증은 기본 3유닛 배치와 핵심 앞 화살탑(5,8)으로 4개 웨이브 승리를 확인했다. 시작 전투 자원을 220에서 260으로 조정하고 이 시나리오를 `tests/run.gd`에 포함했다. 앞선 7/8 탐색 결과는 M4 조건 변경 전 결과이며, 나머지 캠페인 스테이지까지의 밸런스 인수를 대신하지 않는다.
- M4 초기 자원 시드 갱신 포함 Android Debug APK 재생성: `build/holo-debug.apk`, 86,352,298 bytes (2026-11-12 13:40 KST); APK Signature v2/v3 검증 통과, min API 24/target API 36. 실기기/FPS 미검증.
- 적 진영 이동/도달 경로 수정 포함 Android Debug APK 재생성: `build/holo-debug.apk`, 86,352,298 bytes (2026-11-12 13:35 KST); APK Signature v2/v3 검증 통과, min API 24/target API 36. 실기기/성능 미검증.

## M0

- 실행 환경: Windows, Godot 4.7.2 stable, Java 17; Android SDK 경로는 `%LOCALAPPDATA%/Android/Sdk`.
- 통과: `Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --quit` (프로젝트 import 및 스크립트 파싱).
- 통과: `--headless --path . --script res://tests/run.gd` (유효 데이터, 중복 ID, 미해결 참조, 비정수 버전, 순환 의존성, 버전 상수).
- 통과: `--headless --path . --script res://scripts/validate_content.gd` (`Content validation passed`).
- 통과: `--headless --path . --quit-after 2` (기본 메인 씬 실행).
- 첫 검증에서 JSON 숫자 타입 가정 때문에 버전 검사에 실패했고, 정수값 판별을 보완한 후 전체 재실행 통과.
- Android debug APK export 통과: `--export-debug "Android Debug APK" build/holo-debug.apk`; APK Manifest min API 24/target API 36. API 36 x86_64 에뮬레이터에서 실행, 검사 배치(-50 자원), 웨이브 시작과 적 출현을 터치로 확인했다.
- 정적 `blocked_cells` 타일을 추가한 APK를 다시 내보내 API 36 에뮬레이터에 설치했다. 메인 화면→전투 진입, 장애물 타일 표시, 검사 배치(자원 160→110), 웨이브 시작 및 적 출현을 터치로 확인했고 앱 스크립트 오류는 관찰되지 않았다.
- 실기기 FPS·Android 10 물리 기기·Google Play AAB/비공개 테스트는 검증하지 않았다. Android emulator 실행은 보급형 실기기 성능 인수를 대신하지 않는다.

## M1 진행 중

- Headless에서 단위 배치, 체크포인트 JSON 파일 저장/복원, 수동 이동 명령, 적 처치, 웨이브 보상 1회 정산, 수성 핵심 파괴 패배, 최종 웨이브 승리를 확인한다.
- 3유닛 시험 배치로 2개 웨이브를 자동 교전해 M1 시드 콘텐츠가 승리로 끝나는 시뮬레이션을 확인한다. A* 적용 뒤 기존 2유닛 배치가 패배함을 확인해 초기 자원을 160으로 조정했다. 이 수치는 밸런스 임시 초기값이며 승인된 정책이 아니다.
- A* 경로 테스트에서 장애물 우회 및 완전 차단 경로 실패를 확인한다.
- A*를 아군 수동 이동과 적의 핵심 접근 경로에 연결했다. 점유 타일·지형 타일 우회, 이동 위치 검사, 콘텐츠상 웨이브 스폰 경로 단절 및 핵심 겹침 오류를 headless 테스트로 확인했다. 파괴 가능한 방어벽, 경로 우회/파괴 Utility 비교, 6종 적 역할은 아직 미구현.
- 적 FSM의 공격·진격·쿨타임 상태, 행동 점수에 따른 공격/목표 우선 선택, 프로필 및 웨이브 가중치 덮어쓰기를 headless 테스트로 확인했다. 현재 콘텐츠 프로필과 역할은 고블린 전사 1종 시드다.
- UI 코드 반영 전 Android screenshot에서 상태 문구가 가로로 넘친 것을 발견해 줄바꿈 처리 및 타일 구역색을 적용했다. APK 재내보내기 및 실행으로 확인.

## 재검증 (2026-11-12)

- 통과: Godot 4.7.2 `--headless --editor --path . --quit`, `--headless --path . --script res://tests/run.gd --quit-after 5`, `--headless --path . --script res://scripts/validate_content.gd`, `--headless --path . --quit-after 2`. 전체 테스트 통과, `Content validation passed`, 기본 씬 실행.
- 통과: 최신 소스에서 Android Debug APK 재내보내기 (`build/holo-debug.apk`, 86,252,151 bytes); package `com.example.holotactics`, target API 36, prebuilt APK min API 24.
- API 29 AVD 재확인: 설치 이미지 `android-29/google_apis/x86_64`는 GLES2만 제공. 앱에서 `eglCreateContext ... no ES 3 support` 및 `createContext failed` 발생. 해당 AVD 실행 실패는 Android 10 실기기 검증 결과로 간주하지 않는다.
- API 37 AVD: 최신 APK 설치 성공, 앱 프로세스/포그라운드 Activity 실행 확인. 로그에서 GLES3 Scene/Canvas shader uniform limit 오류(`GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`)가 확인되어 화면 렌더링 및 입력 플레이는 통과 판정하지 않았다.
- 제약: 실기기, 성능(FPS/P95), Android 10 실제 기기 및 Google Play AAB/비공개 테스트는 미검증. 이전 API 36 터치 스모크 결과는 이전 코드 빌드에 한정되며 최신 공성 코드 빌드의 동작 증거로 재사용하지 않는다.

## M2 증원 재검증 (2026-11-12)

- 통과: 증원 데이터 참조/정수 좌표/시각/수량 validator 검사와 스폰 경로 차단 검사를 추가했다. 잘못된 좌표 및 막힌 출현 경로 테스트가 예상 Error를 발생시킨다.
- 통과: 공성 W2에 3초 후 1기 증원 시드 데이터를 연결했다. 기본 적이 먼저 전멸해도 예약 증원이 소진될 때까지 웨이브가 종료되지 않고, 같은 출현 지점의 복수 적은 인접 유효 타일로 분산된다.
- 통과: 모든 타일을 막은 테스트에서 6회 제한 재시도 후 `safe_abort`, 웨이브 보상 없음, 준비 단계의 마지막 체크포인트 보존을 확인했다.
- 재실행 결과: Godot headless import, `tests/run.gd`, 콘텐츠 validator 모두 통과. 이 단계에서 시설/방어벽 파괴 및 실제 Android 화면 검증은 완료하지 않았다.
- 테스트 중 증원 대체 타일 검사에서 테스트 전제(기존 적 사망)를 잘못 설정해 assertion이 실패했다. 적을 출현 지점에 생존시킨 상태로 검사하도록 고친 뒤 전체 통과했다. Godot 스크립트 assertion 종료만으로 프로세스 코드가 실패로 전달되지 않을 수 있어 CI에서 성공 sentinel 출력도 필수 확인하도록 보강했다.
- 코드 점검 중 `safe_abort`도 일반 패배처럼 체크포인트를 삭제하던 UI 경로를 발견해 수정했다. 안전 종료는 체크포인트를 보존하고 이유를 구분해 표시하도록 변경했으며, 최종 재검증에 포함했다.
- 공성 시험 버튼을 메인 화면에 추가하고 공성 체크포인트 파일을 수성 저장과 분리했다. 최신 메뉴/씬 스크립트 포함 Android APK export가 통과했으며, 에뮬레이터의 GLES shader 제한 때문에 화면 확인은 여전히 미통과다.

## M2 방어벽 재검증 (2026-11-12)

- 방어벽을 정적 불가침 지형과 분리하고 HP/경로 장애물로 추가했다. 적은 우회 비용과 벽 접근·파괴·잔여 경로 비용을 비교하며, 우회가 불가능하면 벽을 공격한다. 파괴 시 경로가 다시 열리고, 체크포인트에 HP/파괴 상태를 저장한다.
- 통과: 벽 데이터 좌표/HP/충돌 검증, 막힌 복도에서 돌파 행동 선택 및 파괴, 부분 HP 저장·복원, 벽 필드가 없는 이전 체크포인트의 기본 HP 복원 테스트.
- 최종 재실행: Godot headless import, 테스트 sentinel, 콘텐츠 검사, 메인 씬, Android Debug APK export 및 `git diff --check` 모두 통과. 이번 APK의 실제 GLES 화면은 재검증하지 않았으며 기존 AVD shader 제한이 적용된다.

## 시설 시스템 (2026-11-12)

- 화살탑·마법탑·지원 초소·방어벽 4종을 카탈로그 데이터로 정의하고, 아군 시설의 유효 타일 건설·자원 차감, 재정비 무료 이동, HP/피해/파괴 상태 체크포인트 복원을 연결했다. 화살탑·마법탑은 범위 안 적을 자동 공격하고 적은 공격 가능한 아군 시설을 선택해 공격한다. 경로 차단 시설은 적의 우회/돌파 판단에도 참여한다.
- 통과: 잘못된 시설 스탯 검증, 중복 배치 무차감, 자원 지불, 타워 피해, 시설 피해/파괴, 방벽 설치 후 적 돌파 경로, 재정비 이동/전투 중 이동 거부, 손상·파괴 및 같은 칸 재건 저장/복원 테스트.
- 당시 테스트 시점에는 수리 정책 결정 전이라 기능을 추가하지 않았다. 2026-11-12 이후 사용자 결정으로 전투 중 수리를 허용했고 모델/UI 테스트를 추가해 검증했다. 지원 초소 효과 및 공성 적 시설 웨이브 처리도 미구현.
- 최종 개발 export: `build/holo-debug.apk` (86,268,535 bytes, Godot 4.7.2, target API 36 / min API 24) 생성 및 APK 서명/검증 통과. 이번 확인 시 API 36/37 ADB 에뮬레이터가 모두 offline 상태라 시설 UI가 포함된 APK를 기기에서 실행하지 못했다. 이전 API 37 GLES shader uniform 오류도 아직 해결/재검증되지 않았다.

## 지원 초소 및 재검증 (2026-11-12)

- 지원 초소의 임시 SEED 효과를 치유로 선택했다: HP 비율이 가장 낮은 유효 아군 유닛을 8 HP 회복, 초과 치유 및 부활 금지, 사거리 2, 1.5초 간격. 카탈로그 검증에서 치유량·유효 사거리·간격·아군 전용 조건을 검사한다.
- 자동 검사 통과: HP 절대값이 아닌 비율 기준 선택, 최대 HP 상한, 사망자 제외, 회복 대상이 없을 때 쿨다운 유지 안 함, 체크포인트 복원 시 카탈로그 기반 치유 효과 재구성, 잘못된 치유 사거리 거부.
- 전체 재검증 통과: Godot 4.7.2 headless editor import, `tests/run.gd` 성공 sentinel, 콘텐츠 validator, 기본 메인 씬 headless 실행.
- 최초 실행에서 비율 변수 타입 추론 파싱 오류와 테스트 fixture 자원 부족/웨이브 자동 완료 전제를 발견했다. 타입을 명시하고 테스트에 필요한 전투 자원 및 생존 적을 설정한 뒤 전체 재검증 통과했다.
- 치유 기능 포함 최신 소스의 Android Debug APK 내보내기/서명 검증 통과: `build/holo-debug.apk`, 86,272,631 bytes (2026-11-12 09:16 KST). ADB 실기기 실행은 수행하지 않았다. 앞서 기재한 AVD GLES 문제와 실기기 미검증 상태는 그대로다.

## 공성 적 시설 및 사전 배치 (2026-11-12)

- 웨이브 데이터에 적 시설 ID/좌표 배치를 추가하고, 참조 ID·진영·보드 경계·코어/장애물/방벽 충돌을 콘텐츠 검사에 연결했다. 테스트 웨이브에는 감시탑과 마법탑 임시 SEED 배치를 넣었다.
- 재정비에는 초기 적·적 시설을 별도 비활성 미리보기 배열로 배치하고, 웨이브 시작 때 활성 전투 배열로 옮겨 공격·피격 가능하게 했다. 적 시설은 범위 안 아군 유닛/시설을 공격하며 아군 유닛과 공격 시설도 적 시설을 공격할 수 있다. 일반 웨이브 종료 때 기존 적 시설은 제거되고 다음 웨이브 정의로 교체된다.
- 통과: 비활성 적과 시설 사전 배치/비행동, 웨이브 시작 활성화, 적 시설 양방향 피해, 웨이브 교체 및 저장 복원 미리보기 재구성; 잘못된 진영/좌표/초기·증원 스폰 충돌/누락 참조 콘텐츠 거부. 지원 초소 회복 테스트 포함해 headless 테스트 sentinel 통과.
- Godot 4.7.2 import, 전체 테스트, 콘텐츠 검사, 메인 씬 실행을 통과했다. 현재 Android APK는 직전 치유 커밋 기준이며 이 웨이브 변경 포함 APK export와 기기 확인은 재검증 대기다.
- 최종 Android Debug APK export/서명 검증 통과: `build/holo-debug.apk`, 86,272,631 bytes (2026-11-12 09:32 KST), API 36 target / API 24 minimum. API 29/37 AVD 프로세스는 한 차례 온라인으로 열거됐지만 APK 설치 전에 ADB 재시작 후 둘 다 offline으로 바뀌어 기기 실행 검증은 하지 않았다. 실기기 미검증.

## 마법탑 광역 공격 (2026-11-12)

- 마법탑은 사거리 안 최근접 적을 중심으로 맨해튼 반경 1타일에 광역 피해를 준다. 적마다 피해/사망·처치 보상을 개별 처리하고, 한 발당 쿨다운은 한 번 적용한다. 반경과 수치는 시드 밸런스다.
- 통과: 중심/인접 대상 동시 피격, 반경 밖 적 무피해, 광역 반경의 콘텐츠 검증, 체크포인트 복원 시 카탈로그에서 반경 재구성.
- Godot 4.7.2 headless import, 테스트 sentinel, 콘텐츠 검사, 메인 씬 실행 통과. 광역 공격 포함 Android Debug APK 내보내기 및 서명 검사 통과: `build/holo-debug.apk`, 86,276,727 bytes (2026-11-12 09:37 KST). 실기기/에뮬레이터 설치 확인은 미검증.

## 기본 유닛/적 11종 (2026-11-12)

- 카탈로그에 아군 검사·궁수·창병·지원병·마법사 5종, 적 고블린 전사/궁수·오크 전사/돌격병·적 마법사/지원병 6종과 각 적 AI 프로필을 등록했다. 시험 M1/M2 웨이브에 원거리 적, 오크, 적 지원병 증원을 배치했다.
- 배치 UI에 5종 선택을 노출하고, 각 유닛의 체력·공격·사거리·비용을 실제 전투 모델에 반영했다. 지원병은 범위 안 부상 아군 중 HP 비율 최저 대상을 초과 치유 없이 회복하고, 마법사는 중심 대상 주변에 광역 공격한다. 적 지원병/마법사에도 같은 기본 치유/광역 규칙을 적용했다. 전투 처치 보상은 고블린 종류에 한정하지 않고 적 진영 유닛 전반에 지급한다.
- 통과: 5종 실제 배치, roster 5/6 검증, 지원 치유와 쿨다운, 아군/적 마법사 광역 피격, 신규 유닛 체크포인트의 카탈로그 스탯 재구성, 비고블린 처치 보상 및 전체 M1 자동 플레이 테스트.
- 추가 능력치·비용·AI 가중치·광역/치유 수치는 `ISSUES.md`에 SEED로 기록했으며, 강화·진화·연구·마을/영구성장은 아직 구현하지 않았다.

## 스테이지별 유닛 해금 제한 (2026-11-12)

- 문서 대조에서 UI가 5종을 일괄 노출하던 구현이 `DECISIONS.md`/`R-GAME-006`의 진행 해금(시작 검사·궁수, M1 후 창병, M3 후 지원병, M4 후 마법사)과 불일치함을 확인했다.
- `stage.available_units`를 배치 UI와 전투 모델의 공통 입력으로 연결했다. 현재 시드 M1은 검사·궁수, M2는 창병까지 허용한다. Validator는 비어 있는 목록과 아군 외/누락/미참조 유닛을 거부한다. 나머지 유닛은 능력 테스트에서만 테스트 전용 목록으로 활성화한다.
- 통과: Godot 4.7.2 headless editor import, 테스트 성공 sentinel, 콘텐츠 validator, main scene 실행, Android Debug APK export/sign/verify 및 `git diff --check`.
- 최신 `build/holo-debug.apk`: 86,280,823 bytes, 2026-11-12 09:51 KST. APK Signature v2/v3 검증 통과.
- ADB: `emulator-5554`, `emulator-5556` 모두 offline. APK 설치·실행은 불가했고 실기기/Android 10 기기는 미검증이다. 이전 GLES2/GLES3 AVD 한계도 해결 증거가 없다.

## M3 개체별 전투 강화 (2026-11-12)

- 카탈로그의 다섯 기본 아군별 4개 강화(20개), 단계별 비용/효과 및 최대 3단계를 정의했다. 선택 유닛 UI에서 재정비·전투 중 구매할 수 있고, 개체 ID 기준 레벨이 유지된다. 강화는 공격 횟수/대상·범위·피해, 상태이상, 밀치기·반격·도발·감소, 치유 대상 범위·보호막·공격 버프·해제에 연결했다.
- 체크포인트에 강화 레벨과 마력 폭발 카운터를 저장한다. 복원 시 카탈로그에 정의된 유닛 전용 강화인지, 레벨이 1~3인지, 저장 스탯이 강화 레벨에서 재구성되는 값인지 검사한다. 체크포인트 밖의 상태이상/보호막은 복원 시 초기화하고 웨이브 사이 상태이상을 해제한다.
- 통과: 20개 강화 각각 3단계 구매/최대 제한, 전투 자원 차감, 다른 유닛 항목 거부, 피해 보너스/콤보/관통/빙결/3중첩 출혈과 지속시간, 방어/반격/밀치기/도발, 광역 치유·보호막·버프·해제, 마력 폭발, 강화 저장·복원과 변조된 레벨 거부 테스트.
- Godot 4.7.2 editor import, `tests/run.gd` sentinel, content validator, battle scene headless 실행을 통과했다. 수치·가격 및 스택 상한 초과 처리는 임시 SEED이며 `ISSUES.md`에 기록했다.

## M3 기본 스킬 (2026-11-12)

- 기본 아군 5종 자동/수동 스킬 각 1개(총 10개)를 콘텐츠로 정의했다. Validator는 효과 형식·수치·쿨타임·비용과 유닛별 모드 구성을 검사한다. 수동 스킬 UI는 선택 유닛에 연결했고, 자동 스킬은 유효 대상이 있을 때만 시전한다.
- 통과: 수동 발동 성공 시에만 비용 차감, 적 부재/쿨타임/자원 부족 발동 거부, 자동 시전 후 독립 쿨타임, 재정비 중 쿨타임 정지, 체크포인트 쿨타임 보존과 변조 초과값 거부; 전체 `tests/run.gd`, 콘텐츠 검증, battle scene headless 실행.
- 테스트 첫 반복에서 기존 validator fixture의 스킬 레코드가 새 스키마에 맞지 않아 실패했고, 전체 자동 시전이 구형 직접 생성 유닛 픽스처의 공격 결과도 바꿨다. 픽스처 스키마/시드 쿨타임을 보정한 후 최종 성공 sentinel로 재검증했다. 중간 반복에서 사전 생성 테스트 유닛의 cooldown map 누락 오류를 발견해 빈 맵 기본값 초기화로 수정했다.
- 재검증 통과: Godot 4.7.2 editor import, 전체 `tests/run.gd`, 콘텐츠 Error 0, battle scene headless 실행, `git diff --check`. Android debug export도 통과: `build/holo-debug.apk`, 86,301,303 bytes, 2026-11-12 10:36 KST, package `com.example.holotactics`, min API 24/target API 36, APK Signature v2/v3 확인.
- 첫 export 호출은 preset 이름을 `Android`로 지정해 실패했다. 프로젝트 preset 이름 `Android Debug APK`를 확인해 재실행했고 성공했다.
- Android 실기기/에뮬레이터 UI 검증은 이전 기록처럼 미해결이다. 스킬 및 강화 밸런스는 모두 초기 SEED다.

## 영구 진행 저장 기반 (2026-11-12)

- 버전 필드가 있는 영구 진행 JSON store를 추가했다: 영구 재화, 연구 ID, 완료 스테이지, 보상 이벤트 ID. 임시 파일 작성·flush 후 원자 교체하며 백업 이름 변경 중 교체 실패 시 이전 파일을 복구한다. 재화 보상은 이벤트 ID를 한 번만 허용한다.
- 통과: 최초 생성/로드, 보상 1회 지급·중복 거부, 다른 인스턴스에서 재로드, 음수 재화 저장 거부.
- 첫 파싱 검증에서 Godot JSON이 정수 표기를 float로 읽는 것을 발견했다. 적분 가능한 숫자는 유효값으로 수용하고, 로드 직후 통화와 보상액을 int로 정규화해 해결했다. 초기 테스트 픽스처 경로 변수 타입 추론 문제도 명시적 String 형식으로 수정했다.
- 최초 저장소 기반 커밋 당시에는 결과/연구가 미연결이었고, 다음 섹션에서 결과 정산을 연결했다. 연구 구매 통합과 버전 변경 마이그레이션/백업 복구 검증은 남아 있다.

## 결과 보상 정산 통합 (2026-11-12)

- 승리·패배·명시적 포기를 `ProgressStore`에 연결했다. 승리는 반복 기본 보상과 최초 클리어 보너스를 분리 합산하며, 패배/포기는 완료 웨이브 수만 계산한다. 전투 실행 ID를 체크포인트에 포함하고 성공 정산 이후에만 체크포인트를 지운다. 진행 저장을 읽지 못하면 정산을 거부해 손상 데이터 위에 초기 상태를 덮지 않는다.
- `BattleView`에 포기 확인, 결과 보상/잔액 표시, 마을 복귀 버튼 전이를 추가했다. 비정상 앱 종료는 이 포기 흐름을 실행하지 않고 기존 체크포인트 재개 방식을 따른다.
- 통과: 첫 클리어/반복 클리어/2웨이브 완료 부분 보상/0웨이브 패배/동일 실행 ID 중복 호출을 포함한 headless 테스트. 편집기 import, 전체 테스트, 카탈로그 검증, battle scene headless 실행 및 `git diff --check` 통과.
- 기존 스테이지의 영구 보상 수치 30/10/5와 40/12/6은 `ISSUES.md`의 임시 SEED다. 전체 캠페인 밸런스 값이 아니다.
- JSON 재로드는 통과했으나, 실제 화면에서 결과 모달과 저장 실패 안내를 터치 검증하지 않았다. Android 에뮬레이터의 기존 GLES/ADB 제한은 유지된다.
- 결과·영구 잔액 표시 변경 포함 Android debug export 통과: `build/holo-debug.apk`, 86,309,658 bytes, 2026-11-12 10:50 KST. Godot export 내 서명 검증이 통과했다. 최근 APK의 별도 ADB 설치/화면 조작은 실행하지 않았다.

## 캠페인 8개 스테이지·26웨이브 시드 (2026-11-12)

- PRODUCT_SPEC 5.2의 메인 6개/선택 2개와 웨이브 분배(2+3+3+4+4+4+3+3)를 카탈로그에 옮겼다. 메인 선행 조건과 S1/S2 선택 해금을 연결했다. 기본 유닛 단계 해금은 사용자 확인대로 스토리 진행 기반이다. 기존 `stage.m2.siege` 수직 슬라이스는 캠페인 슬롯에서 분리했다.
- Validator가 캠페인 규모·총 웨이브 수·순서를 검사한다. 통과: 캠페인 8개 모델 구성, 26개 웨이브 시작/체크포인트/다음 준비 단계/최종 종료 전이를 각 스테이지에서 자동 순회, 첫 웨이브 적 배치, 전체 stage 경로/참조/시설 검사, 콘텐츠 검사, main scene 실행. wave clear를 테스트에서 강제로 완료시킨 구조 검증이며 AI 격파 가능성/난이도를 증명하지 않는다.
- M1 최종 웨이브 테스트에 새로 정의된 예정 증원이 남아 있던 것을 발견해 테스트 픽스처를 종료 조건과 일치하도록 수정했다. 모델은 예정 증원이 남으면 웨이브를 완료하지 않는다.
- 실기 플레이·난이도 조정은 하지 않았다. 좌표/적/시설/보상은 스테이지 설계초안과 임시 SEED다.
- 최신 APK: `build/holo-debug.apk`, 86,313,754 bytes, 2026-11-12 11:04 KST. 새 캠페인 메뉴·8 stage·26 wave 포함 Godot Android export 및 `apksigner` v2/v3 검증 통과. package `com.example.holotactics`, target API 36/min API 24. Android 10 실기기/FPS와 현재 APK의 화면 터치 플레이는 미검증.
- GUI smoke를 위해 computer-use helper를 두 차례 재시도했으나 native pipe 연결 불가 오류로 실행 화면을 캡처하지 못했다. 따라서 메뉴의 시각 레이아웃은 headless 실행만 확인했다.

## 해금 목록 validator 경계 검사 (2026-11-12)

- 잘못된 스테이지 해금 목록이 유닛 누락·중복 또는 잘못된 `references` 형태를 가져도 validator가 충돌하지 않고 Error를 반환하는 회귀 검사를 추가했다.
- 통과: Godot 4.7.2 headless editor import, 전체 테스트 성공 sentinel, 콘텐츠 검사, `git diff --check`.

## 강화 기능 최종 재검증 및 Android export (2026-11-12)

- 통과: Godot 4.7.2 headless editor import, 전체 `tests/run.gd` 성공 sentinel, 카탈로그 validator, `scenes/battle.tscn` headless 실행, `git diff --check`.
- 최신 소스 APK: `build/holo-debug.apk`, 86,297,207 bytes, 2026-11-12 10:24 KST. `apksigner verify`에서 APK Signature v2/v3 통과.
- `aapt dump badging`: package `com.example.holotactics`, min API 24, target API 36. Android 10(API29)+에 설치 가능한 설정이나 API29 실행은 GLES2 전용 AVD 문제로 미검증이다.
- 현재 ADB 재확인: `emulator-5554`, `emulator-5556` 모두 offline. 새 강화 UI 포함 APK를 설치·터치 확인하지 못했다. API29/37 GLES 한계와 실제 Android 10·실기기 FPS 미검증은 그대로다.
- 실패/수정 이력: 새 UI 함수 삽입 위치가 `_refresh()` 내부 루프를 끊어 battle scene 파싱이 실패해 함수를 올바른 최상위 위치로 옮겼다. 비용 검증 테스트가 소환 비용을 포함하지 않아 기대 재화를 고쳤고, 빈 적 fixture가 웨이브 완료/회복을 유발해 비활성 생존 적을 추가했다. 최종 전 항목은 성공 sentinel로 재확인했다.

## Android device-test procedure

- `ANDROID_TESTING.md`에 APK 설치/로그 수집, 캠페인·저장 복원 검수, Godot Remote Profiler 및 `dumpsys gfxinfo` 성능 계측, Google Play 비공개 테스트 준비 항목을 정리했다.
- 이 문서는 재현 절차이며 실기기 검증 증거가 아니다. 물리 기기/Android 10 UI/FPS와 release AAB·Play 배포는 접근 권한이 없어 미실행이다.

## 2026-11-12 이어하기 재검증

- 통과: Godot 4.7.2 editor import 및 `content_editor.gd --check-only`, `tests/run.gd`, `tests/editor_preview.gd`, `scripts/validate_content.gd`, `git diff --check`.
- 추가 검사: Inspector용 `EditableCatalogRecord`의 동적 속성 get/set과 미등록 속성 거부를 자동 검사.
- 미검증: 실제 Inspector GUI 입력/JSON 가져오기/저장 버튼 조작. headless 검사는 스크립트 파싱과 모델 로직까지만 확인한다.

## 2026-11-12 추가 M6 재검증

- 통과: main, battle, village, village_research, editor_preview 5개 씬 headless smoke.
- 통과: 현재 저장소 소스로 Android Debug APK 재생성 (`build/holo-debug.apk`, 86,356,603 bytes, 2026-11-12 13:51 KST); apksigner v2/v3 서명 검증.
- UI 확인: computer-use 연결이 세션에서 native pipe unavailable로 실패하여 Godot 도크/Inspector의 시각·상호작용 검증은 수행하지 못했다.
- 여전히 대기: 실기기(Android 10+), FPS/P95, release AAB/Play 비공개 테스트. API 37 AVD의 GLES3 오류 기록은 해결되지 않았다.

## 2026-11-12 AVD 앱 시작 재검증

- API 29 / Android 10 AVD에 APK 설치는 성공했으나 실행 직후 `EGL_BAD_CONFIG: no ES 3 support`로 앱이 종료되고 홈 화면으로 돌아왔다. 해당 AVD는 GLES 2.0만 제공한다.
- API 37 AVD에서는 Godot가 GLES 3.0 SwiftShader로 시작하고 프로세스가 유지됐지만, `CanvasShaderGLES3` fragment shader가 `GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)` 오류를 반복했고 캡처 화면은 검은색이었다. 실제 게임 UI 구동은 실패로 판정한다.
- 결론: AVD 시작/설치 자체는 가능하나 Android 실행 수직 슬라이스는 통과하지 못했다. Android 10+ 실기기 GLES3 확인과 API 37 shader 문제의 분리가 필요하다.

- 보강: 사용자 결정으로 확정한 스토리 단계별 기본 유닛 해금 순서(검사·궁수 → 창병 → 지원병 → 마법사)가 스테이지 `available_units` 카탈로그에 유지되는지 `tests/run.gd` 회귀 assertion으로 확인.

## 2026-11-12 렌더러 분리 실험

- 공식 Godot 이슈 [#109550](https://github.com/godotengine/godot/issues/109550)은 Godot 4.7.2 + Android Emulator SwiftShader에서 동일한 261-vector 로그를 재현하며 SwiftShader의 GLES3 불완전 구현을 지적한다. 이 경고만으로 실기기 실패를 단정하지 않는다.
- Android 10 API 29 Compatibility 렌더러는 GLES 3.0이 필요하지만 현재 AVD 이미지는 GLES 2.0만 제공해 실행 실패가 예상 범위다.
- 비교용 Mobile/Vulkan 변형 APK export까지 성공했으나 설치 시 API 37 AVD가 offline이어서 비교 실행은 성립하지 않았다. 임시 설정/산출물은 제거하고 Compatibility 설정을 복원한 뒤 기본 APK를 재생성·서명 검증했다.

## M5 오류 탐색 재검증

- 통과: editor import/플러그인 스크립트 parse check, 전체 `tests/run.gd`, `tests/editor_preview.gd`, 카탈로그 validator.
- 추가 검사: Error 메시지에서 가장 구체적인 stable ID를 찾고, 글로벌 오류/잘못된 categories는 안전하게 빈 ID를 돌려준다. 오류 이동 시 저장 전 패널 초안을 ID별로 유지하도록 구현.
- 미검증: GUI에서 ItemList 클릭 후 실제 탭/레코드 이동, Inspector 동기화 및 저장 UX. field path는 오류 메시지에 표시되나 Inspector의 특정 속성 자동 포커스는 없다.

- M5 오류 탐색 변경 포함 Android APK 재내보내기 통과: `build/holo-debug.apk`, 86,352,507 bytes (2026-11-12 14:10 KST). apksigner v2/v3 검증 통과. EditorPlugin은 런타임 게임 흐름을 바꾸지 않으며 실제 GUI는 여전히 미검증이다.

## 2026-11-12 M4 결과 화면

- 통과: `tests/results_view.gd`의 전용 결과 패널 UI-state 검사(승리/정산 재화, 안전 종료/체크포인트 안내, 정산 저장 실패 시 복귀 버튼 잠금).
- 통과: Godot editor import, `tests/run.gd`, `tests/editor_preview.gd`, `scripts/validate_content.gd`, main/battle/village/village_research/editor_preview 씬 smoke.
- 통과: 최신 결과 화면 포함 Android Debug APK 재생성 (`build/holo-debug.apk`, 86,356,758 bytes, 2026-11-12 14:18 KST); apksigner v2/v3 서명.
- 미검증: 결과 패널의 실제 기기/GUI 시각 배치와 버튼 상호작용. 실기기/FPS 미검증은 계속 유지한다.
# 2026-11-12 Validator field-path 보강

- 환경: Godot 4.7.2 stable, Windows, headless.
- 통과: editor import, validator `--check-only`, `tests/run.gd` (연구 amount 오류의 정확한 `research.swordsman.damage.amount` 경로 포함), `tests/editor_preview.gd`, `tests/results_view.gd`, `scripts/validate_content.gd`, `git diff --check`.
- 범위 제한: 편집기 GUI 사용성, Android 실기기 렌더링/FPS는 이 실행에서 확인하지 않음.

## 2026-11-12 Validator malformed facility 회귀

- 재현: `facility.arrow_tower.damage = "invalid"`일 때 기존 후속 비교가 Godot 런타임 오류를 냈다.
- 수정/검증: 관계 검사를 유효한 숫자 타입에 한정하고 `damage`, `heal`, `splash_radius`, `range`, `attack_time` 각각 문자열 입력에서 필드 오류를 반환하는 테스트를 추가.
- 통과: editor import, validator parse, 전체 `tests/run.gd`, `tests/editor_preview.gd`, `tests/results_view.gd`, 콘텐츠 Error 0, 5개 씬 smoke, `git diff --check`.
- Android: APK 86,360,854 bytes (2026-11-12 14:36 KST), apksigner v2/v3 검증 통과. ADB emulator-5554/5556은 offline. 물리 기기/FPS 미검증.

## 2026-11-12 M2 불가침 장애물

- 콘텐츠 Validator: obstacle data 필수 필드와 스테이지 보유/배치 한도·참조 검증 통과. 현재 시드 `obstacle.barricade` 비용 20, 보유 3, 동시 배치 2는 테스트용.
- `tests/run.gd`: 최초 비용/보유·배치 상한, 자원 미차감 실패, 타일 점유·A* 우회, 회수 및 재배치 무상/전투 중 이동·회수 거부, 체크포인트에서 배치/보관 상태와 자원 복원을 검사.
- `tests/results_view.gd`: M2 battle view에 장애물 도구가 생성되고 설치→회수→저장 개체 선택→재설치가 동작하는 상태 검사.
- 통과: 전체 headless 모델·미리보기·화면 테스트, 콘텐츠 검증, main/battle/village/village_research/editor_preview 씬 smoke, diff 검사.
- Android Debug APK 갱신 통과: `build/holo-debug.apk`, 86,364,950 bytes (2026-11-12 15:03 KST), apksigner v2/v3 검증. Debug 서명이라 Play 업로드용은 아니다. AVD offline 및 실기기/FPS 미검증 상태 유지.

## 2026-11-12 이동 유형 데이터 계약

- UnitData 11종에 `movement_type: ground`, obstacle 정의에 `blocked_movement_types: [ground]`를 명시했다. Validator가 누락/미지원 이동 유형을 거부하고, 경로 검사와 A*에서 장애물 유형을 반영한다. 세이브 복원 시 기존 스냅샷은 기본 ground로 이어지고, 저장된 유형이 카탈로그와 다르면 거부한다.
- 통과: editor import, validator parse, 전체 모델·에디터 미리보기·전투 UI 테스트, 콘텐츠 검사, 5개 씬 smoke, `git diff --check`.
- APK 갱신: 86,369,046 bytes (2026-11-12 15:14 KST), apksigner v2/v3 서명 검증 통과. Debug 서명, 실기기/FPS 및 Play 업로드 미검증.
- 후속 회귀 추가: 이동 유형이 없는 레거시 유닛 스냅샷은 `ground`로 복원되고, 카탈로그와 불일치하는 명시 유형은 복원을 거부한다. `tests/run.gd` 통과.

## 2026-11-12 Android AVD 재검증

- 최신 Debug APK 설치는 API 29/37 AVD 모두 성공했다. API 29 실행은 GLThread `createContext failed: EGL_SUCCESS`로 중단; API 37은 Godot `GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)` 초과를 기록했다.
- 별도 API 36 AVD는 설정 경로가 가리키는 SDK 시스템 이미지가 없어서 시작하지 못했다. 실기기/FPS는 미검증이며, APK 설치 성공은 Android 호환성 통과로 계산하지 않는다.

## 2026-11-12 진화 콘텐츠 편집 스키마

- 카탈로그 진화 탭에 기획서의 6형태를 등록했다. Validator는 형태 수, 아군 기본 유닛, 같은 유닛의 강화 ID/단계, 총 강화 단계, 양수 전투 비용, 특수 스킬 필드를 검사하고 오류 필드 경로를 반환한다.
- 통과: `tests/run.gd`(잘못된 유닛 강화 참조·특수 스킬 형태/쿨타임·0 비용·누락 형태), `tests/editor_preview.gd`, `tests/results_view.gd`, 콘텐츠 검증, `git diff --check`.
- 한계: 이름·조건·비용·특수 스킬 수치는 제안/임시 SEED다. 연구 해금과 전투 적용, 실제 Godot GUI 조작은 아직 검증되지 않았다.
- 추가 통과: Godot headless 편집기 초기화/플러그인 로드와 main/battle/village/village_research/editor_preview 5개 씬 smoke. 최신 소스로 Android Debug APK 재생성 및 apksigner v2/v3 검증 통과: 86,369,046 bytes (2026-11-12 15:34 KST). 에뮬레이터 렌더 실패와 별개로 실기기 검증은 미완료.

## 2026-11-12 캠페인 8스테이지 시드 플레이 검사

- 신규 `tests/campaign_playability.gd`가 메인 6·선택 2 스테이지를 순서대로 실제 `BattleModel`에 로드한다. 의존 스테이지 완료를 확인하고, 로스터에 맞춘 유닛 배치·공성 수동 이동·재정비 증원으로 전 웨이브를 승리한 뒤 `ProgressStore` 정산·완료 저장·중복 보상 방지를 확인한다.
- 통과: `All 8 campaign stages won in the seeded playability simulation`. GitHub Actions에도 별도 단계로 추가했다.
- 범위 제한: 게임 UI 없이 스테이지 ID를 직접 실행하므로 마을 UI/수동 조작 흐름은 검증하지 않는다. 한 개의 자동 전술 시드는 승리 가능성 증거이며 전체 전략 밸런스 승인은 아니다.

## 2026-11-12 continuation regression

- Godot 4.7.2 headless editor import, `tests/run.gd`, `tests/editor_preview.gd`, `tests/results_view.gd`, `tests/campaign_playability.gd`, and `scripts/validate_content.gd` all passed on commit `855590a`.
- The export script's PowerShell parser check passed; APK manifest confirms min API 29/target API 36 and apksigner confirms v2. Test AAB contains bundle config, base manifest, and dex, but `jarsigner` reports it unsigned.
- Physical-device rendering/FPS, publisher-key AAB signature, and Play Console upload remain unverified.

- 편집기 GUI 직접 확인 재시도는 Computer Use native pipe 초기화 오류로 중단됐다(창 상태/플러그인 상호작용 증거 없음). 별도로 disposable signing key 생성이 자동 검토에서 차단돼 release signing 검증은 진행하지 않았다.

## 2026-11-12 checkpoint restore atomicity

- `BattleModel.restore()` previously applied permanent research before validating checkpoint versions and contents. A rejected snapshot could therefore mutate research and unit balance on the live model.
- Changed restore to build a temporary research/balance state, validate unit upgrades against that state, and commit research plus combat state only after all checks pass. Added regression coverage for both unsupported schema and malformed unit stats.
- First test run exposed `_apply_unit_upgrades()` reading the live model balance; it now accepts the candidate balance for restore validation. Re-run passed: editor import, `tests/run.gd`, campaign playability, and content validator. `git diff --check` passed.

- After the checkpoint restore fix, Android Debug APK was re-exported successfully from the updated source: `build/holo-debug.apk`, 249,871,658 bytes (2026-11-12 16:15 local). `aapt` confirmed min API 29/target API 36; `apksigner` confirmed v2=true and v3=false. This is a debug APK, not Play release evidence.

- 추가 회귀: 직접 `ProgressStore.load_progress()`에 잘못된 JSON을 넣었을 때 로드 실패, 기존 메모리 재화 777 유지, 원본 파일 `{}` 보존을 확인했다. Godot 4.7.2 `tests/run.gd` 통과.

- R-SAVE-006 보강: permanent research가 저장된 체크포인트에 대해 `content_version`, `schema_version`, `save_version` 각각을 독립적으로 증가시켜 복원 거부와 모델 무변경을 확인했다. malformed unit stat 거부도 함께 유지되며 `tests/run.gd` 통과.

- 최신 M6 코드로 Debug AAB 재생성: `build/holo-test.aab`, 86,280,839 bytes (2026-11-12 16:23 local). `jar tf`에서 `BundleConfig.pb`, `base/manifest/AndroidManifest.xml`, `base/dex/classes.dex` 확인. `jarsigner`는 `jar is unsigned`를 반환했다. 이는 패키징 smoke test이며 release 서명/AAB 또는 Play 준비 완료 증거가 아니다.

## GitHub Actions Android export job

- `.github/workflows/validate.yml`에 Android SDK/API 36, Godot 4.7.2 export template 및 Gradle template을 이용한 Debug AAB packaging job을 추가했다. CI verifies bundle config, base manifest, and dex, then uploads `holo-debug-aab-unsigned` for 7 days.
- Locally: official actionlint v1.7.12 binary checksum-list digest and archive checksum were verified before execution; actionlint passed. Actual GitHub-hosted execution is pending repository/Actions access. This artifact is not a signed Play release.

- Android AAB manifest 직접 검사: Google bundletool 1.18.3 `dump manifest --bundle=build/holo-test.aab` 출력에서 `android:minSdkVersion="29"`, `android:targetSdkVersion="36"`을 각각 assert하여 통과했다. 번들 파일 자체가 Android 10+ manifest 조건을 충족함을 확인했다. 이 검사는 unsigned Debug AAB만 대상으로 하며 release 서명/Play 업로드를 입증하지 않는다.

## 2026-11-12 battle speed control (R-GAME-005)

- Added a 1×/2× battle speed control. New stages and isolated editor previews remain locked to 1×. Previously completed stage IDs from `ProgressStore` unlock 2× on re-entry; battle ticks remain fixed at 0.2 s while timer cadence and intermission countdown scale.
- First test run found a GDScript type inference parse error on the unlock boolean; explicitly typed it as `bool`. Re-run passed: editor import, `tests/results_view.gd`, `tests/run.gd`, campaign playability, and content validation; `git diff --check` passed.
- R-UI-003 pause/read-only inspection was completed and verified in the following entry.

## 2026-11-12 R-UI-003 일시정지 재검증

- 일시정지 UI는 타이머의 잔여 시간을 보존하며 전투 명령 버튼과 직접 호출 핸들러를 차단한다. 타일 조회는 선택/배치 상태를 변경하지 않고 대상 정보를 status에 출력한다.
- 회귀: `tests/results_view.gd`에서 준비 단계 시작/명령 차단/핵심 정보 조회/전투 자원 불변/재개, 재정비 타이머 잔여시간 재개를 확인했다.
- 통과: Godot 4.7.2 headless editor import, `tests/results_view.gd`, `tests/run.gd`, `tests/editor_preview.gd`, `tests/campaign_playability.gd`, `scripts/validate_content.gd`, `git diff --check`.
- 제한: 실제 기기 터치/화면 배치 및 성능은 이전 Android 렌더러/기기 접근 차단 상태로 검증되지 않았다.

- R-UI-003 포함 Debug APK 재생성: `build/holo-debug.apk`, 249,875,578 bytes (2026-11-12 16:51 KST); `aapt` min API 29/target API 36, `apksigner` v2=true 확인. 실기기 실행과 FPS는 미검증.

- R-UI-003 반영 AAB 재검증 (2026-11-12 16:55 KST): `build/holo-test.aab`, 86,284,601 bytes. bundletool 1.18.3 `validate` 성공; `BundleConfig.pb`, `base/manifest/AndroidManifest.xml`, `base/dex/classes.dex` 존재; base manifest minSdk 29/targetSdk 36 확인. `jarsigner`는 unsigned로 보고함. release 서명/Play 업로드 검증은 아님.

## 2026-11-12 R-UI-002 컨텍스트 패널

- 강화/수동 스킬을 화면 하단 공통 행에서 선택 아군 옆 플로팅 컨텍스트 패널로 재배치했다. 화면 가장자리에서 좌우/상하 위치를 반전·제한한다. 선택 시설은 주변 패널에 HP 및 이동 안내를 표시한다.
- `tests/results_view.gd`: 유닛/시설 컨텍스트 표시, 강화 컨트롤 소속, 메뉴 bounds, 일시정지 시설 조회 검사 통과.
- Godot 4.7.2 editor import, 결과/UI 테스트, 전체 모델 테스트, editor preview 격리, 8-stage seeded playability, 콘텐츠 validator 및 `git diff --check` 통과.
- 한계: 실제 화면 비율/터치 상호작용 미검증. 시설 수리·강화 UI는 해당 기능 및 수리 정책이 구현되지 않아 미포함이므로 R-UI-002는 부분 충족 상태다.

- R-UI-002 반영 Android artifacts (2026-11-12): Debug APK `build/holo-debug.apk`, 249,877,422 bytes; `aapt` min API 29/target API 36, `apksigner` v2 signature true. Test AAB `build/holo-test.aab`, 86,286,445 bytes; bundletool 1.18.3 validation pass and manifest min API 29/target API 36. AAB is unsigned. Both artifacts are local/ignored; neither proves physical device rendering or performance.

- 기본 유닛 해금 충돌 회귀: 사용자 승인된 순차 해금 정책을 캠페인 테스트에 명시했다. 시작/M2/M4/M5 스테이지의 유닛 구성과 직전 시점 잠금을 확인한 뒤 전체 8개 stage seeded playability 통과.

- 시설 컨텍스트 도움말을 전투 단계별로 분기(재정비에서만 이동 가능)하고 preparation/combat 문구 회귀를 추가했다. Godot editor import와 `tests/results_view.gd` 통과.

- 2026-11-12 R-UI-002 문구 수정 반영 Android 산출물 재생성: APK `build/holo-debug.apk` 249,877,946 bytes (API 29/36, v2 signature true); AAB `build/holo-test.aab` 86,286,970 bytes (bundletool 1.18.3 validate, BundleConfig/base manifest/dex 존재, API 29/36). AAB는 unsigned이며 publisher release/Play 업로드용이 아님.

- 세로 모바일 레이아웃 회귀: `tests/results_view.gd`가 보드가 ScrollContainer 바깥에 남고 공통 조작부가 그 내부에 있으며 세로 scroll range가 생기는지 assert한다. 360×640 클래스 화면에서의 실기기 가시성/노치 터치는 `ANDROID_TESTING.md`에 추가했으며 미검증이다. 전체 headless/콘텐츠 검증 통과.

- 최신 세로 전투 레이아웃 Android 빌드 (2026-11-12 17:20 KST): APK 249,879,210 bytes, min API 29/target 36 및 apksigner v2 확인. AAB 86,288,227 bytes, bundletool 1.18.3 validate 성공, 필수 BundleConfig/manifest/dex 엔트리 및 API 29/36 확인. `jarsigner`는 unsigned로 보고. 기기에서 스크롤/노치 동작 및 FPS는 미검증.

- 전투 UI 크기 회귀를 실제 `360×640` root window로 고정해 재실행했다. 보드 고정/조작부 overflow/컨텍스트 메뉴 경계 검사가 모두 통과했으며 전체 회귀와 validator도 재통과했다.

- 고정 pause 푸터 변경 포함 Android Debug APK `build/holo-debug.apk` 249,879,286 bytes; API29/target36 및 v2 서명 확인. AAB `build/holo-test.aab` 86,288,306 bytes; bundletool validate/manifest 통과, unsigned. 실제 화면·기기 실행은 미검증.

## 2026-11-12 진화 영구 연구 해금

- `data/catalog.json`에 6개 진화 형태별 연구를 추가했다. 검사/궁수는 M1 시점, 창병은 M2, 지원병은 M3, 마법사는 M4 완료 이후 연구 가능하도록 스토리 조건을 연결했다. 훈련소/마법 연구소 소속은 기본 유닛 연구 분류와 일치한다.
- 연구 비용 100은 임시 SEED이며 전투 진화 비용과 별개다. 구매 ID는 영구 저장되고 `BattleModel.set_permanent_research()` 및 체크포인트 복원에서 해금 목록을 재구성한다. Validator는 미연결/중복/잘못된 유닛 진화 연구를 Error 처리한다.
- `tests/run.gd`에서 구매 조건·재구매 방지·비용·6형태 매핑·체크포인트 복원을 확인했다. `tests/results_view.gd`에서 360×640 연구 목록 스크롤을 확인했다.
- 분기 선택과 재진화, 실제 전투 변신/특수 스킬 적용은 결정 대기라 미구현이다.


## 2026-11-12 재검증: 진화 연구 해금

- Godot 4.7.2 headless: tests/run.gd, tests/results_view.gd, tests/editor_preview.gd, tests/campaign_playability.gd, scripts/validate_content.gd 모두 성공. 8개 캠페인 스테이지 시뮬레이션 통과. git diff --check 통과.
- Android APK 재생성: 249,881,554 bytes, min API 29 / target API 36, APK Signature Scheme v2 검증 성공.
- Android AAB 재생성: 86,290,465 bytes, bundletool 1.18.3 validate 통과, manifest min API 29 / target API 36 확인. unsigned 테스트 번들.
- 참고: 첫 bundletool XPath 조회는 element 반환 미지원으로 실패했으나 전체 manifest 출력 방식으로 재확인했다. 실제 Android 기기 실행/FPS, release signing 및 Play 업로드는 검증하지 않았다.


## 2026-11-12 재검증: 진행 저장 백업 복구

- tests/run.gd 백업만 남은 진행 저장 복구 회귀 통과. results_view.gd, editor_preview.gd, campaign_playability.gd, validate_content.gd 통과.
- Godot 4.7.2 headless editor에서 콘텐츠 플러그인 초기화 오류 없음. main/battle/village/village_research/editor_preview 씬 smoke 통과.
- Android APK 249,881,626 bytes: min API 29, target API 36, APK v2 서명 통과.
- Android AAB 86,290,543 bytes: bundletool 1.18.3 validate 통과, manifest API 29/36, unsigned임을 확인.


## 2026-11-12 재검증: 콘텐츠 Warning 정책

- 기본 26웨이브 시드는 Error/Warning 없음. 유효한 27웨이브 변형은 validate() Error 0건 및 조정 목표 초과 Warning 1건을 낸다. 6+2 스테이지 수 누락은 Error로 유지됨을 회귀 테스트로 확인.
- tests/run.gd, results_view.gd, editor_preview.gd, campaign_playability.gd, validate_content.gd, editor plugin headless load 모두 통과. 주요 씬 smoke/diff check 포함.
- 최신 APK 249,882,822 bytes(API29/36, v2 통과), AAB 86,291,741 bytes(bundletool validate, manifest API29/36 통과, unsigned).


## 2026-11-12 재검증: Android export 자원 제외

- APK 249,823,557 bytes. manifest min API 29/target API 36, APK v2 서명 통과.
- AAB 86,231,323 bytes. bundletool 1.18.3 validate, manifest API 29/36 통과; unsigned 테스트 번들.
- APK sparse PCK에서 tests/, content_editor, editor_preview 씬/런처가 제외되고 런타임 ContentValidator는 포함됨을 확인. 5개 핵심 테스트 및 diff check 통과.
- SDK adb: emulator-5554/5556 offline, 연결 기기 없음.


## 2026-11-12 최신 APK AVD 실행 재확인

- adb server 재시작으로 기존 API29/API37 AVD의 offline 상태가 해소됐다. API37 device 부팅 완료, 화면 1080×2400 density 420.
- 최신 APK streamed install 성공. Godot 앱 pid가 실행 중이고 launcher activity가 resumed 상태.
- 캡처 화면은 검정. logcat에서 GLES3 SwiftShader OpenGL ES 3.0 및 `GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`로 SceneShaderGLES3/CanvasShaderGLES3 연결 오류가 발생했다. API37 AVD 렌더 검증 실패; 실제 Android 기기 성능 검증은 별도 대기.


## 2026-11-12 재검증: 콘텐츠 저장 백업 복구

- tests/run.gd에서 EditorPlugin의 저장된 카탈로그 경로에 본 파일 없이 .bak만 남은 상태를 만들고 복구 데이터 및 경로 복원을 확인했다.
- headless EditorPlugin 초기화, editor preview 격리, 콘텐츠 validator 통과. `git diff --check` 통과.
- 변경은 editor-only 플러그인과 tests 디렉터리에 한정되어 Android export 제외 규칙에 따라 APK/AAB 재생성은 생략.


## 2026-11-12 재검증: 재시작 전투 복원 진입

- tests/run.gd에서 기본/스테이지별 checkpoint 경로 규칙, 격리된 폴더의 체크포인트 발견/없음 동작을 검사.
- tests/run.gd, results_view.gd, editor_preview.gd, campaign_playability.gd, 콘텐츠 validator 및 main 씬 smoke 통과.
- 런타임 변경 반영 APK 249,824,537 bytes (min API29/target36, v2 통과), AAB 86,232,303 bytes (bundletool validate 및 API29/36 manifest 통과, unsigned).
- Main→Battle 실기기 화면/복원 카운트다운은 현재 AVD SwiftShader 화면 렌더 실패 때문에 검증 대기.


## 2026-11-12 재시작 체크포인트 백업 보완

- `tests/run.gd`가 `.bak`만 있는 스테이지 체크포인트를 만들고 latest-stage 검색 시 primary 파일 복구 및 해당 stage 감지를 확인.
- APK 249,824,589 bytes: min API 29/target 36, v2 signature true.
- AAB 86,232,352 bytes: bundletool 1.18.3 validate 통과, manifest API 29/36 확인, unsigned.


## 2026-11-12 세로 UI 크기 회귀

- `tests/results_view.gd`의 SubViewport 시나리오: 320×568, 360×640, 412×915. 각 해상도에서 문맥 메뉴와 고정 pause 버튼이 화면 안에 있고 컨트롤 스크롤 영역이 보이는지 확인.
- tests/run.gd, results_view.gd, editor_preview.gd, campaign_playability.gd, validate_content.gd 모두 통과. `git diff --check` 통과.
- 화면 비율 headless 검사는 기기 픽셀 밀도, 시스템 안전 영역, 실제 터치 반응을 대신하지 않는다.


## 2026-11-12 Main campaign layout

- `tests/run.gd`: 320/360/412px viewport에서 캠페인 버튼 2개의 총 최소 폭이 viewport를 넘지 않는지 검사. `scenes/main.tscn` smoke 통과.
- 전체 필수 테스트(run/results_view/editor_preview/campaign_playability/content validator) 통과.
- APK 249,824,757 bytes: min API29/target36, v2 검증 통과. AAB 86,232,522 bytes: bundletool 1.18.3 validate, manifest API29/36 통과, unsigned.

## 2026-11-12 stale catalog backup 회귀 검사

- 통과: tests/run.gd (유효 주 파일 + stale backup 정리, 오류 주 파일 + backup 보존).
- 통과: editor_preview.gd, results_view.gd, campaign_playability.gd (8개 스테이지), validate_content.gd, headless editor import, editor_preview.tscn smoke, git diff --check.
- 실행 엔진: Godot 4.7.2 stable, Windows headless. Android 산출물은 에디터 플러그인/테스트 전용 변경이라 재생성하지 않음.

## 2026-11-12 규칙 결정 후 검증

- 통과: tests/run.gd — 수성 아군 0명/core 생존 계속 진행; 전투 중 시설 수리 비용 차감, HP 복구, 중복 수리 차단.
- 통과: tests/results_view.gd — 손상된 시설 선택 시 전투 중 수리 버튼 활성화 및 HP 복구.
- Android AVD: API29에서 APK 설치 후 GLES3 EGL 시작 실패, 앱 Activity 미유지. API37에서 설치/foreground 성공이나 캡처 화면 검정, CanvasShaderGLES3 GL_MAX_FRAGMENT_UNIFORM_VECTORS (261) 오류 재현. 실기기 호환성/렌더 합격으로 취급하지 않음.
## 2026-11-12 진화 전투 적용 회귀

- 통과: tests/run.gd — 연구 해금·강화 조건·비용 검증, 개체 ID/위치/강화 보존, 재진화 및 궁수 분기 교체 차단, 자동/수동 특수 스킬, 쿨타임과 진화 체크포인트 복원, 잘못된 진화 상태의 원자적 거부, SaveVersion 1 비진화 저장 호환.
- 통과: tests/results_view.gd — 진화 버튼, 형태 표시, 특수 스킬 UI 실행.
- 통과: editor_preview.gd, campaign_playability.gd (8개 스테이지 승리), validate_content.gd, main/battle/village 씬 smoke, git diff --check.
- 실행 환경: Godot 4.7.2 stable, Windows headless. 런타임 변경 후 Android APK/AAB export 예정.
## 2026-11-12 진화 반영 Android 산출물

- Android Debug APK: 249,828,753 bytes. API 29 minimum / API 36 target manifest 확인, apksigner v2 signature pass.
- Android test AAB: 86,236,526 bytes. Google bundletool 1.18.3 validate 통과, base manifest API 29 / target 36 확인. 테스트 AAB는 unsigned.
- API 37 AVD: 최신 APK 설치 성공, Godot Activity foreground 유지. 화면 캡처는 검정이며 CanvasShaderGLES3 fragment uniform 261 오류 반복. 플레이/렌더 검증 실패.
- 실제 Android 기기 실행/FPS, release keystore 서명, Google Play 비공개 테스트는 여전히 미검증.- 추가 smoke: village_research.tscn, editor_preview.tscn headless 실행 통과.

## 이어하기 문서 상태 정정 (2026-11-12)

- ISSUES/PROGRESS의 과거 문구 중 수성 승패, 진화 고정, 전투 중 수리를 여전히 미결정·미구현으로 표기한 항목을 최신 사용자 결정 및 구현 결과에 맞게 정정했다. 원본 기획 4종은 수정하지 않았다.
- Godot 4.7.2 headless `tests/run.gd: 통과. `scripts/validate_content.gd`: 통과 (콘텐츠 Error 0). `git diff --check`: 통과.
- 범위: 문서 상태 정합성만 수정. Android 산출물은 코드 변경이 없어 재생성하지 않았다.

## 2026-11-12 Android Vulkan AVD 재검증

- `project.godot`의 Android 모바일 전용 렌더러를 `mobile`(Vulkan)로 바꿨다. 데스크톱 기본 렌더러는 Compatibility로 유지했다.
- Godot 4.7.2 Debug APK: 249,828,829 bytes. aapt: package `com.example.holotactics`, min API 29 / target API 36. apksigner v2 검증 통과.
- Debug AAB: 86,236,623 bytes. Google bundletool 1.18.3 `validate` 통과. unsigned이며 Play 출시 서명 증거가 아니다.
- API 37 AVD (1080×2400/density 420): APK 설치 및 foreground 실행, Vulkan 1.2 SwiftShader, 캠페인 메뉴 캡처, ADB 터치 후 M1 수성 보드 캡처 통과. 검사 유닛 두 기를 터치 배치해 보드 glyph와 자원 차감(160→60)을 확인했고 Activity가 유지됐다.
- API 29 AVD: APK 설치/Activity 진입은 되지만 Vulkan present `VkResult error 5`가 발생해 화면 렌더 검증 실패. 이 에뮬레이터의 GPU 경로 결함일 수 있으므로 실기기 결론으로 일반화하지 않는다.
- API 37의 첫 시작 구간 gfxinfo는 17 frames, 11 janky, p50 61ms/p90 300ms. 이는 짧고 시작 구간에 한정된 샘플이며 일반 전투 60FPS 또는 고부하 30FPS 성능 측정은 여전히 미실시.
- 재검증: `tests/run.gd`, `tests/results_view.gd`, `tests/editor_preview.gd`, `tests/campaign_playability.gd`(8개 스테이지), `scripts/validate_content.gd` 모두 통과. main/battle/village/village_research/editor_preview headless smoke 통과.

## API 37 AVD 수성 수동 전투 흐름 (2026-11-12)

- 실제 Android 화면 터치로 캠페인→M1, 검사 2기 배치(전투 자원 160→60), 웨이브 시작을 수행했다.
- 1웨이브 뒤 유닛이 모두 사라진 상태에서도 핵심 HP 300으로 2웨이브 재정비 단계에 진입했다. 2웨이브 중 핵심 HP가 188, 76으로 감소하는 동안에도 전투 상태가 유지됐다. 핵심 HP가 0이 된 뒤에만 패배 결과가 나타났다. 최신 사용자 결정 “수성은 핵심 생존 시 계속 진행”의 실제 화면 회귀 증거다.
- 결과 패널은 완료 웨이브 1/2, 부분 보상 +5, 잔액 105를 표시했다. 이 결과는 실패 정산 정책 및 결과 UI 표시까지 확인하지만 승리·마을 복귀 전체 흐름의 실기기 인수는 아니다.
- 테스트 장치는 API 37 Android Emulator / Vulkan SwiftShader이며 물리기기가 아니다. 터치 시나리오와 렌더 표시만 검증했고 FPS 목표는 검증하지 않았다.

## API 37 앱 재시작 체크포인트 복원 (2026-11-12)

- M1 1웨이브 전투 도중 Android 앱을 force-stop하고 다시 실행했다. 앱은 캠페인 메뉴 대신 진행 중이던 M1 전투로 직접 복귀했다.
- 재개 화면에서 같은 웨이브, core HP 300, 생존 검사 및 남은 적, 전투 자원을 표시하고 전투를 계속했다. 비정상 종료가 포기로 처리되지 않고 저장된 전투를 복원하는 경로를 AVD에서 확인했다.
- 영구 잔액 105도 앱 재시작 뒤 캠페인 메뉴에 유지됨을 확인했다. 증거는 API37 AVD Vulkan SwiftShader이며 물리 Android 데이터 마이그레이션/기기 다양성 검증은 아니다.

## Android renderer 후속 회귀 및 편집기 연결 재시도 (2026-11-12)

- Godot 4.7.2 headless editor/plugin 초기화 통과. `tests/run.gd`, `tests/results_view.gd`, `tests/editor_preview.gd`, `tests/campaign_playability.gd`(8/8), 콘텐츠 validator 모두 통과; 콘텐츠 Error 0.
- Computer Use 연결은 native pipe 누락 파일, browser host unavailable로 다시 실패했다. 이번 시도는 GUI 클릭·시각 편집 테스트 증거가 아니며 M5 GUI 검증을 대신하지 않는다.
- 코드/설정 변경이 없으므로 APK/AAB는 다시 생성하지 않았다. 현재 APK/AAB 증거는 2026-11-12 Android Vulkan 섹션을 참조한다.

## Status-effect policy regression (2026-11-12)

- Passed: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/run.gd --quit-after 10` (includes shield-first DOT mitigation, overlapping freeze/stun, blocked movement/skill, and action resumption).
- Passed: headless editor startup; `tests/results_view.gd`; `tests/campaign_playability.gd` (8/8 stages); `tests/editor_preview.gd`; `scripts/validate_content.gd` (0 errors).
- Environment: Godot 4.7.2 stable, Windows headless.
- Not rerun: Android package export/device smoke and FPS. Changes affect battle runtime; refresh Android build before next device validation.

## 2026-11-12 Android status-effect rebuild

- Re-exported debug APK and test AAB after BattleModel changes. APK API29/36 manifest and debug v2 signature verified; AAB bundletool 1.18.3 validation and API29/36 base manifest verified.
- AAB remains unsigned; publisher signing key and permanent package ID are unavailable. Both AVDs report offline, so no device smoke/FPS run was possible. Detailed hashes and sizes are in ANDROID_TESTING.md.

- 2026-11-12: M5 GUI 검증 재시도도 computer-use native pipe 부재로 실패. plugin headless 시작 및 자동 preview/data 검사만 통과했으므로 GUI 패널 완료로 간주하지 않는다.

## Latest emulator smoke (2026-11-12)

- API 37 AVD: installed current status-effect APK and verified campaign menu/M1 screen rendering.
- API 29 AVD: installed and launched but captured a black frame with repeated Vulkan present error 5.
- Android 10 emulator rendering is still a release risk; no physical device or FPS target is verified. Details and local screenshot path are recorded in ANDROID_TESTING.md.

- 2026-11-12: API29 AVD renderer isolation tried both host GPU and SwiftShader software GPU; both fail Vulkan presentation. API37 SwiftShader passes UI rendering. Android 10 acceptance remains pending physical hardware or a validated API29 emulator configuration.

## Battle sprite atlas test results (2026-11-12)

- Passed `tests/run.gd`: all temporary atlas regions are 32x32 and every catalog unit/facility is mapped.
- Passed `tests/results_view.gd`, `tests/campaign_playability.gd` (8/8), `tests/editor_preview.gd`, `scripts/validate_content.gd` (0 content errors), headless import, and main/battle/village scene starts.
- Fresh Android debug APK: API29 minimum/API36 target, one debug signer verified. Fresh test AAB: bundletool 1.18.3 validation passed; unsigned.
- API37 AVD: latest APK rendered M1 board and placed swordsman using pixel sprite atlas. API29 remains black with Vulkan present error 5 under host and SwiftShader GPU modes. No physical-device or FPS validation.
- Visual asset is temporary placeholder art; final production art pass remains open.

## Android frame-time instrumentation check (2026-11-12)

- Attempted system-level frame capture during active M1 on API37 AVD. `dumpsys gfxinfo` had 0 ViewRoot frames; percentile defaults were invalid. `SurfaceFlinger --latency` exposed only 60Hz display period (16.67ms), no app frame timestamps.
- Result: no performance conclusion. Use Godot Remote Profiler or a physical device with a GPU/frame-time profiler; performance acceptance remains pending.

## M5 catalog editor safety tests (2026-11-12)

- Passed core tests including: Error edit rejected with byte-for-byte unchanged catalog; stable-ID rename rejected without writes; Warning-only 27-wave edit accepted and persisted; temporary/backup files cleaned; simple and nested error fields selected in the editor JSON control.
- Passed results view, seeded 8-stage campaign simulation, preview isolation, content validator (0 errors), editor-preview headless scene start.
- Godot 4.7.2 stable, Windows headless. Editor GUI dock/Inspector flow remains unverified.

## M6 debug frame sampler (2026-11-12)

- Added debug-build-only sampling across combat and preparation so short waves do not reset a sample before its 10-second window. Tests verify average FPS and frame-time percentiles using synthetic data.
- Godot 4.7.2 editor import and `tests/run.gd` passed. Fresh APK and AAB exports completed; APK v2 signature verification passed. APK package `com.example.holotactics`, min API 29, target API 36.
- API37 SwiftShader AVD, M1 wave: consecutive windows measured 25.9 and 25.4 average FPS; p95 41.67 and 41.31ms; max 50ms. This virtualized software GPU result is below the stated FPS goals; it is diagnostic only and does not establish physical-device performance. No script or fatal error appeared during the sampling window.
- Visual smoke: campaign menu and M1 board/unit sprites rendered; wave start accepted. API29 Vulkan presentation and physical Android performance remain unverified.

## API29 GLES renderer fallback probe (2026-11-12)

- Exported a temporary Android APK with `renderer/rendering_method.mobile="gl_compatibility"`; restored `project.godot` immediately after export. The production setting remains Godot Mobile/Vulkan.
- Installed/launched on the API29 AVD. OpenGL selected (`renderingDevice: opengl3`) but the Android GL thread terminated with `_start_success` EGL startup failure; the app returned to the launcher. This fallback also fails on the current API29 emulator image.
- No renderer change is justified by this emulator-only result. API29 hardware verification remains required.

## Full CI-equivalent revalidation (2026-11-12)

Passed Godot 4.7.2 headless editor import, `tests/run.gd`, `tests/editor_preview.gd`, `tests/results_view.gd`, `tests/campaign_playability.gd` (8/8 seeded wins), content validator (0 errors), and headless starts for main, battle, village, village_research, and editor_preview scenes. Re-exported official Mobile/Vulkan APK and test AAB; APK v2 signature and required AAB entries verified. Both AVDs reported offline after the API29 renderer experiment, so this export was not freshly installed. Physical Android 10+ performance, Play signing/upload, and M5 GUI remain pending.

- Follow-up smoke after ADB recovered: installed the exact official APK hash above on API37; cold-start campaign menu and tapped M1 board rendered with sprite atlas/HUD. No script, Vulkan-present, or fatal exception in the short log sample. API29 and physical Android remain unverified.

## Release signing preflight (2026-11-12)

- Ran `scripts/export_android_aab.ps1` with release signing environment variables absent. It stopped at the required keystore-path check before export and created no release artifact.
- A separate attempt to generate and use a throwaway local signing key was rejected by the automatic approval review (`blocked by policy`); no key was created and no alternate credential path was used. Publisher-signed AAB remains pending the publisher's permanent application ID and signing setup.

## M0–M4 milestone evidence reconciliation (2026-11-12)

Marked M0–M4 complete in `PROGRESS.md`: M1 has API37 manual defense evidence plus headless combat/checkpoint/reward tests; M2/M3 have outcome, AI/path, growth/evolution/status tests; M4 has campaign lock/reward persistence checks and a seeded 8/8 stage win simulation across all 26 waves. The seeded simulation is not a full manual UI campaign run; that remains additional QA. M5 GUI interaction and M6 physical-device/FPS/release-signing gates remain incomplete.

## CI build gate correction (2026-11-12)

The Android AAB job now declares `needs: godot`, so export and artifact upload are skipped unless import, tests, content validation, and scene smoke all succeed. Cached actionlint v1.7.12 linted `.github/workflows/validate.yml` with no diagnostics, and `git diff --check` passed. A hosted GitHub Actions run remains pending repository/Actions access.

## Status-effect policy revalidation (2026-11-12)

- Godot 4.7.2 `tests/run.gd` passes after the user reconfirmed the rules. Existing assertions verify bleed/burn consume an 8-point shield before applying 50% damage reduction (10 total post-shield damage results in 6.5 HP loss) and that a shorter freeze application does not shorten an overlapping 0.8-second stun. No runtime code change was needed.

## M5 editor panel structure (2026-11-12)

- Godot 4.7.2 editor-headless test passed: three tabs created, catalog counts were stages/waves 37, evolutions 6, upgrades 20; both stage and direct-wave preview controls exist. Added to CI and actionlint passes.
- Limitation: this does not exercise actual visible dock/Inspector interactions. Godot exits successfully but prints renderer/ObjectDB leak diagnostics while closing this headless editor-script process; this is recorded as harness teardown noise pending a GUI session.

## M6 AVD reconnection smoke (2026-11-12)

- Using the installed SDK ADB, reconnected and installed the current APK (SHA-256 `E0B817428BEC235CEAC51950794658D88C92FA42E7AC89494C3F2C46A6D033EC`) on API29 and API37 AVDs. API37 displayed the campaign menu and initialized Vulkan/SwiftShader. API29 resumed its activity but logged repeated Vulkan queue present error 5.
- ADB touch injection did not change the API37 menu in this run; M1 entry is not claimed from this check. This does not validate physical Android compatibility or FPS.

## Windows headless process cleanup (2026-11-12)

- Found and stopped 53 stale Godot headless processes with test or AAB export command lines; these were hours old and no active exec sessions remained. Updated the documented local test commands and CI's synchronous test/validator invocations with `--quit-after 2`.
- Re-ran the full Godot CI-equivalent suite: import, core, preview isolation, editor panels, results UI, 8/8 seeded campaign wins, content validation, five scene starts, and actionlint all passed. A process query found zero new headless leftovers. The editor panel process still prints engine renderer/ObjectDB teardown diagnostics while exiting successfully.

## External CI/GUI access recheck (2026-11-12)

- Computer-use initialization reached the `@oai/sky` package, but `list_apps()` returned native pipe unavailable (Windows error 2). No window actions were executed.
- The connected GitHub account's accessible repository list did not include this Godot project, and the local Git repo has no remote. No hosted workflow run can be attributed to this checkout; actionlint and full local CI-equivalent checks pass.

## API 29 렌더러 추가 검사 (2026-11-12)

- Godot 4.7.2 Android export: 현행 Mobile/Vulkan APK를 Emulator 37.2.13의 API29 Google APIs 및 임시 Google Play AVD에서 실행했으나 양쪽에서 Vulkan present error 5가 재현됐다. 임시 Compatibility/OpenGL APK는 API29 AVD GLES 2 환경에서 EGL 컨텍스트 생성에 실패했다.
- 실행 후 기존 API29 AVD 데이터는 보존하고 임시 Google Play 이미지/AVD는 제거했다. Emulator 업데이트는 유지했다. Android 10 실기기 동작과 FPS는 검증되지 않았다.
- 전투 규칙 재검증: `tests/run.gd` — Godot 4.7.2 headless, 통과. 출혈/화상 보호막 우선·방어력 후순위와 빙결/기절 최대 남은 시간 동작 확인 포함.

- 2026-11-12: fresh API37 install smoke showed the current APK campaign menu with Vulkan/SwiftShader and no captured runtime error. ADB touch did not enter M1. Count only as launch/menu evidence; no combat, Android 10 hardware, or FPS acceptance.

- API37 emulator smoke (2026-11-12): touch entered M1; unit deployment charged the expected 50 resources (160→110), and wave 1 enemy attack reduced core HP (300→280). This strengthens launch-only evidence to a short interactive combat path; it is not a full-stage or physical-device/FPS pass.

## Build directory editor scan regression

- Added empty `build/.gdignore` (force-tracked because `/build/` is Git-ignored) so Godot's editor filesystem scanner ignores generated Android APK/AAB and local screenshots.
- `Godot_v4.7.2 --headless --editor --path . --quit`: passed; filesystem scan/import output did not enumerate generated files under `build/`.
- `tests/editor_panels.gd`: passed after the change. Existing renderer/ObjectDB teardown diagnostics persist on exit; do not count them as a clean shutdown.

## Android checkpoint + perf follow-up

- API37 M1 checkpoint file inspection, force-stop/relaunch resume, defeat settlement and checkpoint removal passed on the current APK. Permanent-currency balance stayed at 115 (no duplicate reward on this zero-reward defeat).
- SwiftShader AVD combat samples: average 25.2/24.5/23.7/24.4 FPS, p95 43.45/43.75/45.68/42.80ms. Under target in this software emulator; not a physical-device result.

## M1 result-count fix and Android artifact revalidation (2026-11-12)

- Godot 4.7.2: `tests/results_view.gd`, `tests/run.gd`, and `tests/campaign_playability.gd` passed; seeded playability simulation won all 8 stages. `git diff --check` passed.
- API37/Emulator 37.2.13: installed fixed APK and manually replayed M1 to victory. Result panel displayed 2/2 completed waves and repeat reward +10; screenshot `build/mvp-fixed-result.png` is a local ignored artifact. This is emulator gameplay evidence only.
- APK SHA-256 `B8845B0ECDA245D51EA6234D898C19B925982FB92C470111E3E141D806F0A5BA`; `apksigner verify --verbose` passed (v2 signature). Test AAB SHA-256 `3941E299153244DB5BD4698DA95C6F2A9D9B6AD86C52A1E1CB038F8A8CED59E0`; `bundletool validate` passed. Manifest: `com.example.holotactics`, min API 29, target API 36.
- Release signing is not configured; this AAB is for testing. Physical Android 10 compatibility, physical FPS targets, GUI interaction of M5 panels, and Play private-test upload remain unverified.

## Current GUI and catalog recheck (2026-11-12)

- Correct CI invocation for the M5 editor structure check: Godot 4.7.2 `--headless --editor --path . --script res://tests/editor_panels.gd`; passed with stages/waves, 6 evolutions, and 20 upgrades. Engine prints renderer/ObjectDB leak diagnostics during standalone editor-script shutdown despite exit success; no clean GUI session was available.
- `scripts/validate_content.gd --quit-after 2`: passed (0 content Errors).
- Computer Use inventory still returns no apps because its native Windows pipe and browser host are unavailable. M5 visual dock/Inspector interaction remains unverified.

## Full local revalidation and release-gate check (2026-11-12)

- Godot 4.7.2: editor import, 	ests/run.gd, editor preview isolation, M5 editor-panel construction, battle results, seeded 8-stage campaign simulation (all 8 wins), content validation (0 Errors), and headless starts for main/battle/village/village_research/editor_preview all passed. git diff --check passed.
- Current local artifacts: APK SHA-256 $apkHash; test AAB SHA-256 $aabHash. undletool validate was previously successful; current jarsigner -verify confirms the test AAB is unsigned, as expected, and not a Play-upload artifact.
- Rechecked external prerequisites: ADB reports no connected devices; all three GODOT_ANDROID_KEYSTORE_RELEASE_* environment variables are absent. The package ID remains com.example.holotactics. Thus release AAB signing, physical-device Android/FPS acceptance, and Play private-test upload cannot be completed in this environment.

## Android AAB export exit probe (2026-11-12)

Tried the CI AAB export locally with `--quit-after 2`. Godot launched the Android Gradle export but did not return within the observation window; the existing test AAB stayed at SHA-256 `3941E299153244DB5BD4698DA95C6F2A9D9B6AD86C52A1E1CB038F8A8CED59E0`. `bundletool validate` still passed for that existing artifact, which does not prove this export attempt completed. Stopped only the Godot process started by this probe. No workflow change was retained because the added quit option was not verified to resolve the lingering process.

## Facility upgrades: implementation and regression (2026-11-13)

- User decision: facility upgrades are available during both preparation and combat. Four ally facility upgrade records were added to `data/catalog.json`, each with three SEED levels: arrow tower damage +4/+8/+12, magic tower damage +6/+12/+18, support outpost healing +2/+4/+6, defense wall max HP +20/+40/+60. Each tier costs 25/40/60 combat resources. Bonuses are cumulative tier values; wall upgrades do not heal current HP. Rebuilding creates a fresh facility with no retained upgrades (SEED consistent with the design draft).
- Added `BattleModel.purchase_facility_upgrade`, cost validation, per-instance levels, computed stats, max-HP-aware repairs, save/restore validation and legacy checkpoint defaulting. Added a selected-facility context button. Editor validator accepts exactly one unit/facility target and enforces one upgrade record per ally facility.
- Godot 4.7.2: core suite, results/facility UI test, 8/8 seeded campaign simulation, content validator (0 Errors), editor import, 3-panel editor structural test (24 upgrade records), and five scene starts passed. Regression covers both phases, per-effect stats, cost/max-level, wall repair after HP upgrade, save/restore, legacy missing field, malformed target/effect/count, and UI availability in combat.
- APK export produced and validated: 249,837,983 bytes, debug signature v2=true, package `com.example.holotactics`, min API29/target API36; SHA-256 `6823CA453156ED7AB8B157C2C4AE65FBE6C98C6C89E3C29F9BC132356A4A5CB2`. AAB: `bundletool validate` passed, JAR unsigned as expected for test artifact, 86,245,875 bytes; SHA-256 `80842D888B27FAC689502F1FFB8B1EBE391362ACA93E718C61FBB4E832FD182C`.
- API37 AVD installed the new APK and displayed the campaign menu with existing progress intact. ADB taps did not enter M1 in this pass; no facility interaction is claimed from the AVD. Physical Android10+ and FPS acceptance remain pending.

## Resumed-session revalidation (2026-11-13)

- Re-ran Godot 4.7.2 core suite, content validation (0 Errors), and seeded campaign simulation: all passed (8/8 stages).
- Re-ran battle/facility UI regression and editor-panel structure test: both passed (24 upgrade records). The editor-headless process reports resource/ObjectDB cleanup warnings on exit; test assertions pass.
- `git diff --check` passes. Godot was invoked by its installed console executable because no `godot` command alias is on PATH.

## Godot and Android emulator execution check (2026-11-13)

- Godot 4.7.2 core headless suite passed; main scene launched headlessly and exited without reported script/engine errors.
- API 37 x86_64 emulator: installed the released debug APK with `adb install -r` (`Success`), launched `com.example.holotactics`, observed the game process and `GodotAppLauncher` as the resumed foreground activity. Screenshot shows the campaign menu and existing progress.
- No app fatal exception was present for the launched process. Mesa logged missing rendernode messages from the emulator software renderer; this is emulator-specific and does not establish physical-device performance.
- The user’s Galaxy S25 Ultra is not connected to this workstation, so its installation result remains unverified.

## Rebuilt APK and release refresh (2026-11-13)

- Re-exported the current `master` project with Godot 4.7.2. APK size 249,837,983 bytes; SHA-256 `6823CA453156ED7AB8B157C2C4AE65FBE6C98C6C89E3C29F9BC132356A4A5CB2` (byte-identical to prior reproducible build).
- APK v2 signature and 16 KB ZIP alignment checks passed. API 37 x86_64 AVD install returned `Success`; app launched as foreground activity with a live process.
- Replaced `holo-debug.apk` on GitHub release `v0.1.0-preview.1`; GitHub asset size and SHA-256 match the local build.
- Physical Galaxy S25 Ultra installation remains unverified.
