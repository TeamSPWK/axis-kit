# Evolution Scan Report (2026-04-15)

> 스캔 일시: 2026-04-15T15:00:00+09:00
> 소스: Anthropic 공식, Claude Code 생태계, 하네스 도구, AI 엔지니어링
> 이전 스캔: 2026-04-13 (9건 제안)
> 발견: 28건 → 관련: 7건 (필터율: 75%)

---

## patch (2건)

### P1. PreCompact 훅으로 NOVA-STATE.md 보호

> 출처: https://x.com/ClaudeCodeLog/status/2043835972513669466 (v2.1.105, April 13)
> 수준: patch
> 자율 등급: Full Auto

#### 발견
Claude Code v2.1.105에서 `PreCompact` 훅 이벤트가 추가되었다. 훅이 exit code 2 또는 `{"decision":"block"}`을 반환하면 컴팩션을 차단할 수 있다. 컴팩션 직전에 중요한 컨텍스트를 백업하는 용도로 사용 가능.

#### Nova 적용 방안
Nova의 `context-chain` 스킬이 NOVA-STATE.md로 세션 간 맥락을 유지하는데, 컴팩션 시 STATE 갱신이 누락될 수 있다. PreCompact 훅에서:
1. 현재 진행 중인 태스크 상태를 NOVA-STATE.md에 강제 갱신
2. 컴팩션 직전 스냅샷을 보장하여 컨텍스트 손실 방지

#### 영향 범위
- `hooks/hooks.json` (plugin.json hooks 섹션) — PreCompact 핸들러 추가
- `hooks/pre-compact.sh` — 새 스크립트 (STATE 갱신 트리거)

#### 리스크
낮음 — 컴팩션 전 STATE를 갱신하는 것이므로 기존 동작에 부정적 영향 없음. v2.1.105 미만에서는 훅이 무시됨.

---

### P2. EnterWorktree `path` 파라미터로 field-test 최적화

> 출처: https://x.com/ClaudeCodeLog/status/2043835972513669466 (v2.1.105, April 13)
> 수준: patch
> 자율 등급: Full Auto

#### 발견
`EnterWorktree` 도구에 `path` 파라미터가 추가되어, 기존 워크트리 경로를 직접 지정하여 진입할 수 있게 되었다. 이전에는 항상 새 워크트리를 생성해야 했다.

#### Nova 적용 방안
Nova `field-test` 스킬이 워크트리에서 격리 테스트를 수행하는데, 동일 프로젝트에 대해 반복 테스트 시 기존 워크트리를 재사용할 수 있다. 스킬 프롬프트에 "기존 워크트리가 있으면 `path`로 진입, 없으면 새로 생성" 가이드를 추가.

#### 영향 범위
- `skills/field-test/SKILL.md` — EnterWorktree path 활용 가이드 추가

#### 리스크
낮음 — 기존 동작(새 워크트리 생성)이 기본이므로, path 사용은 선택적 최적화.

---

## minor (3건)

### M1. Plugin monitors 매니페스트로 백그라운드 품질 모니터

> 출처: https://code.claude.com/docs/en/changelog (v2.1.107, April 13), https://claudefa.st/blog/guide/mechanics/monitor
> 수준: minor
> 자율 등급: Semi Auto (PR)

#### 발견
Claude Code v2.1.107에서 플러그인에 `monitors` 매니페스트 키가 추가되었다. 세션 시작 시 또는 스킬 호출 시 자동으로 백그라운드 프로세스를 실행하고, stdout 출력이 세션에 스트리밍된다. Monitor 도구(v2.1.100)와 결합하면 폴링 없이 이벤트 기반으로 반응할 수 있다.

#### Nova 적용 방안
Nova 플러그인에 monitors를 추가하여:
1. **테스트 워치 모니터**: `--watch` 모드 테스트 러너의 출력을 모니터링. 테스트 실패 시 자동으로 세션에 알림.
2. **빌드 모니터**: `tsc --watch`나 dev server 출력을 모니터링. 빌드 에러 발생 시 즉시 반응.
3. plugin.json에 `monitors` 키로 선언, 조건부 활성화 (프로젝트에 package.json이 있을 때만 등).

#### 영향 범위
- `.claude-plugin/plugin.json` — monitors 매니페스트 추가
- 새 파일: `monitors/` 디렉토리 (모니터 스크립트)
- `docs/nova-rules.md` — 모니터 관련 가이드

