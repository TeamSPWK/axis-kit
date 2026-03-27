# [Rule Proposal] 공통 쉘 프리앰블 분리

> AXIS Engineering — Adaptive Rule Proposal
> 날짜: 2026-03-27
> 상태: 제안됨
> 제안자: AI

---

## 감지 (Detect)

### 발견된 패턴
모든 스크립트(5개)가 동일한 색상 변수 블록을 각각 선언하고 있다.
또한 `SCRIPT_DIR`/`ROOT_DIR`/`ENV_FILE` 경로 해석, `.env` 로드, 의존성 검사(`jq`, `curl`) 코드가 2~3개 파일에서 동일하게 반복된다.

### 발생 빈도
- 색상 변수 선언: **5회** (install.sh, x-verify.sh, gap-check.sh, init.sh, test-scripts.sh)
- 경로 해석 (SCRIPT_DIR/ROOT_DIR): **3회** (x-verify.sh, gap-check.sh, test-scripts.sh)
- .env 로드: **2회** (x-verify.sh, gap-check.sh)
- 의존성 검사 (jq/curl): **2회** (x-verify.sh, gap-check.sh) — 에러 메시지까지 동일

### 증거
```bash
# 색상 — 5개 파일에서 동일
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 경로 — 3개 파일에서 동일
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

# 의존성 검사 — 2개 파일에서 동일
for cmd in jq curl; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}ERROR: '${BOLD}$cmd${NC}${RED}'이 설치되어 있지 않습니다.${NC}"
```

---

## 제안 (Propose)

### 규칙 내용
`scripts/lib/common.sh`를 만들어 공통 코드를 분리한다:
- 색상 변수
- 경로 해석 (`SCRIPT_DIR`, `ROOT_DIR`, `ENV_FILE`)
- `.env` 로드 함수
- 의존성 검사 함수 (`require_commands jq curl`)

각 스크립트에서 `source "$(dirname "$0")/lib/common.sh"` 또는 `source "${SCRIPT_DIR}/lib/common.sh"`로 로드한다.

### 적용 범위
- 적용 대상: `scripts/*.sh`, `install.sh`, `tests/*.sh`
- 강제 수준: **가이드라인** — 새 스크립트 추가 시 common.sh를 source할 것을 권장

### 기대 효과
- 색상/경로 변경 시 1곳만 수정
- 새 스크립트 작성 시 보일러플레이트 감소
- 에러 메시지 일관성 자동 보장

### 주의
- `install.sh`는 원격 실행(`curl | bash`)되므로 common.sh를 source할 수 없다. install.sh는 예외로 유지.
- 스크립트가 5개 수준이므로 현 시점에서는 **시기상조**일 수 있다. 스크립트가 7개 이상으로 늘어나면 적용을 권장한다.

---

## 승인 (Approve)

> 아래는 사람이 작성

- [x] 승인
- [ ] 수정 후 승인 (수정 내용: )
- [ ] 기각 (사유: )
- [ ] 보류 — 스크립트 7개 이상 시 재검토

승인자: jay
승인일: 2026-03-27

---

## 적용 (Apply)

> 승인 후 작성

- 반영 위치: `scripts/lib/common.sh` 생성, 각 스크립트에 source 추가
- 반영 커밋:

## 검증 (Verify)

- 기존 코드 충돌: 없음 (추가 분리만)
- 적용 후 문제: install.sh 원격 실행에서 common.sh 부재 — 예외 처리 필요
