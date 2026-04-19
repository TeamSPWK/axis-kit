#!/usr/bin/env bash
# Nova Agent Tools Audit — Sprint 2a
#
# .claude/agents/*.md frontmatter의 tools 선언을
# .claude-plugin/plugin.json tool_contract.per_agent와 대조한다.
# 불일치 시 exit 1, 정상 시 exit 0.
#
# Sprint 2a 기능 (하네스 엔지니어링 "constrain" 원칙의 선언 레이어):
#   - frontmatter에 tools 선언 있는지 검증
#   - plugin.json tool_contract 필드 존재 검증
#   - 양쪽 값 정확 일치(쉼표 분리, trim, sort, diff)
#
# 런타임 enforcement는 .claude/settings.json PreToolUse 훅(Sprint 2b)이 담당.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="${ROOT_DIR}/.claude-plugin/plugin.json"
AGENTS_DIR="${ROOT_DIR}/.claude/agents"

if ! command -v jq >/dev/null 2>&1; then
  echo "[nova:audit] ERROR: jq 필요" >&2
  exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "[nova:audit] ERROR: plugin.json 없음: $MANIFEST" >&2
  exit 2
fi

if ! jq -e '.tool_contract' "$MANIFEST" >/dev/null 2>&1; then
  echo "[nova:audit] FAIL: plugin.json에 tool_contract 필드 없음" >&2
  exit 1
fi

FAIL=0
AGENT_COUNT=0

for agent_file in "$AGENTS_DIR"/*.md; do
  [[ -f "$agent_file" ]] || continue
  agent_name=$(basename "$agent_file" .md)
  AGENT_COUNT=$((AGENT_COUNT + 1))

  # frontmatter 첫 블록에서 tools 라인 추출
  fm_tools=$(awk '
    /^---[[:space:]]*$/ { n++; if (n==2) exit }
    n==1 && /^tools:/ { sub(/^tools:[[:space:]]*/, ""); print; exit }
  ' "$agent_file" | tr -d '\r')

  if [[ -z "$fm_tools" ]]; then
    echo "[nova:audit] FAIL: ${agent_name} — frontmatter에 tools 선언 없음" >&2
    FAIL=$((FAIL + 1))
    continue
  fi

  # 쉼표 split + trim + sort + dedup
  fm_set=$(printf '%s' "$fm_tools" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sort -u)

  # plugin.json에서 per_agent 가져오기
  pj_tools=$(jq -r --arg a "$agent_name" '.tool_contract.per_agent[$a] // empty | .[]' "$MANIFEST" 2>/dev/null)

  if [[ -z "$pj_tools" ]]; then
    echo "[nova:audit] FAIL: ${agent_name} — plugin.json tool_contract.per_agent.${agent_name} 없음" >&2
    FAIL=$((FAIL + 1))
    continue
  fi

  pj_set=$(printf '%s\n' "$pj_tools" | sort -u)

  if [[ "$fm_set" != "$pj_set" ]]; then
    echo "[nova:audit] FAIL: ${agent_name} — frontmatter tools와 plugin.json tool_contract.per_agent 불일치" >&2
    echo "  frontmatter: $(printf '%s' "$fm_set" | tr '\n' ',' | sed 's/,$//')" >&2
    echo "  plugin.json: $(printf '%s' "$pj_set" | tr '\n' ',' | sed 's/,$//')" >&2
    FAIL=$((FAIL + 1))
  fi
done

# ── Orphan 감지 (Sprint 2a Evaluator Issue #4) ──
# plugin.json tool_contract.per_agent에 등록됐으나 agents/*.md 없는 키
ORPHAN=0
PJ_KEYS=$(jq -r '.tool_contract.per_agent // {} | keys[]' "$MANIFEST" 2>/dev/null)
for pj_key in $PJ_KEYS; do
  if [[ ! -f "$AGENTS_DIR/${pj_key}.md" ]]; then
    echo "[nova:audit] FAIL: orphan — plugin.json per_agent.${pj_key} 등록됐으나 agents/${pj_key}.md 없음" >&2
    ORPHAN=$((ORPHAN + 1))
  fi
done
FAIL=$((FAIL + ORPHAN))

if [[ $FAIL -eq 0 ]]; then
  echo "[nova:audit] ${AGENT_COUNT}/${AGENT_COUNT} agents — frontmatter × plugin.json tool_contract 일치 (orphan 0)"
  exit 0
else
  echo "[nova:audit] ${FAIL}건 불일치 (orphan ${ORPHAN})" >&2
  exit 1
fi
