# Issues and open decisions

## OPEN_DECISION

- **GAP-P0-01 — 해결:** 2026-11-12 사용자 결정: 수성은 아군 유닛이 모두 전멸해도 핵심이 생존하면 계속 진행한다. 자동 패배시키지 않으며 core HP가 0이 되면 패배한다.

## 사용자 결정 기록

- **GAP-P0-UNIT-UNLOCK — 기본 유닛 해금 문서 충돌 (해결):** 2026-11-12 사용자 확인으로 **스토리 진행에 따라 단계별 해금**으로 정리. DEC-572~573/C2 표를 적용하고 MVP 5종 모두의 해금 시점은 스토리 안에 포함한다. 초기 전부 해금 정책은 적용하지 않는다.
- **R-EFFECT-005 — 상태이상 피해·행동불가 중첩 (해결):** 2026-11-12 사용자 결정(DEC-654~655). 출혈·화상 피해는 보호막을 먼저 소모한 뒤 남은 피해에 방어력/피해 감소를 적용한다. 빙결·기절이 겹치면 더 긴 남은 시간을 기준으로 행동불가를 유지한다. 기존 동일 상태 재적용 갱신 및 출혈·화상 3중첩 상한은 유지한다.
- **R-FAC-003 / R-UI-002 — 시설 전투 강화 (해결, 2026-11-13):** 사용자 결정으로 전투와 재정비 모두에서 허용. 강화는 시설 개체별 3단계이며 수치·가격은 SEED다. 화살탑 피해 +4/+8/+12, 마법탑 피해 +6/+12/+18, 지원 초소 치유 +2/+4/+6, 방어벽 최대 HP +20/+40/+60; 각 시설의 단계별 비용은 25/40/60 전투 자원. 방어벽 강화는 현재 HP를 즉시 올리지 않으며 이후 수리로 회복한다. 재건설은 새 개체로 취급해 강화 단계가 초기화된다.

## 확인된 미결정(문서 기재)

- 세부 스킬 상호작용, 증원 제한시간/실패 UI는 미확정 또는 설계초안이다. 해당 로직이 필요한 마일스톤 전에 사용자 결정이 필요한지 재검토한다.
- 재정비/전투 중 시설 강화 허용 시점은 확정됐고 구현됐다. 숫자·3단계 상한은 사용자 승인 규칙이 아닌 조정 가능한 SEED다.
- 보급형 Android 테스트 기기 모델이 미선정이다. 실제 성능 목표 인수 전에 기기가 필요하다.
- 최신 APK 재확인: API37 AVD에서 캠페인 메뉴 렌더링, API29 AVD에서 Vulkan present error 5 재현. 이번 headless AVD 실행은 ADB 터치로 M1 진입을 재현하지 못했으며 실기기 검증도 아직 없다.
- M5 EditorPlugin은 headless 구조 검증에 통과했으나 실제 Godot GUI에서 dock/Inspector 편집·미리보기 버튼을 조작하지 못했다. UI 연결이 복구되면 편집 저장/오류 이동/미리보기까지 수동 확인한다.
- 시설 수리·강화는 전투와 재정비 모두 허용으로 확정·구현됐다. 수리 및 강화 비용/효과 숫자는 조정 가능한 SEED다.

## 임시 초기값

- 마을 시작 영구 재화 100, 훈련소 비용 75, 공방/마법 연구소 비용 100은 건물 배치 경로 시험용 SEED다. 경제 밸런스 또는 연구 해금 정책 확정값이 아니다.
- 기본 영구 연구 SEED: 아군 각 유닛의 공격력 +2, 연구당 영구 재화 50. 검사·궁수는 M1, 창병은 M2, 지원병은 M3, 마법사는 M4 완료 이후 해당 훈련 건물에서 연구할 수 있다. 경험 곡선과 전투 밸런스 검증용이며 승인 수치가 아니다.

