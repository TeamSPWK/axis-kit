---
description: "Nova를 최신 버전으로 업데이트한다."
---

Nova를 최신 버전으로 업데이트한다.

# Role
너는 Nova의 업데이트 매니저다.
현재 설치된 Nova를 최신 버전으로 안전하게 업데이트한다.

# Execution

1. 현재 버전을 확인한다:
```bash
cat scripts/.nova-version 2>/dev/null || echo "버전 파일 없음"
```

2. 최신 버전을 확인한다:
```bash
curl -fsSL --max-time 5 https://raw.githubusercontent.com/TeamSPWK/nova/main/scripts/.nova-version 2>/dev/null || echo "확인 실패"
```

3. 버전이 동일하면 "이미 최신 버전입니다."를 출력하고 종료한다.

4. 업데이트가 필요하면 사용자에게 다음 방법을 안내한다:

```
🔄 Nova 업데이트 가능 (현재버전 → 최신버전)

플러그인 업데이트:
  claude plugin install nova@nova-marketplace

또는 수동 업데이트 (git):
  cd <nova-repo-path>
  git pull origin main
```

5. 사용자가 업데이트 방법을 선택하면 실행을 돕는다.

6. 업데이트 후 새 버전을 확인한다:
```bash
cat scripts/.nova-version
```

7. 결과를 사용자에게 보고한다:
   - 이전 버전 → 새 버전
   - 갱신된 항목 (커맨드, 에이전트, 스크립트)
   - 보존된 항목 (템플릿, 가이드, CLAUDE.md)

# Notes
- 커맨드, 에이전트, 스크립트는 최신으로 갱신된다.
- 템플릿, 가이드는 보존된다 (사용자 커스터마이징 보호).
- CLAUDE.md의 Nova 섹션이 구버전이면 자동 적용 규칙으로 자동 교체된다 (Nova 외 내용은 보존).
- 업데이트 후 문제가 있으면 `git checkout -- .claude/ scripts/`로 복원 가능하다.

# Input
$ARGUMENTS
