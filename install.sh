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
UNINSTALL_MODE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE_MODE=true
  shift
elif [[ "${1:-}" == "--minimal" ]]; then
  MINIMAL_MODE=true
  shift
elif [[ "${1:-}" == "--uninstall" ]]; then
  UNINSTALL_MODE=true
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
if $UNINSTALL_MODE; then
echo -e "${CYAN}  🗑️  AXIS Kit Uninstaller${NC}"
elif $UPDATE_MODE; then
echo -e "${CYAN}  🔄 AXIS Kit Updater${NC}"
elif $MINIMAL_MODE; then
echo -e "${CYAN}  📦 AXIS Kit Installer ${YELLOW}(Minimal)${NC}"
else
echo -e "${CYAN}  📦 AXIS Kit Installer${NC}"
fi
echo -e "${CYAN}  ${BOLD}A${NC}${CYAN}daptive · ${BOLD}X${NC}${CYAN}-Verification · ${BOLD}I${NC}${CYAN}dempotent · ${BOLD}S${NC}${CYAN}tructured${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── Uninstall 모드 ──
if $UNINSTALL_MODE; then
  echo -e "  ${BOLD}📂 대상 경로:${NC} ${CYAN}$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")${NC}"
  echo ""

  COUNT_REMOVED=0

  # AXIS가 설치한 커맨드 파일 제거
  COMMANDS_UNINSTALL=(next init plan xv design gap review propose metrics team auto axis-update)
  echo -e "${BOLD}🔧 커맨드 제거 중...${NC}"
  for cmd in "${COMMANDS_UNINSTALL[@]}"; do
    local_path="${TARGET_DIR}/.claude/commands/${cmd}.md"
    if [[ -f "$local_path" ]]; then
      rm "$local_path"
      echo -e "  ${RED}✗${NC} ${CYAN}.claude/commands/${cmd}.md${NC}"
      COUNT_REMOVED=$((COUNT_REMOVED + 1))
    fi
  done
  echo ""

  # AXIS 에이전트 제거
  AGENTS_UNINSTALL=(architect senior-dev qa-engineer security-engineer devops-engineer)
  echo -e "${BOLD}🤖 에이전트 제거 중...${NC}"
  for agent in "${AGENTS_UNINSTALL[@]}"; do
    local_path="${TARGET_DIR}/.claude/agents/${agent}.md"
    if [[ -f "$local_path" ]]; then
      rm "$local_path"
      echo -e "  ${RED}✗${NC} ${CYAN}.claude/agents/${agent}.md${NC}"
      COUNT_REMOVED=$((COUNT_REMOVED + 1))
    fi
  done
  # .claude/agents/ 디렉토리가 비었으면 제거
  rmdir "${TARGET_DIR}/.claude/agents" 2>/dev/null || true
  echo ""

  # AXIS 스크립트 제거
  SCRIPTS_UNINSTALL=(.axis-version lib/common.sh x-verify.sh gap-check.sh init.sh)
  echo -e "${BOLD}🚀 스크립트 제거 중...${NC}"
  for scr in "${SCRIPTS_UNINSTALL[@]}"; do
    local_path="${TARGET_DIR}/scripts/${scr}"
    if [[ -f "$local_path" ]]; then
      rm "$local_path"
      echo -e "  ${RED}✗${NC} ${CYAN}scripts/${scr}${NC}"
      COUNT_REMOVED=$((COUNT_REMOVED + 1))
    fi
  done
  # scripts/lib/ 디렉토리가 비었으면 제거
  rmdir "${TARGET_DIR}/scripts/lib" 2>/dev/null || true
  echo ""

  # 템플릿 제거
  TEMPLATES_UNINSTALL=(cps-plan.md cps-design.md claude-md.md decision-record.md rule-proposal.md)
  echo -e "${BOLD}📄 템플릿 제거 중...${NC}"
  for tmpl in "${TEMPLATES_UNINSTALL[@]}"; do
    local_path="${TARGET_DIR}/docs/templates/${tmpl}"
    if [[ -f "$local_path" ]]; then
      rm "$local_path"
      echo -e "  ${RED}✗${NC} ${CYAN}docs/templates/${tmpl}${NC}"
      COUNT_REMOVED=$((COUNT_REMOVED + 1))
    fi
  done
  echo ""

  # 가이드 문서 제거
  GUIDES_UNINSTALL=(context-chain.md eval-checklist.md adoption-guide.md)
  echo -e "${BOLD}📚 가이드 문서 제거 중...${NC}"
  for guide in "${GUIDES_UNINSTALL[@]}"; do
    local_path="${TARGET_DIR}/docs/${guide}"
    if [[ -f "$local_path" ]]; then
      rm "$local_path"
      echo -e "  ${RED}✗${NC} ${CYAN}docs/${guide}${NC}"
      COUNT_REMOVED=$((COUNT_REMOVED + 1))
    fi
  done
  echo ""

  # 사용자 문서는 보존
  echo -e "${YELLOW}  ℹ️  보존됨: docs/plans/, docs/designs/, docs/decisions/, docs/verifications/ (사용자 문서)${NC}"
  echo -e "${YELLOW}  ℹ️  보존됨: CLAUDE.md, .env (사용자 설정)${NC}"
  echo ""

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  ✅ AXIS Kit 제거 완료: ${BOLD}${COUNT_REMOVED}개${NC}${GREEN} 파일 삭제${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}💡 CLAUDE.md에서 AXIS 섹션을 수동으로 제거하세요.${NC}"
  echo ""
  exit 0
