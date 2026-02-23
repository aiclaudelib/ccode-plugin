#!/bin/bash
set -euo pipefail
# validate-agent.sh — Validate agent .md files for correct structure and content
# Checks frontmatter, required fields, name format, description, system prompt
# Exit 2 on errors (feedback to agent), exit 0 on success/warnings

# Usage
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <path/to/agent.md>"
  echo ""
  echo "Validates agent file for:"
  echo "  - YAML frontmatter structure"
  echo "  - Required fields (name, description)"
  echo "  - Optional fields (tools, disallowedTools, model, permissionMode, maxTurns, skills, mcpServers, hooks, memory, background, isolation)"
  echo "  - Name format (lowercase + hyphens)"
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
  exit 2
fi
echo "  [ok] File exists"

# Check 2: Starts with ---
FIRST_LINE=$(head -1 "$AGENT_FILE")
if [[ "$FIRST_LINE" != "---" ]]; then
  echo "  [FAIL] File must start with YAML frontmatter (---)" >&2
  exit 2
fi
echo "  [ok] Starts with frontmatter"

# Check 3: Has closing ---
if ! tail -n +2 "$AGENT_FILE" | grep -q '^---$'; then
  echo "  [FAIL] Frontmatter not closed (missing second ---)" >&2
  exit 2
fi
echo "  [ok] Frontmatter properly closed"

# Extract frontmatter and system prompt
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$AGENT_FILE")
SYSTEM_PROMPT=$(awk '/^---$/{i++; next} i>=2' "$AGENT_FILE")

error_count=0
warning_count=0

# --- Valid frontmatter fields for agents ---
VALID_FIELDS="name description tools disallowedTools model permissionMode maxTurns skills mcpServers hooks memory background isolation"

# Check for unknown top-level fields (skip indented lines which are nested YAML)
FIELD_NAMES=$(echo "$FRONTMATTER" | grep -E "^[a-zA-Z]" | sed 's/:.*//' | tr -d ' ')
for field in $FIELD_NAMES; do
  if ! echo "$VALID_FIELDS" | grep -qw "$field"; then
    echo "  [WARN] Unknown frontmatter field: '$field'. Valid fields: $VALID_FIELDS"
    ((warning_count++)) || true
  fi
done

# Check 4: Required fields
echo ""
echo "Checking required fields..."

# Check name field (required)
NAME=$(echo "$FRONTMATTER" | grep '^name:' | sed 's/name: *//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\\(.*\\)'$/\\1/" || true)

if [[ -z "$NAME" ]]; then
  echo "  [FAIL] Missing required field: name"
  ((error_count++)) || true
else
  echo "  [ok] name: $NAME"

  # Validate name format: lowercase letters, numbers, and hyphens
  if [[ ! "$NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "  [FAIL] name must contain only lowercase letters, numbers, and hyphens (got '$NAME')"
    ((error_count++)) || true
  fi

  # Check for generic names
  if [[ "$NAME" =~ ^(helper|assistant|agent|tool)$ ]]; then
    echo "  [WARN] name is too generic: $NAME"
    ((warning_count++)) || true
  fi
fi

# Check description field (required)
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

# Check model field (optional, defaults to inherit)
MODEL=$(echo "$FRONTMATTER" | grep '^model:' | sed 's/model: *//' || true)

if [[ -z "$MODEL" ]]; then
  echo "  [info] model: not specified (defaults to inherit)"
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

# Check permissionMode field (optional)
PERM_MODE=$(echo "$FRONTMATTER" | grep '^permissionMode:' | sed 's/permissionMode: *//' || true)

if [[ -n "$PERM_MODE" ]]; then
  echo "  [ok] permissionMode: $PERM_MODE"

  case "$PERM_MODE" in
    default|acceptEdits|dontAsk|bypassPermissions|plan)
      ;;
    *)
      echo "  [FAIL] Invalid permissionMode: $PERM_MODE (valid: default, acceptEdits, dontAsk, bypassPermissions, plan)"
      ((error_count++)) || true
      ;;
  esac
fi

# Check maxTurns field (optional, must be positive integer)
MAX_TURNS=$(echo "$FRONTMATTER" | grep '^maxTurns:' | sed 's/maxTurns: *//' || true)

if [[ -n "$MAX_TURNS" ]]; then
  if [[ "$MAX_TURNS" =~ ^[0-9]+$ ]] && [[ "$MAX_TURNS" -gt 0 ]]; then
    echo "  [ok] maxTurns: $MAX_TURNS"
  else
    echo "  [FAIL] maxTurns must be a positive integer (got '$MAX_TURNS')"
    ((error_count++)) || true
  fi
fi

# Check memory field (optional)
MEMORY=$(echo "$FRONTMATTER" | grep '^memory:' | sed 's/memory: *//' || true)

if [[ -n "$MEMORY" ]]; then
  case "$MEMORY" in
    user|project|local)
      echo "  [ok] memory: $MEMORY"
      ;;
    *)
      echo "  [FAIL] Invalid memory scope: $MEMORY (valid: user, project, local)"
      ((error_count++)) || true
      ;;
  esac
fi

# Check background field (optional, must be boolean)
BACKGROUND=$(echo "$FRONTMATTER" | grep '^background:' | sed 's/background: *//' || true)

if [[ -n "$BACKGROUND" ]]; then
  if [[ "$BACKGROUND" == "true" ]] || [[ "$BACKGROUND" == "false" ]]; then
    echo "  [ok] background: $BACKGROUND"
  else
    echo "  [FAIL] background must be 'true' or 'false' (got '$BACKGROUND')"
    ((error_count++)) || true
  fi
fi

# Check isolation field (optional)
ISOLATION=$(echo "$FRONTMATTER" | grep '^isolation:' | sed 's/isolation: *//' || true)

if [[ -n "$ISOLATION" ]]; then
  if [[ "$ISOLATION" == "worktree" ]]; then
    echo "  [ok] isolation: $ISOLATION"
  else
    echo "  [FAIL] Invalid isolation value: $ISOLATION (valid: worktree)"
    ((error_count++)) || true
  fi
fi

# Check tools field (optional)
TOOLS=$(echo "$FRONTMATTER" | grep '^tools:' | sed 's/tools: *//' || true)

if [[ -n "$TOOLS" ]]; then
  echo "  [ok] tools: $TOOLS"
else
  echo "  [info] tools: not specified (agent has access to all tools)"
fi

# Check disallowedTools field (optional)
DISALLOWED=$(echo "$FRONTMATTER" | grep '^disallowedTools:' | sed 's/disallowedTools: *//' || true)

if [[ -n "$DISALLOWED" ]]; then
  echo "  [ok] disallowedTools: $DISALLOWED"
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
  exit 2
fi
