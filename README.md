# Sunjoo OBS Link Controller

제작자 **SunjooAn** · 현재 버전 **0.1.1**. [통합 버전 안내](docs/OBS_LINK_SUITE.md).

# Camera MIX Controller 1.3.4

**제작자: SunjooAn · 버전: 1.3.4**

OBS에서 카메라 장면과 그룹을 방송용 CUT/MIX로 전환하는 Lua 스크립트입니다.

- ME1: 기존 카메라 장면을 전환하며 장면 안의 자막·장식을 유지합니다.
- ME2~ME8: 원본 소스/장면을 카메라별 그룹에 배치하고, 배치가 포함된 두 화면을 하나의 OBS Fade로 혼합합니다.
- 글로벌 ME 이름/출력·입력 이름/공통 타입·시간. 기본 CUT, MIX 시간 300ms.
- 그룹 자체와 내부 항목의 위치/크기/자르기를 반영합니다. 내부 MIX 화면은 공개 장면 목록에 추가하지 않습니다.
- 입력 변경·반복 전체 적용은 같은 그룹의 주 입력만 교체하며 배치·추가 항목을 유지합니다.
- ME별/전체 카메라 제어와 독립 단축키 옵션을 제공합니다.
- OBS 재시작 시 마지막 카메라와 설정을 복원하고 장면 로드가 늦으면 재시도합니다.
- 사용 ME 수를 줄이면 비활성 ME의 전환 자원을 해제하고, 다시 늘리면 기존 선택·배치·자막을 유지하며 복원합니다.
- 제작자와 버전을 스크립트 설명 및 설정창에 함께 표시합니다.

## 설치

검증 환경: Windows x64 / OBS Studio 32.2.2. ME1에는 [Exeldro Source Switcher](https://github.com/exeldro/obs-source-switcher/releases) 플러그인이 필요합니다(검증 버전 0.4.4). 이 프로젝트의 설치 ZIP에는 외부 플러그인이나 OBS DLL을 포함하지 않습니다.

1. 배포 ZIP의 data 폴더를 OBS 설치 폴더에 복사하거나 scripts/camera-mix-controller.lua를 원하는 폴더에 저장합니다.
2. OBS → 도구 → 스크립트 → +로 camera-mix-controller.lua를 추가합니다.
3. 카메라·화면 설정을 열고 사용할 ME 수와 입력을 선택합니다. ME1은 장면, ME2 이후는 소스 또는 장면을 선택합니다.
4. 설정 완료 / 전체 적용을 누릅니다. 이 버튼은 카메라1로 전환합니다.
5. ME1 PGM Output / ME2 SUB Output 등의 출력 장면을 실제 방송 장면에 연결합니다. 고정 자막은 MIX 출력 위에 배치합니다.

업데이트는 Lua를 교체하고 스크립트를 새로고침합니다. 파일명을 바꾸는 이전 버전 이행 시 기존 두 등록 항목을 제거하고 현재 파일을 추가하세요. 개인 설정 가져오기 파일은 공개 배포에 포함하지 않습니다. 재시작 후에는 전체 적용을 다시 누를 필요가 없습니다.

[자세한 사용법](docs/broadcast-mix-guide.md) · [글로벌 옵션](docs/global-options-guide.md) · [개발 및 검증](docs/DEVELOPMENT.md) · [변경 기록](CHANGELOG.md)

## 저장소 구성

- scripts/: 주력 컨트롤러 하나.
- tests/: OBS LuaJIT 모의 회귀와 별도 libobs/D3D11 픽셀 검증.
- vendor/: 읽기 검증에 사용한 외부 공식 소스와 해당 라이선스. 스크립트에 포함해 컴파일하지 않습니다.
- .local/: 개인 설정·개발 이력·검증 결과(비공개, Git 제외).
- release/: 버전별 설치 ZIP(로컬 생성, Git 제외).

외부 탈리 연동은 별도 후속 작업입니다. 현재 배포가 외부 탈리 허브/리스너를 수정하지 않습니다.
