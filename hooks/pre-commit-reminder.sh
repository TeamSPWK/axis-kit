#!/usr/bin/env bash

# Nova Engineering — PreToolUse Hook (Bash)
# git commit 명령 감지 시 NOVA-STATE.md 갱신 확인 + verify 리마인더를 주입.

# $TOOL_INPUT 환경변수에 Bash 도구의 command가 전달됨
INPUT="${TOOL_INPUT:-}"

# git commit 패턴 감지 (git commit, git -c ... commit 등)
if echo "$INPUT" | grep -qE '^\s*git\s+(.*\s+)?commit(\s|$)'; then
  # NOVA-STATE.md 갱신 여부 확인
  STATE_STALE=""
  if [ -f "NOVA-STATE.md" ]; then
    # staged 파일에 NOVA-STATE.md가 포함되어 있는지 확인
    if ! git diff --cached --name-only 2>/dev/null | grep -q "NOVA-STATE.md"; then
      STATE_STALE="⚠️ NOVA-STATE.md가 이번 커밋에 포함되지 않았습니다. 갱신이 필요한지 확인하세요."
    fi
  fi

  # nova-meta.json 최신 여부 확인
  META_STALE=""
  if [ -f "docs/nova-meta.json" ] && [ -f "scripts/generate-meta.sh" ]; then
    META_VER=$(python3 -c "import json; print(json.load(open('docs/nova-meta.json'))['stats']['commands'])" 2>/dev/null || echo "0")
    ACTUAL_CMD=$(ls -1 .claude/commands/*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$META_VER" != "$ACTUAL_CMD" ]; then
      META_STALE="⚠️ nova-meta.json이 최신이 아닙니다 (meta: ${META_VER}개, 실제: ${ACTUAL_CMD}개). bash scripts/release.sh를 사용하세요."
    fi
  fi

  # 변경 파일 수 감지
  CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  if [ "$CHANGED_FILES" -ge 3 ]; then
    cat << NOVA_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[Nova Quality Gate] git commit 감지 — 변경 파일 ${CHANGED_FILES}개.\n\n${STATE_STALE}\n${META_STALE}\n\n3파일 이상 변경입니다. Nova Always-On 규칙에 따라:\n1. NOVA-STATE.md를 갱신했는가? (필수)\n2. /nova:review --fast 를 실행했는가? (필수)\n3. 검증 결과가 PASS인가?\n\n💡 릴리스 시 bash scripts/release.sh <patch|minor|major> \"메시지\" 를 사용하면 전체 절차가 자동 실행됩니다."
  }
}
NOVA_EOF
  else
    cat << NOVA_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[Nova Quality Gate] git commit 감지 — 변경 파일 ${CHANGED_FILES}개.\n\n${STATE_STALE}\n${META_STALE}\n\n소규모 변경입니다. 로직 변경이 포함되어 있다면 /nova:review --fast를 권장합니다.\n💡 릴리스 시 bash scripts/release.sh <patch|minor|major> \"메시지\" 를 사용하세요."
  }
}
NOVA_EOF
  fi
fi

exit 0
