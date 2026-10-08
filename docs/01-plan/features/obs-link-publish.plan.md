# Sunjoo OBS Link 정리 및 GitHub 게시

2026-10-08 사용자 승인: 세 원래 프로젝트의 이전 버전과 임시 파일 정리, GitHub 게시. 이전 지시의 최종 비 Hybrid 보관 ZIP은 archive/pre-obs-link에 유지한다. 사용자 3D 작업, 개인 설정과 현장 실행 파일은 정리 대상이 아니다.

## 현재 확인
- GitHub 인증 유효, sunjoo1968-design 계정.
- source-toggler PUBLIC/main, obs-multiview-plus PUBLIC/main, OBS-tally PRIVATE/main. 탈리는 비공개 유지.
- 모두 codex/obs-link-suite 브랜치. 완료 개발 커밋: Controller 9f88666, Multiview 0c785b7, Tally aa45749.
- 현재 일반 사용 허용, 5시간 사용량 98%. 자동 재개 automation 활성(30분 간격), 리셋 크레딧 자동 사용 금지.

## 순서
1. 보관 ZIP 및 최종 설치 ZIP/해시 검증. 실행 프로세스 경로와 사용자 설정 보호.
2. 이전 릴리스 중 최종 보관 ZIP에 포함된 파일과 기타 지난 릴리스 삭제. 생성 SDK/build/node_modules/test sandbox 등은 실행 경로/개인 설정 제외하고 안전한 절대 경로 확인 후 삭제. 재빌드 의존성은 재설치 가능하나 release 및 보관 ZIP은 유지.
3. 최신 README/CHANGELOG/최종 배포 안내 정리. 새 커밋을 명시적 파일만 저장.
4. 원격 main fetch 후 빠른 전진 가능 여부 확인. 가능하면 최신 개발 커밋을 main에 게시. 원격 변경이 있으면 보존하며 병합/PR 처리.
5. 세 새 GitHub 릴리스 게시: 설치 ZIP+SHA256, 공개 두 개/비공개 탈리. 온라인 상태와 자산 검증.
6. 완료 보고와 실제 개선 제안. 자동 재개 중지.

## 체크포인트
2026-10-08 20:51 KST 리셋 후 재개. 이전 릴리스 중복, SDK/build/node_modules/테스트 OBS 생성물 정리 완료. 비 Hybrid 최종 보관본 유지. 구 Controller 실행 코드·모의 테스트는 Controller-1.3.4-legacy-source.zip에 보관하고 주력 소스에서 삭제했다. 사용자 설정은 config/preserved-private-settings 또는 .local/user-settings에 유지한다. 자동 승인 검토가 확인되지 않은 개발 이력/evidence의 영구 삭제를 거절하여 archive로 이동하는 가역적인 방법으로 정리했다.

현재 README/설치 안내를 새 버전 기준으로 정리했고 최종 ZIP의 문서만 갱신했다. 실행 바이너리는 검증본과 같다. GitHub push/릴리스 게시/온라인 해시 검증은 다음 단계다. release 최종 파일 경로는 Source-Toggler/release/OBS-LINK-RELEASES.json. 원격 main은 세 개발 브랜치 HEAD의 조상으로 확인되었다.
