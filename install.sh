#!/bin/bash
# AXIS Kit — 원격 설치 스크립트
# Usage: curl -fsSL https://raw.githubusercontent.com/TeamSPWK/axis-kit/main/install.sh | bash
#    or: bash install.sh [target-dir]
#    or: curl -fsSL ... | bash -s -- --update [target-dir]

set -euo pipefail

REPO="TeamSPWK/axis-kit"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# 모드 설정
UPDATE_MODE=false
MINIMAL_MODE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE_MODE=true
  shift
elif [[ "${1:-}" == "--minimal" ]]; then
  MINIMAL_MODE=true
  shift
fi

# 색상
BOLD='\033[1m'
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
echo -e "${CYAN}  🔄 AXIS Kit Updater${NC}"
elif $MINIMAL_MODE; then
echo -e "${CYAN}  📦 AXIS Kit Installer ${YELLOW}(Minimal)${NC}"
else
echo -e "${CYAN}  📦 AXIS Kit Installer${NC}"
fi
echo -e "${CYAN}  ${BOLD}A${NC}${CYAN}daptive · ${BOLD}X${NC}${CYAN}-Verification · ${BOLD}I${NC}${CYAN}dempotent · ${BOLD}S${NC}${CYAN}tructured${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# curl 확인
if ! command -v curl &> /dev/null; then
  echo -e "${RED}ERROR: curl이 필요합니다.${NC}"
  exit 1
fi

echo -e "  ${BOLD}📂 설치 경로:${NC} ${CYAN}$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")${NC}"
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
    echo -e "  ${GREEN}✓${NC} ${CYAN}${2:-$1}${NC}"
    COUNT_UPDATED=$((COUNT_UPDATED + 1))
  else
    echo -e "  ${RED}✗${NC} ${CYAN}${2:-$1}${NC} ${RED}(다운로드 실패)${NC}"
  fi
}

# 업데이트 모드에서 건너뛰기 함수
skip() {
  local path="$1"
  echo -e "  ${YELLOW}→${NC} ${CYAN}${path}${NC} (건너뜀 — 사용자 커스터마이징 보호)"
  COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
}

# 커맨드 다운로드
if $MINIMAL_MODE; then
  echo -e "${BOLD}🔧 핵심 커맨드 설치 중...${NC} ${YELLOW}(minimal)${NC}"
  COMMANDS=(next plan review)
  for cmd in "${COMMANDS[@]}"; do
    download ".claude/commands/${cmd}.md"
  done
else
  echo -e "${BOLD}🔧 커맨드 설치 중...${NC}"
  COMMANDS=(next init plan xv design gap review propose metrics)
  for cmd in "${COMMANDS[@]}"; do
    download ".claude/commands/${cmd}.md"
  done
fi
echo ""

# 스크립트 다운로드
if $MINIMAL_MODE; then
  echo -e "${BOLD}🚀 스크립트 설치 중...${NC} ${YELLOW}(minimal)${NC}"
  download "scripts/init.sh"
  chmod +x "${TARGET_DIR}/scripts/"*.sh 2>/dev/null
else
  echo -e "${BOLD}🚀 스크립트 설치 중...${NC}"
  download "scripts/x-verify.sh"
  download "scripts/gap-check.sh"
  download "scripts/init.sh"
  chmod +x "${TARGET_DIR}/scripts/"*.sh 2>/dev/null
fi
echo ""

# 템플릿 다운로드
if $MINIMAL_MODE; then
  echo -e "${BOLD}📄 템플릿 건너뜀${NC} ${YELLOW}(minimal 모드)${NC}"
  echo ""
elif $UPDATE_MODE; then
  echo -e "${BOLD}📄 템플릿 건너뜀${NC} ${YELLOW}(업데이트 모드)${NC}"
  TEMPLATES=(cps-plan cps-design claude-md decision-record rule-proposal)
  for tmpl in "${TEMPLATES[@]}"; do
    skip "docs/templates/${tmpl}.md"
  done
  echo ""
else
  echo -e "${BOLD}📄 템플릿 설치 중...${NC}"
  TEMPLATES=(cps-plan cps-design claude-md decision-record rule-proposal)
  for tmpl in "${TEMPLATES[@]}"; do
    download "docs/templates/${tmpl}.md"
  done
  echo ""
fi

# 가이드 다운로드 (선택)
if $MINIMAL_MODE; then
  echo -e "${BOLD}📚 가이드 문서 건너뜀${NC} ${YELLOW}(minimal 모드)${NC}"
elif $UPDATE_MODE; then
  echo -e "${BOLD}📚 가이드 문서 건너뜀${NC} ${YELLOW}(업데이트 모드)${NC}"
  skip "docs/context-chain.md"
  skip "docs/eval-checklist.md"
  skip "docs/adoption-guide.md"
else
  echo -e "${BOLD}📚 가이드 문서 설치 중...${NC}"
  download "docs/context-chain.md"
  download "docs/eval-checklist.md"
  download "docs/adoption-guide.md"
fi
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if $UPDATE_MODE; then
  echo -e "${GREEN}  ✅ 업데이트 완료: 커맨드 ${BOLD}${#COMMANDS[@]}개${NC}${GREEN}, 스크립트 업데이트 / ${BOLD}${COUNT_SKIPPED}개${NC}${GREEN} 건너뜀 (템플릿/가이드는 보존)${NC}"
elif $MINIMAL_MODE; then
  echo -e "${GREEN}  ✅ AXIS Kit 최소 설치 완료!${NC} (핵심 커맨드 3개: ${BOLD}/next${NC}, ${BOLD}/plan${NC}, ${BOLD}/review${NC})"
else
  echo -e "${GREEN}  ✅ AXIS Kit 설치 완료!${NC}"
fi
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
if $MINIMAL_MODE; then
echo -e "${BOLD}👉 다음 단계:${NC}"
echo ""
echo -e "  1. ⚙️  CLAUDE.md에 AXIS 섹션 추가"
echo -e "     ${YELLOW}\$ bash scripts/init.sh --adopt 프로젝트명${NC}"
echo ""
echo -e "  2. 🧭 다음 할 일 확인"
echo -e "     ${YELLOW}\$ /next${NC}"
echo ""
echo -e "${BOLD}🔄 전체 설치로 업그레이드:${NC}"
echo -e "     ${YELLOW}\$ curl -fsSL https://raw.githubusercontent.com/TeamSPWK/axis-kit/main/install.sh | bash${NC}"
echo ""
elif ! $UPDATE_MODE; then
echo -e "${BOLD}👉 다음 단계:${NC}"
echo ""
echo -e "  1. 📄 CLAUDE.md 생성"
echo -e "     ${YELLOW}\$ bash scripts/init.sh 프로젝트명${NC}"
echo ""
echo -e "  2. 🔑 교차검증용 API 키 설정"
echo -e "     ${CYAN}.env${NC} 파일에 ${BOLD}ANTHROPIC${NC}, ${BOLD}OPENAI${NC}, ${BOLD}GEMINI${NC} 키 추가"
echo ""
echo -e "  3. 🧭 다음 할 일 확인"
echo -e "     ${YELLOW}\$ /next${NC}"
echo ""
echo -e "${BOLD}🔧 기존 프로젝트에 도입:${NC}"
echo -e "     ${YELLOW}\$ bash scripts/init.sh --adopt 프로젝트명${NC}"
echo ""
echo -e "📚 상세 가이드: ${CYAN}docs/adoption-guide.md${NC}"
echo ""
fi
