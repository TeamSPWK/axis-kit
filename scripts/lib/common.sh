#!/bin/bash
# AXIS Kit — 공통 쉘 유틸리티
# Usage: source "$(dirname "$0")/lib/common.sh"

# 색상
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# .env 로드
load_env() {
  local env_file="${1:-.env}"
  if [[ -f "$env_file" ]]; then
    set -a
    source "$env_file"
    set +a
  fi
}

# 필수 명령어 검사
require_commands() {
  for cmd in "$@"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo -e "${RED}ERROR: '${BOLD}$cmd${NC}${RED}'이 설치되어 있지 않습니다.${NC}"
      echo -e "  ${YELLOW}\$ brew install $cmd${NC}  (macOS)"
      echo -e "  ${YELLOW}\$ apt install $cmd${NC}   (Ubuntu)"
      exit 1
    fi
  done
}

# 배너 출력
banner() {
  local title="$1"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  ${title}${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 구분선만 출력
divider() {
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}
