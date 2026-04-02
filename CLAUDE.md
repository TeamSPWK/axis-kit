# Nova

AI 개발 품질 게이트 — Claude Code 플러그인으로 배포. 오케스트레이터 루프 안의 검문소.

## Language

- Claude는 사용자에게 항상 **한국어**로 응답한다.

## Nova Quality Gate

이 프로젝트는 Nova Quality Gate 방법론을 따른다.
자동 적용 규칙은 `hooks/session-start.sh`가 매 세션 주입한다 (경량 요약).
규칙 상세 소스: `docs/nova-rules.md` (§1~§9).

> 규칙 수정 시 반드시 session-start.sh와 동기화. CLAUDE.md만 수정하면 사용자에게 반영 안 됨.

## Build & Test

```bash
bash tests/test-scripts.sh                              # 전체 테스트 (169개)
bash hooks/session-start.sh | python3 -m json.tool      # session-start JSON 유효성
bash scripts/bump-version.sh <patch|minor|major>         # 버전 범프
```

### 릴리스 전 스크립트 단위 검증

서브에이전트 필드 테스트는 설치된 플러그인 버전을 참조하므로, **커밋 전에는 스크립트 출력을 직접 검증**한다. 검증 예제는 `tests/test-scripts.sh` 상단 주석 참조.

검증 관점: **구조**(섹션 존재/부재) · **포맷**(출력 형식) · **동기화**(nova-rules.md, session-start.sh, commands/*.md, skills/*/SKILL.md 일괄 반영)

## 플러그인 배포 구조 (필수 이해)

Nova는 Claude Code 플러그인이다. **이 CLAUDE.md는 Nova 개발용이지, 플러그인 사용자에게 전달되지 않는다.**

플러그인 사용자에게 전달되는 파일:

| 파일 | 전달 방식 | 수정 시 반영 |
|------|----------|-------------|
| `commands/*.md` | 슬래시 커맨드 | 플러그인 업데이트 시 자동 |
| `agents/*.md` | 에이전트 타입 | 플러그인 업데이트 시 자동 |
| `skills/*/SKILL.md` | 스킬 | 플러그인 업데이트 시 자동 |
| `hooks/session-start.sh` | SessionStart additionalContext | 플러그인 업데이트 시 자동 |
| **`CLAUDE.md`** | **전달 안 됨** | **반영 안 됨** |

### session-start.sh 동기화 규칙

`hooks/session-start.sh`는 매 세션 시작 시 자동 주입되는 **유일한 전역 규칙**이다.
자동 적용 규칙을 변경하면 반드시 동기화한다:

```
1. docs/nova-rules.md 수정 (소스)
2. hooks/session-start.sh additionalContext 동기화
3. bash hooks/session-start.sh | python3 -m json.tool  ← JSON 유효성 확인
4. bash tests/test-scripts.sh  ← 동기화 테스트 통과 확인
```

## Release Workflow (필수)

Nova는 Claude Code 플러그인이므로 **모든 커밋은 릴리스 단위**다.
변경사항을 커밋할 때 반드시 다음을 한 세트로 수행한다:

```
1. 구현 + 테스트 통과 확인
2. /review 실행 (patch: --fast, minor: 기본, major: --strict)
3. git add + git commit
4. bash scripts/bump-version.sh <patch|minor|major>  ← 범프된 파일 자동 생성
5. git add + git commit (버전 범프)
6. git tag v{새버전}
7. git push origin main --tags
8. gh release create v{새버전} --title "v{새버전} — {한줄 설명}" --notes "{변경 요약}"
```

### 버전 범프 기준

| 수준 | 기준 | 예시 |
|------|------|------|
| **patch** | 버그 수정, 문서 정리, 레거시 정리 | v2.4.0 → v2.4.1 |
| **minor** | 새 커맨드/스킬 추가, 기존 기능 개선 | v2.4.0 → v2.5.0 |
| **major** | 호환성 깨지는 변경, 아키텍처 전환 | v2.4.0 → v3.0.0 |

### 버전 동기화 구조

`bump-version.sh`가 3곳을 자동 동기화한다:
- `scripts/.nova-version` — 원격 버전 체크용 (단일 파일 curl)
- `.claude-plugin/plugin.json` — 플러그인 매니페스트
- `README.md` + `README.ko.md` — 배지

## Git Convention

```
feat: 새 기능/커맨드 추가   | fix: 버그 수정, 레거시 정리
update: 기존 기능 개선      | docs: 문서 변경
refactor: 리팩토링          | chore: 설정/기타
```

커밋 메시지에 버전 포함: `feat(v2.5.0): 새 기능 설명`

## Credentials

- **절대 git 커밋 금지**: `.env`, `.secret/`, `*.pem`, `*accessKeys*`
