#!/usr/bin/env bash
# Nova v5.18.3 S1 hotfix — 실기 테스트 (Claude Code 완전 재시작 후 실행)
#
# 전제:
#   1. 이 스크립트를 실행하기 **전에** Claude Code를 완전 종료 후 재시작한다.
#      (/reload-plugins로는 PreToolUse 훅 재등록이 안 됨 — 완전 재시작 필수.
#       근거: memory reference_claude_code_hooks_mechanics.md)
#   2. 본 스크립트는 hook 로직을 stdin 주입으로 직접 검증하므로
#      Claude Code 재시작 없이도 대부분 실행 가능하지만, 마지막 실기 항목
#      (S1-V7: `if` 필드 런타임 유효성)은 Claude Code 세션 내부에서만 검증 가능.
#
# Sprint Contract S1 Critical 13건 중 스크립트 자동 검증 가능 항목:
#   S1-V1~V9, V11~V13 → 이 스크립트
#   S1-V7, V10, V12 실기 → Claude Code 세션에서 직접 수행 (아래 가이드 참조)
#
# Usage:
#   bash tests/smoke-s1-restart.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/hooks/pre-commit-reminder.sh"
FIXTURES="$ROOT/tests/fixtures"
TODAY=$(date +%Y-%m-%d)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

case_assert() {
  local label="$1"
  local expected_exit="$2"
  local actual_exit="$3"
  local extra_check="${4:-}"

  if [ "$actual_exit" = "$expected_exit" ]; then
    if [ -z "$extra_check" ] || eval "$extra_check"; then
      echo -e "  ${GREEN}✓${NC} $label (exit=$actual_exit)"
      PASS=$((PASS + 1))
    else
      echo -e "  ${RED}✗${NC} $label — 추가 조건 실패"
      FAIL=$((FAIL + 1))
    fi
  else
    echo -e "  ${RED}✗${NC} $label — expected exit=$expected_exit, got $actual_exit"
    FAIL=$((FAIL + 1))
  fi
}

echo -e "${YELLOW}━━━ Nova v5.18.3 S1 hotfix 실기 검증 ━━━${NC}"
echo "  ROOT=$ROOT"
echo "  TODAY=$TODAY"
echo ""

# ── Case 1: PASS fixture (오늘) → exit 0
TMPD=$(mktemp -d)
cd "$TMPD"
sed "s/TODAY_PLACEHOLDER/$TODAY/g" "$FIXTURES/nova-state-pass.md" > NOVA-STATE.md
echo '{"tool_input":{"command":"git commit -m test"}}' | bash "$HOOK" >/dev/null 2>&1
CASE1_EXIT=$?
case_assert "S1-V3: PASS fixture → exit 0" 0 "$CASE1_EXIT"
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 2: NO_PASS fixture → exit 2 + stderr
TMPD=$(mktemp -d)
cd "$TMPD"
sed "s/TODAY_PLACEHOLDER/$TODAY/g" "$FIXTURES/nova-state-no_pass.md" > NOVA-STATE.md
OUT=$(echo '{"tool_input":{"command":"git commit -m test"}}' | bash "$HOOK" 2>&1)
CASE2_EXIT=$?
case_assert "S1-V4: NO_PASS fixture → exit 2 + 차단 메시지" 2 "$CASE2_EXIT" \
  'echo "$OUT" | grep -qE "COMMIT BLOCKED|NO_PASS"'
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 3: NOVA_EMERGENCY=1 우회 (NO_PASS)
TMPD=$(mktemp -d)
cd "$TMPD"
sed "s/TODAY_PLACEHOLDER/$TODAY/g" "$FIXTURES/nova-state-no_pass.md" > NOVA-STATE.md
echo '{"tool_input":{"command":"git commit -m test"}}' | NOVA_EMERGENCY=1 bash "$HOOK" >/dev/null 2>&1
CASE3_EXIT=$?
case_assert "S1-V5: NOVA_EMERGENCY=1 + NO_PASS → exit 0 (우회)" 0 "$CASE3_EXIT"
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 4: CONFLICT + EMERGENCY → exit 2 (초월 fail-closed)
TMPD=$(mktemp -d)
cd "$TMPD"
cp "$FIXTURES/nova-state-conflict.md" NOVA-STATE.md
OUT=$(echo '{"tool_input":{"command":"git commit -m test --emergency"}}' | NOVA_EMERGENCY=1 bash "$HOOK" 2>&1)
CASE4_EXIT=$?
case_assert "S1-V12 (N3): CONFLICT + --emergency + NOVA_EMERGENCY=1 → exit 2" 2 "$CASE4_EXIT" \
  'echo "$OUT" | grep -qE "CONFLICT|merge conflict"'
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 5: non-git Bash → exit 0
TMPD=$(mktemp -d)
cd "$TMPD"
echo '{"tool_input":{"command":"bash -c echo-not-git"}}' | bash "$HOOK" >/dev/null 2>&1
CASE5_EXIT=$?
case_assert "S1-V2: non-git Bash → exit 0 (조기 종료)" 0 "$CASE5_EXIT"
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 6: MISSING → exit 2
TMPD=$(mktemp -d)
cd "$TMPD"
OUT=$(echo '{"tool_input":{"command":"git commit -m x"}}' | bash "$HOOK" 2>&1)
CASE6_EXIT=$?
case_assert "S1-V6/V9: MISSING → exit 2 + 'MISSING' stderr" 2 "$CASE6_EXIT" \
  'echo "$OUT" | grep -q MISSING'
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 7: Cold-start (init-nova-state + first commit)
TMPD=$(mktemp -d)
cd "$TMPD"
echo "{\"cwd\":\"$TMPD\"}" | bash "$ROOT/scripts/init-nova-state.sh" >/dev/null 2>&1
echo '{"tool_input":{"command":"git commit -m x"}}' | bash "$HOOK" >/dev/null 2>&1
CASE7_EXIT=$?
case_assert "S1-V6: MISSING → init → PASS 전환 (cold-start catch-22 해소)" 0 "$CASE7_EXIT"
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 8: NOVA_DISABLE_EVENTS=1 전역 우회
TMPD=$(mktemp -d)
cd "$TMPD"
echo 'garbage-not-json' | NOVA_DISABLE_EVENTS=1 bash "$HOOK" >/dev/null 2>&1
CASE8_EXIT=$?
case_assert "S1-V11: NOVA_DISABLE_EVENTS=1 → exit 0 (최상위 우회)" 0 "$CASE8_EXIT"
cd - >/dev/null && rm -rf "$TMPD"

