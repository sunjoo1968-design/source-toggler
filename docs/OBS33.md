# Sunjoo OBS Link Controller 0.2.1 — OBS 33

제작자 SunjooAn · 2026-10-26 · Windows x64 · 검증 OBS 33.0.0

## 변경
- 배치 편집 카메라 번호와 선택 카메라 장면/그룹 열기 버튼 제거. OBS 장면 목록의 Camera Inputs 장면에서 해당 그룹을 직접 편집합니다.
- 전체 ME 연동 선택 버튼 영역(CUT/MIX/카메라 버튼) 제거. 기존 전체 ME 공통 단축키·등록값과 ME별 독립 단축키 옵션은 유지합니다. 공통 전환 타입/시간 글로벌 옵션도 유지합니다.
- UI의 Hybrid 접두사와 새 기본 생성 이름에서 Hybrid 제거. 기본 ME1/ME2, ME1 PGM Output/ME2 SUB Output/ME2 Camera Inputs, Copy Output 사용.
- 이전 복제 출력은 소유 ME를 확인하고 같은 UUID를 재사용하여 이름만 정리합니다. 같은 이름의 사용자 소스를 덮어쓰지 않습니다. 내부 DLL/source/vendor/hotkey/설정 키와 스크립트 파일명은 호환성을 위해 유지합니다.

## 업데이트
OBS를 사용자가 종료한 후 해당 OBS용 파일로 교체합니다. 기존 등록 스크립트를 같은 파일 경로에서 덮어쓰고 다시 로드하면 기존 설정·단축키를 이어 쓸 수 있습니다. 두 스크립트를 동시에 등록하지 마세요. 이전 출력 장면·그룹의 사용자 지정 이름은 유지됩니다. 예전 기본 이름까지 정리하려면 글로벌 옵션에서 ME 이름을 확인한 뒤 **이름만 적용**을 사용하세요. **설정 완료/전체 적용**은 기존처럼 카메라 1로 전환하므로 이름 정리만을 위해 누를 필요가 없습니다.

OBS33 설치형: ZIP의 plugins 안 모듈 폴더를 C:/ProgramData/obs-studio/plugins/에 복사합니다. portable: plugins 폴더를 OBS 루트에 합칩니다. 새 경로는 plugins/camera-mix-hybrid/camera-mix-hybrid.dll입니다. 기존 동일 모듈 DLL은 다른 경로에 중복 설치하지 마세요. 공식 OBS33.0.0 SDK로 재빌드했으며 RC1용 배포와 구분합니다. Source Switcher는 기존 OBS33 재빌드판을 사용할 수 있습니다.

## 검증
- 격리된 해당 OBS에서 실제 Properties UI의 삭제 항목 부재와 전체 ME 공통 단축키 유지 확인.
- 기존 Copy Output의 구 이름을 같은 UUID로 재사용하고 중복 출력 없이 복원 확인.
- 신규 설정 생성/재시작 복원 및 이전 릴리스 설정으로 생성 후 새 버전으로 재시작 복원, 정상 종료 통과.
- 실제 ME1/ME2 MIX 도중 TAKE, 양쪽 카메라 기여·독립 완료·이전 카메라 OFF, 탈리/멀티뷰 PGM/PVW 일치 및 정상 종료 검증.

현장 설치본·설정·탈리·멀티뷰·씬 트리·리스너 펌웨어는 변경하지 않았습니다. OBS33의 연동 시험 상대는 기존 Multiview 0.6.0/Tally 1.7.0-obs33.rc1이며 이 작업에서 재배포하지 않습니다. OBS32 상대는 Multiview 0.5.4/Tally 1.6.0-obs.6입니다. 실제 장비 수 시간 운용과 음질 평가는 별도 시험이며 전체 OBS 메모리 누수 0을 보증하지 않습니다. 외부 Source Switcher/OBS의 원저작권·라이선스는 유지합니다.
