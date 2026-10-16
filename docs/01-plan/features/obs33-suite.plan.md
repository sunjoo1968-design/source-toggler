# OBS 33 Suite 전환 계획

2026-10-16 · 제작자 SunjooAn · PDCA

목표: Controller, Multiview, Tally, Scene Tree View(scene-anchor)의 현재 커밋과 배포물을 OBS 32 Legacy로 보존하고 OBS 33.0.0-rc1 전용 신규 시험 릴리스를 제작한다.

기준: 공식 tag 33.0.0-rc1(commit 7d98beb), 공식 Sources SHA256 1a73e95b5ad8addd79aeb5b48e5292b982dd2ffa69744294930a7c474c958fe0. 사용자가 제공한 Windows x64 배포 폴더는 수정하지 않고 격리 portable 시험본을 사용한다.

변경: OBS 33 headers/import libraries, Qt 6.11 ABI, 새 plugins/<module>/<module>.dll + data/manifest.json 레이아웃, core 모듈 경로, 설치/시험 스크립트. 내부 source/vendor ID와 사용자 설정 키는 보존한다. 기존 기능 및 Source Switcher 의존성을 검증한다. 사용자 화면에 SunjooAn과 버전을 표시한다.

후보: Controller 0.2.0, Multiview 0.6.0, Tally 1.7.0-obs33.rc1, Scene Tree View 1.1.0. 모두 OBS 33 RC1 시험판으로 명시한다.

검증: 네 native DLL 재빌드, 기존 회귀시험, 새 plugin manager 로딩, Lua 복원, ME1/ME2 CUT/MIX/TAKE, PGM/PVW 판정, Scene Tree 저장/복원 및 정상 종료. 미검증 범위를 명시한다. ZIP manifest/hash와 GitHub public/public/private/public 유지 확인 후 prerelease 게시.

보존: 현장 OBS/허브 자동 종료·교체 금지. firmware/UDP/vMix/ATEM 불변. 기존 릴리스는 삭제하지 않는다. 사용자 .gitignore/LOCAL-RESUME/3D 작업 제외. 제작자·외부 라이선스 유지.

진행: 공식 변경·소스 조사 완료. OBS 33 플러그인 로딩 개편, 스튜디오 모드 그룹 복제 수정, Qt 최소 6.10 변경 확인. 신규 개발 브랜치와 Legacy manifest 준비 중.
