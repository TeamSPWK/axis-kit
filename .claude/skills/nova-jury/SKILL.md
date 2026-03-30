---
name: nova-jury
description: Nova LLM Jury — 다중 관점 평가로 단일 Evaluator의 편향을 보정하고 판단 품질을 자동 개선
---

# Nova LLM Jury

> 단일 LLM 심판은 위치 편향(position bias)과 장황함 편향(verbosity bias)이 있다.
> 다중 관점으로 평가하면 이 편향을 구조적으로 상쇄할 수 있다.

## Multi-Perspective Evaluation

### Jury 구성 (3인)
각 Jury 멤버는 독립 서브에이전트로, 서로 다른 관점에서 평가한다:

**Jury 1 — Correctness Judge (정확성 심판)**
- 코드가 요구사항대로 동작하는가?
- 테스트가 통과하는가?
- 엣지 케이스에서 깨지지 않는가?

**Jury 2 — Design Judge (설계 심판)**
- 아키텍처 원칙을 따르는가?
- 기존 코드와 일관되는가?
- 유지보수하기 쉬운 구조인가?

**Jury 3 — User Judge (사용자 심판)**
- 사용자가 3분 내에 문제 없이 쓸 수 있는가?
- 에러 메시지가 이해 가능한가?
- 문서가 충분한가?

### 합의 프로토콜
각 Jury가 독립적으로 판정(PASS/CONDITIONAL/FAIL)을 내린 후:

| Jury 합의 | 최종 판정 | 행동 |
|-----------|----------|------|
| 3/3 PASS | **PASS** | 통과 |
| 2/3 PASS + 1 CONDITIONAL | **PASS with notes** | 통과, 소수 의견 기록 |
| 2/3 PASS + 1 FAIL | **CONDITIONAL** | 소수 의견의 FAIL 사유 검토 필요 |
| 2/3 CONDITIONAL | **CONDITIONAL** | 이슈 목록 종합 |
| 2/3 FAIL | **FAIL** | 실패, 버그 리포트 생성 |
| 3/3 FAIL | **HARD FAIL** | 즉시 중단 |

### 소수 의견 기록
합의와 다른 판정을 낸 Jury의 의견은 반드시 기록한다:
```
━━━ Jury Verdict ━━━━━━━━━━━━━━━━━━━━━━━━━━
  최종 판정: CONDITIONAL PASS

  Correctness Judge: PASS
  Design Judge: CONDITIONAL — "서비스 레이어가 Controller에 직접 결합"
  User Judge: PASS

  소수 의견 (Design Judge):
  - 서비스 레이어 분리 권장
  - 현재 동작에는 영향 없으나 확장 시 문제 가능
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Evaluator Feedback Loop (RLAIF)

> Evaluator의 판단 품질을 시간이 지남에 따라 자동 개선한다.

### 피드백 수집
1. Evaluator가 FAIL 판정 → Generator 수정 → 재검증 PASS
   → **유효한 FAIL**: Evaluator가 실제 문제를 발견함 ✅
2. Evaluator가 FAIL 판정 → 사용자가 "이건 문제 아님"으로 오버라이드
   → **False Positive**: Evaluator가 과민 반응함 ⚠️
3. Evaluator가 PASS 판정 → 이후 사용자가 버그 발견
   → **False Negative**: Evaluator가 놓침 ❌

### 피드백 저장
`docs/eval-feedback.md`에 누적 기록:
```markdown
| 날짜 | 유형 | Evaluator 판정 | 실제 결과 | 학습 포인트 |
|------|------|---------------|----------|-----------|
| 2026-03-30 | False Positive | FAIL | 정상 | 타입 경고를 에러로 오판 |
| 2026-03-30 | Valid FAIL | FAIL | 실제 버그 | DB 커넥션 누수 정확히 탐지 |
```

### 피드백 적용
- `/review`, `/gap` 실행 시 `docs/eval-feedback.md`를 참조
- False Positive 패턴이 반복되면 Evaluator 프롬프트에 "다음은 과민 반응하지 마라" 컨텍스트 추가
- False Negative 패턴이 반복되면 "다음은 특히 주의하라" 컨텍스트 추가
- **Adaptive Evaluator**: 프로젝트별로 Evaluator가 학습하여 정밀도 향상

## 적용 시점
- `/auto --careful`: Jury 시스템 전체 활성화
- `/auto` (기본): 단일 Evaluator (현재와 동일)
- `/review --jury`: 코드 리뷰 시 Jury 활성화
- Feedback Loop: 모든 Evaluator 실행 시 자동 수집
