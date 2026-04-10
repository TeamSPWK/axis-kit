#!/usr/bin/env bash

# Nova Engineering — PreToolUse Hook (Bash)
# git commit 명령 감지 시 verify 리마인더를 주입.
# 변경 파일 수에 따라 강도를 조절한다.

# $TOOL_INPUT 환경변수에 Bash 도구의 command가 전달됨
INPUT="${TOOL_INPUT:-}"

# git commit 패턴 감지 (git commit, git -c ... commit 등)
if echo "$INPUT" | grep -qE '^\s*git\s+(.*\s+)?commit(\s|$)'; then
  # 변경 파일 수 감지
  CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

  if [ "$CHANGED_FILES" -ge 3 ]; then
    # 3파일 이상: 강력한 리마인더
    cat << NOVA_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[Nova Quality Gate] git commit 감지 — 변경 파일 ${CHANGED_FILES}개.\n\n3파일 이상 변경입니다. Nova Always-On 규칙에 따라:\n1. /nova:review --fast 를 실행했는가? (필수)\n2. 검증 결과가 PASS인가?\n3. NOVA-STATE.md가 갱신되었는가?\n\n검증 없이 커밋하면 품질 게이트가 무력화됩니다. /nova:review --fast를 먼저 실행하세요."
  }
}
NOVA_EOF
  else
    # 1~2파일: 경량 리마인더
    cat << NOVA_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[Nova Quality Gate] git commit 감지 — 변경 파일 ${CHANGED_FILES}개.\n\n소규모 변경입니다. 로직 변경이 포함되어 있다면 /nova:review --fast를 권장합니다.\nREADME, 설정 등 사소한 변경은 건너뛸 수 있습니다."
  }
}
NOVA_EOF
  fi
fi

exit 0
