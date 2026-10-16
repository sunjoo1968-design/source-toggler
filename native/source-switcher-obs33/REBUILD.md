# Source Switcher OBS33 비공식 재빌드

버전: 0.4.4-sunjoo.obs33.1 · OBS 33.0.0-rc1 · Windows x64
원작자: Exeldro · OBS33 재빌드 및 안내: SunjooAn

원본 https://github.com/exeldro/obs-source-switcher 의 0.4.4(593be4bb54c27d6e378693b98dafe904f04c46dc)를 기준으로 공식 OBS33 RC1 headers/import libraries를 사용하여 재빌드했습니다. 원작자의 공식 OBS33 배포가 아닙니다. GPL-2.0 및 원작자 표시를 유지합니다. 원본 C 로직 변경은 없고 속성 창의 재빌드 정보 한 줄, 버전 헤더·Windows 빌드 설정·배포 manifest를 추가했습니다.

## 설치
OBS를 사용자가 종료한 뒤 새 portable OBS에서는 ZIP의 plugins 폴더를 OBS 루트에 합칩니다. 설치형 OBS에서는 plugins 안의 source-switcher 폴더를 C:/ProgramData/obs-studio/plugins/ 아래에 복사합니다. DLL 이름 source-switcher.dll과 source-switcher 소스 ID는 유지합니다. 예전 source-switcher.dll을 레거시 위치와 새 위치에 중복 설치하지 마세요. 기존 DLL은 보관한 뒤 교체합니다. 기존 소스 배정과 Controller 설정은 유지합니다. 현장 설치본은 자동 변경하지 않았습니다.

## 빌드
동봉 source 폴더의 CMakeLists.txt를 대상으로 cmake -S source -B build -G "Visual Studio 17 2022" -A x64 -DOBS_SOURCE_DIR=<공식OBS33RC1소스> -DOBS_IMPORT_DIR=<OBS33 import libs> 후 cmake --build build --config Release 를 실행합니다. 전체 Controller 저장소에서는 scripts/build-obs33.ps1 -SourceSwitcher -ObsPath <OBS33> -ObsSourceDir <SDK>를 사용합니다.

## 시험 범위
격리된 OBS33 RC1에서 네 suite 모듈과 함께 로딩, ME1/ME2 PGM/PVW, MIX 도중 TAKE의 두 카메라 기여·독립 완료·이전 카메라 OFF 및 정상 종료를 검증합니다. 전체 Source Switcher 옵션과 실제 방송 장시간 운용·음질은 별도 검증이 필요합니다. OBS33 시험판의 전체 종료 잔여 할당 1건은 suite 보고서에 기록되어 있으며 전체 누수 0건을 주장하지 않습니다.
