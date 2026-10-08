# Sunjoo OBS Link 개선 계획

2026-10-08 사용자 승인: 앞서 제안한 연결·버전 상태 표시, MIX 도중 TAKE 복제 개선, 통합 반복·재접속·장시간 검증 실행.

## 개발 범위
- 각 원래 프로젝트에서 개발: Source-Toggler, OBS-Multiview, wifi-vtally-v1.0.1.
- 현장 OBS/허브 자동 종료·교체 금지. 리스너 firmware·UDP·vMix/ATEM·사용자 3D 작업 보존. 탈리 비공개 유지.
- 새 버전은 Controller 0.1.2, Multiview 0.5.4, Tally 1.6.0-obs.6을 후보로 사용하되 검증 완료 후 확정한다. 제작자 SunjooAn 표기.

## 구현 및 성공 조건
1. 기존 GetSnapshot protocol 1에 선택적 호환 정보 추가, 허브 화면에서 OBS 연결과 Controller/Multiview/Tally 설치 버전·부재·호환 경고를 한곳에 표시. 기존 bridge/옵션 OFF도 지원한다.
2. 현재 wrapper create는 snapshot_uuid의 도착 카메라를 복제하여 MIX 중간 TAKE가 도착 완성 화면으로 바뀐다. OBS 공개 transition API와 Source Switcher 구현을 조사하여 실제 A/B·진행률·배치를 독립 복제하고 이후 Preview 변경에도 PGM을 유지한다. 비디오 프레임 정지 방식은 사용하지 않으며 두 카메라의 실제 기여를 탈리/멀티뷰가 인식해야 한다. ME1/ME2, clone-of-clone, 음성과 참조 수명을 검증한다.
3. 기존 실제 OBS 통합 runtime 테스트를 반복 CUT/MIX/TAKE, 네트워크 재접속, 입력·장면 교체, 정상 종료로 확장한다. 정해진 시간·반복 수·참조 수·PGM/PVW 판정을 결과에 기록한다. 실제 장비 장시간 운용을 모의 시험과 혼동하지 않는다.
4. 원래 릴리스는 보존하고 새 설치 ZIP·해시·검증 보고서를 제공한다. GitHub 게시와 정리는 기존 정책 및 이번 검증 결과에 따라 수행한다.

## 현재 체크포인트
구현 진행: Tally 상태 이벤트·서버 캐시 재전달·OBS 설정 패널·규격 2 호환 확인 구현 및 백엔드 빌드/기존 273개+신규 4개 테스트 검증. Controller native는 실제 Fade A/B·진행률·배치를 복제하고 private Fade를 독립 완료한다. Multiview/Tally는 복제된 Fade 아래 원본 UUID도 추적한다. 실제 OBS ME1·ME2 중간 TAKE 테스트 통과. 600초 569 TAKE/28 인증 재접속 및 정상 종료 통과. native idle 500복제 13686→13686, 중간 MIX 100복제 16316→16316. Multiview 2000조회 13914→13914, Tally 2000조회 8414→8414. MIX 시작 경계 t=0에서 OBS manual cancel을 피하는 epsilon 처리를 추가했고 최종 빌드·재검증 중이다. 새 버전은 0.1.2 / 0.5.4 / 1.6.0-obs.6으로 설정했다.

남은 작업: 최종 Tally 실행 파일의 상태·late-client replay 테스트와 기존 runtime 테스트, 최종 3모듈 재검증, 전체 검증 보고서/새 릴리스·해시·GitHub 게시 및 완료 후 자동 재개 중지. 실제 장치의 수 시간 soak와 음질 측정은 모의 검증과 구분할 것. 이전 0.5.3 로컬 ZIP은 GitHub에서 검증본으로 복원하여 archive/previous-obs-link에도 유지했다. 사용자 3D/멀티뷰 .gitignore/LOCAL-RESUME 미커밋 변경은 유지.

계획/읽기 분석 시작. 사용량 일반 허용, primary 8% 소비. 이전 정리로 .deps/.build-tools/node_modules와 테스트 OBS가 삭제되어 빌드·테스트 의존성 재구성이 필요하다. 이전 세 GitHub 릴리스는 정상 게시·검증됨.

native/camera-mix-hybrid/output.cpp frozen create가 target(source snapshot/frozen UUID)을 obs_source_duplicate 하고 원본 UUID metadata를 기록한다. live는 ME1 Source Switcher 또는 ME2 private Fade이며 초기 create는 registry lock 아래이므로 active-child 재귀 호출을 피해야 한다. 기존 shutdown 수정·PGM private identity 판정을 유지한다.

최종 검증 모두 통과. 사용자 확정: 남은 MIX를 독립 완료. 배포 ZIP 및 GitHub 새 릴리스 게시·해시 검증 진행 중.
