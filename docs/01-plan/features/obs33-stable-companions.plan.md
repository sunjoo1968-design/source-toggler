# OBS33 정식 Companion 릴리스 계획

2026-10-26 · SunjooAn · PDCA

대상 원래 프로젝트: OBS-Multiview, wifi-vtally-v1.0.1, scene-anchor. Controller 0.2.1은 이미 정식33 검증·게시 완료이며 이번에는 변경하지 않는다.

기준: 공식 OBS33.0.0 source SHA256 c1ae3c98c1bb70ebdced33e894a526fcbbbda9bfd95806970a3fc31f74b08f6c, 설치된33.0.0 bin DLL에서 생성한 import libraries. Qt6.11 SDK/runtime 사용. 기존 OBS32 릴리스·태그·브랜치와 현장 설치본은 보존한다.

설계: MV0.6.1/Tally1.7.2-obs33.1/SceneTree1.1.1, 별도 codex/obs33-stable 브랜치. RC 플래그/표시/패키징을 정식33으로 전환. Source/vendor/dock/settings 식별자 유지. Tally 최신 c10085e CUT preview 깜빡임 보완 포함. Listener/UDP/vMix/ATEM 불변. 사용자 .gitignore/LOCAL-RESUME/3D 변경 제외.

검증: native3개와 Hub 실행파일 빌드, CTest·Hub회귀·런타임, Controller0.2.1과 ME1/ME2 MIX TAKE 및 PGM/PVW 통합, 빠른 CUT 회귀시험, SceneTree 저장/투영·실제dock 로딩, 정상 종료. 배포 ZIPmanifest/해시·firmware 불변 및 비공개 Tally 확인 후 GitHub 릴리스 게시.

제한: 실제 장치 수 시간 방송/음질과 모든 SceneTree 수동UI 조작은 별도 검증. 시험 전후 현장 OBS/Hub 자동 종료·교체 금지.

완료: 각 native/허브/통합 검증 및 세 정식용 릴리스 게시·원격 해시·기존릴리스 불변·Tally비공개 확인. docs/04-report/obs33-stable-companions.md 참조.