#### 리스크
중간 — 모니터가 토큰을 소비하므로, 출력이 과도한 프로세스를 모니터링하면 비용 증가. stdout 필터링/쓰로틀링 필요. 모니터 미지원 버전에서의 graceful degradation 확인 필요.

---

### M2. Anthropic 3-Agent 하네스 패턴 — 구조화된 핸드오프 아티팩트

> 출처: https://www.anthropic.com/engineering/harness-design-long-running-apps, https://www.infoq.com/news/2026/04/anthropic-three-agent-harness-ai/
> 수준: minor
> 자율 등급: Semi Auto (PR)

#### 발견
Anthropic이 공식 3-Agent 하네스 설계를 발표했다 (Planner → Generator → Evaluator). Nova의 기존 아키텍처와 동일한 구조이나, 핵심 차이점이 있다:
1. **구조화된 핸드오프 아티팩트**: 에이전트 간 전달 시 JSON feature spec, commit-by-commit progress, `claude-progress.txt` 파일을 사용
2. **컨텍스트 리셋**: 각 에이전트는 새로운 컨텍스트 윈도우에서 시작하되, 이전 아티팩트를 구조화된 형태로 전달받음
3. **5~15회 반복**: 단일 기능에 대해 Generator-Evaluator 사이클을 5~15회 반복, 최대 4시간

#### Nova 적용 방안
Nova Orchestrator에 **구조화된 핸드오프 프로토콜**을 추가:
1. Generator가 완료 시 `SPRINT-PROGRESS.md` (또는 JSON)에 구조화된 결과를 기록
2. Evaluator가 해당 파일을 읽어 검증 (현재는 코드 diff만 검증)
3. Evaluator 피드백도 구조화된 형태로 Generator에게 전달 (현재는 자연어 리뷰만)
4. NOVA-STATE.md가 이미 이 역할을 부분적으로 수행하지만, 에이전트 간 핸드오프 전용 포맷으로 강화

#### 영향 범위
- `skills/orchestrator/SKILL.md` — 핸드오프 아티팩트 프로토콜 섹션 추가
- `skills/evaluator/SKILL.md` — 구조화된 입력/출력 포맷 정의
- `commands/run.md` — Generator-Evaluator 핸드오프에 아티팩트 포함

#### 리스크
중간 — 핸드오프 아티팩트가 너무 무거우면 오버헤드. Nova의 "경량 기본, --strict에서 풀 검증" 원칙과 균형 필요.

---

### M3. "Gold Standard Files" 패턴 — 에이전트용 코딩 가이드라인

> 출처: https://stackoverflow.blog/2026/03/26/coding-guidelines-for-ai-agents-and-people-too/
> 수준: minor
> 자율 등급: Semi Auto (PR)

#### 발견
Stack Overflow 블로그(2026-03-26)에서 AI 에이전트용 코딩 가이드라인의 새로운 패턴을 정리:
1. **Gold Standard Files**: 단순한 규칙 목록 대신, 실제 "모범 구현" 파일을 제공하여 AI가 패턴을 모방
2. **패턴 기반 예제**: 올바른/잘못된 구현의 쌍을 제공
3. **피드백 플라이휠**: 에이전트 오류를 규칙 파일 업데이트에 반영 (Quinn Slack, Sourcegraph CEO)

#### Nova 적용 방안
Nova의 `/nova:setup`에서 프로젝트 초기화 시:
1. 프로젝트 내 "gold standard" 파일을 자동 식별 (가장 잘 작성된 파일을 코드 품질 점수로 선정)
2. `.claude/rules/`에 "이 파일을 참조 패턴으로 사용하라"는 규칙 자동 생성
3. `/nova:review` 피드백 중 반복 패턴을 규칙으로 자동 제안 (이전 스캔의 M3 "Learned Rules"와 연계)

#### 영향 범위
- `commands/setup.md` — gold standard 식별 + 규칙 생성 로직
- `skills/evaluator/SKILL.md` — gold standard 참조 검증 항목

#### 리스크
중간 — "gold standard" 자동 식별의 정확도가 핵심. 잘못된 파일을 선정하면 역효과. 사용자 확인 게이트 필수.

---

## major (2건)

### X1. Plugin Monitors 기반 실시간 품질 대시보드 (M1의 full 구현)