- M1 시드 스테이지 시작 전투 자원은 `160`으로 설정했다. A* 이동을 연결한 뒤 120 자원/2유닛 시험 배치가 패배해 3유닛 배치로 승리 시뮬레이션을 다시 통과시키기 위한 임시값이다. 밸런스 승인값이 아니며 실기기 플레이 테스트에서 조정한다.
- 고블린 AI 프로필의 공격/목표 가중치 `1.2/1.0`도 임시 시드값이다. 적 역할 및 웨이브 보정은 콘텐츠 데이터로 추가하되 플레이 테스트에서 조정한다.
- 증원 출현 시각은 공성 W2 시드 3초, 충돌 재시도 간격은 0.5초/최대 6회로 임시 설정했다. 실제 테스트에서 조정할 SEED 값이다. 재시도 제한 이후 모델은 무보상 `safe_abort`로 끝나며 기존 체크포인트를 보존한다.
- M1 방어벽 HP `60`은 임시 시드값이다. 벽 돌파 AI 비교는 현재 경로 길이와 이동+파괴+목표까지의 추정 비용으로 판단하며, 전투 플레이 테스트에서 조정할 수 있다.
- 시설 밸런스(화살탑 HP/공격/사거리/비용 120/16/3/80, 마법탑 90/25/4/110, 지원 초소 HP/치유량/사거리/간격/비용 140/8/2/1.5초/95, 방어벽 HP/비용 60/25)는 테스트용 SEED다. 지원 초소는 치유형으로 구현했다: 사거리 내 생존 아군 유닛 중 HP 비율이 가장 낮은 대상을 초과 치유 없이 회복하고 사망자는 제외한다. 방패/공격 강화 기능은 미구현이다. 전투/재정비 수리는 사용자 확정 규칙이며 구현했다. 비용(누락 HP 5당 자원 1), 최대 HP 복구, 파괴 시설 수리 불가는 미승인 테스트 SEED다. 파괴 후 재건은 기존 신규 건설 규칙을 따른다.
- 불가침 장애물 테스트 시드: `obstacle.barricade` 최초 설치 비용 20, M2 갈림길 스테이지별 보유 3/동시 배치 2. 입력·저장·경로 차단 검사 확인용이며 수치와 콘텐츠 종류는 밸런스/콘텐츠 승인값이 아니다.
- 현재 11종 유닛의 `movement_type`은 모두 `ground`, 바리케이드의 차단 유형도 `ground`다. 이는 기존 단일 타일 경로 시스템을 명시한 값이며, 비행 등 다른 유형은 런타임·전투 규칙이 구현되지 않아 Validator가 허용하지 않는다.
- 공성 적 시설 시드(감시탑 HP/공격/사거리/간격 100/12/3/1.5초, 마법탑 80/18/4/2초)와 배치 좌표는 테스트용 SEED다. 적 시설은 현재 단일 대상 기본 공격만 한다. 광역/상태이상/지원 효과는 적 마법사·지원병 역할의 후속 구현 범위다.
- 아군 마법탑 광역 범위는 맨해튼 반경 1타일 SEED다. 중심 대상은 기본 사거리 안의 최근접 적이고, 효과 반경/수치는 전투 테스트로 조정한다. 마법탑의 추가 상태이상은 미구현.
- 신규 유닛 시험 초기값(SEED): 창병 HP/공격/사거리/간격/비용 180/15/2/1.4초/70, 지원병 90/5/1/1.5초/70 및 치유 8·사거리3, 마법사 75/25/3/1.8초/90 및 광역 반경1. 적 궁수 45/8/3/1.6초, 오크 전사 150/18/1/1.8초, 오크 돌격병 110/20/1/1.3초, 적 마법사 70/22/3/2초 및 광역 반경1, 적 지원병 90/5/1/1.5초 및 치유10·사거리3. 새 AI 가중치와 웨이브 조합도 시험 SEED이며 밸런스 승인값이 아니다.
- 전투 강화 20개 가격/효과(SEED): 단계 비용은 항목별 `data/catalog.json`을 따르며 25/40/60 또는 30/45/65. 값은 연속 베기 추가 타격 1/2/3, 출혈 초당 피해 2/3/4, 회전·폭발·마법 범위 반경 1/1/2 또는 1/2/3, 돌진 추가 피해 5/8/12, 관통·다중·연쇄 추가 표적 1/2/3, 빙결 0.5/0.8/1.2초, 밀치기 1/1/2타일, 반격 20/30/40%, 도발 반경 2/3/4, 방패 피해 감소 15/25/35%, 광역 치유 반경 1/2/3, 보호막 10/15/20, 공격 버프 10/15/20%, 화상 초당 피해 3/4/5, 마력 폭발 피해 배율 1.2/1.5/2.0. 상태 해제 반경은 1/2/3이다. 출혈·화상은 최대 3개별 타이머 스택, 네 번째 이후 추가 적용 무시; 빙결 재적용은 새 지속시간으로 갱신. 이 수치와 중첩 상한 초과 동작은 테스트 초기값이며 승인 밸런스가 아니다.
- 기본 스킬 SEED: 검사 강타/영웅 돌격, 궁수 연속 사격/화살비, 창병 수호 진형/전선 휩쓸기, 지원병 응급 치유/성역, 마법사 비전 탄환/운석 낙하. 자동은 단일 타격·유효 부상 아군 치유·보호막, 수동은 범위 공격·보호막으로 연결했다. 상세 값(각각 8~18초 쿨타임, 수동 비용 20~25, 피해/보호막/치유량 및 반경)은 `data/catalog.json`에 있으며 전부 임시 밸런스 SEED다. 자동 스킬은 실행 가능한 대상이 없으면 발동하지 않고 자원을 쓰지 않는다. 실제 밸런스/자동 AI 조건은 플레이 테스트로 조정해야 한다.
- 진화 콘텐츠 SEED: 여섯 형태의 요구 강화 단계·전투 비용·특수 스킬 효과는 `data/catalog.json`에 있다. 각 형태는 이제 영구 연구로 해금되고, 해금 ID는 전투 모델/체크포인트에 복원된다. 영구 연구 비용 100은 임시 SEED다. 진화 전투 실행은 구현 완료. 사용자 결정으로 형태를 1회 선택 후 고정하고 재진화하지 않는다.
- 영구 보상 SEED: 현재 두 시험 스테이지에 최초 클리어 추가 보너스/반복 기본 보상/완료 웨이브당 부분 보상을 각각 30/10/5 및 40/12/6으로 넣었다. 모든 값은 조정 가능한 시험값이며 캠페인 8개 스테이지 제작 시 재조정한다.
- 캠페인 스테이지·웨이브 SEED: 메인 6+선택 2, 웨이브 분배 2/3/3/4/4/4/3/3으로 초기 구성했다. 좌표, 시작 전투 자원, 적/증원 수와 보상 값은 기획 5.2 설계초안이며 실기 플레이 검증 전이다. 기존 `stage.m2.siege`는 캠페인 슬롯에 포함하지 않고 공성 시험 시나리오로 남겼다.

