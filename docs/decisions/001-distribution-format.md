# [Decision] 배포 형태: 간편 설치 스크립트 + 로컬 소유

> Nova Engineering — Decision Record
> 날짜: 2026-03-26
> 상태: 승인됨

---

## Context (배경)

Nova 사용자가 늘어나면서 설치 편의성이 중요해짐. 현재는 git clone → cp 수동 복사.

## Problem (문제)

쉬운 설치(npm install 수준)와 Nova 철학("내 것으로 만드는 도구", 수정 자유)을 동시에 만족하는 배포 형태는?

## Decision (결정)

**원격 설치 스크립트** 방식 채택.

```bash
# 한 줄 설치
curl -fsSL https://raw.githubusercontent.com/TeamSPWK/nova/main/install.sh | bash
```

- 스크립트가 repo에서 파일을 다운로드하여 현재 디렉토리에 복사
- 복사 후 파일은 완전히 사용자 소유 (패키지 매니저 의존 없음)
- npm/brew 패키지로는 가지 않음

### 대안 비교

| 기준 | 설치 스크립트 (채택) | npm 패키지 | 순수 cp |
|------|-------------------|-----------|---------|
| 설치 편의성 | ✅ 한 줄 | ✅ 한 줄 | ❌ 여러 줄 |
| 수정 자유 | ✅ 로컬 파일 | ⚠️ node_modules | ✅ 로컬 파일 |
| 인프라 부담 | ✅ GitHub만 | ❌ npm 계정, CI | ✅ 없음 |
| 업데이트 | ✅ 재실행 | ✅ npm update | ❌ 수동 |

## Consequences (결과)

### 긍정적
- 한 줄 설치로 진입 장벽 제거
- Nova 철학 유지 — 설치 후 완전 로컬 소유
- npm/brew 의존 없음

### 부정적
- 사용자가 curl | bash를 꺼릴 수 있음 → git clone도 병행 안내

## X-Verification (교차 검증)

합의율: 60% → 판정: HUMAN REVIEW
- Claude/GPT: 하이브리드(패키지+로컬) 선호
- Gemini: git clone 유지, 간편 스크립트 보완 선호
- 최종 판단: 패키지 매니저 없이 설치 스크립트로 타협 (Gemini 쪽에 가까움)
