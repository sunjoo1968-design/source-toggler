# Controller UI 정리 / OBS32·OBS33 정식

2026-10-26 · SunjooAn · PDCA

요청: 배치 편집 카메라 번호/선택 그룹 열기, 전체 ME 연동 버튼 영역 제거. 공통/독립 단축키 유지. UI와 신규 기본 이름의 Hybrid 제거. 기존 카메라·그룹 배치와 자막·이름·등록 ID 유지.

설계: 기존 DLL/source/vendor/hotkey/script settings 식별자는 보존한다. 복제 출력 신규 suffix는 Copy Output; 구 suffix는 소유 bank 확인 후 기존 UUID를 재사용하여 이름만 정리한다. 기존 사용자 입력 이름은 자동 변경하지 않는다. 설정 적용은 현행 명시적 버튼 경로를 유지한다.

산출: OBS32 Controller 0.1.3(별도 worktree), OBS33.0.0 정식 Controller 0.2.1. 각 대상 SDK 재빌드, 격리 OBS 최초 설정/재시작과 실제 ME1/ME2 MIX TAKE·PGM/PVW 시험. 단축키/설정 유지 및 중복 출력 방지 확인. 현장 OBS/설정 자동 교체·종료 금지.

진행: 현행 UI·이름·소유 metadata 분석 완료. OBS33 정식 공식 SDK SHA256 c1ae3c98c1bb70ebdced33e894a526fcbbbda9bfd95806970a3fc31f74b08f6c 확인. 공식 설치본은 33.0.0, 기존 격리 시험본은32.2.2와33RC1 보존.