## 환경 제한

- M4 초기 방어 전술 진단: 시작 재화 220으로 기본 유닛만 배치한 시험은 W4에서 패배했다. 검사/궁수/창병 3종과 핵심 앞 화살탑(5,8)을 사용하는 전술은 260 자원에서 4개 웨이브 모두 이겼다. `start_resource`를 220→260으로 조정하고 해당 전술을 자동 회귀 테스트에 고정했다. 이는 한 유효 전략을 입증하지만 전체 밸런스 승인이나 모든 전술의 승리를 뜻하지 않는다.

- 로컬 Godot 4.7.2와 Android SDK가 설치되어 있다. Godot·ADB는 PATH에 없어 전체 경로로 실행하며, ADB는 `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`에서 확인했다. 2026-11-13 현재 API37 `MaDangStage6_API37` AVD가 online이고 업데이트 APK의 캠페인 메뉴가 표시됐다. M1 터치 입력은 진입을 재현하지 못했으며, 물리 Android 10 기기는 연결되지 않았다.
- 로컬 Git remote가 없고 연결된 GitHub 저장소 목록에도 이 Godot 프로젝트가 없다. hosted Actions 결과를 확인할 저장소 식별정보가 없으며, 실기기 연결·Google Play 계정·서명 키도 확인되지 않았다. 외부 상태를 완료로 표시하지 않는다.
- 최신 APK는 API37 AVD에서 캠페인 메뉴를 렌더링하지만, 현재 headless AVD ADB touch 입력으로는 화면 전환이 재현되지 않았다. API29 Android 10 AVD는 Vulkan 초기화 후 queue present error 5가 반복된다. 과거 GLES 호환 렌더러 실패도 기록했으나 물리 Android 10 호환성 판단 근거는 아니다.

- M5 Inspector 동기화 모델, Validator의 ID·필드 경로 표시, 오류별 레코드 이동은 구현됐지만 GUI에서 편집→가져오기→저장/오류 이동 흐름은 직접 확인하지 않았다.

