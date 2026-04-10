# Evolution Scan Report: Anthropic 공식 (2026-04-10)

> 스캔 일시: 2026-04-10T23:00:00+09:00
> 소스: Anthropic 공식 (Claude Code v2.1.89~v2.1.98)
> 발견: 14건 → 관련: 6건

---

## patch (3건)

### P1. MCP maxResultSizeChars 지원

> 출처: https://github.com/anthropics/claude-code/releases (v2.1.91)
> 수준: patch
> 자율 등급: Full Auto

#### 발견
Claude Code v2.1.91에서 MCP 도구 결과에 `_meta["anthropic/maxResultSizeChars"]` 주석을 추가하면 최대 500K까지 결과 크기를 제어할 수 있다. DB 스키마 등 대용량 결과 지원.

#### Nova 적용 방안
Nova MCP 서버의 `get_rules`, `get_state` 도구에서 대용량 응답이 잘리는 경우 대비하여 `_meta` 주석을 추가한다. 특히 `get_rules`는 nova-rules.md 전체를 반환하므로 크기 제한에 걸릴 수 있다.

#### 영향 범위
- `mcp-server/src/tools/get-rules.ts`
- `mcp-server/src/tools/get-state.ts`

#### 리스크
낮음 — 메타데이터 추가만으로 기존 동작에 영향 없음.

---

### P2. disableSkillShellExecution 호환성 문서화

> 출처: https://github.com/anthropics/claude-code/releases (v2.1.91)
> 수준: patch
> 자율 등급: Full Auto

#### 발견
`disableSkillShellExecution` 설정이 추가되어 스킬/커맨드의 인라인 쉘 실행을 비활성화할 수 있다. 이 설정이 활성화된 환경에서 Nova의 `/consult`(Mode A: x-verify.sh 실행)가 작동하지 않을 수 있다.

#### Nova 적용 방안
- `commands/consult.md`에 "disableSkillShellExecution 설정 시 Mode A 불가, Mode B(에이전트 모드)로 자동 전환" 안내 추가.
- 또는 `/consult` 실행 시 해당 설정을 감지하여 자동으로 Mode B 전환.

#### 영향 범위
- `commands/consult.md` — Notes 섹션에 호환성 안내 추가

#### 리스크
낮음 — 문서 변경만.

---

### P3. /reload-plugins 사용법 문서화

> 출처: https://github.com/anthropics/claude-code/releases (v2.1.90)
> 수준: patch
> 자율 등급: Full Auto

#### 발견
`/reload-plugins` 명령이 추가되어 플러그인 변경 후 세션 재시작 없이 즉시 반영 가능. Nova 개발/업데이트 시 유용.

#### Nova 적용 방안
- `docs/usage-guide.md`에 "Nova 업데이트 후 `/reload-plugins`로 즉시 반영" 안내 추가.

#### 영향 범위
- `docs/usage-guide.md`

#### 리스크
없음.

---

## minor (2건)

### M1. PermissionDenied 훅으로 품질 게이트 강화

> 출처: https://github.com/anthropics/claude-code/releases (v2.1.89)
> 수준: minor
> 자율 등급: Semi Auto (PR)

#### 발견
`PermissionDenied` 훅이 추가되어 자동 모드 분류기가 도구 사용을 거부한 후 실행된다. `{retry: true}`를 반환하면 재시도 가능. 이는 Nova의 Always-On 행동을 강화할 수 있다.

#### Nova 적용 방안
- Nova가 자동 검증을 실행하려 할 때 권한이 거부되면, `PermissionDenied` 훅에서 사용자에게 "Nova 품질 게이트 실행을 위해 권한이 필요합니다" 안내를 제공.
- `hooks/hooks.json`에 `PermissionDenied` 이벤트 핸들러 추가.

#### 영향 범위
- `hooks/hooks.json` — 새 이벤트 핸들러 추가
- `hooks/permission-denied.sh` — 새 스크립트 생성

#### 리스크
중간 — 훅 추가는 세션 시작 시 로드되므로, 오류 발생 시 전체 세션에 영향.

---

### M2. Monitor 도구로 백그라운드 Evaluator 관측성 강화

> 출처: https://github.com/anthropics/claude-code/releases (v2.1.98)
> 수준: minor
> 자율 등급: Semi Auto (PR)

#### 발견
Monitor 도구가 추가되어 백그라운드 스크립트의 이벤트를 스트리밍할 수 있다. 현재 Nova의 Evaluator는 백그라운드 서브에이전트로 실행되지만, 진행 상황을 실시간으로 확인하기 어렵다.

#### Nova 적용 방안
- `/auto` 커맨드에서 Evaluator 실행 시 Monitor 도구 활용하여 진행 상황을 실시간 표시.
- `skills/evaluator/SKILL.md`에 Monitor 연동 옵션 추가.

#### 영향 범위
- `commands/auto.md` — Evaluator 실행 시 Monitor 연동 안내
- `skills/evaluator/SKILL.md` — Monitor 활용 섹션 추가

#### 리스크
낮음 — 기존 동작을 변경하지 않고 옵션으로 추가.

---

## major (1건)

### X1. PreToolUse defer 기반 headless 품질 게이트

> 출처: https://github.com/anthropics/claude-code/releases (v2.1.89)
> 수준: major
> 자율 등급: Manual (제안만)

#### 발견
`PreToolUse` 훅에 `"defer"` 결정이 추가되어, 헤드리스 세션이 도구 호출에서 일시 중지하고 `-p --resume`으로 재개할 수 있다. 이는 CI/CD 파이프라인에서 Nova 품질 게이트를 실행하는 새로운 가능성을 연다.

#### Nova 적용 방안
- CI/CD에서 Claude Code를 headless로 실행 → 커밋/PR 시 Nova 품질 게이트 자동 트리거.
- `pre-commit-reminder.sh`가 `"defer"`를 반환 → CI 파이프라인에서 review 결과 확인 후 resume.
- 새 커맨드 `/nova:ci` 또는 `--headless` 플래그로 CI 전용 모드.

#### 영향 범위
- 새 커맨드 또는 플래그 추가
- `hooks/pre-commit-reminder.sh` 대폭 변경
- CI/CD 연동 가이드 문서 필요

#### 리스크
높음 — 아키텍처 변경. headless 모드에서의 동작 보장 필요. 충분한 테스트 필요.
