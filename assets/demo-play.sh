#!/usr/bin/env bash
# Nova demo — /nova:check catches a hardcoded JWT secret.
# Played back inside asciinema. All output is scripted for deterministic demo.

set -u
export PS1='$ '

# Colors
BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
PURPLE=$'\033[35m'
BLUE=$'\033[34m'
RESET=$'\033[0m'

# Type command character by character (simulates typing)
type_cmd() {
  local cmd="$1"
  local delay="${2:-0.04}"
  printf "${GREEN}$ ${RESET}"
  for (( i=0; i<${#cmd}; i++ )); do
    printf "%s" "${cmd:$i:1}"
    sleep "$delay"
  done
  printf "\n"
  sleep 0.3
}

pause() { sleep "${1:-0.5}"; }

clear

# ── Scene 1: the problem ─────────────────────────────────
type_cmd "cat src/auth/login.ts"
cat <<'EOF'
export async function login(email: string, password: string) {
  const jwt_secret_key = "hardcoded-super-secret-1234";
  return signJwt({ email }, jwt_secret_key);
}
EOF
pause 1.2

# ── Scene 2: invoke Nova ────────────────────────────────
type_cmd "claude" 0.05
pause 0.3
printf "${DIM}Claude Code v2.1.119 • Nova v5.19.4 loaded${RESET}\n"
pause 0.8
printf "${PURPLE}>${RESET} "
pause 0.4
type_cmd "/nova:review src/auth/login.ts" 0.03
pause 0.6

printf "${DIM}⎯ Nova Review • Independent adversarial evaluator (subagent)${RESET}\n"
pause 0.6
printf "${CYAN}→${RESET} Spawning evaluator subagent (isolated context)…\n"
pause 1.2
printf "${CYAN}→${RESET} Loading 5-dimension verification criteria\n"
pause 0.5
printf "  ${DIM}functionality · data flow · design alignment · craft · boundary${RESET}\n"
pause 1.0
printf "${CYAN}→${RESET} Static analysis: string literals in security context\n"
pause 1.5
printf "\n"

# ── Scene 3: the catch ──────────────────────────────────
printf "${BOLD}${RED}█ Hard-Block detected${RESET}\n"
printf "${DIM}────────────────────────────────────────────────────${RESET}\n"
printf "${RED}✗${RESET} ${BOLD}src/auth/login.ts:2${RESET}  ${YELLOW}jwt_secret_key hardcoded${RESET}\n"
printf "    ${DIM}'hardcoded-super-secret-1234'${RESET}\n"
printf "    ${DIM}→ Secret must come from env var (process.env.JWT_SECRET)${RESET}\n"
printf "    ${DIM}→ Category: Security / Hard-Block${RESET}\n"
printf "\n"
pause 1.0

printf "${BOLD}Verdict: ${RED}FAIL${RESET}\n"
printf "  ${DIM}1 Hard-Block · 0 Soft-Block · 0 Auto-Resolve${RESET}\n"
printf "  ${DIM}Commit will be blocked at pre-commit gate${RESET}\n"
pause 1.4

# ── Scene 4: attempt to commit ──────────────────────────
printf "\n"
printf "${PURPLE}>${RESET} "
pause 0.5
type_cmd "git commit -m \"feat: login\"" 0.03
pause 0.3
printf "${RED}✗ COMMIT BLOCKED${RESET} ${DIM}(Nova pre-commit hook)${RESET}\n"
printf "${DIM}  NOVA-STATE.md Last Activity verdict is not PASS${RESET}\n"
printf "${DIM}  Fix the Hard-Block and re-run /nova:review to update state${RESET}\n"
pause 2.0

# ── Scene 5: brand ──────────────────────────────────────
printf "\n"
printf "${BOLD}${PURPLE}Nova${RESET}${DIM} — Verify before you ship. Every time.${RESET}\n"
printf "${DIM}  https://github.com/TeamSPWK/nova${RESET}\n"
pause 1.5