- 2026-11-12: computer-use 네이티브 연결이 unavailable 상태라 Godot 편집기 GUI 직접 검증이 막혔다. 자동 파싱/모델 검사와 씬 실행은 통과하지만, Inspector GUI 상호작용 및 모바일 실기기 UI/FPS 검증 증거는 없다.
- 2026-11-12 재확인: @oai/sky `list_apps()`가 native pipe 연결 실패(os error 2)로 반환되어 UI 제어를 시작하지 못했다. 따라서 Godot dock/Inspector GUI 검증은 계속 대기.
- Windows 로컬 검증 종료 후 테스트·AAB export를 실행한 오래된 headless Godot 프로세스 53개(추가 `results_view.gd` 4개 포함)가 남아 있었다. 정리 완료. README와 CI의 동기 테스트 실행에 `--quit-after 2`를 적용했다; 전체 회귀 실행 뒤 새 잔류 프로세스 0개.

- 2026-11-12 AVD 재검증 결과: API 29 Android 10 이미지의 GLES 2 한계로 EGL 컨텍스트 생성 실패, API 37 SwiftShader는 Godot GLES3 canvas shader uniform 초과로 검은 화면. APK 설치만으로 Android 실행 호환성이 입증되지 않는다.
- 추가 확인: API 29에 최신 APK 설치 후에도 GLThread `createContext failed: EGL_SUCCESS`로 시작 실패, API 37에서 `GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)` 오류를 재현했다. API 36 AVD는 지정된 `android-36/google_apis/x86_64` 시스템 이미지가 SDK에 없어 실행 불가.

