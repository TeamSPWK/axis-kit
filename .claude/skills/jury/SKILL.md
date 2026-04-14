---
name: jury
description: Nova LLM Jury — 다중 관점 평가로 단일 Evaluator의 편향을 보정
user-invocable: false
---

# Nova LLM Jury

> 단일 LLM 심판은 위치 편향(position bias)과 장황함 편향(verbosity bias)이 있다.
> 다중 관점으로 평가하면 이 편향을 구조적으로 상쇄할 수 있다.

## 사용법

`/nova:review --jury` 옵션으로 활성화한다.

## Jury 구성 (3인)

각 Jury는 독립 서브에이전트로 실행한다:

| Jury | 관점 | 핵심 질문 |
|------|------|----------|
| **Correctness** | 정확성 | 코드가 요구사항대로 동작하는가? |
| **Design** | 설계 | 아키텍처 원칙과 일관되는가? |
| **User** | 사용자 | 사용자가 문제 없이 쓸 수 있는가? |

## 합의 프로토콜

| Jury 합의 | 최종 판정 |
|-----------|----------|
| 3/3 PASS | **PASS** |
| 2/3 PASS + 1 CONDITIONAL | **PASS with notes** — 소수 의견 기록 |
| 2/3 PASS + 1 FAIL | **CONDITIONAL** — FAIL 사유 검토 필요 |
| 2/3 FAIL 이상 | **FAIL** |

합의와 다른 판정을 낸 Jury의 의견은 반드시 기록한다.
