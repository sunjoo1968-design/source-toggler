# Camera MIX Hybrid 설계

버전은 `scripts/camera-mix-hybrid.lua`의 VERSION 한 곳에서 관리하며 CMake가 이 값을 읽습니다. 제작자 SunjooAn을 Lua 설명·설정 및 native 소스 이름·속성에 표시합니다.

Lua는 기존 기능을 별도 파일에 유지합니다. 기본 이름은 Hybrid ME1 PGM Output, Hybrid ME2 SUB Output, Hybrid ME2 Camera Inputs이며 소유 메타데이터와 단축키 이름 공간도 분리합니다. 자동 설정 가져오기는 수행하지 않습니다.

`camera_mix_hybrid_output`은 복제 금지 플래그가 없는 composite 입력입니다. 원본은 `live_uuid`로 Source Switcher 또는 private Fade를 렌더링합니다. Lua는 선택 변경 시 `snapshot_uuid`를 갱신합니다. OBS private copy는 이 선택 장면/view를 즉시 private copy로 보존합니다. 복제 생성 중 Source Switcher의 mutex를 조회하지 않습니다. 실제 영상 장치의 공유 정책은 OBS가 결정합니다. 외부 자막은 기존 출력 장면의 소스 복제로 유지됩니다.

출력 child 참조는 mutex 아래에서 확보하고 render/enum/audio의 OBS 호출 전 mutex를 해제합니다. create에서는 registry lock 안에서 composite 자식을 재귀 열거하지 않습니다. destroy는 활성 연결 및 참조를 해제합니다. clone의 원본 UUID는 private metadata에 기록하되 이번 작업에서 탈리 코드를 변경하지 않습니다.

검증은 별도 libobs D3D11 픽셀 검사, 500회 복제·해제 할당 수 비교, 별도 portable OBS의 Lua 전체 적용·반복 적용·카메라 선택·재실행·정상 종료로 진행합니다. 초기 개발판은 선택 완료 후 TAKE를 기준으로 검증하며, MIX 도중 복제는 완료 대상 카메라를 사용합니다.
