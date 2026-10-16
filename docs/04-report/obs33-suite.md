# OBS33 Suite 완료 보고

2026-10-16 · SunjooAn

Controller 0.2.0, Multiview 0.6.0, Tally 1.7.0-obs33.rc1, Scene Tree View 1.1.0을 OBS 33.0.0-rc1 전용 prerelease로 게시했다. 각 저장소 공개 범위는 PUBLIC/PUBLIC/PRIVATE/PUBLIC 유지. GitHub 모든 asset digest와 로컬 SHA256 일치, 네 release tag의 원격 commit 일치 및 Legacy stable main 불변 확인.

새 배포는 native SDK 재빌드, 신형 plugins/module/module.dll+data/manifest.json, Creator/Version UI, explicit main canvas Lua API, 전용 build/package tooling을 제공한다. source/vendor/settings ID와 Listener/UDP/vMix/ATEM, firmware 13파일은 보존했다.

검증: 실제 OBS33 네 모듈 로딩, ME1/ME2 중간 MIX TAKE 독립 완료, PGM/PVW 탈리/멀티뷰, 120초 117 TAKE/5재접속, 최종 조합 재시험, Controller CREATED/RESTORED 재시작/정상종료, 3 CTest 및 Hub 277회귀/runtime 모두 통과. 전체 OBS 종료 잔여 할당 1건과 장시간 실장치/음질/씬트리 전체 조작 미검증은 docs/OBS33-VALIDATION.md에 명시했다.

이전 릴리스는 OBS 32 Legacy로 표시하고 legacy-obs32-20261016 태그·로컬 source archive로 보존했다. 원본 OBS33 폴더·현장 설치·사용자 설정 및 3D/LOCAL-RESUME 작업을 변경하지 않았다.

로컬 게시 기록: release/OBS33-GITHUB-PUBLISHED.json
배포 ZIP SHA256: release/OBS33-RELEASES.json

- https://github.com/sunjoo1968-design/source-toggler/releases/tag/obs33-controller-v0.2.0-rc1
- https://github.com/sunjoo1968-design/obs-multiview-plus/releases/tag/obs33-multiview-v0.6.0-rc1
- https://github.com/sunjoo1968-design/OBS-tally/releases/tag/obs33-tally-v1.7.0-obs33.rc1-rc1
- https://github.com/sunjoo1968-design/scene-tree-view/releases/tag/obs33-scene-tree-v1.1.0-rc1
