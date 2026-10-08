# Camera MIX Hybrid 0.1.0 개발판 결과

제작자 SunjooAn. 기존 Controller 1.3.4 파일과 설치본을 변경하지 않았고, 탈리 프로젝트를 수정하지 않았습니다.

Lua 설정·단축키·CUT/MIX 제어와 복제 가능한 native 출력의 혼용 구조를 별도 이름으로 구현했습니다. 생성 기본 이름, 소유 메타데이터와 단축키가 기존판과 분리됩니다. 이름 변경 시 같은 ME의 이전 복제 출력 연결을 대치하며, 기존 그룹 주 입력 교체·추가 항목 보존 기능을 유지합니다. Lua hotkey 해제는 실제 OBS Lua API가 요구하는 callback으로 수행합니다.

검증 결과:

- MSVC x64 Release 빌드 통과.
- 실제 libobs D3D11 픽셀 검사: ME1 선택 장면 유지, ME2 선택·배치 유지, 검은 화면 없는 복제, 외부 자막 보존. 기존 CUT/MIX 밝기 및 배치 검증도 통과.
- 500회 private 복제·해제 전후 libobs 할당 수 동일. 복제본 재복제도 원래 선택·배치를 유지.
- 별도 portable OBS 32.2.2: 전체 적용·반복 적용, 카메라 선택, 스튜디오 소스 복제 ON에서 TAKE 후 Preview 변경 시 PGM 유지 및 재TAKE 반영 확인.
- 종료·재실행: 마지막 ME2 카메라 2 복원, 출력 연결 1개 유지, 두 번 정상 종료 exit=0. 최종 로그에 Lua 실행 오류와 double destroy 없음.
- 기존 Controller 회귀 테스트 및 100회 load/unload, 1000회 적용, 3000회 선택 모의 자원 검사 통과.

초기 테스트에서 timer 내부 공개 장면 생성으로 멈춤을 재현했으며, 최종 실제 UI 테스트는 FINISHED_LOADING callback에서 설정 적용을 실행합니다. Native create에서는 registry lock 안에서 composite child를 재귀 열거하지 않으며 clone은 Lua가 제공하는 snapshot UUID를 사용합니다. Headless Lua 테스트의 frontend 및 종료 조건은 실제 OBS 종료 검증으로 대체했습니다.

개발판 제한: MIX 도중 TAKE는 도착 카메라의 완성 배치를 사용합니다. 복제된 private 장면의 기존 탈리 대응은 추가 검증/호환 작업 대상입니다. 카메라 장치 및 소스의 복제 정책은 OBS를 따릅니다. 전체 portable OBS 종료의 기존 누수 수 1을 native 플러그인 무누수로 해석하지 않습니다.

패키지에는 Lua, DLL, native 소스·라이선스, 테스트 소스, 빌드 스크립트, 안내 및 SHA256SUMS를 포함합니다. 현장 설치·재시작과 GitHub 게시를 수행하지 않았습니다.
