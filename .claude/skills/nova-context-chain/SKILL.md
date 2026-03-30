---
name: nova-context-chain
description: Nova Context Chain — 세션 간 맥락 연속성 보장
---

# Nova Context Chain

세션이 끊겨도 작업 맥락이 유지되도록 한다.

## Handoff Artifact 작성 규칙
- 현재 스프린트 상태, 완료/미완료 항목
- 다음 세션에서 바로 이어갈 수 있는 수준의 상세도
- `docs/auto-handoff.md`에 저장

## Context Reset 전략
- 스프린트 간 새 서브에이전트로 컨텍스트 오염 방지
- Handoff Artifact + Design 문서로 상태 복원
