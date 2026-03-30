#!/usr/bin/env bash
#
# AXIS Kit 프로젝트 초기화 스크립트
# Usage: bash scripts/init.sh <프로젝트명> [기술스택] [언어]
#
# 예시:
#   bash scripts/init.sh my-app "Next.js + TypeScript" "한국어"
#   bash scripts/init.sh my-app
#   bash scripts/init.sh --adopt my-app   # 기존 프로젝트에 비파괴적 도입
#

set -euo pipefail

# --- 모드 감지 ---
ADOPT_MODE=false
if [[ "${1:-}" == "--adopt" ]]; then
  ADOPT_MODE=true
  shift
fi

# --- 인자 파싱 ---
PROJECT_NAME="${1:-}"
TECH_STACK="${2:-}"
LANGUAGE="${3:-한국어}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
check_update

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${BOLD}사용법:${NC}"
  echo -e "  ${YELLOW}\$ bash scripts/init.sh [--adopt] <프로젝트명> [기술스택] [언어]${NC}"
  echo ""
  echo -e "${BOLD}예시:${NC}"
  echo -e "  ${YELLOW}\$ bash scripts/init.sh my-app \"Next.js + TypeScript\" \"한국어\"${NC}"
  echo -e "  ${YELLOW}\$ bash scripts/init.sh --adopt my-app${NC}   # 기존 프로젝트에 비파괴적 도입"
  exit 1
fi

if [ "$ADOPT_MODE" = true ]; then
  banner "🔧 AXIS Kit 기존 프로젝트 도입: ${BOLD}$PROJECT_NAME"
else
  banner "🔧 AXIS Kit 초기화: ${BOLD}$PROJECT_NAME"
fi
echo ""

# --- 디렉토리 생성 ---
dirs=(
  "docs/plans"
  "docs/designs"
  "docs/decisions"
  "docs/verifications"
  "docs/templates"
  "scripts"
)

for dir in "${dirs[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    echo -e "  ${GREEN}✓${NC} 📁 ${CYAN}$dir/${NC} 생성"
  else
    echo -e "  ${YELLOW}→${NC} 📁 ${CYAN}$dir/${NC} (이미 존재)"
  fi
done

echo ""

# --- CLAUDE.md 생성/업데이트 ---
if [ -f "CLAUDE.md" ] && [ "$ADOPT_MODE" = true ]; then
  # 기존 프로젝트: AXIS 섹션만 추가
  if grep -q "AXIS Engineering" CLAUDE.md 2>/dev/null; then
    echo -e "  ${YELLOW}→${NC} 📄 ${CYAN}CLAUDE.md${NC} — AXIS 섹션이 이미 존재합니다."
  else
    cat >> CLAUDE.md << 'AXIS_SECTION'

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

### 합의 프로토콜
- 90%+ → 자동 채택
- 70~89% → 사람 판단
- 70% 미만 → 재정의 필요
AXIS_SECTION
    echo -e "  ${GREEN}✓${NC} 📄 ${CYAN}CLAUDE.md${NC} — AXIS 섹션 추가 완료 (기존 내용 유지)"
  fi
elif [ -f "CLAUDE.md" ]; then
  echo -e "  ${YELLOW}⚠️  CLAUDE.md가 이미 존재합니다. 건너뜁니다.${NC}"
  echo -e "     기존 프로젝트에 도입하려면: ${YELLOW}\$ bash scripts/init.sh --adopt $PROJECT_NAME${NC}"
else
  TECH_SECTION=""
  if [ -n "$TECH_STACK" ]; then
    TECH_SECTION="- $TECH_STACK"
  else
    TECH_SECTION="- (기술 스택을 여기에 작성)"
  fi

  cat > CLAUDE.md << TMPL
# ${PROJECT_NAME}

{프로젝트 한 줄 설명을 여기에 작성}

## Language

- Claude는 사용자에게 항상 **${LANGUAGE}**로 응답한다.

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

