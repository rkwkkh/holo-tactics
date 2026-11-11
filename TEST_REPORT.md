# Test report

## M0

- 실행 환경: Windows, Godot 4.7.2 stable, Java 17; Android SDK 경로는 `%LOCALAPPDATA%/Android/Sdk`.
- 통과: `Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --quit` (프로젝트 import 및 스크립트 파싱).
- 통과: `--headless --path . --script res://tests/run.gd` (유효 데이터, 중복 ID, 미해결 참조, 비정수 버전, 순환 의존성, 버전 상수).
- 통과: `--headless --path . --script res://scripts/validate_content.gd` (`Content validation passed`).
- 통과: `--headless --path . --quit-after 2` (기본 메인 씬 실행).
- 첫 검증에서 JSON 숫자 타입 가정 때문에 버전 검사에 실패했고, 정수값 판별을 보완한 후 전체 재실행 통과.
- Android 내보내기·실기기 FPS·Google Play AAB 업로드는 아직 검증하지 않았다.
