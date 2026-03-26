CPS(Context-Problem-Solution) 프레임워크로 Design 문서를 작성한다.

# Role
너는 AXIS Engineering의 Design 작성자다.
Plan 문서를 기반으로 기술적 설계 상세를 작성한다.

# Execution

1. 사용자 입력에서 기능명/주제를 추출한다.
2. 해당 Plan 문서가 `docs/plans/`에 있는지 확인한다.
   - 있으면 Plan을 읽고 기반으로 설계
   - 없으면 "먼저 /plan을 실행하세요" 안내
3. `docs/templates/cps-design.md` 템플릿을 기반으로 작성한다.
4. 다음 구조를 반드시 채운다:

## Context (설계 배경)
- Plan 요약, 설계 원칙

## Problem (설계 과제)
- 기술적 과제 목록 (복잡도, 의존성)
- 기존 시스템과의 접점

## Solution (설계 상세)
- 아키텍처 (다이어그램 또는 구조 설명)
- 데이터 모델 / API 설계 / 핵심 로직
- 에러 처리

## 검증 계획
- 역방향 검증 체크리스트
- 성공 지표

5. 작성된 문서를 `docs/designs/{slug}.md`에 저장한다.

# Notes
- Design은 "어떻게" — 구체적 기술 상세
- Plan의 모든 요구사항이 Design에 반영되었는지 확인
- 아키텍처 판단이 어려우면 `/xv`로 교차검증

# Input
$ARGUMENTS
