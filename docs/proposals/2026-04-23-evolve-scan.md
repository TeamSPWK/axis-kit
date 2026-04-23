# Evolution Scan Report (2026-04-23)

> 스캔 일시: 2026-04-23T15:00:00+09:00
> 소스: Anthropic 공식, Claude Code 생태계, 하네스 도구, AI 엔지니어링
> 이전 스캔: 2026-04-17 (Opus 4.7 반영 완료), 2026-04-18 (design-system/ui-build/figma 3건 pending)
> 발견: 22건 → 관련: 6건 (필터율: 73%)

---

## Scan Summary

| # | 항목 | 수준 | 자율 등급 | 출처 |
|---|------|------|----------|------|
| P1 | `claude plugin tag` 도입 — release.sh `git tag` 교체 | patch | Full Auto | [Claude Code 2.1.118](https://code.claude.com/docs/en/changelog) |
| P2 | autoMode `$defaults` 패턴 가이드 추가 (문서) | patch | Full Auto | [Claude Code 2.1.118](https://code.claude.com/docs/en/changelog) |
| M1 | `type: "mcp_tool"` 훅으로 evaluator/x-verify 직접 호출 | minor | Semi Auto (PR) | [Claude Code 2.1.118](https://code.claude.com/docs/en/changelog) |
| M2 | agent frontmatter `mcpServers` 로 main-thread MCP 제어 | minor | Semi Auto (PR) | [Claude Code 2.1.117](https://code.claude.com/docs/en/changelog) |
| M3 | "Demystifying evals" 공식 용어 → evaluator 스킬 정렬 | minor | Semi Auto (PR) | [Anthropic Engineering](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) |
| Mj1 | Plugin `bin/` executables — scripts를 bare command로 | major | Manual | [Claude Code 2.1.113](https://code.claude.com/docs/en/changelog) |

---

## patch (2건)

### P1. marketplace.json validate를 release.sh 전처리에 추가 (scope 축소)

> 출처: [Claude Code v2.1.118 (2026-04-23)](https://code.claude.com/docs/en/changelog)
> 수준: patch
> 자율 등급: Full Auto

#### 실측 노트 (2026-04-23)

**`claude plugin tag` 직접 도입 보류**. 실측 결과 2가지 블로커 발견:
1. `claude plugin tag`가 강제하는 태그 포맷이 **`{name}--v{version}` (예: `nova--v5.19.0`)** — Nova 기존 관습 `v5.18.3`과 충돌. landing 동기화·gh release `gh release create "v${NEW_VERSION}"` 전부 재설계 필요.
2. `claude plugin validate .claude-plugin/plugin.json` 이 Nova 커스텀 필드 `tool_contract`(Sprint 2a 도구 제약 계약)을 `Unrecognized key`로 FAIL.

"공식 문서 ≠ 실제 런타임" 원칙대로 실측이 이 두 건을 사전에 잡아냈다.

#### Nova 적용 방안 (축소판)

`claude plugin validate .claude-plugin/marketplace.json`만 `scripts/release.sh` Step 1 직전에 추가:
- marketplace 매니페스트 건전성(필수 필드·버전 파싱 가능)을 CLI 공식 스키마로 검증
- plugin.json은 커스텀 필드 때문에 validate 스킵 → Nova가 자체 jq 검사로 이미 버전 일치 확인
- `claude` CLI 없으면 경고 후 스킵 (fail-open, 기존 동작 유지)

#### 영향 범위

- `scripts/release.sh` — Step 1 이전에 marketplace validate 블록 추가 (~10 lines)
- CLAUDE.md·문서 변경 없음

#### 리스크

매우 낮음 — fail-open + 기존 태그·커밋 로직 무변경. `claude` 없으면 스킵.

---

### P2. `autoMode.allow`/`environment` `$defaults` 패턴 가이드 추가

> 출처: [Claude Code v2.1.118 (2026-04-23)](https://code.claude.com/docs/en/changelog)
> 수준: patch
> 자율 등급: Full Auto

#### 발견

v2.1.118에서 사용자 settings.json의 `autoMode.allow`, `autoMode.soft_deny`, `autoMode.environment`에 `"$defaults"` 토큰을 포함하면 **built-in 규칙을 보존하면서 커스텀 규칙을 추가**할 수 있게 됨. 이전에는 사용자 설정이 전체 대체.

#### Nova 적용 방안

Nova의 `docs/nova-rules.md §5 환경 안전` 및 `scripts/setup-permissions.sh` 가이드에 `$defaults` 패턴 명시. 사용자가 Nova permissions + 자신의 커스텀 규칙을 병행할 때 built-in 유실을 방지.

#### 영향 범위 (실제 반영)

- `docs/nova-rules.md` §11 — "In-situ 검증 권장" 뒤에 "autoMode `$defaults` 병행 사용 가이드" 서브섹션 추가
- ~~`scripts/permissions-template.json`~~ — 미반영. autoMode는 Nova 관리 영역이 아니라 사용자 전용이므로 템플릿에 예시 주석 추가 불필요 (Nova는 `permissions` 스키마만 관리)
- ~~`scripts/setup-permissions.sh`~~ — 미반영. 동일 이유

> 초안 대비 scope 축소. autoMode는 Nova가 manage 하지 않는 사용자 전용 영역이라 nova-rules.md 문서 가이드만 추가하는 것이 §9 "설정 파일 직접 수정 금지" 원칙과 정합.

#### 리스크

낮음 — 순수 문서/가이드 변경. 실제 설정 파일을 건드리지 않음 (§9 "환경 설정 안전 규칙" 유지).

---

## minor (3건)

### M1. ~~`type: "mcp_tool"` 훅~~ — **실측 결과 보류, `type: "agent"`/`"prompt"` 후속 탐색**

> 출처: [Claude Code v2.1.118 (2026-04-23)](https://code.claude.com/docs/en/changelog), [Hooks reference](https://code.claude.com/docs/en/hooks)
> 수준: minor → **보류**
> 자율 등급: ~~Semi Auto~~ → N/A

#### 실측 노트 (2026-04-23)

changelog는 "MCP tools directly invocable via hooks using `type: \"mcp_tool\"`"로 요약하지만, 공식 [Hooks reference](https://code.claude.com/docs/en/hooks)에는 `type: "mcp_tool"`이 **명시되지 않음**. 공식 문서는 4종만 열거: `command`, `http`, `prompt`, `agent`.

`claude plugin validate`는 plugin.json 스키마만 검사하고 hooks.json은 스키마 밖. 실제 런타임 파싱 여부는 세션 단위 실행 필요.

**Nova v5.18.3 "if 필드" 사건 선례**에 따라 공식 문서 미확인 시 보류 원칙 적용. merge 금지.

#### 후속 탐색 기회 (더 가치 있음)

실측 과정에서 **더 중요한 기회** 발견: `type: "agent"` 훅이 공식 지원. Nova evaluator 서브에이전트를 Stop 훅으로 노출 가능성:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "agent",
        "agent": "evaluator",
        "prompt": "직전 턴의 변경사항을 적대적으로 검증"
      }]
    }]
  }
}
```

이는 Nova "커밋 전 Evaluator PASS" 하드 게이트를 **커밋 시도 대신 턴 종료 시점**으로 앞당긴다. 실제 적용은 별도 설계 필요.

#### 결론

**M1 보류**. 후속 탐색: `type: "agent"` 훅으로 evaluator를 Stop 훅에 연결하는 설계 스파이크. 이는 독립 제안서로 분리 예정.

---

### M2. ~~Agent frontmatter `mcpServers`~~ — **실측 결과 보류**

> 출처: [Claude Code v2.1.117 (2026-04-22)](https://code.claude.com/docs/en/changelog), [Sub-agents reference](https://code.claude.com/docs/en/sub-agents)
> 수준: minor → **보류**
> 자율 등급: ~~Semi Auto~~ → N/A

#### 실측 노트 (2026-04-23)

Claude Code 공식 문서 실측 결과:

> "For security reasons, **plugin subagents do not support** the `hooks`, `mcpServers`, or `permissionMode` frontmatter fields. These fields are ignored when loading agents from a plugin."

Nova는 플러그인으로 배포되므로 `agents/*.md`에 `mcpServers` 추가해도 **무시된다**. 본 제안 무효.

#### 추가 발견 (불필요함)

Nova는 이미 `.mcp.json`에 nova MCP server를 선언 → 플러그인 로드 시 자동 연결. agents에서 별도 선언 없이도 MCP 도구 사용 가능 (세션 레벨 공유).

`mcpServers` frontmatter의 가치는 **서브에이전트 격리 MCP 서버** 활성화인데, plugin에서는 막혀 있으므로 적용 불가.

#### 결론

**M2 전면 보류**. 사용자가 agent 파일을 `.claude/agents/`로 직접 복사할 때만 활성화되지만, 이는 Nova 플러그인 사용자 표준 경로가 아님. 제안서 보존(미래에 plugin 제약이 완화될 경우 재개 가능).

---

### M3. "Demystifying evals" 공식 용어 → evaluator 스킬 정렬

> 출처: [Anthropic — Demystifying evals for AI agents (2026-01-09)](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
> 수준: minor
> 자율 등급: Semi Auto (PR)

#### 발견

Anthropic이 공식 블로그에서 agent 평가 5대 개념을 정의: **task** (입력+성공기준), **trial** (1회 시도), **transcript** (trace/trajectory), **outcome** (환경 최종 상태), **harness** (end-to-end 실행 인프라).

#### Nova의 갭

Nova evaluator 스킬은 "기능/데이터 관통/설계 정합성/크래프트/경계값" 등 자체 용어로 판정 기준을 정의. 공식 용어와 매핑되지 않아:
- 외부 문서(Anthropic evals 학습자료)와의 크로스 레퍼런스가 어려움
- 판정 로그(`.nova/events.jsonl`)의 `verdict/critical_issues/target`이 trajectory/outcome 개념과 1:1 매핑 미비
- "하네스 엔지니어링"을 표방하면서도 공식 harness 정의(tool/input/trial 레코딩)와 대조 안 됨

#### Nova 적용 방안

1. `skills/evaluator/SKILL.md`에 "공식 용어 매핑" 섹션 추가:
   - Nova `record-event.sh evaluator_verdict` = outcome
   - Nova `.nova/events.jsonl` = transcript
   - Nova `/nova:run` 한 사이클 = trial
   - Nova `docs/nova-rules.md §3 검증 기준` = task success criteria
2. `docs/nova-rules.md §10 관찰성 계약`에 trajectory vs outcome 구분 명시
3. `docs/harness-engineering.md`(존재 시) 또는 CLAUDE.md에 "하네스 = end-to-end 실행 + 그레이딩 + 집계 인프라" 정의 인용

#### 영향 범위

- `skills/evaluator/SKILL.md` — 용어 매핑 섹션 추가
- `docs/nova-rules.md` — §10 관찰성 용어 정렬
- `skills/jury/SKILL.md` — 참조 갱신 (jury도 evaluator 기반)

#### 리스크

낮음 — 문서/용어 정리. 기존 로직 변경 없음. 단 **용어 쇄신 시 기존 Nova 사용자 학습 곡선 증가** → 기존 Nova 용어는 유지하고 "= 공식 XXX" 병기 형태 권장.

---

## major (1건)

### Mj1. Plugin `bin/` executables — Nova scripts를 bare command로 노출

> 출처: [Claude Code v2.1.113 (2026-04-17)](https://code.claude.com/docs/en/changelog)
> 수준: major
> 자율 등급: Manual (제안서만, 사용자 결정)

#### 발견

v2.1.113부터 플러그인 `bin/` 디렉토리의 executables가 Bash tool에서 bare command로 호출 가능. 예: `nova-xverify "질문"` 처럼 경로 없이 실행.

#### Nova의 현재 상태

Nova는 모든 스크립트를 `scripts/` 하위에서 `bash scripts/x-verify.sh ...` 경로 기반으로 호출. CLAUDE.md·release.sh·커맨드 다수가 이 경로에 의존.

#### Nova 적용 방안 (옵션)

**옵션 A**: `bin/` 추가 + 래퍼 심볼릭 링크 (호환성 유지)
- `bin/nova-xverify` → `scripts/x-verify.sh` 심볼릭
- `bin/nova-release` → `scripts/release.sh`
- `bin/nova-evaluate` → (신규) evaluator 직접 호출 스크립트
- 기존 경로 그대로 → 사용자/문서 변경 없음

**옵션 B**: scripts/ 재구조화 + 문서 일괄 이관 (깨끗한 전환)
- `bin/`으로 실사용 실행 파일 이동
- `scripts/lib/`에 내부 헬퍼 유지
- CLAUDE.md, commands/*.md, release.sh 전부 갱신

#### 영향 범위

- **옵션 A (권장)**: `bin/` 디렉토리 추가, 기존 코드 무변경 — 소폭
- **옵션 B**: `scripts/` 전체 재배치 + 50+ 파일 참조 수정 — 대규모

#### 리스크

**높음** — 주의 포인트:
1. 심볼릭 링크는 git 인덱스에 120000 mode로 저장되어 Windows에서 깨질 수 있음. 사용자 OS 다양성 테스트 필요.
2. v2.1.113 미만 사용자는 bare command 인식 못 함 → `bash bin/...` fallback 문서화 필수.
3. release.sh 무결성 게이트가 bin/ 엔트리도 tracked 검증하도록 확장 필요.
4. **사용자 승인 필수** — Nova는 "안정 우선" 철학. 이 변경은 가치 대비 리스크 trade-off 판단 필요.

#### 권장

**당분간 옵션 A도 도입하지 않음** — 현재 `bash scripts/xxx` 경로 기반이 충분히 안정적. v2.1.113이 Nova 사용자 과반으로 자리잡은 후(6~8주) 재검토. 해당 시점에도 "scripts 호출이 사용자를 실제로 불편하게 하는가?"를 먼저 측정한 후 결정.

---

## 제외 항목 (필터에서 탈락, 기록 목적)

| 항목 | 제외 사유 |
|------|---------|
| `/tui` 전체화면 렌더링 | Nova 핵심 가치와 무관 (UI 레벨) |
| Vim visual mode | Claude Code 사용자 UX, Nova 관여 여지 없음 |
| Themes (`themes/` 디렉토리) | Nova는 기능 플러그인, 테마 배포 계획 없음 |
| Managed Agents (hosted) | 별도 런타임/가격 — Nova는 Claude Code 플러그인 |
| Cursor 3 / Windsurf Arena | 타 IDE, 경쟁 플랫폼 |
| Forked subagents (`CLAUDE_CODE_FORK_SUBAGENT=1`) | 외부 빌드 대상. Nova는 official binary 사용자 우선 |
| Sandbox deniedDomains | 보안 기능이지만 Nova §9 "환경 설정 안전 규칙"(설정 파일 직접 수정 금지)과 충돌 |
| Bash deny `env`/`sudo` 래퍼 매칭 | 이미 Nova `precheck-tool.sh`가 유사 검사 수행 |
| Agent SDK skills option / list_subagents | Python SDK 기능. Nova CLI 사용자는 무관 |

---

## 반영 우선순위 권장

1. **P1 (plugin tag)** — 즉시 적용 가능. release 안전성 직접 향상.
2. **M3 (evals 용어)** — 문서 정리로 가치 중간. PR 1건.
3. **P2 (autoMode $defaults 문서)** — 문서 업데이트, 리스크 없음.
4. **M1 (mcp_tool hook)** — 실측 필수. 호환성 실험 후 결정.
5. **M2 (agent mcpServers)** — 점진 적용. audit 스크립트 단계 고려.
6. **Mj1 (bin/)** — **보류**. 6~8주 후 재평가.

---

## Next Action

- `--apply` 모드로 P1, P2, M3부터 진행 권장 (patch + 문서).
- M1은 별도 브랜치에서 실측 검증 후 PR.
- M2는 agents/*.md 일괄 편집 PR.
- Mj1은 본 제안서 유지, 반영 시점 추후 결정.
