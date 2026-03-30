# Nova

[![CI](https://github.com/TeamSPWK/nova/actions/workflows/ci.yml/badge.svg)](https://github.com/TeamSPWK/nova/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-2.1.0-blue)](https://github.com/TeamSPWK/nova/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**처음부터 제대로. 매번 더 빠르게.**
Build Right the First Time. Faster Every Time.

> AI가 코드를 빠르게 만들어줘도, 잘못된 판단 하나가 3주 뒤 전체 리팩토링으로 돌아온다.
> Nova는 **설계 판단을 구조화**하여 재작업을 제거하는 Claude Code 플러그인이다.

```bash
# 30초 설치 — 바로 써보세요
claude plugin marketplace add TeamSPWK/nova
claude plugin install nova@nova-marketplace
```

설치 후 Claude Code에서 `/nova:next`를 입력하면 바로 시작됩니다.

---

## 수동 개발 vs Nova

| | 수동 개발 | Nova |
|---|---|---|
| **설계 판단** | AI 하나한테 물어보고 진행 | `/nova:xv`로 3개 AI 다관점 수집, 합의 수준 자동 분석 |
| **기획 → 구현** | 머릿속 → 바로 코딩 | 복잡도 자동 판단 → Plan → Design → 구현 (CPS 구조) |
| **코드 검증** | 같은 AI가 구현하고 평가 | **독립 Evaluator 에이전트**가 적대적 검증 (자기 평가 편향 차단) |
| **설계-코드 일치** | 수동 대조 또는 안 함 | `/nova:gap`으로 자동 갭 탐지 + Sprint Contract 기반 검증 |
| **세션 연속성** | 세션 끊기면 맥락 증발 | CLAUDE.md + Handoff Artifact + git으로 영속 복원 |
| **코드 리뷰** | 감에 의존 | 독립 에이전트의 적대적 리뷰 |
| **방법론 적용** | 커맨드를 외워야 함 | **플러그인 설치만으로 자동 적용** — 커맨드 몰라도 작동 |

---

## 왜 재작업이 사라지는가

AI 코딩 도구는 **타이핑 속도**를 높여줬다. 하지만 진짜 병목은 거기에 없다.

**재작업의 근본 원인은 속도가 아니라 판단이다.** 잘못된 판단은 복리로 비용이 쌓인다. 1주차의 잘못된 결정이 4주차에 10배의 재작업으로 돌아온다.

Nova는 8가지 자산으로 개발 과정의 핵심 병목을 제거한다.

| 자산 | 제거하는 병목 | 결과 |
|------|-------------|------|
| **Harness Architecture** | "AI가 자기 코드를 자기가 평가" | Generator-Evaluator 분리로 자기 평가 편향 구조적 차단 |
| **3단계 평가 레이어** | "코드를 읽고 괜찮아 보이면 PASS" | 정적분석 → 의미론적 분석 → 실행 검증 순차 수행 |
| **CPS 문서 체계** | "뭘 만들지 합의 안 됨" | 기획-설계-구현이 하나의 구조로 연결 |
| **다관점 수집 (`/nova:xv`)** | "AI 한 마리 말만 믿음" | 3개 AI 합의로 잘못된 판단 사전 차단 |
| **역방향 검증 (`/nova:gap`)** | "설계와 코드가 따로 놂" | 적대적 Evaluator가 갭 탐지, Sprint Contract 기반 검증 |
| **컨텍스트 체인** | "세션 끊기면 맥락 증발" | CLAUDE.md + Handoff Artifact + git으로 영속 복원 |
| **Hooks + Skills** | "중요한 규칙이 무시됨" | Hooks로 필수 규칙 100% 보장, Skills로 온디맨드 전문 지식 |
| **적응형 규칙** | "규칙이 낡아서 무시됨" | 프로젝트와 함께 진화하는 살아있는 규칙 |

## 철학

Nova는 세 가지 원칙 위에 서 있다.

**일관성** -- 누가 작업하든, 어떤 AI를 쓰든 같은 품질이 나온다. 구조가 품질을 만든다.

**생산성** -- 재작업을 제거하는 것이 가장 빠른 길이다. 처음부터 제대로 만들면 두 번 만들 필요가 없다.

**혁신 흡수** -- 규칙은 고정이 아니다. 좋은 패턴이 발견되면 제안하고, 검증하고, 흡수한다.

```
N — New Standards  : AI 개발의 새로운 기준을 세운다
O — Orchestrated   : 멀티 에이전트를 체계적으로 조율한다
V — Verified       : 독립 검증으로 품질을 보장한다
A — Adaptive       : 규칙이 프로젝트와 함께 진화한다
```

## 빠른 시작

### 1. 설치

```bash
# 1. Nova 마켓플레이스 등록
claude plugin marketplace add TeamSPWK/nova

# 2. 플러그인 설치 — 12개 커맨드 + 5개 에이전트 + 5개 스킬 자동 활성화
claude plugin install nova@nova-marketplace
```

### 2. 시작

```bash
/nova:next   # 다음 할 일 확인 — 여기서부터 시작
```

### 3. API 키 설정 (다관점 수집용, 선택)

```bash
cat > .env << 'EOF'
ANTHROPIC_API_KEY="your-key"
OPENAI_API_KEY="your-key"
GEMINI_API_KEY="your-key"
EOF
```

> `/nova:xv`(다관점 수집)만 API 키가 필요합니다. 나머지 커맨드는 모두 API 키 없이 동작합니다.

### 업데이트 & 삭제

```bash
# 업데이트
claude plugin update nova@nova-marketplace

# 삭제
claude plugin uninstall nova@nova-marketplace
claude plugin marketplace remove nova-marketplace
```

## 커맨드

모든 커맨드는 `nova:` 접두사로 사용합니다.

| 커맨드 | 설명 | 사용 시점 |
|--------|------|----------|
| `/nova:next` | 다음 할 일 자동 추천 | 뭘 해야 할지 모를 때 |
| `/nova:init 프로젝트명` | 프로젝트에 Nova 초기 설정 | 신규 프로젝트 시작 시 |
| `/nova:plan 기능명` | CPS Plan 문서 작성 | 새 기능 기획 시 |
| `/nova:xv "질문"` | 멀티 AI 다관점 수집 (Claude+GPT+Gemini) | 설계 판단, 아키텍처 선택 |
| `/nova:design 기능명` | CPS Design 문서 작성 | Plan 이후 기술 설계 시 |
| `/nova:gap 설계.md 코드/` | 설계↔구현 역방향 검증 | 구현 완료 후 누락 확인 |
| `/nova:review 코드` | 단순성 원칙 코드 리뷰 | 코드 품질 점검 |
| `/nova:propose 패턴` | 규칙 제안 (Adaptive) | 반복 패턴 발견 시 |
| `/nova:metrics` | Nova 도입 수준 자동 측정 | 정기 평가, 현황 파악 |
| `/nova:auto 기능명` | Plan→구현→검증 자율 실행 (Autopilot) | 기능 단위 자동 개발 |
| `/nova:team 프리셋` | Agent Teams 병렬 구성 | 팀 단위 리뷰, QA, 디버깅 |
| `/nova:nova-update` | Nova 최신 버전으로 업데이트 | 새 버전 출시 시 |

> **커맨드 없이도 작동합니다.** Nova을 설치한 프로젝트에서는 CLAUDE.md의 자동 적용 규칙에 따라
> 일상 대화만으로도 복잡도 판단 → 구현 → 독립 검증이 자동 실행됩니다. 커맨드는 상세 절차가 필요할 때의 숏컷입니다.

## 에이전트

특화된 관점이 필요할 때, 전문 에이전트를 호출한다.

| 에이전트 | 전문 영역 |
|----------|----------|
| `architect` | 시스템 아키텍처 설계, 기술 선택, 확장성/유지보수성 검토 |
| `senior-dev` | 코드 품질 개선, 리팩토링, 기술 부채 식별 |
| `qa-engineer` | 테스트 전략, 엣지 케이스 식별, 품질 검증 |
| `security-engineer` | 보안 취약점 점검, 위협 모델링, 인증/인가 검토 |
| `devops-engineer` | CI/CD 파이프라인, 인프라 설정, 배포 전략 |

## Agent Teams

`/nova:team` 커맨드로 목적별 에이전트 팀을 병렬 구성한다. tmux 사이드 패널에 팀원 활동이 표시된다.

| 프리셋 | 팀 구성 | 사용 시점 |
|--------|---------|----------|
| `/nova:team qa` | 테스터 + 엣지케이스 + 회귀분석 | PR 전 품질 검증 |
| `/nova:team visual-qa` | 스크린샷 + 인터랙션 + 접근성 | UI/UX 시각적 검증 |
| `/nova:team review` | 아키텍트 + 보안 + 성능 | 코드 리뷰 |
| `/nova:team design` | API설계 + 도메인모델 + DX | 신규 기능 설계 |
| `/nova:team refactor` | 클린코드 + 의존성 + 테스트 | 기술부채 해소 |
| `/nova:team debug` | 근본원인 + 로그분석 + 수정 | 프로덕션 이슈 |

> Agent Teams는 실험적 기능입니다. 활성화: `.claude/settings.json`에 `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` 추가

## 워크플로우

```
/nova:next ─── 뭘 해야 하지?
  │
  ├── 수동 모드 (단계별 제어)               자동 모드 (한 번 승인)
  │                                         │
  ▼                                         ▼
/nova:plan ─── 기능 기획 (CPS)           /nova:auto ─── 계획 승인 한 번이면 끝
  │                                         │
  ├── /nova:xv ─── 다관점 수집               ├── Plan 자동 생성 (Planner)
  │                                         ├── Design 자동 생성 (Planner)
  ▼                                         ├── 승인 요청 ← 유일한 개입
/nova:design ─ 기술 설계 (CPS)              ├── 구현 (Generator 서브에이전트)
  │                                         ├── 검증 (Evaluator 독립 에이전트)
  ▼                                         ├── Independent Verifier
  구현                                       ▼
  │                                         완료 보고
  ├── /nova:gap ──── 설계 vs 구현 갭 검증
  ├── /nova:review ─ 코드 리뷰
  │
  ▼
  완료
  │
  └── 패턴 발견 → /nova:propose → 승인 → 규칙 진화
```

![X-Verification 데모](assets/xv-demo.gif)
![Gap Check 데모](assets/gap-demo.gif)

## 문서

| 문서 | 설명 |
|------|------|
| **[사용법 가이드](docs/usage-guide.md)** | 커맨드, 에이전트 상세 사용법 |
| **[Todo API 튜토리얼](examples/tutorial-todo-api.md)** | Plan - Design - 구현 - Gap 전체 워크플로우 체험 |
| **[방법론 상세](docs/nova-engineering.md)** | Nova 4 Pillars, CPS, MECE, 보안 체계 |

## 파일 구조

```
nova/
├── .claude-plugin/
│   ├── plugin.json             # 플러그인 메타데이터
│   └── marketplace.json        # 마켓플레이스 매니페스트
├── commands/                   # 슬래시 커맨드 (→ .claude/commands/ symlink)
│   ├── next.md                 #   /nova:next — 다음 할 일 추천
│   ├── init.md                 #   /nova:init — 프로젝트 초기 설정
│   ├── plan.md                 #   /nova:plan — CPS Plan 작성
│   ├── xv.md                   #   /nova:xv — 멀티 AI 다관점 수집
│   ├── design.md               #   /nova:design — CPS Design 작성
│   ├── gap.md                  #   /nova:gap — 역방향 검증
│   ├── review.md               #   /nova:review — 코드 리뷰
│   ├── propose.md              #   /nova:propose — 규칙 제안
│   ├── metrics.md              #   /nova:metrics — 도입 수준 측정
│   ├── team.md                 #   /nova:team — Agent Teams 병렬 구성
│   └── auto.md                 #   /nova:auto — Autopilot 자율 실행
├── agents/                     # 전문 에이전트 (→ .claude/agents/ symlink)
│   ├── architect.md
│   ├── senior-dev.md
│   ├── qa-engineer.md
│   ├── security-engineer.md
│   └── devops-engineer.md
├── skills/                     # 온디맨드 스킬 (→ .claude/skills/ symlink)
│   ├── nova-evaluator/         #   3단계 평가 레이어
│   ├── nova-context-engine/    #   코드베이스 맥락 관리
│   ├── nova-context-chain/     #   세션 간 맥락 연속성
│   ├── nova-jury/              #   다중 관점 평가
│   └── nova-mutation-test/     #   뮤턴트 기반 테스트 강화
├── docs/
│   ├── usage-guide.md          # 사용법 가이드
│   ├── nova-engineering.md     # 방법론 상세
│   ├── context-chain.md        # 컨텍스트 유지 체계
│   ├── eval-checklist.md       # 도입 수준 자가 평가
│   ├── rules-changelog.md      # 규칙 변경 이력
│   ├── proposals/              # 규칙 제안서
│   ├── decisions/              # 의사결정 기록 (ADR)
│   ├── verifications/          # 다관점 수집 결과
│   └── templates/              # 문서 템플릿
├── tests/
│   └── test-scripts.sh         # 테스트
└── examples/                   # 사용 예시 + 튜토리얼
    ├── tutorial-todo-api.md
    ├── sample-plan.md
    ├── sample-design.md
    ├── sample-decision.md
    └── sample-xv-result.md
```

## 치트시트

### 설치 & 업데이트

```bash
# 설치
claude plugin marketplace add TeamSPWK/nova
claude plugin install nova@nova-marketplace

# 업데이트
claude plugin update nova@nova-marketplace

# 삭제
claude plugin uninstall nova@nova-marketplace
```

### 커맨드 요약

```bash
/nova:next                              # 다음 할 일 추천
/nova:plan 기능명                        # CPS Plan 작성
/nova:xv "질문"                          # 멀티 AI 다관점 수집
/nova:design 기능명                      # CPS Design 작성
/nova:gap docs/designs/x.md src/        # 설계↔구현 갭 검증
/nova:review src/                       # 코드 리뷰
/nova:propose 패턴명                     # 규칙 제안
/nova:metrics                           # Nova 도입 수준 측정
/nova:init 프로젝트명                    # 프로젝트 초기 설정
/nova:team qa src/                      # Agent Teams 품질 검증
/nova:team review src/                  # Agent Teams 코드 리뷰
/nova:auto 회원가입                      # Autopilot 자율 실행
/nova:auto --fast 회원가입               # 1단계 승인으로 빠르게
/nova:auto --careful 결제 시스템          # 2단계 승인으로 신중하게
```

### 워크플로우

```
수동: 기능 요청 → /nova:plan → /nova:xv(필요시) → /nova:design → 구현 → /nova:gap → /nova:review → /nova:propose(패턴 발견시)
                                                                          └── /nova:team(병렬 리뷰/QA 필요시)
자동: 기능 요청 → /nova:auto → [승인] → 자율 실행(plan→design→구현→gap→review) → 완료 보고
```

## 요구사항

- [Claude Code](https://claude.ai/code) CLI
- API 키: OpenAI + Google AI Studio (다관점 수집 `/nova:xv` 사용 시, 선택)

## 자주 묻는 질문

<details>
<summary><b>팀원 전체가 써야 하나요?</b></summary>

아닙니다. 한 사람만 써도 효과가 있습니다. 팀 전체 도입 시에는 CLAUDE.md에 Nova 섹션을 커밋하면 됩니다.
</details>

<details>
<summary><b>Cursor, Windsurf 등 다른 AI 도구와 함께 쓸 수 있나요?</b></summary>

네. Nova는 Claude Code 플러그인으로 설치되므로 다른 도구와 충돌하지 않습니다. 다관점 수집(`/nova:xv`)은 오히려 다른 도구와 병행하면 효과적입니다.
</details>

<details>
<summary><b>API 키 없이도 쓸 수 있나요?</b></summary>

네. `/nova:xv`(다관점 수집)만 API 키가 필요합니다. 나머지 커맨드는 모두 API 키 없이 동작합니다.
</details>

<details>
<summary><b>이전 스크립트 설치(install.sh) 잔해를 정리하고 싶어요</b></summary>

v2.0.0부터 플러그인 설치로 전환되었습니다. 이전 스크립트 설치 잔해를 정리하려면:

```bash
# 프로젝트 디렉토리에서 실행
rm -rf .claude/commands/next.md .claude/commands/plan.md .claude/commands/review.md \
       .claude/commands/xv.md .claude/commands/design.md .claude/commands/gap.md \
       .claude/commands/propose.md .claude/commands/metrics.md .claude/commands/init.md \
       .claude/commands/team.md .claude/commands/auto.md .claude/commands/nova-update.md \
       .claude/agents/architect.md .claude/agents/senior-dev.md \
       .claude/agents/qa-engineer.md .claude/agents/security-engineer.md \
       .claude/agents/devops-engineer.md \
       .claude/skills/nova-evaluator .claude/skills/nova-context-chain \
       .claude/skills/nova-context-engine .claude/skills/nova-jury \
       .claude/skills/nova-mutation-test \
       scripts/.nova-version scripts/x-verify.sh scripts/gap-check.sh \
       scripts/init.sh scripts/lib
```

빈 디렉토리가 남았다면 `rmdir`로 정리하세요.
</details>

## 라이선스

MIT

---

도움이 되셨다면 [GitHub Star](https://github.com/TeamSPWK/nova)를 눌러주세요. 피드백과 기여는 언제나 환영합니다.

Spacewalk Engineering
