---
name: nova-context-engine
description: Nova Context Engine — 코드베이스 맥락을 효율적으로 관리하여 에이전트 품질을 극대화
---

# Nova Context Engine

> "Prompt Engineering → Context Engineering으로 패러다임이 전환되었다." — Andrej Karpathy
> 에이전트의 품질은 모델이 아니라 맥락의 질이 결정한다.

## 5가지 전략

### 1. Selection (선택)
작업에 관련된 파일만 정확히 선택한다:
- `git diff`로 변경된 파일 목록 추출
- import/require 의존성 그래프 추적 (1-hop)
- Design 문서에서 명시된 파일 경로
- **제외**: 테스트 파일, 설정 파일, 빌드 아티팩트 (검증 단계 제외)

### 2. Compression (압축)
선택된 파일의 맥락을 압축한다:
- 함수 시그니처 + JSDoc만 추출 (구현 본문 생략)
- 타입 정의 파일 우선 (`.d.ts`, 인터페이스)
- 관련 테스트의 describe/it 블록만 추출 (테스트 본문 생략)
- 최대 토큰 예산: 전체 컨텍스트의 30% 이하

### 3. Ordering (순서)
맥락을 중요도 순으로 배치한다:
1. Sprint Contract / Done 조건 (가장 먼저)
2. Design 문서 핵심 섹션
3. 변경된 파일의 타입/인터페이스
4. 변경된 파일의 구현 코드
5. 의존성 파일의 시그니처
6. 관련 테스트 구조

### 4. Isolation (격리)
에이전트별로 필요한 맥락만 전달한다:
- **Generator**: Design + 기존 코드 + 의존성 = 구현에 집중
- **Evaluator**: Sprint Contract + 구현 결과 + 테스트 = 검증에 집중
- **Verifier**: Plan + Design + 최종 코드 = 종합 판단에 집중

### 5. Format Optimization (포맷)
맥락 전달 포맷을 최적화한다:
- 정적 콘텐츠(시스템 프롬프트, 도구 정의)를 먼저 배치 → 프롬프트 캐싱 활용
- 코드 블록에 언어 태그 + 파일 경로 주석
- 변경 부분에 `// CHANGED` 마커로 주의 유도

## Evaluator 맥락 전달 템플릿

Evaluator 서브에이전트에게 전달할 맥락 구성:

```
[1] Sprint Contract (Done 조건)
{Sprint Contract 내용}

[2] Design 핵심 (데이터 계약)
{API 스키마, 데이터 모델}

[3] 구현 결과 (변경 파일)
{git diff 또는 전체 파일}

[4] 테스트 구조
{테스트 파일의 describe/it 블록}

[5] 의존성 시그니처
{import된 모듈의 타입/인터페이스}
```

## 적용 시점
- `/auto` Phase 4-7에서 서브에이전트 생성 시 자동 적용
- Generator/Evaluator/Verifier 각각에 최적화된 맥락 전달
- 수동 호출 시: 코드베이스 요약 생성