fi

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
  ".claude/agents"
  "scripts/lib"
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

# 모드별 파일 목록 결정
COMMANDS_ALL=(next init plan xv design gap review propose metrics team auto axis-update)
COMMANDS_MINIMAL=(next plan review)
SCRIPTS_ALL=(.axis-version lib/common.sh x-verify.sh gap-check.sh init.sh)
SCRIPTS_MINIMAL=(.axis-version lib/common.sh init.sh)
AGENTS_ALL=(architect senior-dev qa-engineer security-engineer devops-engineer)
TEMPLATES_ALL=(cps-plan cps-design claude-md decision-record rule-proposal)
GUIDES_ALL=(context-chain.md eval-checklist.md adoption-guide.md)

if $MINIMAL_MODE; then
  COMMANDS=("${COMMANDS_MINIMAL[@]}")
  SCRIPTS=("${SCRIPTS_MINIMAL[@]}")
  AGENTS=()
  TEMPLATES=()
  GUIDES=()
elif $UPDATE_MODE; then
  COMMANDS=("${COMMANDS_ALL[@]}")
  SCRIPTS=("${SCRIPTS_ALL[@]}")
  AGENTS=("${AGENTS_ALL[@]}")
  TEMPLATES=()
  GUIDES=()
else
  COMMANDS=("${COMMANDS_ALL[@]}")
  SCRIPTS=("${SCRIPTS_ALL[@]}")
  AGENTS=("${AGENTS_ALL[@]}")
  TEMPLATES=("${TEMPLATES_ALL[@]}")
  GUIDES=("${GUIDES_ALL[@]}")
fi

# 섹션 다운로드 함수
download_section() {
  local label="$1" dir="$2" suffix="$3"
  shift 3
  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${BOLD}${label} 건너뜀${NC} ${YELLOW}(${MODE_LABEL})${NC}"
  else
    echo -e "${BOLD}${label} 설치 중...${NC}$( $MINIMAL_MODE && echo -e " ${YELLOW}(minimal)${NC}" || true )"
    for f in "${files[@]}"; do
      download "${dir}/${f}${suffix}"
    done
  fi
  echo ""
}

# 모드 라벨
if $UPDATE_MODE; then
  MODE_LABEL="업데이트 모드"
elif $MINIMAL_MODE; then
  MODE_LABEL="minimal 모드"
