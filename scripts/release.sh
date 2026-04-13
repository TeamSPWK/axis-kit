#!/usr/bin/env bash
# Nova 릴리스 스크립트
# 커밋 → 리뷰 → 버전 범프 → 태그 → 푸시 → GitHub 릴리스를 한 명령으로 실행.
#
# 사용법:
#   bash scripts/release.sh patch "커밋 메시지"
#   bash scripts/release.sh minor "커밋 메시지"
#   bash scripts/release.sh major "커밋 메시지"
#
# 예시:
#   bash scripts/release.sh minor "feat: Coverage Gate + Learned Rules 추가"

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ── 인자 검증 ──
LEVEL="${1:-}"
COMMIT_MSG="${2:-}"

if [[ -z "$LEVEL" || -z "$COMMIT_MSG" ]]; then
  echo "사용법: bash scripts/release.sh <patch|minor|major> \"커밋 메시지\""
  echo ""
  echo "  patch  — 버그 수정, 문서 정리"
  echo "  minor  — 새 커맨드/스킬 추가, 기존 기능 개선"
  echo "  major  — 호환성 깨지는 변경, 아키텍처 전환"
  exit 1
fi

if [[ ! "$LEVEL" =~ ^(patch|minor|major)$ ]]; then
  echo "❌ 수준은 patch, minor, major 중 하나여야 합니다: $LEVEL"
  exit 1
fi

# ── 상태 확인 ──
if git diff --cached --quiet && git diff --quiet; then
  echo "❌ 커밋할 변경사항이 없습니다."
  exit 1
fi

# ── Step 1: 테스트 ──
echo "━━━ Step 1/6: 테스트 실행 ━━━"
bash tests/test-scripts.sh
echo ""

# ── Step 2: 변경사항 커밋 ──
echo "━━━ Step 2/6: 커밋 ━━━"
# unstaged 파일이 있으면 staged만 커밋
if ! git diff --cached --quiet; then
  git commit -m "$COMMIT_MSG"
else
  git add -A
  git commit -m "$COMMIT_MSG"
fi
echo ""

# ── Step 3: 버전 범프 (nova-meta.json + README 자동 갱신 포함) ──
echo "━━━ Step 3/6: 버전 범프 ━━━"
bash scripts/bump-version.sh "$LEVEL"

# 현재 버전 읽기
NEW_VERSION=$(tr -d '[:space:]' < scripts/.nova-version)
echo ""

# ── Step 4: 범프 파일 커밋 ──
echo "━━━ Step 4/6: 범프 커밋 ━━━"
git add scripts/.nova-version .claude-plugin/plugin.json README.md README.ko.md docs/nova-meta.json
git commit -m "chore(v${NEW_VERSION}): 버전 범프"
echo ""

# ── Step 5: 태그 + 푸시 ──
echo "━━━ Step 5/6: 태그 + 푸시 ━━━"
git tag "v${NEW_VERSION}"
git push origin main --tags
echo ""

# ── Step 6: GitHub 릴리스 ──
echo "━━━ Step 6/6: GitHub 릴리스 ━━━"
# 커밋 메시지에서 릴리스 제목 추출 (prefix 제거)
TITLE=$(echo "$COMMIT_MSG" | sed 's/^[a-z]*: //' | sed 's/^[a-z]*(.*): //')
gh release create "v${NEW_VERSION}" \
  --title "v${NEW_VERSION} — ${TITLE}" \
  --notes "${COMMIT_MSG}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 릴리스 완료: v${NEW_VERSION}"
echo "  📦 landing 자동 동기화가 트리거됩니다"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
