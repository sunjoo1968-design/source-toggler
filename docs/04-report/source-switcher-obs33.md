# Source Switcher OBS33 재빌드 검증

2026-10-16 · PDCA

Plan: 원본 Exeldro Source Switcher 0.4.4를 보존하고 OBS33 RC1 SDK로 별도 비공식 재빌드. 원작자와 GPL-2.0 유지, 설치본 자동 교체 금지.
Do: native/source-switcher-obs33에 원본 C/H/data/LICENSE를 보존. 원본 동작 로직은 동일하고 Properties에 SunjooAn/재빌드 버전 정보 한 줄을 추가했다. buildspec.json 단일 버전은 0.4.4-sunjoo.obs33.1. 새 OBS33 plugin layout 및 manifest, 대응 GPL 소스와 재빌드 안내 포함 ZIP 생성.
Check: 실제 OBS33 RC1 로그에서 새 버전 로드 확인. 런타임과 배포 DLL SHA256 동일. ME1/ME2 중간 MIX TAKE에서 양쪽 카메라 PGM 기여·독립 완료·이전 카메라 OFF, Tally/Multiview PGM/PVW 일치, 정상 종료 exit=0 모두 통과. ZIP 내부 모든 파일 해시 확인.
Act: 원본 공식 배포와 구분한 비공식 시험 릴리스로 제공. 기존 DLL 이름 source-switcher.dll과 source ID 유지, 중복 설치 금지 안내. 원본 Controller 0.2.0 등 이미 배포한 파일은 교체하지 않고 재빌드 의존성을 별도 제공.

제한: 전체 Source Switcher 옵션/실제 장비 장시간 방송/오디오 품질 시험은 미실시. OBS 전체 종료 로그 잔여 할당 1건 유지, 전체 누수 0건 주장하지 않음.
