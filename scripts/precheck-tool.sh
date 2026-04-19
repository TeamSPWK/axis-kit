#!/usr/bin/env bash
# Nova Sprint 2b PreToolUse 훅 — 도구 제약 런타임 차단 (v5.15.0)
#
# Sprint 2b Evaluator FAIL 판정 이후 수정(Issue #1/#2/#3/#4/#6/#9/#10 해소):
#   - Bash 복합명령(;, &&, ||, |) 분리 후 세그먼트별 매칭
#   - Write/Edit 도구 file_path glob 매칭 추가
#   - settings.json + settings.local.json deny 합집합(local이 project deny를 축소할 수 없음)
#   - NOVA_BYPASS_PRECHECK=1 환경변수로 감사 가능한 일시 해제 (tool_constraint_bypass 이벤트)
#   - fail-open 시 schema_error 이벤트 기록 (hook 고장을 공격자가 의도 유발 가능성 관측)
#
# Safe-default: 자체 오류는 exit 0 (도구 허용). 단 가능한 경우 schema_error 이벤트 기록.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"

emit_violation() {
  # $1 event_type, $2 extra_json
  [[ -f "${ROOT_DIR}/hooks/record-event.sh" ]] || return 0
  bash "${ROOT_DIR}/hooks/record-event.sh" "$1" "$2" 2>/dev/null || true
}

# ── NOVA_BYPASS_PRECHECK: 사용자 명시 일시 해제 (감사 기록) ──
if [[ -n "${NOVA_BYPASS_PRECHECK:-}" ]]; then
  emit_violation tool_constraint_bypass "$(printf '{"reason":"NOVA_BYPASS_PRECHECK=%s","source":"precheck-tool"}' "${NOVA_BYPASS_PRECHECK}")"
  exit 0
fi

# ── jq 없으면 fail-open + schema_error 기록 ──
if ! command -v jq >/dev/null 2>&1; then
  echo "[nova:precheck] WARN: jq 없음 — 허용(fail-open). nova-rules §11 명시" >&2
  exit 0
fi

# ── 입력 수집 (stdin 우선, 없으면 TOOL_INPUT 환경변수) ──
INPUT=""
if [[ ! -t 0 ]]; then
  INPUT=$(cat 2>/dev/null || true)
fi
if [[ -z "$INPUT" && -n "${TOOL_INPUT:-}" ]]; then
  INPUT="$TOOL_INPUT"
fi

[[ -z "$INPUT" ]] && exit 0

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // .tool // empty' 2>/dev/null)
[[ -z "$TOOL_NAME" ]] && exit 0

BASH_CMD=""
WRITE_PATH=""
case "$TOOL_NAME" in
  Bash)
    BASH_CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .input.command // .command // empty' 2>/dev/null)
    ;;
  Write|Edit|NotebookEdit)
    WRITE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .input.file_path // .tool_input.notebook_path // .file_path // empty' 2>/dev/null)
    ;;
esac

# ── settings deny 합집합 (project + local) — Issue #3 해소 ──
# local이 project deny를 축소하지 못하도록 union(sort -u).
DENY_ACCUM=""
for path in .claude/settings.json .claude/settings.local.json; do
  if [[ -f "$path" ]]; then
    LIST=$(jq -r '.permissions.deny // [] | .[]' "$path" 2>/dev/null || true)
    if [[ -z "$LIST" ]] && ! jq -e . "$path" >/dev/null 2>&1; then
      # invalid JSON → schema_error 기록 (fail-open)
      emit_violation schema_error "$(printf '{"source":"precheck-tool","reason":"invalid_json","path":"%s"}' "$path")"
    fi
    [[ -n "$LIST" ]] && DENY_ACCUM+="$LIST"$'\n'
  fi
done

DENY_LIST=$(printf '%s' "$DENY_ACCUM" | grep -v '^$' | sort -u || true)
[[ -z "$DENY_LIST" ]] && exit 0

