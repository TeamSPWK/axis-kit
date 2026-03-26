#!/bin/bash
# AXIS Kit — 원격 설치 스크립트
# Usage: curl -fsSL https://raw.githubusercontent.com/TeamSPWK/axis-kit/main/install.sh | bash
#    or: bash install.sh [target-dir]
#    or: curl -fsSL ... | bash -s -- --update [target-dir]

set -euo pipefail

REPO="TeamSPWK/axis-kit"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# 업데이트 모드
UPDATE_MODE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE_MODE=true
  shift
fi

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_DIR="${1:-.}"

# 카운터
COUNT_UPDATED=0
COUNT_SKIPPED=0

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if $UPDATE_MODE; then
echo -e "${CYAN}  AXIS Kit Updater${NC}"
else
echo -e "${CYAN}  AXIS Kit Installer${NC}"
fi
echo -e "${CYAN}  Adaptive · X-Verification · Idempotent · Structured${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# curl 확인
if ! command -v curl &> /dev/null; then
  echo -e "${RED}ERROR: curl이 필요합니다.${NC}"
  exit 1
fi

echo -e "${YELLOW}설치 경로:${NC} $(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"
echo ""

# 디렉토리 생성
DIRS=(
  ".claude/commands"
  "scripts"
  "docs/templates"
)

for dir in "${DIRS[@]}"; do
  mkdir -p "${TARGET_DIR}/${dir}"
done

# 파일 다운로드 함수
download() {
  local remote_path="$1"
  local local_path="${TARGET_DIR}/${2:-$1}"

  if curl -fsSL "${BASE_URL}/${remote_path}" -o "$local_path" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} ${2:-$1}"
    COUNT_UPDATED=$((COUNT_UPDATED + 1))
  else
    echo -e "  ${RED}✗${NC} ${2:-$1} (다운로드 실패)"
  fi
}

# 업데이트 모드에서 건너뛰기 함수
skip() {
  local path="$1"
  echo -e "  ${YELLOW}→${NC} ${path} (건너뜀 — 사용자 커스터마이징 보호)"
  COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
}

# 커맨드 다운로드
echo -e "${CYAN}커맨드 설치 중...${NC}"
COMMANDS=(next init plan xv design gap review propose metrics)
for cmd in "${COMMANDS[@]}"; do
  download ".claude/commands/${cmd}.md"
done
echo ""

# 스크립트 다운로드
echo -e "${CYAN}스크립트 설치 중...${NC}"
download "scripts/x-verify.sh"
download "scripts/gap-check.sh"
download "scripts/init.sh"
chmod +x "${TARGET_DIR}/scripts/"*.sh 2>/dev/null
echo ""

# 템플릿 다운로드
if $UPDATE_MODE; then
  echo -e "${CYAN}템플릿 건너뜀 (업데이트 모드)${NC}"
  TEMPLATES=(cps-plan cps-design claude-md decision-record rule-proposal)
  for tmpl in "${TEMPLATES[@]}"; do
    skip "docs/templates/${tmpl}.md"
  done
else
  echo -e "${CYAN}템플릿 설치 중...${NC}"
  TEMPLATES=(cps-plan cps-design claude-md decision-record rule-proposal)
  for tmpl in "${TEMPLATES[@]}"; do
    download "docs/templates/${tmpl}.md"
  done
fi
echo ""

# 가이드 다운로드 (선택)
if $UPDATE_MODE; then
  echo -e "${CYAN}가이드 문서 건너뜀 (업데이트 모드)${NC}"
  skip "docs/context-chain.md"
  skip "docs/eval-checklist.md"
  skip "docs/adoption-guide.md"
else
  echo -e "${CYAN}가이드 문서 설치 중...${NC}"
  download "docs/context-chain.md"
  download "docs/eval-checklist.md"
  download "docs/adoption-guide.md"
fi
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if $UPDATE_MODE; then
  echo -e "${GREEN}업데이트 완료: 커맨드 ${#COMMANDS[@]}개, 스크립트 3개 업데이트 / ${COUNT_SKIPPED}개 건너뜀 (템플릿/가이드는 보존)${NC}"
else
  echo -e "${GREEN}AXIS Kit 설치 완료!${NC}"
fi
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
if ! $UPDATE_MODE; then
echo -e "다음 단계:"
echo -e "  1. ${YELLOW}bash scripts/init.sh 프로젝트명${NC}  — CLAUDE.md 생성"
echo -e "  2. ${YELLOW}.env에 API 키 설정${NC}  — 교차검증용 (ANTHROPIC, OPENAI, GEMINI)"
echo -e "  3. ${YELLOW}/next${NC}  — 뭘 해야 하지?"
echo ""
echo -e "기존 프로젝트에 도입:"
echo -e "  ${YELLOW}bash scripts/init.sh --adopt 프로젝트명${NC}"
echo ""
echo -e "상세 가이드: ${CYAN}docs/adoption-guide.md${NC}"
echo ""
fi
