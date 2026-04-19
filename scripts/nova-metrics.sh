#!/usr/bin/env bash
# Nova Metrics — KPI 4종 산출 (Sprint 1)
#
# 사용법:
#   bash scripts/nova-metrics.sh [--since 7d|30d|all] [--fixture <path>]
#
# 출력 (고정 형식, 스냅샷 비교 가능):
#   Process consistency:    78% (n=41)
#   Gap detection rate:     85% (n=13)
#   Rule evolution rate:    N/A (insufficient data)
#   Multi-perspective:      62% (n=8)

set -u

SINCE="30d"
FIXTURE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      SINCE="${2:-30d}"
      shift 2
      ;;
    --fixture)
      FIXTURE="${2:-}"
      shift 2
      ;;
    -h|--help)
      sed -n '1,11p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

EVENTS_FILE="${FIXTURE:-.nova/events.jsonl}"

format_na() {
  printf "%-24s %s\n" "$1" "N/A (insufficient data)"
}

format_ratio() {
  local label="$1" num="$2" den="$3"
  if [[ "$den" == "0" || -z "$den" ]]; then
    format_na "$label"
    return
  fi
  local pct
  if command -v bc >/dev/null 2>&1; then
    pct=$(printf 'scale=1; %s*100/%s\n' "$num" "$den" | bc 2>/dev/null)
  else
    pct=$(awk -v n="$num" -v d="$den" 'BEGIN{printf "%.1f", n*100/d}')
  fi
  printf "%-24s %s%% (n=%s)\n" "$label" "$pct" "$den"
}

if [[ ! -f "$EVENTS_FILE" ]]; then
  echo "[nova:metrics] events.jsonl 없음: $EVENTS_FILE — 모든 KPI N/A" >&2
  format_na "Process consistency:"
  format_na "Gap detection rate:"
  format_na "Rule evolution rate:"
  format_na "Multi-perspective:"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[nova:metrics] ERROR: jq 미설치" >&2
  exit 2
fi

# ── 윈도우 계산 (GNU/BSD 호환) ──
calc_since_epoch() {
  local spec="$1"
  if [[ "$spec" == "all" ]]; then
    echo 0
    return
  fi
  local n="${spec%[dh]}"
  local unit="${spec: -1}"
  [[ ! "$n" =~ ^[0-9]+$ ]] && { echo $(( $(date -u +%s) - 30 * 86400 )); return; }
  local secs
  case "$unit" in
    d) secs=$((n * 86400)) ;;
    h) secs=$((n * 3600))  ;;
    *) secs=$((30 * 86400)) ;;
  esac
  echo $(( $(date -u +%s) - secs ))
}

SINCE_EPOCH=$(calc_since_epoch "$SINCE")

# Bootstrap 이후로 분모 보정 (업그레이드 사용자)
BOOTSTRAP_EPOCH=$(jq -sr --argjson since "$SINCE_EPOCH" '
  [.[] | select(.event_type=="session_start" and (.extra.bootstrap // false) == true and .timestamp_epoch >= $since) | .timestamp_epoch] | min // empty
' "$EVENTS_FILE" 2>/dev/null || true)
if [[ -z "$BOOTSTRAP_EPOCH" || "$BOOTSTRAP_EPOCH" == "null" ]]; then
  BOOTSTRAP_EPOCH=$SINCE_EPOCH
fi

window_events() {
  jq -c --argjson since "$BOOTSTRAP_EPOCH" '. | select(.timestamp_epoch >= $since)' "$EVENTS_FILE" 2>/dev/null || true
}

NOVA_ROOT_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
HELPER="${NOVA_ROOT_SCRIPTS}/_metrics-helpers.py"

# ── KPI 1: process_consistency ──
# 분자: sprint_completed(planned_files>=3) 중 같은 orchestration_id에 이전 plan_created가 존재
# 분모: sprint_completed(planned_files>=3) 총수
pc_result=$(window_events | python3 "$HELPER" process_consistency 2>/dev/null || echo "0 0")
pc_num=$(echo "$pc_result" | awk '{print $1}')
pc_den=$(echo "$pc_result" | awk '{print $2}')

# ── KPI 2: gap_detection_rate ──
gd_result=$(window_events | python3 "$HELPER" gap_detection_rate 2>/dev/null || echo "0 0")
gd_num=$(echo "$gd_result" | awk '{print $1}')
gd_den=$(echo "$gd_result" | awk '{print $2}')

# ── KPI 3: rule_evolution_rate (docs/rules-changelog.md 파싱) ──
RULES_LOG="docs/rules-changelog.md"
re_num=0
re_den=0
if [[ -f "$RULES_LOG" ]]; then
  # grep -c: match 없으면 exit 1이라도 stdout에 "0"을 출력한다. || true로 exit만 봉합.
  re_den=$({ grep -c '^## .* — proposed' "$RULES_LOG" 2>/dev/null || true; } | head -1)
  re_num=$({ grep -c '^## .* — approved' "$RULES_LOG" 2>/dev/null || true; } | head -1)
  re_den="${re_den:-0}"
  re_num="${re_num:-0}"
fi

# ── KPI 4: multi_perspective_impact ──
mp_result=$(window_events | python3 "$HELPER" multi_perspective_impact 2>/dev/null || echo "0 0")
mp_num=$(echo "$mp_result" | awk '{print $1}')
mp_den=$(echo "$mp_result" | awk '{print $2}')

# ── 출력 ──
format_ratio "Process consistency:" "$pc_num" "$pc_den"
format_ratio "Gap detection rate:"  "$gd_num" "$gd_den"
format_ratio "Rule evolution rate:" "$re_num" "$re_den"
format_ratio "Multi-perspective:"   "$mp_num" "$mp_den"

exit 0