# ── Bash 복합 명령 분리 (Issue #1 해소) ──
# ;, &&, ||, | 구분자로 세그먼트 분리. 각 세그먼트를 앞뒤 공백 trim 후 매칭.
# 주의: subshell `$()`, backtick 내부 분리는 제한적(shell parser 없이 불가능).
#       현재 구현은 lexical defense-in-depth로 단순 wrapping은 잡으나 $()/backtick은 별도.
split_bash_segments() {
  # Sprint 2b Evaluator Issue C: newline도 세그먼트 구분자로 추가
  printf '%s' "$1" | awk '
    BEGIN {RS="[;\n]+|[&][&]|[|][|]|[|]"}
    {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      if (length($0) > 0) print $0
    }
  '
}

match_pattern() {
  local pattern="$1"
  local pat_tool="${pattern%%(*}"
  local pat_arg_spec=""

  if [[ "$pattern" == *"("* ]]; then
    pat_arg_spec="${pattern#*(}"
    pat_arg_spec="${pat_arg_spec%)}"
  fi

  [[ "$pat_tool" != "$TOOL_NAME" ]] && return 1

  # 인자 스펙 없거나 와일드카드 단독
  if [[ -z "$pat_arg_spec" || "$pat_arg_spec" == "*" ]]; then
    return 0
  fi

  case "$TOOL_NAME" in
    Bash)
      [[ -z "$BASH_CMD" ]] && return 1
      # 복합 명령 분리 후 각 세그먼트 매칭 (Issue #1)
      local segments
      segments=$(split_bash_segments "$BASH_CMD")
      local seg
      while IFS= read -r seg; do
        [[ -z "$seg" ]] && continue
        # 양측 와일드카드 보강 매칭(prefix/suffix 노이즈 허용)
        case "$seg" in
          $pat_arg_spec) return 0 ;;
        esac
      done <<< "$segments"
      # 원본 전체도 시도 (세그먼트 분리가 실패한 경우 대비)
      case "$BASH_CMD" in
        $pat_arg_spec) return 0 ;;
      esac
      return 1
      ;;
    Write|Edit|NotebookEdit)
      # Issue #2 해소: file_path glob 매칭
      [[ -z "$WRITE_PATH" ]] && return 1
      case "$WRITE_PATH" in
        $pat_arg_spec) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    *)
      # 기타 도구: 정확 매칭만 (확장 여지)
      return 1
      ;;
  esac
}

MATCHED_PATTERN=""
while IFS= read -r pattern; do
  [[ -z "$pattern" ]] && continue
  if match_pattern "$pattern"; then
    MATCHED_PATTERN="$pattern"
    break
  fi
done <<< "$DENY_LIST"

if [[ -z "$MATCHED_PATTERN" ]]; then
  exit 0
fi

# ── 차단 ──
DETAIL=""
case "$TOOL_NAME" in
  Bash) DETAIL=", command=$BASH_CMD" ;;
  Write|Edit|NotebookEdit) DETAIL=", file_path=$WRITE_PATH" ;;
esac
echo "[nova:precheck] DENIED: \"$MATCHED_PATTERN\" matched — tool=$TOOL_NAME${DETAIL}" >&2

# Data Contract 필수 필드: agent, tool_attempted, matched_pattern (+ 도구별 details)
# Agent 식별: 환경변수 우선, 부재 시 "runtime" — Issue #5는 호출처가 SPRINT/AGENT 컨텍스트 전달 시 개선
AGENT_NAME="${NOVA_CALLER_AGENT:-runtime}"
EXTRA=$(jq -cn \
  --arg agent "$AGENT_NAME" \
  --arg tool "$TOOL_NAME" \
  --arg cmd "${BASH_CMD:-}" \
  --arg path "${WRITE_PATH:-}" \
  --arg pat "$MATCHED_PATTERN" \
  '{agent:$agent, tool_attempted:$tool, command:$cmd, file_path:$path, matched_pattern:$pat, source:"precheck-tool"}')

emit_violation tool_constraint_violation "$EXTRA"

exit 2
