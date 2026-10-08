# Camera MIX Hybrid 0.1.0 개발판

**제작자 SunjooAn · 버전 0.1.0**

기존 Camera MIX Controller 1.3.4를 보존하는 별도 개발판입니다. Lua가 설정·단축키·카메라 전환을 맡고, 새 출력 플러그인이 OBS 스튜디오 모드의 소스 복제를 처리합니다. Source Switcher 0.4.4도 ME1 제어에 필요합니다.

## 설치

1. 방송 종료 후 사용자가 OBS를 종료합니다.
2. 패키지의 `obs-plugins/64bit/camera-mix-hybrid.dll`을 OBS 설치 폴더의 동일 경로에 복사합니다. 플러그인의 별도 data 폴더는 필요하지 않습니다.
3. `scripts/camera-mix-hybrid.lua`를 원하는 폴더에 보관합니다. 기존 `camera-mix-controller.lua`를 덮어쓰지 않습니다.
4. OBS를 실행하고 **새 장면 모음**을 만들거나 기존 장면 모음의 사본에서 시험합니다.
5. 도구 → 스크립트 → +에서 `camera-mix-hybrid.lua`를 추가합니다. 기존판과 함께 로드할 수 있지만 동일 출력·그룹 이름을 지정하지 않습니다. 기본 단축키도 새로 배정합니다.

이번 개발 작업은 현장 OBS에 자동 설치하지 않았으며 탈리 코드를 변경하지 않았습니다.

## 설정

- ME1에는 기존 카메라 **장면**을 선택합니다. 장면 안의 자막·장식도 함께 전환됩니다.
- ME2 이후에는 원본 카메라 **소스 또는 장면**을 선택합니다. 자동으로 생성되는 카메라별 그룹 안이나 그룹 자체에서 배치를 편집합니다.
- 글로벌 옵션에서 ME 이름, 출력·입력 이름, 공통 CUT/MIX 및 시간을 설정합니다. 기본값은 CUT, MIX 시간 300ms입니다.
- 설정 완료 / 전체 적용으로 출력 연결을 생성합니다. 반복 적용이나 입력 교체는 동일 그룹의 배치·추가 항목을 유지합니다. 전체 적용은 카메라 1을 선택합니다.
- 기본 이름은 **Hybrid ME1 PGM Output**, **Hybrid ME2 SUB Output**, **Hybrid ME2 Camera Inputs**입니다. 기존판의 장면을 자동으로 가져오거나 이름을 변경하지 않습니다.
- 출력 장면의 `Hybrid Copy Output`이 실제 영상 출력입니다. 숨겨진 원래 제어 소스/입력 장면은 다시 표시하지 않습니다. 외부 자막은 출력 위에 배치합니다.

## OBS 소스 복제 사용

1. 스튜디오 모드를 켭니다.
2. 스튜디오 모드 옵션에서 **장면 복제**와 **소스 복제**를 켭니다.
3. Preview에 Hybrid 출력 장면을 선택하고 카메라·배치를 정합니다.
4. OBS 전환 버튼으로 TAKE합니다. PGM은 해당 시점의 선택·배치를 유지합니다.
5. Preview에서 다음 카메라를 선택합니다. PGM에는 다음 TAKE 시 반영됩니다. OBS의 Preview/PGM 맞바꾸기 옵션을 사용하는 경우 Preview 장면도 확인합니다.

소스 복제를 켜면 Lua의 CUT/MIX는 Preview 출력에 적용됩니다. 방송으로 보내는 TAKE의 전환 타입·시간은 OBS의 장면 전환 설정을 따릅니다. 카메라를 MIX 중인 상태에서 복제하면 선택한 도착 카메라의 완성 배치를 사용하므로, 이 개발판은 MIX 완료 후 TAKE를 기준으로 사용합니다.

소스 복제를 끄면 원본 출력이 공유되어 기존 방식의 직접 전환이 가능합니다. 원래 영상 장치의 복제/공유 정책은 OBS 각 소스의 정책을 따릅니다. 화면을 정지 이미지로 저장하는 기능은 아닙니다.

## 검증 범위와 제한

Windows x64 / OBS 32.2.2에서 ME1 장면 복제, ME2 선택·배치 복제, 외부 자막, 기본 CUT/MIX, 500회 복제 자원 회수, 실제 OBS의 소스 복제 TAKE와 Preview 독립, Lua 반복 적용 및 재실행 복원·정상 종료를 확인했습니다. 500회 반복 후 libobs 할당 수가 동일했습니다. portable OBS 종료 로그의 전체 메모리 누수 수 1은 기존 기본 환경에서도 확인되는 값이며, 전체 OBS의 무누수를 의미하지 않습니다.

복제된 private 장면에 대한 기존 탈리의 원본 장면 대응은 이번 개발판의 검증 범위에 포함하지 않습니다. 기존 탈리 리스너·펌웨어·vMix·ATEM 및 OBS 탈리 코드는 유지했습니다.

## 빌드 및 라이선스

공식 OBS 32.2.2 source SDK, Windows x64 OBS import libraries, CMake 3.28+, Visual Studio 2022 C++ Build Tools가 필요합니다.

```powershell
./scripts/build-hybrid.ps1 -ObsSourceDir <OBS-SDK> -ObsImportDir <OBS-import-libraries>
```

`-PrepareTestRuntime`을 추가하면 설치된 OBS에서 별도 portable 테스트 환경을 구성합니다. 이후 `python tests/native-hybrid.py`, `python tests/portable-hybrid.py`로 검증합니다. 테스트는 별도 portable 경로와 실행한 PID를 확인한 후 그 테스트 OBS만 정상 종료합니다.

버전 원본은 Lua의 VERSION이며 CMake와 패키지 이름이 이를 사용합니다. Native 출력은 GPL-2.0-or-later로 제공하며 소스와 LICENSE를 함께 포함합니다. OBS 및 Source Switcher의 제작자·라이선스는 각 외부 구성요소와 동봉된 문서에 유지합니다. Source Switcher는 Exeldro의 외부 플러그인이며 이 패키지에 DLL을 재배포하지 않습니다.
