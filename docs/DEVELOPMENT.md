# 개발 및 검증

Camera MIX Controller **1.3.3** · 제작자 **SunjooAn**.

Windows/OBS 32.2.2 환경에서 Python으로 실행합니다.

```powershell
python tests/run-tests.py
```

OBS 설치 폴더의 LuaJIT DLL을 사용합니다. 모의 테스트는 방송 OBS를 변경하지 않습니다. 그룹/주 입력 교체, 배치·추가 장식, CUT/MIX, 큐, 글로벌 이름, 재시작과 지연 로드, 설정 가져오기, 단축키, 참조 해제를 검증합니다.

```powershell
python tests/native-groups.py
```

Pillow와 설치된 OBS DLL/Source Switcher 0.4.4를 사용하며 별도 libobs/D3D11 프로세스로 실행합니다. 실행 중 OBS 장면 모음은 건드리지 않습니다. 테스트 생성 PNG/로그는 Git에서 제외합니다. 동일 영상 MIX의 25/50/75% 밝기, 좌우 배치 전환, 자막 유지와 CUT을 확인합니다. 실행 중인 OBS를 종료하거나 재시작하지 않습니다.

공개 배포에 개인 카메라 설정, 인증 정보, 개발 로그, 설치된 OBS/Qt DLL을 포함하지 않습니다. vendor의 저작권과 라이선스 표기는 보존합니다. 현재 제작자/버전을 사용자 화면과 README/배포 안내에 함께 표시해야 합니다.
