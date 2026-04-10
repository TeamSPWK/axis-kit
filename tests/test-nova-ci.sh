#!/bin/bash
# Nova CI — 테스트 스위트
# Usage: bash tests/test-nova-ci.sh
#
# nova-ci 관련 스크립트 검증:
# - verdict JSON fixture 스키마 (nova-ci.sh 출력 계약)
# - format-pr-comment.sh: verdict JSON → PR 마크다운 변환
# - action.yml: GitHub Action 매니페스트 구조
# - nova-review.yml: PR 트리거 워크플로우 구조

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 색상
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

assert() {
  local description="$1"
  local condition="$2"
  if eval "$condition"; then
    echo -e "  ${GREEN}✓${NC} $description"
    ((PASS++))
  else
    echo -e "  ${RED}✗${NC} $description"
    ((FAIL++))
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Nova CI — 테스트 스위트"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fixture 경로
FIXTURE_DIR="$SCRIPT_DIR/fixtures"
FIX_PASS="$FIXTURE_DIR/verdict-pass.json"
FIX_FAIL="$FIXTURE_DIR/verdict-fail.json"
FIX_COND="$FIXTURE_DIR/verdict-conditional.json"

# ═══════════════════════════════════════════
# 1. Verdict JSON 스키마 검증 (nova-ci.sh 출력 계약)
# ═══════════════════════════════════════════

echo -e "${YELLOW}[Fixture: JSON 스키마]${NC}"

# 1-1. 파일 존재
assert "verdict-pass.json 존재" "[ -f '$FIX_PASS' ]"
assert "verdict-fail.json 존재" "[ -f '$FIX_FAIL' ]"
assert "verdict-conditional.json 존재" "[ -f '$FIX_COND' ]"

# 1-2. jq 파싱 가능
assert "verdict-pass.json: jq 유효" "jq empty '$FIX_PASS' 2>/dev/null"
assert "verdict-fail.json: jq 유효" "jq empty '$FIX_FAIL' 2>/dev/null"
assert "verdict-conditional.json: jq 유효" "jq empty '$FIX_COND' 2>/dev/null"

# 1-3. 필수 필드 존재 (verdict, intensity, summary, counts, issues, known_gaps)
for fixture in "$FIX_PASS" "$FIX_FAIL" "$FIX_COND"; do
  fname=$(basename "$fixture")
  assert "$fname: verdict 필드" "jq -e '.verdict' '$fixture' > /dev/null 2>&1"
  assert "$fname: intensity 필드" "jq -e '.intensity' '$fixture' > /dev/null 2>&1"
  assert "$fname: summary 필드" "jq -e '.summary' '$fixture' > /dev/null 2>&1"
  assert "$fname: counts 필드" "jq -e '.counts' '$fixture' > /dev/null 2>&1"
  assert "$fname: issues 배열" "jq -e '.issues | type == \"array\"' '$fixture' > /dev/null 2>&1"
  assert "$fname: known_gaps 배열" "jq -e '.known_gaps | type == \"array\"' '$fixture' > /dev/null 2>&1"
done

# 1-4. counts 하위 필드 (critical, high, warning — 정수)
for fixture in "$FIX_PASS" "$FIX_FAIL" "$FIX_COND"; do
  fname=$(basename "$fixture")
  assert "$fname: counts.critical 정수" \
    "jq -e '.counts.critical | type == \"number\"' '$fixture' > /dev/null 2>&1"
  assert "$fname: counts.high 정수" \
    "jq -e '.counts.high | type == \"number\"' '$fixture' > /dev/null 2>&1"
  assert "$fname: counts.warning 정수" \
    "jq -e '.counts.warning | type == \"number\"' '$fixture' > /dev/null 2>&1"
done

# 1-5. verdict 값 유효성
assert "PASS fixture: verdict=PASS" \
  "[ \"\$(jq -r '.verdict' '$FIX_PASS')\" = 'PASS' ]"
assert "FAIL fixture: verdict=FAIL" \
  "[ \"\$(jq -r '.verdict' '$FIX_FAIL')\" = 'FAIL' ]"
assert "CONDITIONAL fixture: verdict=CONDITIONAL" \
  "[ \"\$(jq -r '.verdict' '$FIX_COND')\" = 'CONDITIONAL' ]"
echo ""

# ═══════════════════════════════════════════
# 2. 복잡도-강도 매핑 계약 검증
# ═══════════════════════════════════════════

echo -e "${YELLOW}[계약: 복잡도→강도 매핑]${NC}"

# Fixture가 기대하는 intensity 값을 갖는지 검증
# PASS(소규모) → Lite, FAIL(중규모) → Standard, CONDITIONAL(대규모) → Full
assert "PASS fixture: intensity=Lite (소규모 2파일)" \
  "[ \"\$(jq -r '.intensity' '$FIX_PASS')\" = 'Lite' ]"
assert "FAIL fixture: intensity=Standard (중규모 5파일)" \
  "[ \"\$(jq -r '.intensity' '$FIX_FAIL')\" = 'Standard' ]"
assert "CONDITIONAL fixture: intensity=Full (대규모 10파일)" \
  "[ \"\$(jq -r '.intensity' '$FIX_COND')\" = 'Full' ]"

# intensity 값이 허용 범위 내인지
for fixture in "$FIX_PASS" "$FIX_FAIL" "$FIX_COND"; do
  fname=$(basename "$fixture")
  INTENSITY=$(jq -r '.intensity' "$fixture")
  assert "$fname: intensity가 Lite/Standard/Full 중 하나" \
    "echo '$INTENSITY' | grep -qE '^(Lite|Standard|Full)$'"
done

# FAIL fixture에 auth/ 경로 이슈 포함 → Standard 이상
assert "FAIL fixture: auth 관련 이슈 포함 시 Standard 이상" \
  "[ \"\$(jq -r '.intensity' '$FIX_FAIL')\" != 'Lite' ]"
echo ""

# ═══════════════════════════════════════════
# 3. Verdict-Exit Code 매핑 계약 검증
# ═══════════════════════════════════════════

echo -e "${YELLOW}[계약: verdict→exit code]${NC}"

# PASS → critical=0, exit 0 기대
assert "PASS: critical=0" \
  "[ \"\$(jq -r '.counts.critical' '$FIX_PASS')\" -eq 0 ]"

# FAIL → critical>0, exit 1 기대
assert "FAIL: critical>0" \
  "[ \"\$(jq -r '.counts.critical' '$FIX_FAIL')\" -gt 0 ]"

# CONDITIONAL → critical=0 이지만 high>0
assert "CONDITIONAL: critical=0" \
  "[ \"\$(jq -r '.counts.critical' '$FIX_COND')\" -eq 0 ]"
assert "CONDITIONAL: high>0" \
  "[ \"\$(jq -r '.counts.high' '$FIX_COND')\" -gt 0 ]"

# PASS → issues 비어있음
assert "PASS: issues 비어있음" \
  "[ \"\$(jq '.issues | length' '$FIX_PASS')\" -eq 0 ]"

# FAIL → issues 존재
assert "FAIL: issues 존재" \
  "[ \"\$(jq '.issues | length' '$FIX_FAIL')\" -gt 0 ]"

# CONDITIONAL → known_gaps 존재
assert "CONDITIONAL: known_gaps 존재" \
  "[ \"\$(jq '.known_gaps | length' '$FIX_COND')\" -gt 0 ]"
echo ""

# ═══════════════════════════════════════════
# 4. format-pr-comment.sh 출력 검증
# ═══════════════════════════════════════════

echo -e "${YELLOW}[format-pr-comment.sh: 마크다운 출력]${NC}"

FORMAT_SCRIPT="$ROOT_DIR/scripts/format-pr-comment.sh"
assert "format-pr-comment.sh 존재" "[ -f '$FORMAT_SCRIPT' ]"

# 각 verdict 별 출력 생성
OUT_PASS=$(bash "$FORMAT_SCRIPT" < "$FIX_PASS" 2>/dev/null || true)
OUT_FAIL=$(bash "$FORMAT_SCRIPT" < "$FIX_FAIL" 2>/dev/null || true)
OUT_COND=$(bash "$FORMAT_SCRIPT" < "$FIX_COND" 2>/dev/null || true)

# 4-1. 코멘트 식별자 마커
assert "PASS 출력: <!-- nova-ci-verdict --> 마커" \
  "echo '$OUT_PASS' | grep -qF '<!-- nova-ci-verdict -->'"
assert "FAIL 출력: <!-- nova-ci-verdict --> 마커" \
  "echo '$OUT_FAIL' | grep -qF '<!-- nova-ci-verdict -->'"
assert "CONDITIONAL 출력: <!-- nova-ci-verdict --> 마커" \
  "echo '$OUT_COND' | grep -qF '<!-- nova-ci-verdict -->'"

# 4-2. 판정 배지 정확성
assert "PASS 출력: 🟢 PASS 배지" \
  "echo '$OUT_PASS' | grep -qF '🟢 PASS'"
assert "FAIL 출력: 🔴 FAIL 배지" \
  "echo '$OUT_FAIL' | grep -qF '🔴 FAIL'"
assert "CONDITIONAL 출력: 🟡 CONDITIONAL 배지" \
  "echo '$OUT_COND' | grep -qF '🟡 CONDITIONAL'"

# 4-3. 배지 오매칭 방지 (PASS에 🔴 없음, FAIL에 🟢 없음)
assert "PASS 출력: 🔴 없음" \
  "! echo '$OUT_PASS' | grep -qF '🔴'"
assert "FAIL 출력: 🟢 없음" \
  "! echo '$OUT_FAIL' | grep -qF '🟢'"
assert "CONDITIONAL 출력: 🟢/🔴 없음" \
  "! echo '$OUT_COND' | grep -qF '🟢' && ! echo '$OUT_COND' | grep -qF '🔴'"

# 4-4. 검증 강도 표시
assert "PASS 출력: Lite 강도 표시" \
  "echo '$OUT_PASS' | grep -qF 'Lite'"
assert "FAIL 출력: Standard 강도 표시" \
  "echo '$OUT_FAIL' | grep -qF 'Standard'"
assert "CONDITIONAL 출력: Full 강도 표시" \
  "echo '$OUT_COND' | grep -qF 'Full'"

# 4-5. FAIL → 이슈 테이블 존재
assert "FAIL 출력: 이슈 목록 섹션" \
  "echo '$OUT_FAIL' | grep -qF '이슈 목록'"
assert "FAIL 출력: 테이블 헤더" \
  "echo '$OUT_FAIL' | grep -qF '심각도'"

# 4-6. PASS → 이슈 테이블 없음
assert "PASS 출력: 이슈 목록 없음" \
  "! echo '$OUT_PASS' | grep -qF '이슈 목록'"

# 4-7. CONDITIONAL → Known Gaps 섹션
assert "CONDITIONAL 출력: Known Gaps 섹션" \
  "echo '$OUT_COND' | grep -qF 'Known Gaps'"
assert "CONDITIONAL 출력: 미커버 영역 항목 존재" \
  "echo '$OUT_COND' | grep -qF 'Auth module'"

# 4-8. PASS → Known Gaps 없음
assert "PASS 출력: Known Gaps 없음" \
  "! echo '$OUT_PASS' | grep -qF 'Known Gaps'"

# 4-9. 마무리 라인
assert "PASS 출력: _by Nova CI_ 푸터" \
  "echo '$OUT_PASS' | grep -qF '_by Nova CI_'"
assert "FAIL 출력: _by Nova CI_ 푸터" \
  "echo '$OUT_FAIL' | grep -qF '_by Nova CI_'"

# 4-10. counts 수치 표시
assert "FAIL 출력: Critical 2 표시" \
  "echo '$OUT_FAIL' | grep -qF 'Critical **2**'"
assert "PASS 출력: Critical 0 표시" \
  "echo '$OUT_PASS' | grep -qF 'Critical **0**'"
echo ""

# ═══════════════════════════════════════════
# 5. action.yml 구조 검증
# ═══════════════════════════════════════════

echo -e "${YELLOW}[action.yml: GitHub Action 매니페스트]${NC}"

ACTION_YML="$ROOT_DIR/.github/actions/nova-ci/action.yml"
assert "action.yml 존재" "[ -f '$ACTION_YML' ]"

# 5-1. 기본 메타데이터
assert "action.yml: name 필드" "grep -q '^name:' '$ACTION_YML'"
assert "action.yml: description 필드" "grep -q '^description:' '$ACTION_YML'"

# 5-2. required inputs
assert "action.yml: claude-api-key input" \
  "grep -q 'claude-api-key:' '$ACTION_YML'"
assert "action.yml: claude-api-key required=true" \
  "grep -A2 'claude-api-key:' '$ACTION_YML' | grep -q 'required: true'"
assert "action.yml: review-level input" \
  "grep -q 'review-level:' '$ACTION_YML'"
assert "action.yml: fail-on-conditional input" \
  "grep -q 'fail-on-conditional:' '$ACTION_YML'"
assert "action.yml: design-doc-path input" \
  "grep -q 'design-doc-path:' '$ACTION_YML'"

# 5-3. outputs
assert "action.yml: verdict output" \
  "grep -q 'verdict:' '$ACTION_YML'"
assert "action.yml: critical-count output" \
  "grep -q 'critical-count:' '$ACTION_YML'"
assert "action.yml: comment-url output" \
  "grep -q 'comment-url:' '$ACTION_YML'"

# 5-4. composite action
assert "action.yml: composite 타입" \
  "grep -q \"using: 'composite'\" '$ACTION_YML'"

# 5-5. nova-ci-verdict 마커 참조
assert "action.yml: nova-ci-verdict 마커 사용" \
  "grep -q 'nova-ci-verdict' '$ACTION_YML'"
echo ""

# ═══════════════════════════════════════════
# 6. CI 워크플로우 검증
# ═══════════════════════════════════════════

echo -e "${YELLOW}[CI: 워크플로우]${NC}"

CI_YML="$ROOT_DIR/.github/workflows/ci.yml"
assert "ci.yml 존재" "[ -f '$CI_YML' ]"
assert "ci.yml: test-nova-ci.sh 실행 포함" \
  "grep -q 'test-nova-ci.sh' '$CI_YML'"

# nova-review.yml 존재 검증 (PR 트리거 워크플로우)
REVIEW_YML="$ROOT_DIR/.github/workflows/nova-review.yml"
if [ -f "$REVIEW_YML" ]; then
  assert "nova-review.yml: pull_request 트리거" \
    "grep -q 'pull_request' '$REVIEW_YML'"
  assert "nova-review.yml: permissions 설정" \
    "grep -q 'permissions:' '$REVIEW_YML'"
  assert "nova-review.yml: pull-requests: write" \
    "grep -q 'pull-requests:.*write' '$REVIEW_YML'"
  assert "nova-review.yml: concurrency 설정" \
    "grep -q 'concurrency:' '$REVIEW_YML'"
else
  echo -e "  ${YELLOW}⊘${NC} nova-review.yml 미존재 — 생성 시 재검증 필요"
fi
echo ""

# ═══════════════════════════════════════════
# 7. Issue 객체 스키마 검증
# ═══════════════════════════════════════════

echo -e "${YELLOW}[스키마: Issue 객체]${NC}"

# FAIL fixture의 issue 객체 필드 검증
ISSUE_FIELDS=$(jq -r '.issues[0] | keys[]' "$FIX_FAIL" 2>/dev/null | sort | tr '\n' ',')
assert "issue 객체: severity 필드" "echo '$ISSUE_FIELDS' | grep -qF 'severity'"
assert "issue 객체: location 필드" "echo '$ISSUE_FIELDS' | grep -qF 'location'"
assert "issue 객체: issue 필드" "echo '$ISSUE_FIELDS' | grep -qF 'issue'"
assert "issue 객체: action 필드" "echo '$ISSUE_FIELDS' | grep -qF 'action'"

# issue count와 실제 배열 길이 일치
FAIL_TOTAL=$(jq '.counts.critical + .counts.high' "$FIX_FAIL")
FAIL_ISSUES=$(jq '.issues | length' "$FIX_FAIL")
assert "FAIL: counts 합 ≤ issues 배열 길이" \
  "[ '$FAIL_TOTAL' -le '$FAIL_ISSUES' ]"
echo ""

# ═══════════════════════════════════════════
# 결과
# ═══════════════════════════════════════════

TOTAL=$((PASS + FAIL))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}ALL PASS${NC}: ${PASS}/${TOTAL} 테스트 통과"
else
  echo -e "  ${RED}FAIL${NC}: ${PASS}/${TOTAL} 통과, ${FAIL}개 실패"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit "$FAIL"
