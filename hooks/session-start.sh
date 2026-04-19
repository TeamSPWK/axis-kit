#!/usr/bin/env bash

# Nova Engineering — SessionStart Hook
# 핵심 5개 규칙만 경량 주입. 상세(§3/§5/§6/§8/§9)는 관련 커맨드·스킬이 on-demand 로드.

# NOVA-STATE.md에서 Goal을 읽어 세션 타이틀 생성
SESSION_TITLE="Nova"
if [ -f "NOVA-STATE.md" ]; then
  GOAL=$(grep -m1 '^\- \*\*Goal\*\*:' NOVA-STATE.md 2>/dev/null | sed 's/.*\*\*Goal\*\*: *//')
  if [ -n "$GOAL" ]; then
    SESSION_TITLE="Nova: $GOAL"
  fi
fi

# JSON 특수문자 이스케이프
SESSION_TITLE=$(echo "$SESSION_TITLE" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')

# Sprint 1: session_id 동기 선발급 + session_start 이벤트 기록 + start_epoch 저장 (safe-default)
NOVA_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
if [[ -f "${NOVA_ROOT}/hooks/record-event.sh" ]] && [[ -z "${NOVA_DISABLE_EVENTS:-}" ]]; then
  mkdir -p .nova 2>/dev/null || true
  # Race-safe session.id 선발급 (이후 child spawn들이 이 id를 공유)
  if [[ ! -f .nova/session.id ]]; then
    _RAND=$(od -An -N8 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n' | head -c 16)
    _SID=$(printf '%s%s%s' "$PWD" "$$" "$_RAND" | shasum -a 256 2>/dev/null | head -c 12)
    [[ -n "$_SID" ]] && ( set -C; echo "$_SID" > .nova/session.id ) 2>/dev/null || true
  fi
  date -u +%s > .nova/session.start_epoch 2>/dev/null || true
  bash "${NOVA_ROOT}/hooks/record-event.sh" session_start '{}' 2>/dev/null &
fi

cat << NOVA_EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "sessionTitle": "${SESSION_TITLE}",
    "additionalContext": "# Nova Engineering\n\nNova 자동 적용 규칙 — 품질 실행 계약. 상세는 docs/nova-rules.md 및 관련 커맨드가 on-demand 로드. 프로젝트 \`.claude/rules/\`가 있으면 Nova보다 우선.\n\n## 규칙 (핵심)\n\n1. **복잡도**: 간단(1~2)→바로. 보통(3~7)→Plan. 복잡(8+)→Plan→Design→스프린트. 인증/DB/결제 +1. 자가 완화 금지. 파일 수 초과 시 즉시 Plan 승격.\n2. **검증 + 하드 게이트**: 검증은 **독립 서브에이전트**(별도 spawn=창 분리). 메인 재확인은 독립 아님. 커밋 전 tsc/lint→Evaluator→PASS→커밋. PASS 없이 커밋 시 exit 2 차단(--emergency 예외). tmux pane: TeamCreate→Agent(name+team_name+run_in_background:true).\n3. **실행 검증**: 코드 존재 ≠ 동작. 빌드+테스트+curl. 환경 변경 3단계(현재→변경→반영).\n4. **블로커**: Auto/Soft/Hard. 불확실=Hard. 2회 실패 시 강제 분류.\n5. **환경 안전**: 설정 파일 직접 수정 금지. 환경변수/CLI 플래그.\n\n## Nova 커맨드\n\n/nova:plan · /nova:deepplan · /nova:design · /nova:review · /nova:check · /nova:ask · /nova:run · /nova:setup · /nova:next · /nova:scan · /nova:auto · /nova:ux-audit · /nova:worktree-setup\n\n## Always-On (MUST)\n\n1. 모든 코드 변경에 자동 규칙.\n2. 3파일+ 변경 시 Plan.\n3. 구현 완료 시 Evaluator를 독립 서브에이전트로 실행.\n4. 커밋 전 /nova:review --fast.\n5. 세션 시작 시 NOVA-STATE.md 읽기.\n6. 블로커 발생 시 즉시 알림."
  }
}
NOVA_EOF

exit 0
