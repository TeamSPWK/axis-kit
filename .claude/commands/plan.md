---
description: "CPS(Context-Problem-Solution) 프레임워크로 Plan 문서를 작성한다."
---

CPS(Context-Problem-Solution) 프레임워크로 Plan 문서를 작성한다.

# Role
너는 Nova Engineering의 Plan 작성자다.
사용자의 요구사항을 CPS 구조로 분석하고 구조화된 Plan 문서를 생성한다.

# Execution

0. (버전 체크) `scripts/.nova-version` 파일이 있으면 `curl -fsSL --max-time 3 https://raw.githubusercontent.com/TeamSPWK/nova/main/scripts/.nova-version 2>/dev/null`로 최신 버전을 확인한다. 버전이 다르면 출력 마지막에 한 줄 안내한다: `🔄 Nova 업데이트 가능 (현재 → 최신) — curl -fsSL .../install.sh | bash -s -- --update`. 실패 시 조용히 건너뛴다.

1. 사용자 입력에서 기능명/주제를 추출한다.
2. `docs/templates/cps-plan.md` 템플릿을 기반으로 작성한다.
3. 다음 구조를 반드시 채운다:

## Context (배경)
- 현재 상태와 왜 필요한지

## Problem (문제 정의)
- 핵심 문제 한 문장 요약
- MECE로 분해 (겹침 없이, 빠짐 없이)
- 제약 조건

## Solution (해결 방안)
- 선택한 방안과 대안 비교
- 구현 범위 (체크리스트)
- 검증 기준

## Sprints (스프린트 분할)

예상 수정 파일이 4개 이상이면 독립 검증 가능한 스프린트로 분할한다:

| Sprint | 기능 단위 | 예상 파일 | 의존성 | Done 조건 |
|--------|----------|----------|--------|----------|
| 1 | {기능A} | {파일 목록} | 없음 | {검증 가능한 완료 기준} |
| 2 | {기능B} | {파일 목록} | Sprint 1 | {검증 가능한 완료 기준} |

- 각 스프린트는 독립적으로 검증 가능해야 한다
- 의존성이 있으면 의존 순서대로 배치
- Done 조건은 Evaluator가 검증할 수 있는 구체적 기준

예상 수정 파일이 3개 이하면 스프린트 분할 없이 단일 구현으로 진행한다.

4. 작성된 문서를 `docs/plans/{slug}.md`에 저장한다.
5. 교차검증이 필요한 설계 판단이 있으면 `/xv` 사용을 제안한다.
6. Plan 헤더의 `Design:` 필드는 비워둔다. `/design` 실행 시 자동으로 채워진다.

# Notes
- Plan은 "무엇을, 왜" — Design은 "어떻게"
- Plan 없이 바로 코딩하지 않는다
- 간단한 버그 수정에는 불필요 (기능 추가/변경에 사용)
- 스프린트의 Done 조건은 이후 Sprint Contract의 기초가 된다

# Input
$ARGUMENTS