> 출처: https://code.claude.com/docs/en/changelog, https://aiia.ro/blog/claude-code-monitor-tool-background-scripts/
> 수준: major
> 자율 등급: Manual (제안만)

#### 발견
Monitor 도구 + monitors 매니페스트를 완전히 활용하면, Nova가 세션 전체에 걸쳐 **실시간 품질 감시**를 수행할 수 있다. 현재 Nova는 "요청 시 검증" 모델이지만, monitors를 통해 "상시 감시" 모델로 전환 가능.

#### Nova 적용 방안
1. **파일 변경 감시**: `fswatch`나 `inotifywait`로 소스 파일 변경을 모니터링, lint 오류 발생 시 세션에 자동 알림
2. **테스트 상시 실행**: 테스트 워치 모드의 출력을 모니터링, 실패 시 즉시 알림
3. **NOVA-STATE.md 자동 갱신**: 모니터가 감지한 이벤트를 STATE에 기록
4. **토큰 예산 관리**: 모니터 출력에 토큰 예산을 설정, 초과 시 자동 요약

#### 영향 범위
- 아키텍처 수준 변경: Nova의 검증 모델을 "온디맨드"에서 "이벤트 드리븐"으로 확장
- plugin.json, monitors/, hooks/, docs/nova-rules.md 전반

#### 리스크
높음 — 토큰 소비 제어가 핵심. 잘못된 모니터 설정으로 세션 비용이 급증할 수 있음. 점진적 도입 필수.

---

### X2. MCP Channels로 CI/CD 이벤트 수신

> 출처: https://www.vibesparking.com/en/blog/ai/claude-code/changelog/2026-03-20-claude-code-2180-channels-mcp-push-messages/
> 수준: major
> 자율 등급: Manual (제안만)

#### 발견
Claude Code Channels (v2.1.80, research preview)로 MCP 서버가 세션에 메시지를 푸시할 수 있다. `--channels` 플래그로 활성화. 양방향 메시징이 가능해져, 외부 이벤트(CI 실패, 배포 완료, PR 코멘트)를 세션 내에서 실시간 수신 가능.

#### Nova 적용 방안
Nova MCP 서버에 channel 기능을 추가하여:
1. **GitHub Actions 결과 수신**: 푸시 후 CI 결과를 세션에 자동 알림
2. **PR 리뷰 코멘트 수신**: 다른 리뷰어의 코멘트를 실시간 수신
3. **배포 상태 알림**: 릴리스 후 배포 결과를 세션에 전달

#### 영향 범위
- `mcp-server/` — channel 기능 추가
- Nova 아키텍처: "로컬 검증" → "CI/CD 통합 검증"으로 확장

#### 리스크
높음 — Channels는 아직 research preview. API 변경 가능성 높음. 보안 모델(sender allowlist) 관리 복잡도.

---

## 시장 컨텍스트 업데이트

> "Anthropic, OpenAI, Red Hat이 모두 동일한 결론에 도달: **Planner-Generator-Evaluator 분리가 에이전트 코딩의 표준 아키텍처**다." — [InfoQ, April 2026](https://www.infoq.com/news/2026/04/anthropic-three-agent-harness-ai/)

> "코딩 가이드라인은 AI에게 '더 명시적이고, 패턴 기반이고, 즉각 예제를 보여주는' 형태여야 한다." — [Stack Overflow Blog](https://stackoverflow.blog/2026/03/26/coding-guidelines-for-ai-agents-and-people-too/)

> "Monitor 도구는 폴링에서 이벤트 드리븐으로의 전환. 토큰을 절약하면서 반응성을 높인다." — [Claude Code Changelog](https://code.claude.com/docs/en/changelog)

> "Cursor 3의 Design Mode, Windsurf의 Arena Mode — IDE 도구들이 검증과 비교를 내장하기 시작. Nova의 교차검증(X-Verify)이 업계 방향과 일치." — [NxCode](https://www.nxcode.io/resources/news/windsurf-vs-cursor-2026-ai-ide-comparison)

Nova v5.1.0의 아키텍처(Generator-Evaluator 분리, CPS 구조, 품질 게이트)가 Anthropic 공식 가이드와 업계 표준으로 확인됨. 새로운 Claude Code 기능(monitors, PreCompact, channels)이 Nova의 검증 모델을 강화할 기회를 제공.
