# Claude Keepalive 스크립트 사용법

이 폴더의 `claude_keepalive.sh`는 Synology NAS 작업 스케줄러에서 매일 실행하기 위한 스크립트입니다.

## 왜 필요한가

Claude Code는 첫 대화 시작 이후 일정 시간이 지나면 토큰 상태가 초기화될 수 있습니다.  
이 스크립트는 업무 시작 전에 아주 짧은 요청을 자동으로 보내 세션/토큰 상태를 안정적으로 유지하고,
실사용 시 불필요한 초기 지연을 줄이기 위해 사용합니다.

목표:
- 평일(월~금)이며 한국 공휴일이 아닐 때만 Claude에 아주 짧은 요청을 1회 전송
- 주말/공휴일은 자동 스킵
- `holidays` 패키지가 없으면 자동 설치
- 중복 실행 방지 및 로그 기록

## 파일 구성

- `claude_keepalive.sh`: 메인 실행 스크립트

## 동작 방식

1. `BASE` 경로(기본값: `/volume1/scripts/claude-keepalive`) 생성
2. Python venv(`$BASE/.venv`)가 없으면 자동 생성
3. `holidays` 패키지가 없으면 설치
4. 오늘 날짜가 주말/한국 공휴일이면 종료
5. 아니면 `claude --bare`로 최소 토큰 요청 실행 (`Reply exactly: OK`)
6. 결과를 로그 파일(`$BASE/claude_keepalive.log`)에 기록

## 환경 변수(선택)

- `BASE`: 작업 파일/로그/venv 저장 경로
- `CLAUDE_BIN`: claude 실행 파일 경로 (기본: `/usr/local/bin/claude`)

예:
```sh
BASE=/volume1/scripts/claude-keepalive CLAUDE_BIN=/usr/local/bin/claude /volume1/scripts/claude-keepalive/claude_keepalive.sh
```

## NAS에 배치할 때

1. 스크립트를 NAS 경로로 업로드 (예: `/volume1/scripts/claude-keepalive/claude_keepalive.sh`)
2. 실행 권한 부여:
   ```sh
   chmod +x /volume1/scripts/claude-keepalive/claude_keepalive.sh
   ```
3. DSM 작업 스케줄러 등록:
   - 유형: **사용자 정의 스크립트**
   - 사용자: **claude 로그인된 동일 계정**
   - 일정: **매일 07:40**
   - 명령:
     ```sh
     /volume1/scripts/claude-keepalive/claude_keepalive.sh
     ```

## 로그 확인

기본 로그 파일:
```sh
/volume1/scripts/claude-keepalive/claude_keepalive.log
```

예시 로그:
- `ok`
- `skip: weekend/holiday`
- `warn: unexpected output: ...`
- `error: claude not found ...`
