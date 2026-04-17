# Evolution Proposal: Opus 4.7 출시 + Claude Code 2.1.111 대응

> 날짜: 2026-04-17
> 스캔 소스: Anthropic 공식, Claude Code 생태계
> 트리거: 사용자 힌트 "Opus 4.7이 나온것 같네?"

---

## 상태 (2026-04-17 오후 갱신)

| # | 항목 | 상태 | 반영 버전 |
|---|------|------|----------|
| P-1 | Opus 모델 ID 업데이트 | ✅ 반영 완료 | v5.2.3 (ac98dc6) |
| P-2 | Evaluator self-verification 문구 | ✅ 반영 완료 | v5.2.3 (ac98dc6) |
| Sprint 1 | Self-verify 핸드오프 필드 (P-2 후속) | ✅ 반영 완료 | v5.3.0 (252d133) |
| Sprint 1 갭 보완 | 누락 에이전트 3종 + 관측 장치 + Ultra 포지셔닝 | ✅ 반영 완료 | v5.3.1 (본 커밋) |
| M-1 | `xhigh` effort level | ⏸ 보류 | Claude CLI 레벨 기능. Nova 스크립트 관여 여지 적어 별도 스프린트에서 재검토 |
| M-2 | `/ultrareview` 포지셔닝 문서화 | ✅ 반영 완료 | v5.3.1 — `commands/review.md` + `commands/plan.md`에 Related 섹션. 체인 통합 X, 보완재 |
| Major-1 | `/less-permission-prompts` 유사 스킬 | ❌ 도입 안 함 (옵션 A 확정) | Nova §10 "설정 파일 직접 수정 금지" 원칙 우선. Claude Code 기본 스킬로 위임 |

---

## Scan Summary

