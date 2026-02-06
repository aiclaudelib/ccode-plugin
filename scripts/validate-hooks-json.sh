#!/bin/bash
set -euo pipefail
# validate-hooks-json.sh
# PostToolUse hook: validates hooks.json schema after Write|Edit
# Exit 2 on errors (agent gets feedback), exit 0 on success

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only validate files named hooks.json
if [[ "$(basename "$FILE_PATH")" != "hooks.json" ]]; then
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

# Validate JSON syntax
if ! jq empty "$FILE_PATH" 2>/dev/null; then
  echo "Error: Invalid JSON syntax in $FILE_PATH" >&2
  exit 2
fi

# Check for 'hooks' key
HAS_HOOKS=$(jq 'has("hooks")' "$FILE_PATH" 2>/dev/null)
if [[ "$HAS_HOOKS" != "true" ]]; then
  ERRORS+=("hooks.json must contain a top-level 'hooks' key")
fi

# Valid event names
VALID_EVENTS="SessionStart UserPromptSubmit PreToolUse PermissionRequest PostToolUse PostToolUseFailure Notification SubagentStart SubagentStop Stop PreCompact SessionEnd"

# Check event names
EVENT_NAMES=$(jq -r '.hooks // {} | keys[]' "$FILE_PATH" 2>/dev/null)
for event in $EVENT_NAMES; do
  if ! echo "$VALID_EVENTS" | grep -qw "$event"; then
    ERRORS+=("Invalid hook event name: '$event'. Valid events: $VALID_EVENTS")
  fi
done

# Check that each handler has a 'type' field
MISSING_TYPE=$(jq -r '
  .hooks // {} | to_entries[] |
  .key as $event |
  .value[] |
  .hooks[]? |
  select(.type == null) |
  $event
' "$FILE_PATH" 2>/dev/null)

if [[ -n "$MISSING_TYPE" ]]; then
  for event in $MISSING_TYPE; do
    ERRORS+=("Hook handler in '$event' is missing required 'type' field (must be 'command', 'prompt', or 'agent')")
  done
fi

# Validate type values
INVALID_TYPES=$(jq -r '
  .hooks // {} | to_entries[] |
  .key as $event |
  .value[] |
  .hooks[]? |
  select(.type != null) |
  select(.type != "command" and .type != "prompt" and .type != "agent") |
  "\($event): \(.type)"
' "$FILE_PATH" 2>/dev/null)

if [[ -n "$INVALID_TYPES" ]]; then
  while IFS= read -r line; do
    ERRORS+=("Invalid hook type in $line (must be 'command', 'prompt', or 'agent')")
  done <<< "$INVALID_TYPES"
fi

# Report errors
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  for err in "${ERRORS[@]}"; do
    echo "Error: $err" >&2
  done
  exit 2
fi

exit 0
