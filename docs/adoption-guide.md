# AXIS Kit 도입 가이드

> 신규 프로젝트와 기존 프로젝트, 각각의 상황에 맞는 도입 방법

---

## 신규 프로젝트 도입

처음부터 AXIS를 적용하는 경우. 가장 간단합니다.

```bash
# 1. axis-kit에서 복사
cp -r axis-kit/.claude/commands/ your-project/.claude/commands/
cp -r axis-kit/scripts/ your-project/scripts/
cp -r axis-kit/docs/templates/ your-project/docs/templates/

# 2. 초기화
cd your-project
bash scripts/init.sh 프로젝트명 "Next.js + TypeScript"

# 3. .env에 API 키 설정
cat > .env << 'EOF'
ANTHROPIC_API_KEY="your-key"
OPENAI_API_KEY="your-key"
GEMINI_API_KEY="your-key"
EOF

# 4. 시작
/next  # 다음 할 일 확인
```

---

## 기존 프로젝트 도입 (비파괴적)

이미 CLAUDE.md, 컨벤션, 디렉토리 구조가 있는 프로젝트에 AXIS를 도입하는 경우.

### 원칙: 기존 설정을 존중한다

- **덮어쓰지 않는다** — 기존 CLAUDE.md를 교체하지 않고 섹션을 추가
- **충돌하지 않는다** — 기존 컨벤션/린터 규칙과 공존
- **점진적으로 적용한다** — 한 번에 전부가 아니라, 필요한 것부터

### Step 1: 커맨드와 스크립트만 복사

```bash
# 커맨드 복사 (기존 .claude/commands/에 추가)
cp axis-kit/.claude/commands/*.md your-project/.claude/commands/

# 스크립트 복사
cp axis-kit/scripts/*.sh your-project/scripts/
chmod +x your-project/scripts/*.sh

# 템플릿 복사
mkdir -p your-project/docs/templates
cp axis-kit/docs/templates/*.md your-project/docs/templates/
```

이것만으로 `/plan`, `/xv`, `/gap`, `/review`, `/next` 등을 바로 사용할 수 있습니다.

### Step 2: 기존 CLAUDE.md에 AXIS 섹션 추가

기존 CLAUDE.md를 **교체하지 않고**, 아래 섹션만 추가합니다:

```markdown
## AXIS Engineering

이 프로젝트는 AXIS Engineering 방법론을 따른다.

### Commands
| 커맨드 | 설명 |
|--------|------|
| `/next` | 다음 할 일 추천 |
| `/plan 기능명` | CPS Plan 문서 작성 |
| `/xv "질문"` | 멀티 AI 교차검증 |
| `/design 기능명` | CPS Design 문서 작성 |
| `/gap 설계.md 코드/` | 역방향 검증 |
| `/review 코드` | 코드 리뷰 |
| `/propose 패턴` | 규칙 제안 |
| `/metrics` | 도입 수준 측정 |

### 합의 프로토콜
- 90%+ → 자동 채택
- 70~89% → 사람 판단
- 70% 미만 → 재정의 필요
```

### Step 3: docs 디렉토리 확장 (선택)

기존 docs 구조가 있다면, 충돌하지 않게 AXIS용 하위 디렉토리만 추가합니다:

```bash
# 이미 docs/가 있는 경우
mkdir -p docs/plans docs/designs docs/decisions docs/verifications
```

기존 `docs/architecture.md`, `docs/api.md` 등은 그대로 유지됩니다.

### Step 4: .gitignore 추가 (선택)

AXIS 산출물 중 개인/프로젝트별 파일이 커밋되지 않도록:

```gitignore
# AXIS Engineering (사용자별 산출물)
docs/plans/
docs/designs/
docs/verifications/
```

> 주의: 팀 공유가 필요하면 이 항목을 제거하세요.

### Step 5: /metrics로 현황 확인

```
/metrics
```

현재 프로젝트가 AXIS의 어느 수준인지 자동 측정합니다. 부족한 부분부터 점진적으로 채워나가면 됩니다.

---

## 도입 수준별 전략

### 최소 도입 (커맨드만)
- `.claude/commands/` + `scripts/` 복사
- CLAUDE.md에 AXIS 섹션 추가
- 효과: `/xv`, `/gap`, `/next` 바로 사용 가능

### 표준 도입 (문서 체계 포함)
- 최소 도입 + `docs/templates/` 복사
- `docs/` 하위 디렉토리 생성
- 효과: CPS 문서 작성, 의사결정 기록, 컨텍스트 복원

### 전체 도입 (방법론 완전 적용)
- 표준 도입 + `docs/axis-engineering.md`, `docs/context-chain.md`, `docs/eval-checklist.md` 복사
- `/metrics` 기반 정기 평가 루틴 설정
- 효과: AXIS 4 Pillars 전체 운영

---

## 기존 CLAUDE.md와의 공존 패턴

### 패턴 A: 섹션 추가 (권장)
기존 CLAUDE.md 끝에 `## AXIS Engineering` 섹션을 추가.
기존 내용 전혀 수정하지 않음.

### 패턴 B: 별도 파일
CLAUDE.md는 건드리지 않고, `.claude/commands/` 안의 커맨드로만 AXIS를 사용.
CLAUDE.md에 AXIS 인식이 없어도 커맨드 자체는 동작함.

### 패턴 C: 단계적 마이그레이션
1주차: 커맨드만 사용 (CLAUDE.md 수정 없음)
2주차: AXIS 섹션 추가
3주차: 기존 문서를 CPS 구조로 점진적 전환
4주차: /metrics로 평가, 부족한 부분 보강

---

## FAQ

**Q: 기존 CLAUDE.md의 Convention 섹션이 AXIS와 다른데?**
A: 기존 컨벤션을 유지하세요. AXIS는 특정 컨벤션을 강제하지 않습니다. git 커밋 접두사(feat/fix/...)는 권장 사항이지, 필수가 아닙니다.

**Q: 이미 다른 AI 도구(Cursor Rules 등)를 쓰고 있는데?**
A: 공존 가능합니다. AXIS 커맨드는 `.claude/commands/`에만 있으므로, 다른 도구와 충돌하지 않습니다. 교차검증(`/xv`)은 오히려 다른 도구와 병행하면 효과적입니다.

**Q: 팀원들도 AXIS를 써야 하나?**
A: 선택입니다. 한 사람만 써도 효과가 있습니다. 팀 전체 도입 시에는 CLAUDE.md에 AXIS 섹션을 커밋하면 됩니다.