| # | 항목 | 수준 | 자율 등급 | 출처 |
|---|------|------|----------|------|
| 1 | Opus 모델 ID → `claude-opus-4-7` 업데이트 | patch | Full Auto | [Anthropic](https://www.anthropic.com/news/claude-opus-4-7) |
| 2 | Evaluator 스킬 — self-verification 능력 활용 문구 | patch | Full Auto | [Anthropic](https://www.anthropic.com/news/claude-opus-4-7) |
| 3 | `xhigh` effort level 옵션 지원 | minor | Semi Auto (PR) | [Claude Code CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) |
| 4 | `/ultrareview` vs `/nova:review` 포지셔닝 문서화 | minor | Semi Auto (PR) | [Claude Code CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) |
| 5 | `/less-permission-prompts` 유사 스킬 검토 | major | Manual | [Claude Code CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) |

---

## [P-1] Opus 모델 ID 업데이트 — patch

### 발견
- **Claude Opus 4.7** 2026-04-16 일반 출시. Opus 4.6 대비 코딩·비전·self-verification 개선.
- 가격 동일 ($5/$25 per M tokens), 모델 ID: `claude-opus-4-7`.
- Claude Code v2.1.111부터 `xhigh` effort level 추가 (high↔max 중간).

### Nova 적용 방안
하드코딩된 기본 Opus 모델 ID를 `claude-opus-4-6` → `claude-opus-4-7`로 교체.

### 영향 범위
- `scripts/x-verify.sh:76` — `CLAUDE_MODEL_OPUS:-claude-opus-4-6`
- `.claude/commands/ask.md:35` — 예시 `CLAUDE_MODEL_OPUS=claude-opus-4-6`
- `mcp-server/src/tools/x-verify.ts:392` — `opus: envVars.CLAUDE_MODEL_OPUS ?? "claude-opus-4-6"`
- `mcp-server/` 재빌드 필요 (`cd mcp-server && pnpm build`)

### 리스크
- 환경변수 `CLAUDE_MODEL_OPUS`로 오버라이드 가능하므로 하위호환 유지. 리스크 낮음.
- mcp-server dist 재빌드 누락 시 구 모델로 동작 → **커밋 전 반드시 build 확인**.

---

## [P-2] Evaluator 스킬 — self-verification 언급 — patch

### 발견
Opus 4.7 출시문: *"devises ways to verify its own outputs before reporting back"*. Nova의 Generator-Evaluator 분리 철학과 정합.

### Nova 적용 방안
`skills/evaluator/SKILL.md`에 "Opus 4.7의 self-verification 특성을 활용하되, 독립 서브에이전트 실행을 우회하지 않는다" 문구 추가. (철학 훼손 방지)

### 영향 범위
- `.claude/skills/evaluator/SKILL.md` — 검증 절차 설명 보완 (1~2줄)

### 리스크
- 본문 과도 확장 위험. 1~2줄로 제한.

---

## [M-1] xhigh effort level 지원 — minor

### 발견
Claude Code v2.1.111에서 `xhigh` effort level 도입. `/effort`, `--effort` 플래그로 설정.

### Nova 적용 방안
`/nova:review --strict`, `/nova:evaluator`, `/nova:jury`처럼 **최고 엄격도가 필요한 커맨드**에서 환경변수 `CLAUDE_MODEL_OPUS_EFFORT=xhigh`를 권장.

문서 업데이트:
- `commands/review.md` — `--strict` 설명에 "xhigh effort 사용 시 CLAUDE_MODEL_OPUS_EFFORT=xhigh 설정 권장"
- `commands/ask.md` — 환경변수 목록에 `CLAUDE_MODEL_OPUS_EFFORT` 추가

### 영향 범위
- `.claude/commands/review.md`
- `.claude/commands/ask.md`
- `scripts/x-verify.sh` (선택: `--effort` 플래그 전달)

### 리스크
- Opus 이외 모델은 자동 fallback → 에러 없음.
- 환경변수 오타 시 사일런트 무시 가능 → 문서에 명시.

---

## [M-2] `/ultrareview` vs `/nova:review` 포지셔닝 — minor

### 발견
Claude Code v2.1.111에 `/ultrareview` 추가 — 클라우드 기반 **병렬 multi-agent** code review. Nova의 `/nova:review`와 컨셉이 유사하여 사용자 혼란 가능.

### Nova 적용 방안
`docs/nova-rules.md` 또는 `commands/review.md`에 차별점 명시:

| 구분 | `/ultrareview` | `/nova:review` |
|------|---------------|---------------|
| 실행 위치 | 클라우드 병렬 | 로컬 서브에이전트 |
| 패러다임 | 다중 에이전트 비평 | Generator-Evaluator 분리 + 적대적 검증 |
| 통합 | 독립 실행 | Nova Quality Gate 체인 (test → review → commit) |
| 출력 | 이슈 목록 | PASS/CONCERNS/FAIL + 증거 기반 |

**두 커맨드는 대체재가 아닌 보완재**. `/nova:review` 통과 후 대형 PR 전 `/ultrareview` 병용 권장.

### 영향 범위
- `.claude/commands/review.md` — "Related" 섹션 추가
- `docs/nova-rules.md` — §5 검증 경량화 부분 보강

### 리스크
- 없음 (문서 변경).

---

## [Major-1] `/less-permission-prompts` 유사 스킬 — major (Manual)

### 발견
Claude Code v2.1.111에 `/less-permission-prompts` 스킬 추가 — transcript 스캔으로 read-only Bash/MCP 호출 패턴을 찾아 `.claude/settings.json` allowlist 자동 제안.

### Nova 적용 방안 (사용자 결정 대기)

**옵션 A — 도입 안 함**: Claude Code 기본 스킬에 위임. Nova는 "설정 파일 직접 수정 금지" 원칙 유지.

**옵션 B — Nova 전용 스킬**: `/nova:permission-tune` — Nova 커맨드 실행 transcript만 분석해 Nova 관련 도구의 allowlist를 제안. Nova의 Always-On 동작(Evaluator, review 자동 실행 등)에 특화.

### 영향 범위 (옵션 B 선택 시)
- `.claude/skills/permission-tune/SKILL.md` 신규
- `hooks/session-start.sh` 커맨드 목록
- `tests/test-scripts.sh` EXPECTED_COMMANDS

### 리스크
- 옵션 B: Nova §10 환경 안전 규칙("설정 파일 직접 수정 금지")과 충돌. **제안 방식**으로 한정하여 사용자 승인 필수.
- Claude Code 기본 스킬과 중복 개발 우려.

### 권장
**옵션 A (도입 안 함)** — Nova 철학(설정 수정 금지)과 정합성 우선. Claude Code 기본 스킬로 위임.

---

## 차기 단계

1. **자동 적용 가능 (P-1, P-2, M-1, M-2)**: `/nova:evolve --apply`로 구현 + 품질 게이트
2. **사용자 결정 필요 (Major-1)**: 옵션 A/B 선택

권장 순서:
```
/nova:evolve --apply   # P-1, P-2 자동 커밋 + 버전 범프
# M-1, M-2는 PR로 분리 생성
# Major-1은 사용자 판단
```