# ── Case 9: 빈 stdin → fail-closed
TMPD=$(mktemp -d)
cd "$TMPD"
: | bash "$HOOK" >/dev/null 2>&1
CASE9_EXIT=$?
case_assert "Fail-closed: 빈 stdin → exit 2" 2 "$CASE9_EXIT"
cd - >/dev/null && rm -rf "$TMPD"

# ── 결과
echo ""
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}━━━ S1 자동 실기: $PASS/$TOTAL PASS ━━━${NC}"
else
  echo -e "${RED}━━━ S1 자동 실기: $PASS/$TOTAL ($FAIL 실패) ━━━${NC}"
fi

# ── Claude Code 세션 내부에서 수동 실기해야 하는 항목 안내
echo ""
cat <<'EOF'
━━━ Claude Code 세션 내부 수동 실기 (재시작 후) ━━━

이 스크립트로는 Claude Code 런타임 훅 동작을 직접 증명할 수 없습니다.
아래 세 케이스를 Claude Code를 완전 재시작한 뒤 실제로 실행해 주세요:

[S1-V7] hooks.json `"if": "Bash(git *)"` 필드 유효성
  1. Claude Code 완전 종료 후 재시작
  2. 세션에서 Bash 도구로 `bash -c "echo non-git"` 실행
  3. .nova/events.jsonl 에 tool_call 이벤트는 기록되지만
     pre-commit-reminder.sh 관련 stderr 출력은 없어야 함
  4. 그 다음 Bash 도구로 `git status` 실행
  5. 역시 pre-commit-reminder가 본문 조건 미충족으로 조기 종료 (비차단) 해야 함

[S1-V10] 실제 git commit 차단
  1. 위 재시작 상태에서 NOVA-STATE.md Last Activity를 NO_PASS 상태로 만든다
     (예: "→ WARN" 마커만 있고 PASS 없음)
  2. Bash 도구로 `git commit -m "test"` 시도
  3. Hard Gate 차단 메시지가 stderr로 나오고 commit이 실패해야 함
  4. `NOVA_EMERGENCY=1 git commit -m "test --emergency"` 는 통과해야 함

[S1-V12] CONFLICT 초월 fail-closed
  1. NOVA-STATE.md를 conflict fixture로 덮어쓴다:
     cp tests/fixtures/nova-state-conflict.md NOVA-STATE.md
  2. Bash 도구로 `NOVA_EMERGENCY=1 git commit -m "test --emergency"` 시도
  3. exit 2 + "CONFLICT" stderr 로 차단되어야 함 (EMERGENCY 무시)
  4. 테스트 후 원본 NOVA-STATE.md 복구

실기 결과는 NOVA-STATE.md Last Activity 에 기록 후 커밋하세요.
EOF

exit "$FAIL"
