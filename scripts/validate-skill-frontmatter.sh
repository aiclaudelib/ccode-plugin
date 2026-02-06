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

CONTENT=$(cat "$FILE_PATH")
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

# Extract name field
NAME=$(echo "$FRONTMATTER" | grep -E "^name:" | sed 's/^name:\s*//' | tr -d '"' | tr -d "'" | xargs)

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

  # Check reserved words
  if echo "$NAME" | grep -iqE "(anthropic|claude)"; then
    ERRORS+=("name cannot contain reserved words 'anthropic' or 'claude' (got '$NAME')")
  fi
fi

# Check description field
DESCRIPTION=$(echo "$FRONTMATTER" | grep -E "^description:" | sed 's/^description:\s*//')
if [[ -z "$DESCRIPTION" ]]; then
  ERRORS+=("description field is required in frontmatter")
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
