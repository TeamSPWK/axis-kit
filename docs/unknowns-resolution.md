# Unknowns Resolution Log

Nova Plan/Design에서 열린 Unknowns 항목의 해소 결과를 기록한다. Plan이 제시한 "해소 절차"를 실행한 결과를 시간 순으로 남긴다.

---

## U1 — Claude Code plugin.json permission 필드 지원 범위

**Plan**: `docs/plans/harness-engineering-gap-coverage.md` — Unknowns §U1
**해소 일자**: 2026-04-19
**해소자**: main-agent (Sprint 1 착수 gate)
**방법**: `claude-code-guide` 서브에이전트 호출로 Claude Code v2.1.112 공식 문서 확인

### 질문 & 답변

**Q1. plugin.json이 agent/tool permission 필드를 공식 지원하는가?**

**A: No.** `.claude-plugin/plugin.json` 공식 스키마에 `permissions`, `tools`, `tool_contract`, `allowedTools`, `disallowedTools` 같은 필드가 **없다**. 플러그인 매니페스트는 `name`, `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords` 같은 메타데이터 필드만 관리한다.

출처: [Plugins reference — Plugin manifest schema](https://code.claude.com/docs/en/plugins-reference.md)

**Q2. agent frontmatter `tools:` / `disallowedTools:`는 런타임 enforcement로 작동하는가?**

**A: No — 선언적 힌트일 뿐.** 이 필드는 **에이전트 시스템 프롬프트의 일부로 주입**되지만 런타임 enforcement 메커니즘은 없다. 에이전트가 지시를 어기거나 프롬프트 인젝션으로 무시할 수 있다.

출처: [Sub-agents — Agent frontmatter](https://code.claude.com/docs/en/sub-agents.md)

**Q3. 프로젝트 `.claude/settings.json`의 `permissions` 필드 우선순위는?**

**A: 공식 정의 있음.** **Managed Settings > Project `.claude/settings.json` > User settings**. 플러그인은 이 체계에 참여하지 않으며, "기본값(defaults)"만 제공 가능.

출처: [Permissions — Settings precedence](https://code.claude.com/docs/en/permissions.md)

### 결론

| 방안 | Plan의 원래 권장 | U1 해소 후 재평가 |
|------|----------------|-------------------|
| A (frontmatter tools 엄격화) | ⭐ 기반 | **유지** — 단 "선언적 힌트" 명시. 에이전트 지시/감사용 |
| B (plugin.json tool_contract) | ⭐ 보조 | **격하** — 공식 미지원. "문서 목적 전용" 주석 명시 후 유지 |
| C (PreToolUse 훅으로 차단) | 보류 (U1 해소 후) | **⭐ 승격 — 유일한 공식 런타임 enforcement 경로** |
| D (`/nova:setup --permissions` 템플릿) | ⭐ 옵션 | **⭐ 유지 + 강화** — 우선순위 공식 정의됨(Project settings) |

### Plan에 반영할 변경사항

1. **Solution — 선택한 방안**: "A+B+D 하이브리드" → **"C+D(핵심) + A(선언 보조) + B(문서 목적)"**
2. **대안 비교 — 도구 제약 레이어 표**: C 권장도 ⭐ 승격, B 격하(문서 목적 주석)
3. **Sprint 2a 내용**: 정적 부분은 유지. 단 plugin.json `tool_contract` 필드는 "공식 미지원 — 문서 용도" 주석 명시. `/nova:setup --permissions`가 **실제 `.claude/settings.json`의 `permissions.defaultMode`와 `PreToolUse` 훅 엔트리까지 제공**
4. **Sprint 2b 내용**: "JSONL 기반 런타임 감사" → **"PreToolUse 훅 스크립트로 실제 차단 + JSONL 위반 이벤트 기록"**. 실질 enforcement 레이어.
5. **Risk Map R11**: "Claude Code permissions 필드 비표준" → **"해소(2026-04-19): 미지원 확정, C 경로로 전환"**
6. **Verification Hooks V28**: "의도 위반 fixture → evaluator 판정"에 더해 **"PreToolUse 훅이 실제로 도구 실행 차단(exit 2) + stderr에 정책 이유 + JSONL에 `tool_constraint_violation` 기록"** 추가
7. **스프린트 견적 변경 없음**: Sprint 2b가 더 강력한 기능을 가지지만 파일 수 증가는 없음(훅 스크립트 1개 추가, JSONL 연동은 Sprint 1의 `record-event.sh` 재사용).

---

## U2 — Deferred 도구 resolution 타이밍

**상태**: 미착수 (Sprint 2a 진입 시 해소 예정)

## U3 — 이벤트 로그 저장 경로

**상태**: 해소됨 (Plan Solution에서 결정 — 기본 `.nova/events.jsonl`, opt-in으로 `$NOVA_EVENTS_PATH`)

## U4 — plugin.json ↔ CLAUDE.md 우선순위

**상태**: 부분 해소 (U1 조사 중 관련 정보 획득)

U1 답변에서 확인: Claude Code 공식 우선순위는 **Managed > Project `.claude/settings.json` > User settings**. 플러그인은 이 체계에 기본값만 제공 가능. 프로젝트의 `CLAUDE.md`(또는 `.claude/rules/`)는 system prompt에 주입되지만, **규칙 레벨의 precedence 공식 정의는 여전히 없다** — docs/nova-rules.md §0에서 "프로젝트 `.claude/rules/`가 Nova보다 우선"으로 이미 Nova가 스스로 정한 대로 유지 가능.

## U5 — 이벤트 로그 파일 권한

**상태**: 해소됨 (Plan 결정 — `record-event.sh` 최초 호출 시 `chmod 600`)

## U6 — 스키마 혼재 로그 reader 정책

**상태**: 해소됨 (Plan 결정 — 라인별 `schema_version` 감지, 미지원 버전 warning+skip, major 변경 시 수동 `scripts/migrate-events.sh`)
