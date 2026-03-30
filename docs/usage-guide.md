# Nova 사용법 가이드

> 처음부터 제대로. 매번 더 빠르게.
>
> 12개 커맨드 + 5개 전문가 에이전트 + 5개 스킬의 상세 사용법

---

## 목차

1. [시작하기](#시작하기)
2. [커맨드 상세](#커맨드-상세)
3. [전문가 에이전트](#전문가-에이전트)
4. [전체 워크플로우 예시](#전체-워크플로우-예시)
5. [팁과 베스트 프랙티스](#팁과-베스트-프랙티스)

---

## 시작하기

### 설치

```bash
# 1. Nova 마켓플레이스 등록
claude plugin marketplace add TeamSPWK/nova

# 2. 플러그인 설치 — 12개 커맨드 + 5개 에이전트 + 5개 스킬 자동 활성화
claude plugin install nova@nova-marketplace
```

### API 키 설정

다관점 수집(`/nova:xv` Mode A)을 사용하려면 AI API 키가 필요합니다:

```bash
cat > .env << 'EOF'
ANTHROPIC_API_KEY="sk-ant-..."
OPENAI_API_KEY="sk-..."
GEMINI_API_KEY="AI..."
EOF
```

> **API 키 없이도 다관점 수집 가능!** `/nova:xv`는 API 키 없이 에이전트 모드(Mode B)로 자동 전환됩니다.
> 나머지 커맨드는 API 키 없이도 동작합니다.

### 업데이트 & 삭제

```bash
# 업데이트
claude plugin update nova@nova-marketplace

# 삭제
claude plugin uninstall nova@nova-marketplace
claude plugin marketplace remove nova-marketplace
```

---

## 커맨드 상세

### `/nova:next` — 다음 할 일 추천

프로젝트 상태를 자동 진단하고, Nova 워크플로우에서 다음에 실행할 커맨드를 추천합니다.

```bash
/nova:next
```

**동작 원리:**
- `docs/plans/`, `docs/designs/`, `docs/verifications/` 스캔
- `git log`, `git status` 확인
- 워크플로우 규칙에 따라 추천:

| 상태 | 추천 |
|------|------|
| Plan 없음 | `/nova:plan` |
| Plan 있고 Design 없음 | `/nova:design` |
| Design 있고 코드 커밋 있지만 검증 없음 | `/nova:gap` |
| 검증 완료 | `/nova:review` |
| 리뷰 완료 | `/nova:propose` |
| 모두 완료 | "다음 기능 시작 준비 완료" |

**출력 예시:**
```
추천: /nova:gap docs/designs/auth.md src/

프로젝트 진단:
  Plans:         2개 (최근: auth.md)
  Designs:       1개
  Verifications: 0개
  최근 커밋:     5개 (마지막: feat: 인증 모듈 구현)

이유: 설계 문서가 있고 최근 구현 커밋이 있지만 검증이 없습니다.

이후 흐름: /nova:gap → /nova:review → /nova:propose
```

---

### `/nova:init` — 프로젝트 초기 설정

Nova 디렉토리 구조와 CLAUDE.md를 자동 생성합니다.

```bash
/nova:init my-project            # 기본 (프로젝트명만)
/nova:init                       # 대화형 — 정보를 물어봄
```

**생성되는 것:**
- `CLAUDE.md` — 프로젝트 맥락 + Nova 커맨드 + 컨벤션
- `docs/plans/`, `docs/designs/`, `docs/decisions/`, `docs/verifications/`
- `.gitignore` 업데이트

**기존 프로젝트에 도입할 때:**
```bash
/nova:init --adopt my-project
```
→ 기존 CLAUDE.md를 수정하지 않고, 끝에 Nova 섹션만 추가합니다.

---

### `/nova:plan 기능명` — CPS Plan 작성

CPS(Context → Problem → Solution) 구조로 기능 계획서를 작성합니다.

```bash
/nova:plan 사용자 인증
/nova:plan 아파트 비교 기능
/nova:plan 결제 시스템 도입
```

**포함 내용:**
- **Context**: 왜 필요한가? 현재 상태
- **Problem**: 핵심 문제 + MECE 분해 (겹침 없이, 빠짐 없이)
- **Solution**: 선택한 방안, 대안 비교, 구현 범위, 검증 기준

**산출물:** `docs/plans/{slug}.md`

> Plan은 "무엇을, 왜" — Design은 "어떻게"

**예시:** [examples/sample-plan.md](../examples/sample-plan.md)

---

### `/nova:xv "질문"` — 멀티 AI 다관점 수집

3개 이상의 독립 관점에서 동시 질의하고 합의 수준을 자동 산출합니다.

```bash
/nova:xv "Next.js에서 서버 액션 vs API 라우트, 기본으로 어떤 걸 쓸까?"
/nova:xv "PostgreSQL vs MongoDB, 부동산 플랫폼에 적합한 건?"
/nova:xv --agent "API 키 없이 에이전트로 다관점 수집"
```

#### Mode A: API 다관점 수집

`.env`에 API 키가 1개 이상 있으면 자동 선택됩니다. Claude + GPT + Gemini 3개 AI에게 동시 질의합니다.

```bash
/nova:xv "기술적 질문"           # API 키가 있으면 자동으로 Mode A
```

#### Mode B: 에이전트 다관점 수집

API 키 없이도 다관점 수집을 수행합니다. 3개 병렬 에이전트를 서로 다른 전문가 관점(아키텍트, 시니어 개발자, QA/보안)으로 **동시에** 실행합니다.

```bash
/nova:xv --agent "질문"          # 명시적으로 에이전트 모드 사용
/nova:xv "질문"                  # API 키가 없으면 자동으로 Mode B
```

**모드 자동 판별:**

| 조건 | 선택 모드 |
|------|-----------|
| `--agent` 옵션 사용 | Mode B (에이전트) |
| `.env`에 API 키 없음 | Mode B (에이전트) |
| `.env`에 API 키 있음 | Mode A (API) |

**합의 프로토콜 (양쪽 모드 공통):**

| 합의 수준 | 판정 | 행동 |
|-----------|------|------|
| Strong Consensus | AUTO APPROVE | 자동 채택 |
| Partial Consensus | HUMAN REVIEW | AI가 차이점 요약, 사람이 판단 |
| Divergent | REDEFINE | 질문 재정의 필요 |

**산출물:** `docs/verifications/{date}-{slug}.md`

**예시:** [examples/sample-xv-result.md](../examples/sample-xv-result.md)

---

### `/nova:design 기능명` — CPS Design 작성

Plan을 기반으로 기술 설계 상세를 작성합니다.

```bash
/nova:design 사용자 인증     # docs/plans/에서 관련 Plan을 자동 참조
```

**포함 내용:**
- **Context**: Plan 요약, 설계 원칙
- **Problem**: 기술적 과제, 기존 시스템 접점
- **Solution**: 아키텍처, 데이터 모델, API 설계, 에러 처리
- **검증 계약**: `/nova:gap`에서 검증할 테스트 가능한 성공 조건 목록

**산출물:** `docs/designs/{slug}.md`

> 검증 계약은 Generator-Evaluator 패턴의 핵심입니다.
> 구현자(AI)와 검증자(AI/사람)가 "이것이 성공 조건"이라고 사전에 합의합니다.

**예시:** [examples/sample-design.md](../examples/sample-design.md)

---

### `/nova:gap 설계.md 코드/` — 역방향 검증

설계 문서와 실제 구현 코드를 비교하여 갭을 자동 탐지합니다.

```bash
/nova:gap docs/designs/auth.md src/
/nova:gap docs/designs/auth.md         # 코드 경로 자동 추론
/nova:gap                              # 최근 설계 문서 자동 선택
```

**판정 기준:**

| 매칭률 | 판정 | 행동 |
|--------|------|------|
| 90%+ | PASS | 설계-구현 일치 |
| 70~89% | REVIEW NEEDED | 미구현 항목 정리 → 보완 |
| 70% 미만 | SIGNIFICANT GAPS | 설계 재검토 또는 대규모 보완 |

**핵심 원칙:** Generator-Evaluator 분리 — 구현한 AI와 검증하는 AI가 독립적으로 동작하여 자기 평가 편향을 제거합니다.

---

### `/nova:review 코드` — 코드 리뷰

단순성 원칙(Rob Pike)과 Nova 구조 원칙으로 코드를 진단합니다.

```bash
/nova:review src/auth/
/nova:review src/components/CompareTable.tsx
```

**평가 기준:**
- **Over_Abstraction**: 1-2회 사용을 위한 불필요한 레이어?
- **Control_Flow_Bloat**: 데이터 구조로 제거 가능한 조건문?
- **Side_Effect_Scatter**: 부수효과가 여러 계층에 분산?
- **Premature_Optimization**: 측정 없이 성능 가정?
- **Missing_Lookup**: 런타임 계산을 정적 Map으로 치환 가능?
- **Design_Drift**: 설계 문서와 구현의 괴리? (Nova 고유)

**출력 형식:**
1. Rule Violation Report — 기준별 True/False + 사유
2. Complexity Analysis — 문제 함수 + 간소화 방향
3. Refactoring Suggestion — Before/After 코드
4. Nova Alignment — 설계 문서와의 정합성

---

### `/nova:propose 패턴` — 규칙 제안

반복되는 코드/프로세스 패턴을 규칙으로 승격시키는 제안서를 작성합니다.

```bash
/nova:propose 에러 핸들링 패턴
/nova:propose API 응답 구조 통일
```

**Adaptive 사이클:**
```
감지(Detect) → 제안(/nova:propose) → 승인(사람) → 적용 → 검증
```

**산출물:** `docs/proposals/{slug}.md`

> AI는 제안만 합니다. 승인은 반드시 사람이 합니다.
> 패턴 3회 이상 반복 시 규칙 제안을 고려하세요.

---

### `/nova:metrics` — Nova 도입 수준 측정

프로젝트의 Nova 4대 Pillar별 점수를 자동 산출합니다.

```bash
/nova:metrics
```

**측정 항목 (17점 만점):**

| Pillar | 항목 수 | 측정 내용 |
|--------|---------|----------|
| Structured | 5점 | CLAUDE.md, Plan/Design 문서, 린터, 커밋 컨벤션 |
| Idempotent | 4점 | 템플릿, Tech Stack, 컨텍스트 체인, 의사결정 기록 |
| X-Verification | 4점 | 다관점 수집 도구/결과, 갭 체크 도구/결과 |
| Adaptive | 4점 | /nova:propose, 규칙 변경 이력, 제안 템플릿/기록 |

**등급:**

| 등급 | 점수 |
|------|------|
| Level 5 | 17점 — Nova 완전 적용 |
| Level 4 | 14~16점 — 높은 수준 |
| Level 3 | 10~13점 — 중간 |
| Level 2 | 6~9점 — 초기 |
| Level 1 | 0~5점 — 시작 단계 |

---

## 전문가 에이전트

Nova는 5종의 전문가 에이전트를 제공합니다. 플러그인 설치 시 자동으로 활성화됩니다.

### 에이전트 개요

| 에이전트 | 핵심 역할 | 활용 시점 |
|----------|----------|----------|
| Architect | 시스템 구조 설계, 기술 선택, 확장성 검토 | 아키텍처 결정, 모듈 분리, ADR 작성 |
| Senior Dev | 코드 품질, 리팩토링, 최소 변경 구현 | 코드 리뷰, 기술 부채 해소, 디자인 패턴 적용 |
| QA Engineer | 테스트 전략, 엣지 케이스, 품질 검증 | 테스트 시나리오 설계, 버그 재현, 경계값 분석 |
| Security Engineer | 보안 취약점, 위협 모델링, 인증/인가 검토 | 보안 감사, 시크릿 노출 탐지, OWASP 기반 분석 |
| DevOps Engineer | CI/CD, 인프라, 배포 전략, 모니터링 | Dockerfile, GitHub Actions, IaC 검토/작성 |

### 에이전트 상세

#### Architect (아키텍트)

시스템 아키텍처 전문가. 확장성, 유지보수성, 모듈 간 결합도를 최우선으로 판단합니다.

**판단 우선순위:** 단순성 → 확장성 → 유지보수성 → 성능
- 설계 판단 시 최소 2개 대안을 비교하고 트레이드오프를 명시
- 코드를 직접 수정하지 않음 — 구조와 방향만 제시
- 불확실한 기술 선택은 `/nova:xv` 다관점 수집을 제안

#### Senior Dev (시니어 개발자)

10년차 시니어 개발자. 코드 품질, DX(개발자 경험), 최소 변경 원칙을 최우선으로 판단합니다.

**판단 우선순위:** 정확성 → 가독성 → 최소 변경 → 테스트 용이성
- 구현 전 영향 범위를 먼저 분석하고 계획을 제시
- 3개 이상 파일 수정 시 계획 승인 후 진행
- 불필요한 추상화, 과도한 설정, 미래 대비 코드를 만들지 않음

#### QA Engineer (QA 엔지니어)

**판단 우선순위:** 재현 가능성 → 커버리지 → 자동화 가능성 → 유지보수성
- 정상 경로보다 실패 경로를 먼저 확인
- 입력 경계값(0, -1, 빈 문자열, null, 최대값)을 항상 검증
- 코드를 직접 수정하지 않음 — 테스트와 이슈 리포트만 작성

#### Security Engineer (보안 엔지니어)

**판단 우선순위:** 악용 가능성 → 영향 범위 → 수정 용이성 → 심층 방어
- 분석 전 공격 표면(입력 경로, 인증 경계, 외부 API)을 먼저 매핑
- 시크릿 패턴(.env, API 키, 토큰, 비밀번호)을 항상 탐지
- 코드를 직접 수정하지 않음 — 취약점 리포트와 수정 가이드만 제공

#### DevOps Engineer (데브옵스 엔지니어)

**판단 우선순위:** 롤백 가능성 → 재현 가능성 → 관측성 → 자동화
- 인프라 변경 전 롤백 계획을 먼저 수립
- 시크릿은 환경변수 또는 시크릿 매니저로만 관리
- 클라우드 리소스 변경 전 반드시 사용자 확인

### 에이전트와 `/nova:xv`의 관계

`/nova:xv` 에이전트 모드(Mode B)에서는 Architect, Senior Dev, QA/Security 3개 관점을 병렬로 실행하여 다관점 수집합니다. 이는 전문가 에이전트의 핵심 활용 사례입니다.

---

## 전체 워크플로우 예시

### 시나리오: "사용자 인증 기능 추가"

```
1. /nova:next
   → "Plan 없음. /nova:plan으로 시작하세요."

2. /nova:plan 사용자 인증
   → docs/plans/user-auth.md 생성
   → Context: 로그인 기능 필요
   → Problem: MECE로 5개 영역 분해
   → Solution: JWT 이중 토큰 방식 채택

3. /nova:xv "JWT vs 세션 기반 인증, SPA에 적합한 건?"
   → 3개 AI 동시 질의 (또는 에이전트 모드로 3개 관점 병렬 분석)
   → Strong Consensus → JWT 채택

4. /nova:design 사용자 인증
   → docs/designs/user-auth.md 생성
   → 아키텍처, API 7개, 데이터 모델, 검증 계약 11개

5. [구현]
   → 설계에 따라 코드 작성

6. /nova:gap docs/designs/user-auth.md src/
   → 매칭률 85% → REVIEW NEEDED
   → 미구현: "비밀번호 재설정 API"
   → 보완 후 재실행 → 매칭률 95% → PASS

7. /nova:review src/auth/
   → Over_Abstraction: False
   → Design_Drift: False (Gap 통과)
   → Refactoring: TokenService 분리 제안

8. /nova:propose JWT 토큰 갱신 패턴
   → 3번 이상 반복된 토큰 갱신 로직을 규칙으로 제안
   → 사람 승인 → CLAUDE.md에 반영

9. /nova:metrics
   → Structured: 5/5, Idempotent: 4/4, X-Verify: 4/4, Adaptive: 3/4
   → 총점: 16/17 → Level 4
```

---

## 팁과 베스트 프랙티스

### 언제 `/nova:xv`를 쓸까?
- 기술 스택 선택 (DB, 프레임워크, 라이브러리)
- 아키텍처 패턴 결정 (모노리스 vs 마이크로서비스)
- 설계 방향 갈림길 (REST vs GraphQL)
- **API 키 없을 때**: `--agent` 옵션으로 에이전트 모드 사용 — 프로젝트 코드를 직접 참조하여 더 구체적인 답변 가능
- **안 써도 되는 경우**: 단순 버그 수정, 스타일 결정, 이미 합의된 사항

### 전문가 에이전트 활용 시나리오
- **Architect**: "이 모듈을 어떻게 분리해야 할까?", "마이크로서비스로 전환할 시점인가?"
- **Senior Dev**: "이 코드를 리팩토링해줘", "기술 부채를 정리하고 싶어"
- **QA Engineer**: "이 기능의 테스트 시나리오를 설계해줘", "엣지 케이스를 찾아줘"
- **Security Engineer**: "이 API의 보안을 점검해줘", "시크릿 노출이 없는지 확인해줘"
- **DevOps Engineer**: "CI/CD 파이프라인을 구성해줘", "Dockerfile을 최적화해줘"

### `/nova:gap`을 최대한 활용하려면
- `/nova:design`에서 검증 계약을 상세하게 작성하세요
- "사용자가 X하면 Y가 되어야 한다" 형식이 가장 효과적
- 매칭률이 올라가는 추세면 계속, 정체되면 접근 전환

### `/nova:propose`를 쓸 타이밍
- "이거 전에도 이렇게 했는데..." 싶을 때
- 같은 패턴이 3번 이상 반복될 때
- 코드 리뷰에서 같은 피드백이 반복될 때

### 경량 원칙 지키기
- 모든 커맨드를 매번 쓸 필요 없음
- 단순 버그 수정 → Plan/Design 스킵, 바로 구현 → `/nova:review`
- 확신 있는 판단 → `/nova:xv` 스킵
- **`/nova:next`가 항상 적절한 다음 단계를 알려줍니다**
