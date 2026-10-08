# Sunjoo OBS Link Controller 개발·검증

SunjooAn · 0.1.2. scripts/camera-mix-hybrid.lua가 버전의 단일 정의입니다.

공식 OBS SDK/import libraries와 Visual Studio 2022 C++ Build Tools, CMake 3.28+를 준비한 뒤 scripts/build-hybrid.ps1 -ObsSourceDir <SDK> -ObsImportDir <imports>로 빌드합니다. 정리된 생성물·SDK는 다시 준비해야 합니다.

python tests/native-hybrid.py는 별도 libobs/D3D11에서 CUT/MIX 픽셀·배치·복제 참조 수명을 검증합니다. scripts/build-hybrid.ps1의 -PrepareTestRuntime 후 python tests/portable-hybrid.py는 격리 OBS 생성·반복 적용·재시작 복원·정상 종료를 검증합니다. 사용 중인 OBS는 종료하지 않습니다. Python Pillow가 필요합니다.

이전 비 Hybrid 전용 mock-controller/memory-stress 테스트는 보관본으로 이동했습니다. 개인 설정·인증·개발 로그 및 OBS/Qt DLL은 공개 배포에서 제외합니다.
