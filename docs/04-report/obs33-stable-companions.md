# OBS33 정식 Companion 릴리스 완료

2026-10-26 · SunjooAn

각 원래 프로젝트의 codex/obs33-stable 브랜치에서 OBS33.0.0 정식 SDK로 Multiview0.6.1, Tally1.7.2-obs33.1, SceneTree1.1.1을 빌드·검증·게시했다. Tally의 c10085e 빠른 CUT preview 보완은 유지했다. Controller0.2.1 및 리스너/UDP/vMix/ATEM 구현은 변경하지 않았다.

검증: CTest3개, Hub285개 통과/기존1skip, packaged Hub 상태·HTTP·펌웨어·MIX·재접속·배정복원 통과. 실제 OBS33에서 120초 TAKE116회/인증재접속5회 및 ME1/ME2 중간 MIX TAKE/PGM·PVW/정상종료 통과. CUT 목적지100회와 동시CUT 중4000 snapshot 모두 프로그램 경로 유지. 실제 멀티뷰 설정·전체화면·재열기 및 씬 트리 목록/모음재로드 검증 통과. 최종 패키지로 재시험 통과.

보존: firmware13파일 동일. 기존 모든 릴리스 자산의 ID/이름/digest가 게시 전과 같음(MV6개/Tally11개/SceneTree4개 릴리스). Tally는 PRIVATE, 나머지는 PUBLIC. 사용자 .gitignore/LOCAL-RESUME·3D 작업은 커밋하지 않았고 현장 설치본·설정을 변경하지 않았다. 씬트리 OBS33 태그는 기존32 자동빌드와 분리했다.

한계: 전체 OBS 종료 잔여할당1건 관찰. 전체누수0 주장하지 않음. 실장치 수시간 방송·음질과 모든씬트리 수동조작 미검증. 각 ZIP README/VALIDATION에 설치·한계 기재.

게시:
- https://github.com/sunjoo1968-design/obs-multiview-plus/releases/tag/obs-link-multiview-v0.6.1
- https://github.com/sunjoo1968-design/OBS-tally/releases/tag/obs-link-tally-v1.7.2-obs33.1 (비공개)
- https://github.com/sunjoo1968-design/scene-tree-view/releases/tag/obs-link-scene-tree-v1.1.1

로컬 해시/게시 기록: release/OBS33-STABLE-COMPANIONS.json 및 OBS33-STABLE-COMPANIONS-PUBLISHED.json. 세 새 릴리스 자산9개 모두 GitHub SHA256과 로컬 일치 확인.
