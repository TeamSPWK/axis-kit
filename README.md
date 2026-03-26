# AXIS Kit

> **A**daptive · **X**-Verification · **I**dempotent · **S**tructured

AI 시대의 소프트웨어 개발 방법론 도구 키트.
어떤 AI를 쓰든, 누가 쓰든, 언제 쓰든 — 같은 구조에서 같은 품질이 나온다.

## 핵심 원칙

```
A — Adaptive    : 규칙이 프로젝트와 함께 진화한다
X — X-Verify    : 멀티 AI 교차검증으로 단일 판단을 맹신하지 않는다
I — Idempotent  : 누가, 어떤 AI로, 언제 해도 같은 품질이 나온다
S — Structured  : CPS + MECE + 린터로 구조가 품질을 만든다
```

## 빠른 시작

### 1. 설치

```bash
# 프로젝트 루트에 복사
cp -r axis-kit/.claude/commands/ your-project/.claude/commands/
cp -r axis-kit/scripts/ your-project/scripts/
cp -r axis-kit/docs/templates/ your-project/docs/templates/
```

### 2. API 키 설정

```bash
# 프로젝트 루트에 .env 생성
cat > .env << 'EOF'
ANTHROPIC_API_KEY="your-key"
OPENAI_API_KEY="your-key"
GEMINI_API_KEY="your-key"
EOF
```

### 3. 사용

```bash
# Claude Code에서 슬래시 커맨드로 사용
/xv "Next.js에서 서버 액션 vs API 라우트, 어떤 걸 기본으로?"
/plan 아파트 비교 기능
/design 아파트 비교 기능
/gap docs/designs/compare.md src/
/review src/components/CompareTable.tsx
```

## 커맨드

| 커맨드 | 설명 | 사용 시점 |
|--------|------|----------|
| `/xv "질문"` | 멀티 AI 교차검증 (Claude+GPT+Gemini) | 설계 판단, 아키텍처 선택 |
| `/plan 기능명` | CPS Plan 문서 작성 | 새 기능 기획 시 |
| `/design 기능명` | CPS Design 문서 작성 | Plan 이후 기술 설계 시 |
| `/gap 설계.md 코드/` | 설계↔구현 역방향 검증 | 구현 완료 후 누락 확인 |
| `/review 코드` | 단순성 원칙 코드 리뷰 | 코드 품질 점검 |

### 워크플로우

```
기능 요청 → /plan → /xv (필요시) → /design → 구현 → /gap → /review
```

## 교차검증 (X-Verification)

3개 AI(Claude, GPT, Gemini)에게 동시에 질의하고 합의율을 자동 산출합니다.

```bash
# CLI에서 직접 실행
./scripts/x-verify.sh "기술적 질문"

# 결과 저장 없이 실행
./scripts/x-verify.sh --no-save "빠른 질문"

# 파일에서 질문 읽기
./scripts/x-verify.sh -f question.txt
```

**합의 프로토콜:**
- 90%+ 합의 → 자동 채택
- 70~89% → AI가 차이점 요약, 사람이 판단
- 70% 미만 → 사람 필수 개입, 질문 재정의 검토

검증 결과는 `docs/verifications/`에 자동 저장됩니다.

## 역방향 검증 (Gap Check)

설계 문서와 구현 코드의 갭을 자동 탐지합니다.

```bash
./scripts/gap-check.sh docs/designs/feature.md src/
```

**판정 기준:**
- 매칭률 90%+ → PASS
- 매칭률 70~89% → REVIEW NEEDED
- 매칭률 70% 미만 → SIGNIFICANT GAPS

## CPS 프레임워크

모든 설계/분석 문서는 CPS 구조를 따릅니다:

```
Context  — 왜 이 작업이 필요한가? 배경과 현재 상태
Problem  — 구체적으로 무엇이 문제인가? MECE로 분해
Solution — 어떻게 해결하는가? 트레이드오프와 결정 근거 포함
```

템플릿: `docs/templates/cps-plan.md`, `docs/templates/cps-design.md`

## 파일 구조

```
axis-kit/
├── .claude/commands/      # Claude Code 슬래시 커맨드
│   ├── xv.md              # /xv — 멀티 AI 교차검증
│   ├── plan.md            # /plan — CPS Plan 작성
│   ├── design.md          # /design — CPS Design 작성
│   ├── gap.md             # /gap — 역방향 검증
│   └── review.md          # /review — 코드 리뷰
├── scripts/
│   ├── x-verify.sh        # 교차검증 CLI
│   └── gap-check.sh       # 갭 체크 CLI
├── docs/
│   ├── axis-engineering.md # 방법론 상세
│   └── templates/          # CPS 문서 템플릿
└── examples/               # 사용 예시
```

## CLAUDE.md 설정 예시

프로젝트 루트의 CLAUDE.md에 추가:

```markdown
## AXIS Engineering

이 프로젝트는 AXIS Engineering 방법론을 따른다.

### Commands
| 커맨드 | 설명 |
|--------|------|
| `/xv "질문"` | 멀티 AI 교차검증 |
| `/plan 기능명` | CPS Plan 문서 작성 |
| `/design 기능명` | CPS Design 문서 작성 |
| `/gap 설계.md 코드/` | 역방향 검증 |
| `/review 코드` | 코드 리뷰 |

### 합의 프로토콜
- 90%+ → 자동 채택
- 70~89% → 사람 판단
- 70% 미만 → 재정의 필요
```

## 요구사항

- [Claude Code](https://claude.ai/code) CLI
- API 키: Anthropic + OpenAI + Google AI Studio
- `jq`, `curl` (스크립트 실행용)

## 라이선스

MIT

## 만든 사람

Spacewalk Engineering