### Workflow
\`\`\`
사용자 요청
  ├── 간단 → 구현 → 독립 검증 → 완료
  ├── 보통 → Plan → 승인 → 구현 → 독립 검증 → 완료
  └── 복잡 → Plan → Design → 스프린트별 (구현→검증) → 완료
\`\`\`

### Commands (상세 절차가 필요할 때)
| 커맨드 | 설명 |
|--------|------|
| \`/next\` | 다음 할 일 추천 |
| \`/plan 기능명\` | CPS Plan 작성 |
| \`/xv "질문"\` | 멀티 AI 교차검증 |
| \`/design 기능명\` | CPS Design 작성 |
| \`/gap 설계.md 코드/\` | 역방향 검증 |
| \`/review 코드\` | 코드 리뷰 |
| \`/auto 기능명\` | 전체 하네스 자율 실행 |
| \`/team 프리셋\` | Agent Teams 병렬 구성 |

### 합의 프로토콜
- 90%+ → 자동 채택
- 70~89% → 사람 판단
- 70% 미만 → 재정의 필요

## Tech Stack

${TECH_SECTION}

## Project Structure

\`\`\`
${PROJECT_NAME}/
├── src/              # 소스 코드
├── docs/
│   ├── plans/        # CPS Plan 문서
│   ├── designs/      # CPS Design 문서
│   ├── decisions/    # 의사결정 기록 (ADR)
│   ├── verifications/ # 교차검증 결과
│   └── templates/    # 문서 템플릿
├── scripts/          # AXIS 스크립트
└── .env              # API 키 (git 추적 금지)
\`\`\`

## Conventions

### Git
\`\`\`
feat: 새 기능      | fix: 버그 수정
update: 기능 개선  | docs: 문서 변경
refactor: 리팩토링 | chore: 설정/기타
\`\`\`

## Human-AI Boundary

| 영역 | AI 담당 | 인간 담당 |
|------|---------|----------|
| 코드 생성 | 구현 + 독립 검증 | 아키텍처 결정, 비즈니스 판단 |
| 검증 | Evaluator 에이전트 자동 실행 | 최종 승인, 엣지 케이스 판단 |
| 규칙 관리 | 패턴 감지, 규칙 제안 | 승인/거부, 방향성 결정 |
| 문서화 | 초안 생성, 동기화 유지 | 의도/맥락 기술 |

## Credentials

- **절대 git 커밋 금지**: \`.env\`, \`.secret/\`, \`*.pem\`, \`*accessKeys*\`
TMPL

  echo -e "  ${GREEN}✓${NC} 📄 ${CYAN}CLAUDE.md${NC} 생성"
fi

echo ""

# --- .gitignore 업데이트 ---
GITIGNORE_ENTRIES=(
  ".env"
  ".secret/"
  "*.pem"
  "*accessKeys*"
)

ADDED=0

if [ ! -f ".gitignore" ]; then
  touch .gitignore
  echo -e "  ${GREEN}✓${NC} 📄 ${CYAN}.gitignore${NC} 생성"
fi

# AXIS 섹션 헤더 추가 여부 확인
if ! grep -q "# AXIS Engineering" .gitignore 2>/dev/null; then
  echo "" >> .gitignore
  echo "# AXIS Engineering" >> .gitignore
fi

for entry in "${GITIGNORE_ENTRIES[@]}"; do
  if ! grep -qF "$entry" .gitignore 2>/dev/null; then
    echo "$entry" >> .gitignore
    ADDED=$((ADDED + 1))
  fi
done

if [ "$ADDED" -gt 0 ]; then
  echo -e "  ${GREEN}✓${NC} 📄 ${CYAN}.gitignore${NC} 업데이트 (${BOLD}${ADDED}개${NC} 항목 추가)"
else
  echo -e "  ${YELLOW}→${NC} 📄 ${CYAN}.gitignore${NC} (변경 없음)"
fi

# --- 완료 ---
echo ""
divider
echo -e "${GREEN}  ✅ AXIS Kit 초기화 완료: ${BOLD}${PROJECT_NAME}${NC}"
divider
echo ""
if [ "$ADOPT_MODE" = true ]; then
  echo -e "${BOLD}👉 다음 단계:${NC}"
  echo ""
  echo -e "  1. 🧭 현재 상태 진단 + 다음 할 일 확인"
  echo -e "     ${YELLOW}\$ /next${NC}"
  echo ""
  echo -e "${BOLD}🔄 익숙해지면 추가 커맨드 설치:${NC}"
  echo -e "     ${YELLOW}\$ curl -fsSL https://raw.githubusercontent.com/TeamSPWK/axis-kit/main/install.sh | bash${NC}"
  echo ""
else
  echo -e "${BOLD}👉 다음 단계:${NC}"
  echo ""
  echo -e "  1. 📝 ${CYAN}CLAUDE.md${NC}를 열어 프로젝트 설명과 기술 스택을 채우세요"
  echo ""
  echo -e "  2. 🧭 다음 할 일 확인"
  echo -e "     ${YELLOW}\$ /next${NC}"
  echo ""
fi
