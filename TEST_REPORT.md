# Test report

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
