#!/bin/bash
# PreToolUse hook: block commands that push or rewrite git history.
# Also inspects scripts referenced by the command for the same patterns.
set -euo pipefail

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command' <<< "$INPUT")

# Patterns that push or destructively rewrite git history
PATTERNS=(
  'git\s+push'
  'git\s+rebase'
  'git\s+reset\s+--hard'
  'git\s+commit\s+--amend'
  'git\s+filter-branch'
  'git\s+reflog\s+expire'
)

COMBINED=$(IFS='|'; echo "${PATTERNS[*]}")

check() {
  if grep -qEi "$COMBINED" <<< "$1"; then
    local matched
    matched=$(grep -oEi "$COMBINED" <<< "$1" | head -1)
    echo "Blocked: found '$matched' — this rewrites git history or pushes to remote" >&2
    exit 2
  fi
}

# Check the command itself
check "$COMMAND"

# If the command runs a script, inspect its contents too
for token in $COMMAND; do
  # Skip flags and non-file tokens
  [[ "$token" == -* ]] && continue
  # Resolve relative to CWD from hook input
  CWD=$(jq -r '.cwd // "."' <<< "$INPUT")
  candidate="$token"
  [[ "$candidate" != /* ]] && candidate="$CWD/$candidate"
  if [[ -f "$candidate" ]] && head -1 "$candidate" 2>/dev/null | grep -qE '^#!.*(bash|sh|zsh)'; then
    check "$(cat "$candidate")"
  fi
done

exit 0
