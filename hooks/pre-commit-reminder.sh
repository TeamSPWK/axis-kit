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

  # 변경 파일 수 감지
  CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  if [ "$CHANGED_FILES" -ge 3 ]; then
    cat << NOVA_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[Nova Quality Gate] git commit 감지 — 변경 파일 ${CHANGED_FILES}개.\n\n${STATE_STALE}\n\n3파일 이상 변경입니다. Nova Always-On 규칙에 따라:\n1. NOVA-STATE.md를 갱신했는가? (필수)\n2. /nova:review --fast 를 실행했는가? (필수)\n3. 검증 결과가 PASS인가?\n\nNOVA-STATE.md 갱신 없이 커밋하면 세션 간 상태가 불일치합니다."
  }
}
NOVA_EOF
  else
    cat << NOVA_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[Nova Quality Gate] git commit 감지 — 변경 파일 ${CHANGED_FILES}개.\n\n${STATE_STALE}\n\n소규모 변경입니다. 로직 변경이 포함되어 있다면 /nova:review --fast를 권장합니다.\nREADME, 설정 등 사소한 변경은 건너뛸 수 있습니다."
  }
}
NOVA_EOF
  fi
fi

exit 0
