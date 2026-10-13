#!/usr/bin/env bash
# validate-governance.sh
# Runs governance validation tests (skills, checklists, agents).
# Exit 0 = pass, 1 = fail.
# Discoverable by: cursor-governance validate (when wired to this script).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../tests/helpers/stack-root.sh"
if [ -z "${STACK_ROOT:-}" ]; then
  echo "Failed to resolve STACK_ROOT"
  exit 1
fi

EXIT_CODE=0
QUIET=false
[ "${1:-}" = "--quiet" ] || [ "${1:-}" = "-q" ] && QUIET=true

say() { $QUIET || echo "$@"; }
log_pass() { say "[PASS] $1"; }
log_fail() { say "[FAIL] $1"; EXIT_CODE=1; }

# ---- Skills: referenced checklists must exist ----
run_skill_references() {
  say "[CHECK] governance/skills: skill-references"
  local failed=0
  for f in "$STACK_ROOT/skills/"*.yml; do
    [ -f "$f" ] || continue
    local base
    base=$(basename "$f")
    while IFS= read -r line; do
      line=$(echo "$line" | sed 's/^[[:space:]]*//')
      [[ "$line" =~ ^- ]] || continue
      line=${line#- }
      line=$(echo "$line" | tr -d '"'"'")
      if [[ "$line" == checklists/*.yml ]] || [[ "$line" =~ ^checklists/[a-zA-Z0-9_.-]+\.yml$ ]]; then
        local path="$STACK_ROOT/$line"
        if [ ! -f "$path" ]; then
          log_fail "skill $base references missing checklist: $line"
          failed=1
        fi
      fi
    done < <(grep -E '^\s*-\s+checklists/' "$f" 2>/dev/null || true)
  done
  [ $failed -eq 0 ] && [ $EXIT_CODE -eq 0 ] && log_pass "skill-references"
}

# ---- Checklists: must have id, domain, steps (non-empty) ----
run_checklist_structure() {
  say "[CHECK] governance/checklists: checklist-structure"
  local failed=0
  for f in "$STACK_ROOT/checklists/"*.yml; do
    [ -f "$f" ] || continue
    local base
    base=$(basename "$f")
    grep -q '^id:' "$f" 2>/dev/null || { log_fail "checklist $base missing id"; failed=1; }
    grep -q '^domain:' "$f" 2>/dev/null || { log_fail "checklist $base missing domain"; failed=1; }
    if grep -q '^steps:' "$f" 2>/dev/null; then
      if ! grep -A 200 '^steps:' "$f" | grep -qE '^\s+-\s+'; then
        if ! grep -q '^steps_contract:' "$f" 2>/dev/null; then
          log_fail "checklist $base has empty steps and no steps_contract"
          failed=1
        fi
      fi
    elif grep -q '^steps_contract:' "$f" 2>/dev/null; then
      if ! grep -A 200 '^steps_contract:' "$f" | grep -qE '^\s+-\s+'; then
        log_fail "checklist $base has empty steps_contract"
        failed=1
      fi
    else
      log_fail "checklist $base missing steps or steps_contract"
      failed=1
    fi
  done
  [ $failed -eq 0 ] && [ $EXIT_CODE -eq 0 ] && log_pass "checklist-structure"
}

# ---- Agents: referenced skills must exist ----
run_agent_skill_references() {
  say "[CHECK] governance/agents: agent-skill-references"
  local failed=0
  for f in "$STACK_ROOT/agents/"*.yml; do
    [ -f "$f" ] || continue
    local base
    base=$(basename "$f")
    while IFS= read -r line; do
      line=$(echo "$line" | sed 's/^[[:space:]]*//')
      [[ "$line" =~ ^- ]] || continue
      line=${line#- }
      line=$(echo "$line" | tr -d '"'"'")
      if [[ "$line" == skills/*.yml ]] || [[ "$line" =~ ^skills/[a-zA-Z0-9_.-]+\.yml$ ]]; then
        local path="$STACK_ROOT/$line"
        if [ ! -f "$path" ]; then
          log_fail "agent $base references missing skill: $line"
          failed=1
        fi
      fi
    done < <(grep -E '^\s*-\s+skills/' "$f" 2>/dev/null || true)
  done
  [ $failed -eq 0 ] && [ $EXIT_CODE -eq 0 ] && log_pass "agent-skill-references"
}

# Run all governance validations
run_skill_references
run_checklist_structure
run_agent_skill_references

exit $EXIT_CODE