else
  MODE_LABEL="전체"
fi

download_section "🔧 커맨드" ".claude/commands" ".md" "${COMMANDS[@]}"
download_section "🤖 에이전트" ".claude/agents" ".md" ${AGENTS[@]+"${AGENTS[@]}"}
download_section "🚀 스크립트" "scripts" "" "${SCRIPTS[@]}"
chmod +x "${TARGET_DIR}/scripts/"*.sh 2>/dev/null
if $UPDATE_MODE; then
  echo -e "${BOLD}📄 템플릿 건너뜀${NC} ${YELLOW}(${MODE_LABEL})${NC}"
  for tmpl in "${TEMPLATES_ALL[@]}"; do skip "docs/templates/${tmpl}.md"; done
  echo ""
  echo -e "${BOLD}📚 가이드 문서 건너뜀${NC} ${YELLOW}(${MODE_LABEL})${NC}"
  for guide in "${GUIDES_ALL[@]}"; do skip "docs/${guide}"; done
  echo ""

  # CLAUDE.md AXIS 섹션 자동 갱신
  CLAUDE_MD="${TARGET_DIR}/CLAUDE.md"
  if [[ -f "$CLAUDE_MD" ]]; then
    if grep -q "AXIS Engineering" "$CLAUDE_MD" 2>/dev/null; then
      # 기존 AXIS 섹션이 자동 적용 규칙을 포함하는지 확인
      if ! grep -q "자동 적용 규칙" "$CLAUDE_MD" 2>/dev/null; then
        echo -e "${BOLD}📝 CLAUDE.md AXIS 섹션 업그레이드 중...${NC}"
        # 기존 AXIS 섹션을 제거하고 새 버전으로 교체
        # AXIS 섹션 시작 위치를 찾아 이후 내용을 임시 저장
        AXIS_START=$(grep -n "## AXIS Engineering" "$CLAUDE_MD" | head -1 | cut -d: -f1)
        if [[ -n "$AXIS_START" ]]; then
          # AXIS 섹션 이전 내용 보존
          head -n $((AXIS_START - 1)) "$CLAUDE_MD" > "${CLAUDE_MD}.tmp"

          # AXIS 이후 다음 ## 섹션 찾기 (AXIS 내부의 ### 제외)
          AFTER_AXIS=$(tail -n +"$((AXIS_START + 1))" "$CLAUDE_MD" | grep -n "^## [^#]" | head -1 | cut -d: -f1 || true)

          # 새 AXIS 섹션 추가
          cat >> "${CLAUDE_MD}.tmp" << 'AXIS_V16'
## AXIS Engineering

이 프로젝트는 AXIS Engineering 방법론을 따른다.
아래 규칙은 사용자가 커맨드를 명시적으로 호출하지 않아도 **모든 대화에 자동 적용**된다.

### 자동 적용 규칙

#### 1. 작업 전 복잡도 판단
- **간단** (버그, 1~2 파일): 바로 구현 → 독립 에이전트 검증
- **보통** (새 기능, 3~7 파일): Plan → 승인 → 구현 → 독립 검증
- **복잡** (8+ 파일, 다중 모듈): Plan → Design → 스프린트 분할 → 구현 → 독립 검증

#### 2. Generator-Evaluator 분리 (핵심)
- 구현(Generator)과 검증(Evaluator)은 **반드시 다른 서브에이전트**로 실행
- 검증 에이전트는 적대적 자세: "통과시키지 마라, 문제를 찾아라"
- 간단한 작업에서도 구현 후 최소한 독립 서브에이전트로 코드 리뷰 수행

#### 3. 검증 기준
- **기능**: 요청한 것이 실제로 동작하는가?
- **데이터 관통**: 입력 → 저장 → 로드 → 표시까지 완전한가?
- **설계 정합성**: 기존 코드/아키텍처와 일관되는가?
- **크래프트**: 에러 핸들링, 엣지 케이스, 타입 안전성

