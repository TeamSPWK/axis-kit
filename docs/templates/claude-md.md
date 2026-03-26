# CLAUDE.md 템플릿

> 프로젝트에 axis-kit을 도입할 때, 이 템플릿을 기반으로 CLAUDE.md를 작성한다.
> 프로젝트 특성에 맞게 수정해서 사용할 것.

---

```markdown
# {프로젝트명}

{프로젝트 한 줄 설명}

## Language

- Claude는 사용자에게 항상 **{언어}**로 응답한다.

## AXIS Engineering

이 프로젝트는 AXIS Engineering 방법론을 따른다.

### Commands
| 커맨드 | 설명 |
|--------|------|
| `/xv "질문"` | 멀티 AI 교차검증 |
| `/plan 기능명` | CPS Plan 문서 작성 |
| `/design 기능명` | CPS Design 문서 작성 |
| `/gap 설계.md 코드/` | 역방향 검증 |
| `/review 코드` | 코드 리뷰 |

### Workflow
```
기능 요청 → /plan → /xv (필요시) → /design → 구현 → /gap → /review
```

### 합의 프로토콜
- 90%+ → 자동 채택
- 70~89% → 사람 판단
- 70% 미만 → 재정의 필요

## Tech Stack

- {프레임워크}: {버전}
- {언어}: {버전}
- {DB}: {버전}

## Project Structure

```
{프로젝트 루트}/
├── src/              # 소스 코드
├── docs/
│   ├── plans/        # CPS Plan 문서
│   ├── designs/      # CPS Design 문서
│   ├── decisions/    # 의사결정 기록 (ADR)
│   ├── verifications/ # 교차검증 결과
│   └── templates/    # 문서 템플릿
├── scripts/          # AXIS 스크립트
└── .env              # API 키 (git 추적 금지)
```

## Conventions

### Naming
- {파일명 규칙}
- {변수명 규칙}
- {컴포넌트 규칙}

### Git
```
feat: 새 기능      | fix: 버그 수정
update: 기능 개선  | docs: 문서 변경
refactor: 리팩토링 | chore: 설정/기타
```

## Human-AI Boundary

| 영역 | AI 담당 | 인간 담당 |
|------|---------|----------|
| 코드 생성 | 초안 작성, 패턴 적용 | 아키텍처 결정, 비즈니스 판단 |
| 검증 | 자동 테스트, 갭 탐지 | 최종 승인, 엣지 케이스 판단 |
| 규칙 관리 | 패턴 감지, 규칙 제안 | 승인/거부, 방향성 결정 |
| 문서화 | 초안 생성, 동기화 유지 | 의도/맥락 기술 |

## Credentials

- **절대 git 커밋 금지**: `.env`, `.secret/`, `*.pem`, `*accessKeys*`
```

---

## 사용법

1. 이 템플릿을 프로젝트 루트에 `CLAUDE.md`로 복사
2. `{중괄호}` 부분을 프로젝트에 맞게 수정
3. Tech Stack, Conventions, Project Structure를 실제에 맞게 채움
4. 필요 없는 섹션은 삭제 (경량 원칙)

## 필수 섹션 vs 선택 섹션

| 섹션 | 필수 | 이유 |
|------|------|------|
| Language | ✅ | AI 응답 언어 통일 |
| AXIS Engineering | ✅ | 방법론 커맨드 인식 |
| Tech Stack | ✅ | 기술 맥락 제공 |
| Conventions | ✅ | 일관성 (멱등성 핵심) |
| Human-AI Boundary | ✅ | AI 독단 방지 |
| Credentials | ✅ | 보안 사고 방지 |
| Project Structure | 선택 | 복잡한 프로젝트에서 유용 |
