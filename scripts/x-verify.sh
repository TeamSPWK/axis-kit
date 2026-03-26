#!/bin/bash
# AXIS Engineering — X-Verification v2 (멀티 AI 교차검증 + 합의율 자동 산출)
# Usage: ./scripts/x-verify.sh "질문 내용"
#        ./scripts/x-verify.sh -f question.txt
#        ./scripts/x-verify.sh --no-save "질문"  (결과 저장 안 함)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"
VERIFY_DIR="$ROOT_DIR/docs/verifications"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# .env 로드
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo -e "${RED}ERROR: .env 파일을 찾을 수 없습니다: $ENV_FILE${NC}"
  exit 1
fi

# 옵션 처리
SAVE_RESULT=true
if [[ "${1:-}" == "--no-save" ]]; then
  SAVE_RESULT=false
  shift
fi

# 입력 처리
if [[ "${1:-}" == "-f" && -n "${2:-}" ]]; then
  QUESTION=$(cat "$2")
elif [[ -n "${1:-}" ]]; then
  QUESTION="$1"
else
  echo "Usage: $0 [--no-save] \"질문 내용\""
  echo "       $0 [--no-save] -f question.txt"
  exit 1
fi

SYSTEM_PROMPT="당신은 소프트웨어 아키텍처 전문가입니다. 질문에 대해 명확하고 구조화된 의견을 한국어로 제시하세요. 답변은 500자 이내로 핵심만 간결하게."

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  AXIS X-Verification v2 — 멀티 AI 교차검증${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}질문:${NC} $QUESTION"
echo ""

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# ── Phase 1: 3개 AI 병렬 호출 ──

call_claude() {
  curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n --arg q "$QUESTION" --arg s "$SYSTEM_PROMPT" '{
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: $s,
      messages: [{role: "user", content: $q}]
    }')" | jq -r '.content[0].text // "ERROR: 응답 없음"' > "$TMPDIR/claude.txt" 2>&1
}

call_gpt() {
  curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg q "$QUESTION" --arg s "$SYSTEM_PROMPT" '{
      model: "gpt-4o",
      messages: [{role: "system", content: $s}, {role: "user", content: $q}],
      temperature: 0.7
    }')" | jq -r '.choices[0].message.content // "ERROR: 응답 없음"' > "$TMPDIR/gpt.txt" 2>&1
}

call_gemini() {
  curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg q "$SYSTEM_PROMPT\n\n$QUESTION" '{
      contents: [{parts: [{text: $q}]}]
    }')" | jq -r '.candidates[0].content.parts[0].text // "ERROR: 응답 없음"' > "$TMPDIR/gemini.txt" 2>&1
}

echo -e "${BLUE}⏳ Phase 1: 3개 AI에 동시 질의 중...${NC}"
echo ""

call_claude &
call_gpt &
call_gemini &
wait

# 결과 출력
echo -e "${GREEN}━━━ 🟣 Claude (Anthropic) ━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat "$TMPDIR/claude.txt"
echo ""

echo -e "${GREEN}━━━ 🟢 GPT-4o (OpenAI) ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat "$TMPDIR/gpt.txt"
echo ""

echo -e "${GREEN}━━━ 🔵 Gemini (Google) ━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat "$TMPDIR/gemini.txt"
echo ""

# ── Phase 2: 합의율 자동 산출 (4th AI Call) ──

echo -e "${BLUE}⏳ Phase 2: 합의율 분석 중...${NC}"
echo ""

CLAUDE_RESP=$(cat "$TMPDIR/claude.txt")
GPT_RESP=$(cat "$TMPDIR/gpt.txt")
GEMINI_RESP=$(cat "$TMPDIR/gemini.txt")

ANALYSIS_PROMPT="다음은 같은 질문에 대한 3개 AI의 응답입니다. 합의 수준을 분석하세요.

## 원래 질문
$QUESTION

## Claude 응답
$CLAUDE_RESP

## GPT 응답
$GPT_RESP

## Gemini 응답
$GEMINI_RESP

