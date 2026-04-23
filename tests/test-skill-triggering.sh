#!/usr/bin/env bash
# Nova Skill Triggering Fixture Test
# 각 skills/*/SKILL.md에 대응하는 tests/skill-triggering/prompts/{name}-positive.txt 존재 검증
# 실제 LLM 트리거 검증은 nova:field-test로 수동 수행
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills"
PROMPTS_DIR="$ROOT_DIR/tests/skill-triggering/prompts"

PASS=0
FAIL=0
MISSING=()

for skill_dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$skill_dir")
  fixture="$PROMPTS_DIR/${name}-positive.txt"
  if [[ -f "$fixture" && -s "$fixture" ]]; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    MISSING+=("$name")
  fi
done

echo "[skill-triggering] PASS=$PASS FAIL=$FAIL"
if (( FAIL > 0 )); then
  echo "Missing/empty positive fixtures:"
  printf '  - %s\n' "${MISSING[@]}"
  echo ""
  echo "Add tests/skill-triggering/prompts/<name>-positive.txt for each skill."
  echo "See skills/writing-nova-skill/SKILL.md for the authoring contract."
  exit 1
fi
exit 0