#### 4. 블로커 분류
- **Auto-Resolve**: 되돌리기 가능 → 자동 해결
- **Soft-Block**: 진행 가능하나 기록 필요 → 기록 후 계속
- **Hard-Block**: 돌이킬 수 없음 → 즉시 중단, 사용자 판단 요청

#### 5. 복잡한 작업의 스프린트 분할
- 8개 이상 파일 수정 시 독립 검증 가능한 스프린트로 분할
- 각 스프린트마다 구현 → 검증 사이클 반복

#### 6. 실행 검증 우선
- "코드가 존재한다" ≠ "동작한다"
- 가능한 경우 실제 테스트 실행 (테스트, 브라우저 등)

### Workflow
사용자 요청
  간단 → 구현 → 독립 검증 → 완료
  보통 → Plan → 승인 → 구현 → 독립 검증 → 완료
  복잡 → Plan → Design → 스프린트별 (구현→검증) → Independent Verifier → 완료

### Commands (상세 절차가 필요할 때)
| 커맨드 | 설명 |
|--------|------|
| `/next` | 다음 할 일 추천 |
| `/plan 기능명` | CPS Plan 작성 |
| `/xv "질문"` | 멀티 AI 교차검증 |
| `/design 기능명` | CPS Design 작성 |
| `/gap 설계.md 코드/` | 역방향 검증 |
| `/review 코드` | 코드 리뷰 |
| `/auto 기능명` | 전체 하네스 자율 실행 |
| `/team 프리셋` | Agent Teams 병렬 구성 |
| `/propose 패턴` | 규칙 제안 |
| `/metrics` | 도입 수준 측정 |

### 합의 프로토콜
- 90%+ → 자동 채택
- 70~89% → 사람 판단
- 70% 미만 → 재정의 필요
AXIS_V16

          # AXIS 이후의 나머지 섹션 복원
          if [[ -n "$AFTER_AXIS" ]]; then
            echo "" >> "${CLAUDE_MD}.tmp"
            tail -n +"$((AXIS_START + AFTER_AXIS))" "$CLAUDE_MD" >> "${CLAUDE_MD}.tmp"
          fi

          mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
          echo -e "  ${GREEN}✓${NC} ${CYAN}CLAUDE.md${NC} AXIS 섹션 → v1.6 (자동 적용 규칙 추가)"
          COUNT_UPDATED=$((COUNT_UPDATED + 1))
        fi
      else
        echo -e "${BOLD}📝 CLAUDE.md${NC} ${YELLOW}(이미 v1.6+ AXIS 섹션 포함)${NC}"
      fi
    else
      echo -e "${YELLOW}  ℹ️  CLAUDE.md에 AXIS 섹션 없음. 추가하려면: bash scripts/init.sh --adopt 프로젝트명${NC}"
    fi
  fi
  echo ""
else
  download_section "📄 템플릿" "docs/templates" ".md" ${TEMPLATES[@]+"${TEMPLATES[@]}"}
  download_section "📚 가이드 문서" "docs" "" ${GUIDES[@]+"${GUIDES[@]}"}
fi

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

# Agent Teams 활성화 안내 (전체 설치/업데이트 시)
if ! $MINIMAL_MODE && ! $UNINSTALL_MODE; then
echo -e "${BOLD}🤝 Agent Teams (선택):${NC}"
echo -e "  ${CYAN}/team${NC} 커맨드로 병렬 에이전트 팀을 구성할 수 있습니다."
echo -e "  활성화하려면 ${CYAN}.claude/settings.json${NC}에 다음을 추가하세요:"
echo ""
echo -e "  ${YELLOW}{${NC}"
echo -e "  ${YELLOW}  \"env\": {${NC}"
echo -e "  ${YELLOW}    \"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\": \"1\"${NC}"
echo -e "  ${YELLOW}  }${NC}"
echo -e "  ${YELLOW}}${NC}"
echo ""
fi