반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트 없이 JSON만:
{
  \"consensus_rate\": (0-100 정수. 핵심 결론의 방향성이 일치하는 정도),
  \"common_points\": [\"공통 의견1\", \"공통 의견2\"],
  \"differences\": [\"차이점1\", \"차이점2\"],
  \"verdict\": \"auto_approve 또는 human_review 또는 redefine\",
  \"summary\": \"한줄 요약\"
}"

# Gemini flash로 합의 분석 (비용 최소화)
ANALYSIS=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg p "$ANALYSIS_PROMPT" '{
    contents: [{parts: [{text: $p}]}],
    generationConfig: {temperature: 0.1}
  }')" | jq -r '.candidates[0].content.parts[0].text // "ERROR"')

# JSON 추출 (마크다운 코드블록 제거)
CLEAN_JSON=$(echo "$ANALYSIS" | sed 's/```json//g' | sed 's/```//g' | tr -d '\n' | jq '.' 2>/dev/null || echo "$ANALYSIS")

# 파싱
RATE=$(echo "$CLEAN_JSON" | jq -r '.consensus_rate // "?"' 2>/dev/null || echo "?")
VERDICT=$(echo "$CLEAN_JSON" | jq -r '.verdict // "unknown"' 2>/dev/null || echo "unknown")
SUMMARY=$(echo "$CLEAN_JSON" | jq -r '.summary // "분석 실패"' 2>/dev/null || echo "분석 실패")

# 판정 색상
case "$VERDICT" in
  auto_approve) VERDICT_COLOR="${GREEN}✅ AUTO APPROVE${NC}" ;;
  human_review) VERDICT_COLOR="${YELLOW}⚠️  HUMAN REVIEW${NC}" ;;
  redefine)     VERDICT_COLOR="${RED}🔄 REDEFINE${NC}" ;;
  *)            VERDICT_COLOR="${RED}❓ UNKNOWN${NC}" ;;
esac

echo -e "${MAGENTA}━━━ 📊 합의 분석 결과 ━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  합의율:  ${CYAN}${RATE}%${NC}"
echo -e "  판정:    ${VERDICT_COLOR}"
echo -e "  요약:    ${SUMMARY}"
echo ""

# 공통점/차이점 출력
COMMON=$(echo "$CLEAN_JSON" | jq -r '.common_points[]? // empty' 2>/dev/null)
DIFFS=$(echo "$CLEAN_JSON" | jq -r '.differences[]? // empty' 2>/dev/null)

if [[ -n "$COMMON" ]]; then
  echo -e "  ${GREEN}공통점:${NC}"
  echo "$COMMON" | while read -r line; do echo "    • $line"; done
  echo ""
fi

if [[ -n "$DIFFS" ]]; then
  echo -e "  ${YELLOW}차이점:${NC}"
  echo "$DIFFS" | while read -r line; do echo "    • $line"; done
  echo ""
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ── Phase 3: 결과 저장 ──

if [[ "$SAVE_RESULT" == true ]]; then
  mkdir -p "$VERIFY_DIR"
  DATE=$(date +%Y-%m-%d)
  SLUG=$(echo "$QUESTION" | head -c 40 | sed 's/[^a-zA-Z0-9가-힣]/-/g' | sed 's/-\+/-/g' | sed 's/-$//')
  FILENAME="${DATE}-${SLUG}.md"
  FILEPATH="$VERIFY_DIR/$FILENAME"

  cat > "$FILEPATH" << MDEOF
# X-Verification: ${QUESTION:0:80}

> 날짜: $DATE
> 합의율: ${RATE}%
> 판정: $VERDICT

## 질문
$QUESTION

## Claude
$CLAUDE_RESP

## GPT
$GPT_RESP

## Gemini
$GEMINI_RESP

## 합의 분석
- **합의율**: ${RATE}%
- **판정**: $VERDICT
- **요약**: $SUMMARY

### 공통점
$(echo "$COMMON" | while read -r line; do echo "- $line"; done)

### 차이점
$(echo "$DIFFS" | while read -r line; do echo "- $line"; done)
MDEOF

  echo -e "${GREEN}📁 결과 저장: $FILEPATH${NC}"
fi
