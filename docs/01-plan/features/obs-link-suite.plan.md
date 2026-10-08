# Sunjoo OBS Link 통합 개발 계획

제작자: SunjooAn. 사용자 확정 명칭: Sunjoo OBS Link.

## 목표와 범위
Controller(Lua+복제 출력 플러그인), Multiview, Tally OBS 연동을 종합 검토하고 버그·참조 수명·전환 판정·성능을 개선한다. 각 원래 프로젝트에서 개발한다. 현장 설치본은 자동 교체하거나 종료하지 않는다. 리스너 펌웨어, UDP, vMix/ATEM과 사용자 3D 작업은 유지한다.

## 구현 순서
1. 세 프로젝트 변경 상태와 기존 릴리스 해시를 기록하고 최종 비 Hybrid 버전을 보관한다.
2. 공유 계약(camera_mix_hybrid_output, 원본 UUID, PGM/PVW, CUT/Fade 경계)을 검토한다. 기존 식별자와 배정을 유지하며 표시 이름만 공통 제품군 명칭으로 변경한다.
3. Controller·Multiview·Tally 사용자 화면과 OBS 모듈 등록 이름을 통일한다. 각 컴포넌트 버전은 해당 프로젝트의 단일 정의에서 관리한다.
4. 확인된 버그/낭비를 수정하고 실제 libobs, 격리 OBS, 허브 테스트로 검증한다.
5. 세 프로그램 설치 릴리스와 소스/라이선스/해시/설치 안내를 제공한다.
6. 전체 검증 후 재생성 가능한 파일을 정리하고 기존 릴리스·필요한 증거를 보관한다.

## 완료 조건
- ME1 장면 및 ME2 그룹, CUT/MIX, OBS Studio 소스 복제, 직접 장면 선택의 PGM/PVW 판정이 일치한다.
- 입력 교체·반복 적용·재시작 복원·종료·참조 수명 회귀 검증이 통과한다.
- Sunjoo OBS Link Controller / Multiview / Tally 표시, 제작자 SunjooAn과 버전 확인 가능.
- 이전 비 Hybrid 릴리스와 현장/사용자 설정 보존, 공개 패키지에 인증·개인 설정 없음.
- 최종 설치 ZIP 3개와 SHA256 제공. 수행하지 못한 검증은 명시한다.

## 재개 체크포인트
완료: 통합 브랜드와 상호 모듈 정보, 멀티뷰 그래프 개선, 실제 동시 OBS 검증, 세 최종 릴리스, 이전 비 Hybrid 보관, 해시 검증 및 임시 파일 정리를 완료했다. 상세 결과는 docs/04-report/obs-link-suite.md. 이어서 진행할 미완료 작업은 없다.

2026-10-08: 계획/읽기 감사 시작. 명칭 사용자 확정. 기존 자동 재개 작업 automation을 30분 간격으로 재활성화했다. 사용량 초기 87% 소비, 일반 사용 허용. 크레딧 자동 소비 금지.

현재 베이스: Controller Hybrid 0.1.0 (미커밋), Multiview 0.5.2 Hybrid commit 49934b1, Tally 1.6.0-obs.4 commit 5b779c0. 모두 실제 설치본은 유지.

확인할 이슈: Multiview graphContainsVisible/graphUniqueVisibleLeaf 재귀에는 깊이/노드 제한이 없어 악의적 또는 과도한 중첩에 스택 위험이 있다. native alias walk에는 128/8192 제한이 있으나 일반 그래프 검색까지 일관되게 적용되지 않는다. 각 타일이 매번 PGM/PVW 그래프를 다시 만드는 비용도 검토한다. Tally와 Multiview 원본 복제 매칭은 현재 복제 시 재생성되는 item ID를 name/type로 보완하며 원본 이름 변경 시 판정 회귀 가능성을 검토한다.

주의: 다른 두 프로젝트의 샌드박스 git status는 work tree 오류가 발생했으므로 승인된 상승 권한으로 다시 확인한다. 사용자 작업을 포함하는 git 전체 추가 금지. .gitignore/LOCAL-RESUME.md와 Tally 3D 작업은 보호한다.
