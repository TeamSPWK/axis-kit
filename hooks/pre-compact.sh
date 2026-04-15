#!/usr/bin/env bash

# Nova Engineering — PreCompact Hook
# 컴팩션 직전에 NOVA-STATE.md를 보호한다.
# - NOVA-STATE.md가 존재하면 Last Activity에 컴팩션 시점을 기록
# - 기존 컴팩션 마커는 교체하여 누적 방지

# stdin에서 hook payload 읽기 (trigger, session_id 등)
read -r PAYLOAD 2>/dev/null || PAYLOAD="{}"

STATE_FILE="NOVA-STATE.md"

if [ -f "$STATE_FILE" ]; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  MARKER="- context compacted | $TIMESTAMP"

  if grep -q "## Last Activity" "$STATE_FILE"; then
    # 기존 컴팩션 마커 제거 후 새 마커 삽입 (최대 1개 유지)
    TMP=$(mktemp)
    awk -v marker="$MARKER" '
      /^## Last Activity/ { print; print marker; skip=1; next }
      skip && /^- context compacted/ { next }
      { skip=0; print }
    ' "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"
  fi
fi

# 컴팩션 허용 (exit 0). 차단하려면 exit 2.
exit 0
