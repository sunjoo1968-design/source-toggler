# OBS33 Suite 설계

계획: docs/01-plan/features/obs33-suite.plan.md

기존 source ID camera_mix_hybrid_output, vendor sunjooan-tally, module DLL 이름과 scene-anchor dock/settings 키를 유지한다. OBS plugin manager metadata의 표시명과 버전은 Sunjoo OBS Link / SunjooAn으로 표시한다. 새 패키지는 module별 plugins/<name>/<name>.dll 및 data/manifest.json을 제공하며 installed OBS용 ProgramData/obs-studio/plugins와 portable OBS/plugins 배치를 각각 안내한다.

공식 OBS 33 RC1 source SDK, 제공된 RC1 obs.dll/obs-frontend-api.dll에서 생성한 import libs, Qt 6.11.x로 별도 build 디렉터리에 컴파일한다. controller Lua는 source-switcher 외부 의존성을 유지하며 로드·전환 시험 결과를 기록한다. 기존 Tally websocket protocol/firmware/Hub 동작은 유지한다.

Legacy 보존: 각 프로젝트 legacy-obs32-20261016 tag와 현 릴리스 ZIP 보존, git archive 소스 ZIP. 신규 branch codex/obs33-rc1. private Tally는 public 통합 아카이브에 넣지 않는다.

순서: 1) 버전/manifest/build 레이아웃 2) 네 모듈 빌드 3) isolated OBS33 portable 생성 4) 기존 회귀/통합 시험과 SceneTree 시험 5) 보고/해시/시험릴리스. 실패가 있으면 해당 수정 후 재시험한다.

시험: 신형 plugin path 로드 및 버전, Lua settings 복원, CUT/MIX/중간 TAKE 두 ME, PGM/PVW Tally/Multiview, 그룹 위치 불변, scene folders 저장/복원, 재시작/정상종료. 장시간 실제 장치 운용은 별도 제한으로 기재한다.