- Android 렌더러 판단 근거: [Godot 4.7 system requirements](https://docs.godotengine.org/en/4.7/about/system_requirements.html)는 Compatibility 모바일 GPU에 GLES 3.0을 요구한다. API 29 AVD의 GLES 2 실패는 이 요구 미충족으로 설명된다. API 37 SwiftShader uniform 오류는 [Godot 엔진 이슈 #109550](https://github.com/godotengine/godot/issues/109550)에서 동일한 4.7.2/Android Emulator 조합으로 확인됐고, 엔진 개발자는 SwiftShader의 GLES 3.0 불완전 구현 가능성을 지적했다. 이는 물리 기기 호환성을 입증하지 않는다.
# 2026-11-12 이어서 작업 상태

- 해결: Validator 오류를 ID/필드 경로와 함께 표시하고, 연구 데이터의 개별 필드 경로를 테스트함.
- 남음: 편집기 GUI에서 오류 선택→레코드 이동의 시각/상호작용 검증은 자동 headless 테스트로 대체할 수 없음. Android 실기기 GLES 및 성능도 별도 기기 검증 필요.
- 위 OPEN 전투 규칙 질문은 2026-11-12 사용자 결정으로 모두 해결됐다: 수성은 핵심 생존 중 계속, 진화는 1회 선택 후 고정, 시설은 전투 중에도 수리 허용. 세부 구현/SEED는 하단 해결 기록을 따른다.
- 2026-11-12 추가 재검증: 문자열 숫자값에서 Validator가 중단되던 시설 필드 관계 검사를 수정하고 5개 필드의 malformed 입력 테스트를 통과했다. 단말 GUI blocker와 AVD offline 상태는 반복 확인됐지만 다른 독립 작업은 계속 가능하다.

- 2026-11-12 Android export 설정 이슈 해결: 이전 non-Gradle APK의 minimum API 24는 Android 10+ 기준에 못 미쳤다. Gradle APK/AAB로 전환하고 min API 29, target API 36을 적용했으며 최신 APK manifest에서 확인했다. 이전 산출물은 사용하지 않는다.
- 출시 AAB 서명 및 업로드는 publisher-owned package ID, release keystore와 Play 권한이 필요하다. 로컬 unsigned AAB 패키징만 확인됨.

- 2026-11-12 재시도: 편집기 직접 GUI 확인을 위해 Godot 창 탐색을 요청했으나 Computer Use native pipe가 “지정된 파일을 찾을 수 없습니다”로 실패해 창 상태를 관찰하지 못했다. M5 GUI 사용성 검증은 미완료로 유지한다.
- 출시 서명 검증용 disposable keystore 생성 명령은 자동 검토에서 차단됐다. 키를 생성하거나 release 서명 테스트를 완료한 것으로 간주하지 않는다.

## Resolved

- 2026-11-12: `BattleModel.restore()`가 체크포인트 검증 전에 영구 연구를 적용해 실패한 복원이 전투 모델을 부분 변경할 수 있었다. 임시 연구 밸런스로 전부 검증한 다음 커밋하도록 수정하고 회귀 테스트를 추가했다.

- GitHub remote/Actions 권한이 확인되지 않아 새 Android AAB CI job의 hosted run 결과는 미검증이다. workflow lint 및 동일 로컬 export 경로는 확인했다.

- Resolved 2026-11-12: R-UI-003 pause/read-only inspection was implemented and covered by `tests/results_view.gd`. Remaining platform verification is listed under environment limits: physical Android touch/layout and FPS are unverified.

- R-UI-002 구현: 유닛 컨텍스트 강화/수동 스킬, 시설별 강화/수리 버튼, 시설 정보/이동 안내가 있다. 강화·수리 모델은 자동 테스트에서 전투/재정비 단계와 자원 차감, 저장/복원을 확인했다. 실기기 가장자리 배치/터치 검증은 남았다. 수리 비용과 시설 강화 수치·가격은 미승인 SEED다.

- M3 진화 영구 연구 연결과 실제 전투 변신/특수 스킬은 구현·테스트 완료. 연구 비용 100 SEED는 임시 초기값. 사용자 결정에 따라 개체당 1회 선택 후 형태가 고정되며 재진화는 불가하다.

- 해결(2026-11-12): 진행 저장 원자 교체 중 주 파일이 없어지는 중단 시나리오에서 남은 .bak을 자동 복구. 기존 백업 없이 주 파일이 없는 첫 실행은 초기 진행으로 시작한다.

- 해결(2026-11-12): 기존 Validator가 제품 문서의 조정 가능한 26웨이브 제작 목표를 Error로 강제하던 모순. 이제 6개 메인+2개 선택 스테이지 누락은 Error, 다른 웨이브 수는 Warning이다. 기본 시드는 26웨이브이며 27웨이브 검증 변형은 Warning만 생성.

- Android 배포 포장 정리(2026-11-12): APK/AAB에서 tests, content_editor addon, editor_preview 씬/스크립트를 제외했다. 로컬 sparse PCK 검사에서 해당 경로가 없고 런타임 validator는 포함됨을 확인. 현재 adb 장치 emulator-5554/5556는 offline.

- 2026-11-12 최신 APK 재실행: API37 AVD에서 install 성공, Godot 앱 프로세스 유지/foreground 확인. 캡처 화면은 검정이며 `GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`와 SceneShader/CanvasShader GLES3 연결 오류가 발생했다. SwiftShader 가상 GPU 환경의 결과이며 물리 기기 통과로 대체하지 않는다.

- 해결(2026-11-12): 콘텐츠 EditorPlugin은 원자 저장 중단 후 카탈로그 본 파일이 없을 때 .bak을 복구한다. 회귀 테스트는 백업 복원 후 원본 경로가 재생성되고 백업 경로가 없어짐을 확인.

- 수정(2026-11-12): 재시작 시 Main이 체크포인트를 탐색하지 않아 BattleView의 자동 복원 코드에 도달하지 못하던 R-UI-005/R-SAVE-003 결함. 이제 캠페인 체크포인트 중 최신 파일의 스테이지로 직접 이동한다. 단위 경로/탐지 테스트와 메인 씬 smoke는 통과했으나 실기기 시작 화면 검증은 SwiftShader 렌더 실패로 미확인.

- R-SAVE-003 백업 보완(2026-11-12): 시작 탐색이 `.bak`만 존재하는 경우에도 `CheckpointStore.load_checkpoint()` 복구를 호출해 해당 스테이지로 라우팅한다. 탐색 테스트는 백업만 존재하는 fixture에서 최종 경로 복원까지 검증.

- R-UI-001 추가 자동 커버리지: SubViewport 320×568, 360×640, 412×915에서 선택 유닛 문맥 메뉴, 고정 pause 버튼, 스크롤 조작 영역의 viewport 경계를 검사한다. 자동 검사 통과이나 실기기 DPI/안전 영역/터치 사용성은 여전히 미검증.

- R-UI-001 메인 메뉴 대응(2026-11-12): 2열 캠페인 버튼 폭을 `(viewport_width - 24)/2`에 맞춰 120–168px로 제한한다. 320/360/412 논리 너비에서 합산 폭 검사 통과. 실기기 안전 영역 및 글꼴 배율/터치 검증은 별도 대기.

- 해결 (2026-11-12): M5 카탈로그 원자 저장에서 새 주 파일 교체 직후 프로세스가 중단되면 오래된 .bak이 다음 저장을 막을 수 있었음. 검증 통과한 주 파일을 읽을 때만 stale backup을 제거하고, 검증 오류가 있으면 백업을 보존함. 제거 실패 시 읽기를 차단하여 재저장으로 데이터가 덮이는 상황을 방지.

- **GAP-P0-06 — 해결:** 2026-11-12 사용자 결정: 각 유닛은 영구 연구 해금·강화 조건·전투 자원을 충족해 진화를 한 번 선택하면 고정되며 재진화할 수 없다. 궁수도 얼음/폭파 분기를 한 번만 선택할 수 있다.
- **GAP-P0-04 — 시점 해결 / 가격 SEED:** 2026-11-12 사용자 결정으로 시설 수리는 재정비뿐 아니라 전투 중에도 가능하다. 임시 수리 SEED는 누락 HP 5당 전투 자원 1, 한 번에 최대 HP까지 회복, 파괴 시설은 수리 불가로 둔다. 값은 미승인 밸런스이며 파괴 후 새 시설 건설은 기존 건설 규칙을 따른다.

- 2026-11-12 AVD 재검증: API29 APK 설치 후 GLES3 EGL 컨텍스트 생성 실패로 앱이 런처로 돌아감. API37은 APK 설치 및 게임 Activity foreground 확인, 화면 캡처 검정, CanvasShaderGLES3 261 fragment uniform 오류 재현. 동일 오류는 Godot Android/SwiftShader 이슈에도 보고됐고 엔진 이슈 댓글은 SwiftShader 내부 문제 가능성을 제기한다(https://github.com/godotengine/godot/issues/109550). 물리 기기 결과로 일반화하지 않는다.
## 2026-11-12 사용자 결정 후 상태 갱신

- GAP-P0-06 해결 구현: 각 개체는 진화 형태를 한 번만 고르고 고정한다. 궁수 두 분기도 선택 후 바꿀 수 없다. 연구 해금/강화 조건/전투 자원 검사, 특수 스킬, 저장·복원을 구현했다.
- GAP-P0-04 시점 해결: 전투 중에도 시설 수리를 허용한다. 누락 HP 5당 자원 1, 전체 회복이 임시 SEED다. 파괴된 시설은 수리 불가이며 건설은 기존 비용을 사용한다.
- SaveVersion 2는 진화 상태와 특수 쿨타임을 저장한다. Version 1은 진화 데이터가 전혀 없는 기존 전투 저장만 기본 형태로 복원한다.

## Android 및 규칙 검증 잔여 (2026-11-12)

- Android 전용 Mobile/Vulkan 렌더러는 API 37 SwiftShader AVD에서 메뉴와 M1 보드 표시까지 개선됐다. 동일 설정 API 29 AVD는 Vulkan present error 5로 실패했다. 에뮬레이터 결과는 Android 10 실기기 호환 증거가 아니며, 보급형 실기기 및 전투 장시간 FPS/P95 측정이 필요하다.
- AVD 시작 구간 17프레임의 p50 61ms/p90 300ms는 앱 실행/셰이더 준비가 포함된 불충분 샘플이다. 성능 목표 통과로 처리하지 않는다.
- R-EFFECT-005: user has resolved bleed/burn mitigation (shield first, then armor) and overlapping freeze/stun (longer remaining duration). Hit resistance/immunity remains open; code and regression tests cover the confirmed rules.
- M5 EditorPlugin은 headless 초기화/데이터 편집 모델 테스트를 통과했으나 편집기 GUI에서 3개 탭의 실제 Inspector/저장/오류 이동 조작은 검증 대기다.

- 2026-11-12 M5 GUI 재시도: Computer Use `getState()`에서 native app pipe의 지정 파일 없음과 browser host unavailable을 받았다. GUI 실행/클릭은 시작되지 않았고 M5 시각/Inspector 저장 흐름은 미검증이다. Headless EditorPlugin 초기화와 자동 테스트는 통과했다.

## Resolved status-effect decisions (2026-11-12)

R-EFFECT-005: user selected shield-first then armor/damage reduction for bleed/burn damage, and max remaining duration for overlapping freeze/stun. Implemented in BattleModel and covered by tests/run.gd. Resistance/immunity policy remains open; no additional statuses were added.

- 2026-11-12 M5 재확인: computer-use native pipe 연결이 다시 `지정된 파일을 찾을 수 없습니다`로 실패해 Godot GUI 패널 상호작용을 관찰하지 못했다. 이 환경의 GUI 검증 차단은 반복 중이며, headless 플러그인 시작/모델 검증 결과만 유지한다. 편집기 시각 검증은 여전히 미완료다.

- 2026-11-12 emulator rerun after status-effect export: API 37 AVD displays campaign menu and M1 defense screen; API 29 AVD installs/launches but stays black with Vulkan present error 5. Physical Android 10 compatibility and representative-device FPS remain unverified; investigate renderer fallback or verify on real hardware before release.

- Renderer isolation on API29 AVD: both original `-gpu host` and clean `-gpu swiftshader_indirect` runs reproduce black output plus Vulkan present error 5. This narrows the emulator issue but does not prove a device-wide Godot/API29 defect. Obtain physical Android 10 validation or a known-good API29 Vulkan emulator before release.

- Asset gap: the M1 battle board now uses temporary pixel-art sprites for all catalog unit/facility kinds plus core/walls/obstacles. Replace the hand-authored atlas with approved final art before release; current icons are functional placeholders, not production art.

- Performance measurement gap: API37 AVD `gfxinfo` collected zero ViewRoot frames while Godot rendered through SurfaceView; SurfaceFlinger latency query exposed only refresh period, no game frame timestamps. Do not infer FPS from these. Need Godot Remote Profiler/physical GPU profiler before judging 60FPS regular and 30FPS high-load targets.

- Resolved in code/tests: M5 editor Error-vs-Warning save gate and content-id/field navigation now have regressions. GUI interaction remains open; headless tests do not prove actual dock/Inspector usability.

- M6 perf sample on API37 SwiftShader AVD is below target (25.4–25.9 FPS, p95 41–42ms). Emulator software GPU makes this a diagnostic result only; physical device/frame-profiler measurement is still required before acceptance. Debug sampler is excluded from release builds.

- 2026-11-12 M5 GUI retry: Computer Use still reports the native app pipe missing and browser host unavailable after a fresh runtime reset. No UI action occurred; plugin/editor GUI interaction remains unverified, while headless plugin initialization and model tests pass.

- Renderer fallback probe (2026-11-12): API29 AVD fails both configured Mobile/Vulkan presentation and a temporary Compatibility/OpenGL APK (EGL GL-thread startup failure). Production setting is unchanged. Physical Android 10 behavior is still unknown; do not claim API29 acceptance from AVD results.

- 2026-11-12 API29 재검증 보충: Emulator 37.2.13으로 올린 뒤 기존 Google APIs API29 AVD의 Vulkan present error 5가 재현됐다. 별도 Google Play API29 이미지에서도 Vulkan 오류가 재현됐고 임시 Compatibility 빌드는 GLES 2 EGL 컨텍스트를 만들지 못했다. 임시 AVD/이미지는 제거했고 기존 AVD 데이터는 보존했다. 이 결과는 실기기 Android 10 호환 판정이 아니다.

- 2026-11-12 API37 interaction follow-up: corrected touch coordinates entered M1; deploy/resource deduction and first enemy attack/core damage were visually observed. This verifies only a short AVD combat path. Full stage, API29 hardware, GUI editor and FPS checks remain open.

- API37 checkpoint reproduction (2026-11-12): saved pre-wave snapshot was inspected on-device; force-stop/relaunch returned to same M1 run and deployed unit; core-zero defeat settled and removed checkpoint. No duplicate reward was observed. AVD combat FPS remained below numeric target (23.7–25.2 average, p95 42.80–45.68ms); physical performance is still unverified.

## Resolved: victory result wave count (2026-11-12)

- M1 victory UI used `wave - 1`, so the final wave was omitted from the result label. The shared completed-wave calculation now includes the current wave on victory and prior waves on defeat, clamped to stage bounds. Tests cover both outcomes; API37 emulator victory displayed 2/2.
- No known save migration or reward-rule change; only the count passed to settlement and displayed UI now reflects actual completed waves.

## M5 GUI access retry (2026-11-12)

Computer Use state query returned no apps; native pipe and browser host are unavailable (Windows OS error 2). Headless editor-panel structure and content validation pass, but visible dock/Inspector interaction remains open. Retried this turn; no UI interaction occurred.

- M6 environment recheck (2026-11-12): ADB currently lists no devices. Release keystore path, alias, and password environment variables are all unset; current package ID is the placeholder `com.example.holotactics`. The unsigned test AAB is not uploadable to Play. These require publisher/device inputs; no credentials were created or stored.

## User-confirmed Galaxy S25 Ultra smoke (2026-11-13)

- Resolved: user downloaded the refreshed `v0.1.0-preview.1` APK and confirmed it installed and launched on Galaxy S25 Ultra. This is user-reported startup evidence; Android version and gameplay/performance measurements were not provided.
- Still open: hands-on gameplay flows and UI/touch/safe-area checks, S25 frame-time measurement at regular/high load, Android 10/API 29 device compatibility, Godot editor GUI usability, and publisher package ID/signing/Play private-test readiness.

## 사용자 플레이 피드백 반영 (2026-11-13)

해결: 유닛 문맥창 닫기 버튼 부재, 일시정지 화면의 전투 포기 접근성, 공성 자동 진격 조작 설명 부재, 전투 중 신규 아군 배치 제한. 기획과 요구사항에 확정 규칙을 반영했고 DEC-656/657로 기록했다. 자동 테스트 및 에뮬레이터 설치·실행 배치 검증은 통과.

검증 대기: 사용자가 일시정지 메뉴에서 전투를 포기한 뒤 부분 보상 및 마을 복귀 결과를 실기기에서 확인해야 한다. 직접적인 전체 캠페인 UX, S25 성능, Android 10 실기기 검증 이슈는 기존 항목을 유지한다.

## 기획 원문 정합성 재검토 (2026-11-13)

- 발견한 잔여 상충: `PRODUCT_SPEC.md`와 `REQUIREMENTS.md` 일부가 기본 5종 즉시 해금, 수성 아군 전멸 패배 여부, 진화 재선택, 전투 중 시설 수리 규칙을 과거 초안/반대 문구로 유지하고 있었다.
- 수정: 승인된 최신 결정을 네 기획 문서와 함께 대조해 상충 표기를 제거하고, 구버전 DEC-576~578을 DEC-572~573/C2에 대체됨으로 표시했다. 구현/회귀 테스트로 정책 일치를 확인한다.
- 남은 인수 격차: Godot EditorPlugin 실제 GUI, 물리 Android 기기 성능/Android 10, Play용 앱 ID·서명·비공개 트랙 권한. 정책 문서 상충은 없음.

## M5 GUI reattempt (2026-11-13)

Computer Use was reinitialized and `sky.list_apps()` retried; the helper again reports native pipe unavailable (Windows error 2). No Godot window was returned, so visual dock/Inspector and preview-button validation remains blocked by workstation integration. Headless EditorPlugin tests remain green.

## User policy document reconciliation (2026-11-13)

The original four design documents now consistently reflect confirmed user rules: story-gated unit unlocks, defense continues while the core survives, one locked evolution choice per unit, combat/preparation repairs, and the selected DoT/incapacitation policy. The old “five units immediately unlocked” summary is explicitly marked superseded by DEC-572/573/C2. No gameplay rule required new user approval.

## Abandon confirmation viewport correction (2026-11-13)

- ADB screenshot testing found the stock abandon confirmation clipped its Korean message and left the confirm action off-screen on API37 portrait. Changed the text to wrap, localized title/actions, and shortened the message; UI assertions and a rebuilt debug APK pass. Do not release from this turn; latest APK exists only in ignored `build/`.
- API37 AVD hands-on path: campaign→M1→pause→abandon confirm→tap `포기`→0/2 result, +0 permanent currency (balance remained 165)→village. The positive completed-wave partial payout is still model-tested, not visually exercised here.

추가 UX 확인: 공성 준비 화면에서 `진격`이 전투 시작과 전체 자동 진격을 함께 한다는 안내를 노출하고 UI 회귀 테스트로 확인했다. 개별 전투 이동은 목적지 도착 후 자동 진격으로 복귀한다.

## 2026-11-13 현재 소스 Android 사전검사

- `export_android_aab.ps1` 사전검사는 PowerShell 파싱/Godot 경로/API36 확인 후 예시 앱 ID `com.example.holotactics`에서 안전하게 중단함. 영구 앱 ID와 출판 서명 값이 없어 Play용 AAB는 생성하지 않았다.
- 현재 소스 unsigned 테스트 AAB의 ZIP 엔트리는 확인했지만 캐시된 bundletool은 실행형이 아니라 이번 산출물의 매니페스트/번들 규격 검증은 미완료. Play 업로드도 수행하지 않는다.
