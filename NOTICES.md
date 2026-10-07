# 외부 구성요소

Camera MIX Controller 제작자: **SunjooAn**, 버전: **1.3.3**.

ME1의 영상 전환은 Exeldro의 Source Switcher 0.4.4를 사용합니다. 별도 설치가 필요하며 이 설치 ZIP에 DLL을 재배포하지 않습니다. https://github.com/exeldro/obs-source-switcher

vendor/source-switcher.c 및 .h와 관련 라이선스는 Source Switcher 검증용 공식 자료입니다. GNU GPL v2 라이선스 텍스트는 vendor/LICENSE-source-switcher에 보존합니다.

vendor/obs.h, obs-scene.c, crop-filter.c는 OBS Studio 32.2.2 검증용 공식 자료입니다. 파일의 원 저작권 표기와 GPL v2-or-later 안내를 보존합니다. GPL v2 텍스트는 vendor/LICENSE-OBS에 포함합니다. https://github.com/obsproject/obs-studio

외부 구성요소의 저작권을 컨트롤러 제작자로 대체하지 않습니다. 저장소에 보관된 vendor 자료는 컨트롤러 Lua에 포함해 컴파일하지 않습니다.
