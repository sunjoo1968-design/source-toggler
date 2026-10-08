# Sunjoo OBS Link 통합 검증 및 보관

제작자: SunjooAn · Controller 0.1.1 / Multiview 0.5.3 / Tally 1.6.0-obs.5

세 원래 프로젝트에서 개발하고 현장 설치본을 자동 교체하지 않았다. 사용량 소진 전에 모든 이번 검증과 패키징을 완료했다.

## 구현과 검증
각 컴포넌트의 OBS 등록 이름과 사용자 화면에 공통 명칭을 적용했다. 기존 source type ID, WebSocket vendor, 설정 경로와 카메라 배정은 유지했다. 네이티브 탈리 응답은 제품군과 함께 로드된 Controller/Multiview 이름을 선택 필드로 제공한다. 실제 OBS에서 세 모듈 동시 로드와 두 방향의 복제 PGM/PVW 일치를 검증했다.

멀티뷰 그래프 검색을 반복 탐색으로 변경하여 깊은 재귀에 따른 스택 소진 위험을 줄였다. 8192 노드 한도에서 모호한 판정을 거부하고, 깊은 중첩·순환·한도 초과 회귀를 추가했다. 테스트 허브는 자동 UDP 포트로 현장 포트와 분리했다.

각 컴포넌트의 상세 검증은 obs-link-controller.md, Multiview와 Tally 프로젝트의 docs/04-report/obs-link-multiview.md 및 obs-link-tally.md에 기록했다. 실제 리스너/방송 장시간 운용과 서명은 이번 검증에 포함되지 않는다. OBS 첫 실행 RTMP 기본 구성 누수 1건과 초기화 프로필 0건을 구분했다.

## 보관과 정리
- Source-Toggler/archive/pre-obs-link/Controller-1.3.4.zip
- OBS-Multiview/archive/pre-obs-link/Multiview-0.5.1.zip
- wifi-vtally-v1.0.1/archive/pre-obs-link/Tally-1.5.12.zip

각 폴더의 README에 보관 ZIP 해시를 기록했다. 원래 release 및 이전 OBS 호환 .1/.2/.3/.4 버전도 유지했다. 이전 Tally의 현장 설정을 포함하는 확장 폴더는 복사하지 않고 설정이 제외된 공개 릴리스 ZIP을 보관했다. 리스너 firmware와 도구 13개 파일은 기존 1.5.12와 해시가 일치한다.

멀티뷰의 재생성 가능한 package-source 임시 디렉터리 4개를 최종 소스 ZIP 검증 후 삭제했다. 통합 개발 일회성 스크립트 6개는 Source-Toggler/.local/development-history/obs-link-20261008로 이동했다. SDK·빌드 의존성은 다음 빌드에 필요하므로 보존했다. 사용자 3D 작업, .gitignore와 LOCAL-RESUME 변경은 보존했다.

## 릴리스
각 프로젝트 release의 sunjoo-obs-link-*-windows-x64.zip이 최종 설치 파일이다. ZIP 내 SHA256SUMS와 바깥 .sha256 파일을 제공한다. Source-Toggler/release/OBS-LINK-RELEASES.json에 세 파일 경로·크기·해시를 기록했다. 개인 설정/인증/개발 히스토리/테스트 DLL을 제외하고 모든 내부 해시와 ZIP 무결성을 검증했다.

기존 DLL 파일명은 중복 로드와 설정 손실을 피하도록 유지한다. OBS를 수동 종료한 후 기존 파일을 교체하며 이름만 다른 DLL을 추가 설치하지 않는다. 새 Controller는 camera-mix-hybrid.lua이고 기존 camera-mix-controller.lua는 보관판이다. 같은 출력에 두 Lua를 동시에 적용하지 않는다. Tally native 실제 경로 옵션 ON은 복제 경로를 사용하고 OFF는 기존 방식이다. 리스너 firmware 업데이트는 필요하지 않다.
