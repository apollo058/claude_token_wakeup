#!/bin/sh
set -eu

# 필요하면 DSM에서 환경변수 BASE로 덮어쓰기 가능
BASE="${BASE:-/volume1/scripts/claude-keepalive}"
VENV="$BASE/.venv"
PY="$VENV/bin/python"
PIP="$VENV/bin/pip"
CLAUDE="${CLAUDE_BIN:-/usr/local/bin/claude}"
LOG="$BASE/claude_keepalive.log"
LOCK="/tmp/claude_keepalive.lock"

export TZ="Asia/Seoul"

log() {
  echo "$(date '+%F %T') $1" >> "$LOG"
}

init_runtime() {
  mkdir -p "$BASE"

  # venv 없으면 생성
  if [ ! -x "$PY" ]; then
    python3 -m venv "$VENV"
  fi

  # holidays 없을 때만 설치
  if ! "$PY" -c "import holidays" >/dev/null 2>&1; then
    "$PIP" install --upgrade pip >/dev/null 2>&1 || true
    "$PIP" install holidays >/dev/null 2>&1
    log "info: installed python package 'holidays'"
  fi
}

should_run_today() {
  # 0=실행, 1=스킵(주말/공휴일)
  "$PY" - <<'PY'
import datetime
import holidays

today = datetime.date.today()
if today.weekday() >= 5:  # 토/일
    raise SystemExit(1)

kr = holidays.country_holidays("KR")
if today in kr:
    raise SystemExit(1)

raise SystemExit(0)
PY
}

run_claude_ping() {
  PROMPT="Reply exactly: OK"

  if command -v timeout >/dev/null 2>&1; then
    OUT="$(timeout 90 "$CLAUDE" --bare -p "$PROMPT" --output-format text 2>&1 || true)"
  else
    OUT="$("$CLAUDE" --bare -p "$PROMPT" --output-format text 2>&1 || true)"
  fi

  FIRST="$(printf '%s' "$OUT" | head -n 1 | tr -d '\r')"
  if [ "$FIRST" = "OK" ]; then
    log "ok"
  else
    log "warn: unexpected output: $FIRST"
  fi
}

# 중복 실행 방지
if ! mkdir "$LOCK" 2>/dev/null; then
  log "skip: already running"
  exit 0
fi
trap 'rmdir "$LOCK"' EXIT

if [ ! -x "$CLAUDE" ]; then
  log "error: claude not found at $CLAUDE"
  exit 1
fi

init_runtime

if ! should_run_today; then
  log "skip: weekend/holiday"
  exit 0
fi

run_claude_ping
exit 0
