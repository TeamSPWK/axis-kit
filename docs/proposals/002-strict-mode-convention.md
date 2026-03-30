# [Rule Proposal] 쉘 strict 모드 통일

> Nova Engineering — Adaptive Rule Proposal
> 날짜: 2026-03-27
> 상태: 대체됨 (v2.0 플러그인 전환으로 대상 스크립트 삭제됨)
> 제안자: AI

---

## 감지 (Detect)

### 발견된 패턴
스크립트마다 strict 모드 설정이 다르다:
- `set -euo pipefail` (install.sh, x-verify.sh, init.sh) — 3개
- `set -uo pipefail` (gap-check.sh, test-scripts.sh) — 2개

`-e` (errexit) 포함 여부가 일관되지 않아, 어떤 스크립트는 에러 시 즉시 종료되고 어떤 스크립트는 계속 실행된다.

### 발생 빈도
- 5개 스크립트 중 2개가 `-e` 미포함

### 증거
```bash
# install.sh, x-verify.sh, init.sh
set -euo pipefail

# gap-check.sh, test-scripts.sh
set -uo pipefail
```

---

## 제안 (Propose)

### 규칙 내용
**모든 스크립트는 `set -euo pipefail`을 사용한다.**

`-e`를 제외해야 하는 경우(의도적으로 실패를 허용하는 구간)는 해당 라인에서 `|| true`를 사용하거나 `set +e` / `set -e` 블록으로 명시적으로 처리한다.

### 적용 범위
- 적용 대상: `scripts/*.sh`, `install.sh`, `tests/*.sh`
- 강제 수준: **가이드라인** — 새 스크립트 작성 시 필수, 기존 스크립트는 점진 적용

### 기대 효과
- 예상치 못한 에러가 조용히 무시되는 상황 방지
- 디버깅 용이성 향상

---

## 승인 (Approve)

> 아래는 사람이 작성

- [x] 승인
- [ ] 수정 후 승인 (수정 내용: )
- [ ] 기각 (사유: )

승인자: jay
승인일: 2026-03-27

---

## 적용 (Apply)

> 승인 후 작성

- 반영 위치: gap-check.sh `set -uo` → `set -euo`. test-scripts.sh는 assert 특성상 `-e` 제외 유지 (주석으로 사유 명시)
- 반영 커밋:

## 검증 (Verify)

- 기존 코드 충돌: gap-check.sh에서 `-e` 추가 시 curl 실패가 스크립트 종료로 이어질 수 있음 — JSON 파싱 실패 구간에 `|| true` 추가 필요
- 적용 후 문제: test-scripts.sh에서 assert 함수 내 eval 실패가 전체 종료로 이어질 수 있음 — assert 내 `|| true` 이미 존재하므로 영향 없음
