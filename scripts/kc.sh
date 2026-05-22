#!/usr/bin/env bash
# kc.sh — Krīḍā commit helper
#
# Enforces the 3-message commit format defined in kreedah/skills/SKILL-core.md §6:
#
#   chkpt: NNN | [major_type]
#
#   <device>
#
#   <explanation>
#
# Usage:
#   ./scripts/kc.sh <major_type> "<explanation>"
#
# Allowed major_type values:
#   feat      new feature or capability
#   fix       bug fix
#   refactor  code restructuring with no behavior change
#   docs      documentation only
#   pitfall   adding an entry to the pitfalls log
#   phase     phase transition or roadmap milestone
#   chore     tooling, config, dependencies, build, CI
#
# Checkpoint number is per-repo, monotonically increasing, zero-padded to 3 digits.
# Auto-incremented by reading the last commit's subject in the current repo.
#
# Device is auto-detected from hostname. Override with KREEDAH_DEVICE env var.

set -euo pipefail

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------
if [[ $# -ne 2 ]]; then
  echo "Error: expected 2 arguments, got $#." >&2
  echo "Usage: $0 <major_type> \"<explanation>\"" >&2
  echo "Run '$0 --help' for details." >&2
  exit 1
fi

MAJOR_TYPE="$1"
EXPLANATION="$2"

ALLOWED_TYPES=("feat" "fix" "refactor" "docs" "pitfall" "phase" "chore")
VALID=0
for t in "${ALLOWED_TYPES[@]}"; do
  if [[ "$MAJOR_TYPE" == "$t" ]]; then
    VALID=1
    break
  fi
done

if [[ $VALID -eq 0 ]]; then
  echo "Error: invalid major_type '$MAJOR_TYPE'." >&2
  echo "Allowed: ${ALLOWED_TYPES[*]}" >&2
  exit 1
fi

if [[ -z "$EXPLANATION" ]]; then
  echo "Error: explanation cannot be empty." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Verify we're in a git repo with staged changes
# ---------------------------------------------------------------------------
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

if git diff --cached --quiet; then
  echo "Error: no staged changes to commit. Run 'git add' first." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Determine next checkpoint number
# ---------------------------------------------------------------------------
LAST_SUBJECT=""
if git rev-parse HEAD >/dev/null 2>&1; then
  LAST_SUBJECT="$(git log -1 --pretty=%s 2>/dev/null || true)"
fi

# Parse "chkpt: NNN | [...]" from the last subject; default to -1 so next is 000.
LAST_NUM=-1
if [[ "$LAST_SUBJECT" =~ ^chkpt:\ ([0-9]+)\ \| ]]; then
  # Strip leading zeros for arithmetic (base 10 explicit to avoid octal issues).
  LAST_NUM=$((10#${BASH_REMATCH[1]}))
fi

NEXT_NUM=$((LAST_NUM + 1))
CHKPT="$(printf "%03d" "$NEXT_NUM")"

# ---------------------------------------------------------------------------
# Determine device
# ---------------------------------------------------------------------------
if [[ -n "${KREEDAH_DEVICE:-}" ]]; then
  DEVICE="$KREEDAH_DEVICE"
elif [[ "$(uname)" == "Darwin" ]] && command -v scutil >/dev/null 2>&1; then
  DEVICE="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
else
  DEVICE="$(hostname -s 2>/dev/null || hostname)"
fi

# ---------------------------------------------------------------------------
# Build the three messages and commit
# ---------------------------------------------------------------------------
SUBJECT="chkpt: ${CHKPT} | [${MAJOR_TYPE}]"

git commit \
  -m "$SUBJECT" \
  -m "$DEVICE" \
  -m "$EXPLANATION"

echo ""
echo "✓ Committed: ${SUBJECT}"
echo "  device:    ${DEVICE}"
echo "  message:   ${EXPLANATION}"
