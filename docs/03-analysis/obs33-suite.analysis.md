# OBS33 Suite 설계 대조

2026-10-16. Legacy 태그·소스 ZIP, 네 프로젝트의 OBS33 브랜치, 공식 RC1 SDK 재빌드, 새 plugins 레이아웃/manifest, source/vendor/설정 키 보존, 제작자·버전 UI, 명시적 canvas Lua API 및 전용 빌드/패키징 구현 완료.

네 모듈 실제 로딩, ME1/ME2 전환·PGM/PVW, 120초 117 TAKE/5재접속, 최종 Lua 재시작 복원·정상 종료, 단위 시험, 허브 277 회귀시험 및 packaged runtime 통과. firmware 13파일 동일 검증.

제한: 전체 Scene Tree 편집 UI 자동화, 실제 장비 수 시간 운용·오디오 품질은 미검증. OBS 전체 종료 잔여 할당 1건과 upstream scene duplication canvas fallback 경고를 문서화했다. OBS33 RC1 시험판으로 배포하고 stable main/Legacy releases는 유지한다.

남은 항목: GitHub prerelease 4개 게시 및 원격 asset digest 검증.
