# Sunjoo OBS Link Controller

제작자 **SunjooAn** · 버전 **0.1.2** · Windows x64 / OBS 32.2.2

Lua 설정·단축키와 네이티브 복제 출력 플러그인을 함께 사용하는 주력 컨트롤러입니다. Sunjoo OBS Link Multiview 0.5.4 및 Tally 1.6.0-obs.6와 함께 검증했습니다.

## 설치와 사용
1. 방송이 없는 시간에 OBS를 종료합니다.
2. ZIP의 obs-plugins 폴더를 OBS 설치 폴더에 합칩니다. DLL 파일명 camera-mix-hybrid.dll은 호환성을 위해 유지합니다.
3. ME1 제어에는 Exeldro Source Switcher 0.4.4가 필요합니다. 외부 플러그인은 이 ZIP에 포함하지 않습니다.
4. OBS 도구 → 스크립트에서 scripts/camera-mix-hybrid.lua를 등록합니다. OBS 등록 이름과 설명은 Sunjoo OBS Link Controller입니다.
5. ME1에는 카메라 장면, ME2 이후에는 소스 또는 장면을 선택합니다. ME2의 카메라별 그룹에서 배치를 편집합니다.
6. 글로벌 옵션에서 ME 이름과 공통 CUT/MIX·시간을 지정합니다. 기본은 CUT, MIX 시간은 300ms입니다.
7. 설정 완료 / 전체 적용으로 출력과 입력 그룹을 만듭니다. 이 버튼은 카메라 1로 전환합니다. 반복 적용과 주 입력 교체는 그룹 배치·추가 자막을 유지합니다.

기본 출력 이름은 Hybrid ME1 PGM Output, Hybrid ME2 SUB Output입니다. 이름은 글로벌 옵션에서 변경할 수 있습니다. 고정 자막은 출력 위에 배치합니다. 재시작 시 마지막 카메라와 설정을 복원합니다.

## OBS 소스 복제
스튜디오 모드에서 장면 복제·소스 복제를 켜고 Preview에 출력 장면을 선택합니다. 카메라를 정한 뒤 OBS 전환 버튼으로 TAKE하면 PGM의 선택·배치를 유지하고 Preview에서 다음 카메라를 준비할 수 있습니다.

Lua의 CUT/MIX는 Preview 카메라 출력에 적용되며, TAKE의 타입·시간은 OBS 장면 전환 설정을 따릅니다. 카메라 MIX 중 TAKE하면 실제 A/B 입력·혼합 비율·배치를 복제하고 남은 MIX를 PGM에서 독립적으로 끝까지 진행합니다. Preview 변경은 이미 복제된 PGM을 바꾸지 않습니다. 영상 자체를 정지 이미지로 저장하는 기능은 아닙니다.

## 검증·빌드·보관 (저장소 기준 경로)
[통합 검증](docs/04-report/obs-link-suite.md) · [Controller 검증](docs/04-report/obs-link-controller.md) · [개발 안내](docs/DEVELOPMENT.md)

기존 비 Hybrid 1.3.4는 로컬 archive/pre-obs-link에 보관했고 지난 실행 코드·모의 테스트는 현재 소스에서 정리했습니다. 현장 설치본과 개인 설정은 유지합니다. 이전 GitHub 릴리스와 Git 이력은 삭제하지 않습니다.

공식 OBS 32.2.2 SDK와 import libraries, CMake 3.28+, Visual Studio 2022 C++ Build Tools로 scripts/build-hybrid.ps1을 실행합니다. 빌드 캐시는 정리했으므로 재빌드 시 SDK를 다시 준비하세요.

GPL-2.0-or-later. OBS 및 Exeldro Source Switcher의 제작자·라이선스는 vendor와 NOTICES.md에 유지합니다. 실제 현장 장시간 운용은 별도로 확인하세요.
