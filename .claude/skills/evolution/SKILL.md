---
name: evolution
description: "Nova Self-Evolution 엔진 — 기술 동향 스캔, 관련성 필터, 자율 범위 구현까지 전체 파이프라인"
---

# Nova Self-Evolution Pipeline

`/nova:evolve` 커맨드의 핵심 파이프라인을 정의한다.

## Pipeline Overview

```
Scanner → Filter → Proposal → [Builder → Gate Chain → Merge]
                                        (--apply/--auto만)
```

## Scanner 소스 상세

### Anthropic 공식 (최고 우선순위)

검색 키워드:
- `site:docs.anthropic.com Claude Code`
- `site:anthropic.com/blog`
- `Claude Code changelog latest`
- `Claude Code hooks MCP update`

체크 포인트:
- Claude Code 새 버전/기능
- MCP 프로토콜 변경
- hooks API 변경
- 새로운 도구/권한 모델
- 플러그인 시스템 변경

### Claude Code 생태계

검색 키워드:
- `Claude Code plugin community`
- `CLAUDE.md best practices 2026`
- `Claude Code custom agents`

체크 포인트:
- 인기 있는 플러그인 패턴
- CLAUDE.md 작성 최신 권장사항
- 에이전트 설계 패턴

### 하네스 도구 (오픈소스)

검색 키워드:
- `aider changelog latest`
- `cursor rules update`
- `AI coding assistant comparison 2026`
- `LLM harness engineering`

체크 포인트:
- 다른 도구에서 검증된 패턴
- Nova에 없는 유용한 기능
- 품질 게이트 관련 새로운 접근법

## Relevance Filter 상세

### MUST 조건 (하나라도 해당해야 통과)

1. Nova의 commands/, skills/, agents/, hooks/ 에 직접 영향
2. Generator-Evaluator 분리 패턴 강화 가능
3. 세션 간 맥락 보존 개선 가능
4. 검증 기준(5차원) 확장 가능
5. Claude Code 플러그인 호환성 영향

### MUST NOT 조건 (하나라도 해당하면 제외)

1. Nova 철학(하네스 엔지니어링)에 반하는 변경
2. Generator-Evaluator 분리를 약화하는 변경
3. 출처 URL이 없는 정보 기반 변경
4. 사용자 프로젝트의 `.claude/rules/` 우선순위를 침범하는 변경

## Autonomy Levels 상세

### patch (Full Auto)

변경 가능 범위:
- `docs/eval-checklist.md` — 체크리스트 항목 추가/수정
- `docs/nova-rules.md` — 규칙 문구 개선 (의미 변경 불가)
- `docs/templates/*.md` — 템플릿 보완
- `commands/*.md` — 오타 수정, 문구 개선 (로직 변경 불가)
- `README.md`, `README.ko.md` — 문서 개선

변경 불가:
- `hooks/*.sh` — 세션 훅은 patch로 변경 불가
- `skills/*/SKILL.md` — 스킬 로직 변경 불가
- `mcp-server/src/**` — 서버 코드 변경 불가

### minor (Semi Auto — PR)

변경 가능 범위:
- patch 범위 전체 +
- `hooks/*.sh` — 훅 로직 개선
- `commands/*.md` — 옵션 추가, 검증 기준 추가
- `skills/*/SKILL.md` — 스킬 로직 개선
- `docs/nova-rules.md` — 규칙 추가/변경 (session-start.sh 동기화 필수)

### major (Manual — 제안만)

- 새 커맨드 파일 생성
- 새 스킬 디렉토리 생성
- 기존 커맨드/스킬 삭제
- `mcp-server/src/**` 변경
- 호환성이 깨지는 모든 변경

## Gate Chain 실행 규칙

1. **Gate 1 (Tests)**: `bash tests/test-scripts.sh` 실행
   - FAIL 시 변경 전체를 `git restore .`으로 롤백
   - 롤백 후 해당 제안을 "Gate 1 FAIL"로 표기

2. **Gate 2 (Evaluator)**: `/nova:review --fast` 실행
   - FAIL 시 수정 1회 시도
   - 재시도 후에도 FAIL이면 롤백 + "Gate 2 FAIL" 표기

3. **Gate 3 (수준별 분기)**:
   - patch + `--auto`: 커밋 메시지 자동 생성, `git add` + `git commit`
   - minor + `--auto`: 브랜치 생성 + PR
   - major: 제안서만 유지

## Schedule 연동

`/schedule`로 cron 등록하여 자동 실행할 수 있다:

```
/schedule "Nova Self-Evolution 스캔" --cron "0 21 * * 1,3,5" --command "/nova:evolve --auto"
```

> 위 예시: 매주 월/수/금 06:00 KST (UTC 21:00)에 자동 스캔 + 자율 범위 적용
