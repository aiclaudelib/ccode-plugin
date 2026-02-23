#!/bin/bash
set -euo pipefail
# validate-skill-frontmatter.sh
# PostToolUse hook: validates SKILL.md frontmatter after Write|Edit
# Exit 2 on errors (agent gets feedback), exit 0 on success/warnings

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only validate files named SKILL.md
if [[ "$(basename "$FILE_PATH")" != "SKILL.md" ]]; then
  exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "Warning: jq not installed, skipping validation" >&2
  exit 0
fi

ERRORS=()
WARNINGS=()

# Check frontmatter delimiters
FIRST_LINE=$(head -1 "$FILE_PATH")
if [[ "$FIRST_LINE" != "---" ]]; then
  ERRORS+=("SKILL.md must start with '---' frontmatter delimiter")
  echo "${ERRORS[0]}" >&2
  exit 2
fi

# Find closing delimiter
CLOSING_LINE=$(tail -n +2 "$FILE_PATH" | grep -n "^---$" | head -1 | cut -d: -f1)
if [[ -z "$CLOSING_LINE" ]]; then
  ERRORS+=("Missing closing '---' frontmatter delimiter")
  echo "${ERRORS[0]}" >&2
  exit 2
fi

# Extract frontmatter (between the two --- lines)
FRONTMATTER=$(sed -n "2,$((CLOSING_LINE))p" "$FILE_PATH")

# --- Valid frontmatter fields for skills ---
VALID_FIELDS="name description argument-hint disable-model-invocation user-invocable allowed-tools model context agent hooks"

# Check for unknown top-level fields
FIELD_NAMES=$(echo "$FRONTMATTER" | grep -E "^[a-zA-Z]" | sed 's/:.*//' | tr -d ' ' || true)
for field in $FIELD_NAMES; do
  if ! echo "$VALID_FIELDS" | grep -qw "$field"; then
    WARNINGS+=("Unknown frontmatter field: '$field'. Valid fields: $VALID_FIELDS")
  fi
done

# Extract name field
NAME=$(echo "$FRONTMATTER" | grep -E "^name:" | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'" | xargs || true)

# Validate name if present
if [[ -n "$NAME" ]]; then
  # Check max length
  if [[ ${#NAME} -gt 64 ]]; then
    ERRORS+=("name must be at most 64 characters (got ${#NAME})")
  fi

  # Check format: lowercase letters, numbers, hyphens only
  if [[ ! "$NAME" =~ ^[a-z0-9-]+$ ]]; then
    ERRORS+=("name must contain only lowercase letters, numbers, and hyphens (got '$NAME')")
  fi

  # Check reserved words (whole-word match only)
  if echo "$NAME" | grep -iqE "^(anthropic|claude)$|-(anthropic|claude)-|^(anthropic|claude)-|-(anthropic|claude)$"; then
    ERRORS+=("name cannot contain reserved words 'anthropic' or 'claude' (got '$NAME')")
  fi
fi

# Check description field (recommended, not required)
DESCRIPTION=$(echo "$FRONTMATTER" | grep -E "^description:" | sed 's/^description:[[:space:]]*//' || true)
if [[ -z "$DESCRIPTION" ]]; then
  WARNINGS+=("description field is recommended in frontmatter (Claude uses it to decide when to apply the skill)")
fi

# Validate disable-model-invocation (must be boolean)
DMI=$(echo "$FRONTMATTER" | grep -E "^disable-model-invocation:" | sed 's/^disable-model-invocation:[[:space:]]*//' || true)
if [[ -n "$DMI" ]] && [[ "$DMI" != "true" ]] && [[ "$DMI" != "false" ]]; then
  ERRORS+=("disable-model-invocation must be 'true' or 'false' (got '$DMI')")
fi

# Validate user-invocable (must be boolean)
UI=$(echo "$FRONTMATTER" | grep -E "^user-invocable:" | sed 's/^user-invocable:[[:space:]]*//' || true)
if [[ -n "$UI" ]] && [[ "$UI" != "true" ]] && [[ "$UI" != "false" ]]; then
  ERRORS+=("user-invocable must be 'true' or 'false' (got '$UI')")
fi

# Validate context field (only valid value is 'fork')
CTX=$(echo "$FRONTMATTER" | grep -E "^context:" | sed 's/^context:[[:space:]]*//' || true)
if [[ -n "$CTX" ]] && [[ "$CTX" != "fork" ]]; then
  ERRORS+=("context must be 'fork' (got '$CTX')")
fi

# Validate agent field (only meaningful with context: fork)
AGENT=$(echo "$FRONTMATTER" | grep -E "^agent:" | sed 's/^agent:[[:space:]]*//' || true)
if [[ -n "$AGENT" ]] && [[ -z "$CTX" ]]; then
  WARNINGS+=("agent field is set but context is not 'fork'. The agent field only applies when context: fork is set.")
fi

# Check body length (warning only)
BODY_START=$((CLOSING_LINE + 2))
TOTAL_LINES=$(wc -l < "$FILE_PATH" | xargs)
BODY_LINES=$((TOTAL_LINES - BODY_START + 1))
if [[ $BODY_LINES -gt 500 ]]; then
  WARNINGS+=("SKILL.md body is $BODY_LINES lines (recommended: under 500). Consider splitting into supporting files.")
fi

# Report errors
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  for err in "${ERRORS[@]}"; do
    echo "Error: $err" >&2
  done
  exit 2
fi

# Report warnings (non-blocking)
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  for warn in "${WARNINGS[@]}"; do
    echo "Warning: $warn" >&2
  done
fi

exit 0
