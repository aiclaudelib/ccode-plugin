#!/bin/bash
set -euo pipefail
# validate-agent.sh — Validate agent .md files for correct structure and content
# Checks frontmatter, required fields, name format, description, system prompt

# Usage
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <path/to/agent.md>"
  echo ""
  echo "Validates agent file for:"
  echo "  - YAML frontmatter structure"
  echo "  - Required fields (name, description, model, color)"
  echo "  - Name format and length (3-50 chars, alphanumeric + hyphens)"
  echo "  - Description quality"
  echo "  - System prompt presence and length"
  exit 1
fi

AGENT_FILE="$1"

echo "Validating agent file: $AGENT_FILE"
echo ""

# Check 1: File exists
if [[ ! -f "$AGENT_FILE" ]]; then
  echo "ERROR: File not found: $AGENT_FILE" >&2
  exit 1
fi
echo "  [ok] File exists"

# Check 2: Starts with ---
FIRST_LINE=$(head -1 "$AGENT_FILE")
if [[ "$FIRST_LINE" != "---" ]]; then
  echo "  [FAIL] File must start with YAML frontmatter (---)" >&2
  exit 1
fi
echo "  [ok] Starts with frontmatter"

# Check 3: Has closing ---
if ! tail -n +2 "$AGENT_FILE" | grep -q '^---$'; then
  echo "  [FAIL] Frontmatter not closed (missing second ---)" >&2
  exit 1
fi
echo "  [ok] Frontmatter properly closed"

# Extract frontmatter and system prompt
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$AGENT_FILE")
SYSTEM_PROMPT=$(awk '/^---$/{i++; next} i>=2' "$AGENT_FILE")

# Check 4: Required fields
echo ""
echo "Checking required fields..."

error_count=0
warning_count=0

# Check name field
NAME=$(echo "$FRONTMATTER" | grep '^name:' | sed 's/name: *//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\\(.*\\)'$/\\1/" || true)

if [[ -z "$NAME" ]]; then
  echo "  [FAIL] Missing required field: name"
  ((error_count++)) || true
else
  echo "  [ok] name: $NAME"

  # Validate name format
  if ! [[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]; then
    echo "  [FAIL] name must start/end with alphanumeric, contain only letters, numbers, hyphens"
    ((error_count++)) || true
  fi

  # Validate name length
  name_length=${#NAME}
  if [[ $name_length -lt 3 ]]; then
    echo "  [FAIL] name too short (minimum 3 characters)"
    ((error_count++)) || true
  elif [[ $name_length -gt 50 ]]; then
    echo "  [FAIL] name too long (maximum 50 characters)"
    ((error_count++)) || true
  fi

  # Check for generic names
  if [[ "$NAME" =~ ^(helper|assistant|agent|tool)$ ]]; then
    echo "  [WARN] name is too generic: $NAME"
    ((warning_count++)) || true
  fi
fi

# Check description field
DESCRIPTION=$(echo "$FRONTMATTER" | grep '^description:' | sed 's/description: *//' || true)

if [[ -z "$DESCRIPTION" ]]; then
  echo "  [FAIL] Missing required field: description"
  ((error_count++)) || true
else
  desc_length=${#DESCRIPTION}
  echo "  [ok] description: ${desc_length} characters"

  if [[ $desc_length -lt 10 ]]; then
    echo "  [WARN] description too short (minimum 10 characters recommended)"
    ((warning_count++)) || true
  elif [[ $desc_length -gt 5000 ]]; then
    echo "  [WARN] description very long (over 5000 characters)"
    ((warning_count++)) || true
  fi
fi

# Check model field
MODEL=$(echo "$FRONTMATTER" | grep '^model:' | sed 's/model: *//' || true)

if [[ -z "$MODEL" ]]; then
  echo "  [FAIL] Missing required field: model"
  ((error_count++)) || true
else
  echo "  [ok] model: $MODEL"

  case "$MODEL" in
    inherit|sonnet|opus|haiku)
      ;;
    *)
      echo "  [WARN] Unknown model: $MODEL (valid: inherit, sonnet, opus, haiku)"
      ((warning_count++)) || true
      ;;
  esac
fi

# Check color field (optional)
COLOR=$(echo "$FRONTMATTER" | grep '^color:' | sed 's/color: *//' || true)

if [[ -n "$COLOR" ]]; then
  echo "  [ok] color: $COLOR"

  case "$COLOR" in
    blue|cyan|green|yellow|magenta|red)
      ;;
    *)
      echo "  [WARN] Unknown color: $COLOR (valid: blue, cyan, green, yellow, magenta, red)"
      ((warning_count++)) || true
      ;;
  esac
else
  echo "  [info] color: not specified (optional)"
fi

# Check tools field (optional)
TOOLS=$(echo "$FRONTMATTER" | grep '^tools:' | sed 's/tools: *//' || true)

if [[ -n "$TOOLS" ]]; then
  echo "  [ok] tools: $TOOLS"
else
  echo "  [info] tools: not specified (agent has access to all tools)"
fi

# Check 5: System prompt
echo ""
echo "Checking system prompt..."

if [[ -z "$SYSTEM_PROMPT" ]]; then
  echo "  [FAIL] System prompt is empty"
  ((error_count++)) || true
else
  prompt_length=${#SYSTEM_PROMPT}
  echo "  [ok] System prompt: $prompt_length characters"

  if [[ $prompt_length -lt 20 ]]; then
    echo "  [FAIL] System prompt too short (minimum 20 characters)"
    ((error_count++)) || true
  elif [[ $prompt_length -gt 10000 ]]; then
    echo "  [WARN] System prompt very long (over 10,000 characters)"
    ((warning_count++)) || true
  fi

  # Check for second person
  if ! echo "$SYSTEM_PROMPT" | grep -q "You are\|You will\|Your"; then
    echo "  [WARN] System prompt should use second person (You are..., You will...)"
    ((warning_count++)) || true
  fi

  # Check for structure
  if ! echo "$SYSTEM_PROMPT" | grep -qi "responsibilities\|process\|steps"; then
    echo "  [info] Consider adding clear responsibilities or process steps"
  fi
fi

echo ""
echo "========================================"

if [[ $error_count -eq 0 ]] && [[ $warning_count -eq 0 ]]; then
  echo "All checks passed"
  exit 0
elif [[ $error_count -eq 0 ]]; then
  echo "Passed with $warning_count warning(s)"
  exit 0
else
  echo "Failed with $error_count error(s) and $warning_count warning(s)"
  exit 1
fi
