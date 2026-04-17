#!/usr/bin/env bash
# Nova — Worktree Setup Hook (환경 기둥)
#
# git worktree 진입 시 메인 레포의 환경 파일·시크릿을 자동 연결한다.
# SessionStart 훅으로 매 세션 시작 시 멱등하게 실행.
#
# 기본 링크 대상: .env, .env.local, .env.development, .secret/, .npmrc
# 오버라이드: 프로젝트 루트에 .claude/worktree-sync.json 배치
#
# 지원 환경변수:
#   CONDUCTOR_ROOT_PATH — Conductor가 제공하는 메인 레포 경로
#   NOVA_WORKTREE_DEBUG=1 — 상세 로그 출력
#
# 종료 코드: 항상 0 (세션 시작을 절대 막지 않는다)

set -uo pipefail

WORKTREE_ROOT="$(pwd)"

log() {
  [ "${NOVA_WORKTREE_DEBUG:-0}" = "1" ] && echo "[nova:worktree-setup] $*" >&2
  return 0
}

# ── 메인 레포 감지 ──
MAIN_REPO="${CONDUCTOR_ROOT_PATH:-}"

if [ -z "$MAIN_REPO" ]; then
  if ! git -C "$WORKTREE_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    log "git 레포 아님 — skip"
    exit 0
  fi
  # `git worktree list`의 첫 줄이 메인 레포(bare 제외)
  MAIN_REPO=$(git -C "$WORKTREE_ROOT" worktree list 2>/dev/null | awk 'NR==1{print $1}')
fi

if [ -z "$MAIN_REPO" ]; then
  log "메인 레포 감지 실패 — skip"
  exit 0
fi

# ── 현재 디렉토리가 메인 레포면 작업 불필요 ──
WORKTREE_REAL=$(cd "$WORKTREE_ROOT" 2>/dev/null && pwd) || exit 0
MAIN_REAL=$(cd "$MAIN_REPO" 2>/dev/null && pwd) || exit 0

if [ "$MAIN_REAL" = "$WORKTREE_REAL" ]; then
  log "메인 레포에서 실행 — skip"
  exit 0
fi

# ── 링크 대상 결정 ──
DEFAULT_TARGETS=(".env" ".env.local" ".env.development" ".secret" ".npmrc")
TARGETS=()

OVERRIDE_FILE="$MAIN_REAL/.claude/worktree-sync.json"
if [ -f "$OVERRIDE_FILE" ] && command -v jq >/dev/null 2>&1; then
  # links 배열이 있으면 오버라이드, 없으면 기본값 사용
  MAPFILE_ITEMS=$(jq -r '.links[]? // empty' "$OVERRIDE_FILE" 2>/dev/null)
  if [ -n "$MAPFILE_ITEMS" ]; then
    while IFS= read -r item; do
      [ -n "$item" ] && TARGETS+=("$item")
    done <<< "$MAPFILE_ITEMS"
    log "오버라이드 적용 (${#TARGETS[@]}개 항목)"
  fi
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  TARGETS=("${DEFAULT_TARGETS[@]}")
fi

# ── 링크 수행 (멱등) ──
LINKED=()
BROKEN=()
for item in "${TARGETS[@]}"; do
  # 상대 경로만 허용 (외부 경로 주입 방지)
  # 1) 절대 경로 차단  2) 경로 세그먼트가 ".." 인 경우만 차단 (파일명의 ".." 문자열은 허용)
  case "$item" in
    /*) log "경로 무시(절대 경로): $item"; continue ;;
  esac
  if [[ "/$item/" == *"/../"* ]] || [ "$item" = ".." ]; then
    log "경로 무시(상위 이동 세그먼트): $item"
    continue
  fi

  SRC="$MAIN_REAL/$item"
  DST="$WORKTREE_REAL/$item"

  # 깨진 심링크 감지가 "메인에 없음" 체크보다 먼저 와야 한다.
  # 메인 파일이 삭제되면서 링크가 깨지는 케이스를 잡아야 하기 때문.
  if [ -L "$DST" ] && [ ! -e "$DST" ]; then
    log "깨진 심링크 감지: $item"
    BROKEN+=("$item")
    continue
  fi

  # 메인에 없으면 건너뜀
  [ -e "$SRC" ] || { log "메인에 없음: $item"; continue; }

  # worktree에 이미 뭔가 있으면 (심링크/파일/디렉토리) 건너뜀
  if [ -e "$DST" ] || [ -L "$DST" ]; then
    log "이미 존재: $item"
    continue
  fi

  # 부모 디렉토리 보장 (예: config/secrets.json 같은 중첩 경로)
  PARENT=$(dirname "$DST")
  [ -d "$PARENT" ] || mkdir -p "$PARENT" 2>/dev/null || continue

  if ln -s "$SRC" "$DST" 2>/dev/null; then
    LINKED+=("$item")
  fi
done

if [ "${#LINKED[@]}" -gt 0 ]; then
  echo "🔗 Nova worktree-setup: ${#LINKED[@]}개 링크 (${LINKED[*]:-})" >&2
fi
if [ "${#BROKEN[@]}" -gt 0 ]; then
  echo "⚠️  Nova worktree-setup: 깨진 심링크 ${#BROKEN[@]}개 (${BROKEN[*]:-}) — 수동 확인 필요 (/nova:worktree-setup --dry-run 또는 readlink로 대상 경로 점검)" >&2
fi

exit 0
