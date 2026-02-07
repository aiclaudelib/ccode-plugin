#!/bin/bash
set -euo pipefail
# validate-settings.sh — Validate .local.md settings files
# Checks existence, readability, frontmatter structure, YAML fields

# Usage
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <path/to/settings.local.md>"
  echo ""
  echo "Validates plugin settings file for:"
  echo "  - File existence and readability"
  echo "  - YAML frontmatter structure (--- markers)"
  echo "  - Key:value pairs in frontmatter"
  echo "  - Common field validation (booleans, etc.)"
  echo ""
  echo "Example: $0 .claude/my-plugin.local.md"
  exit 1
fi

SETTINGS_FILE="$1"

echo "Validating settings file: $SETTINGS_FILE"
echo ""

# Check 1: File exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "  [FAIL] File not found: $SETTINGS_FILE" >&2
  exit 1
fi
echo "  [ok] File exists"

# Check 2: File is readable
if [[ ! -r "$SETTINGS_FILE" ]]; then
  echo "  [FAIL] File is not readable" >&2
  exit 1
fi
echo "  [ok] File is readable"

# Check 3: Has frontmatter markers
MARKER_COUNT=$(grep -c '^---$' "$SETTINGS_FILE" 2>/dev/null || echo "0")

if [[ "$MARKER_COUNT" -lt 2 ]]; then
  echo "  [FAIL] Invalid frontmatter: found $MARKER_COUNT '---' markers (need at least 2)" >&2
  echo "         Expected format:" >&2
  echo "         ---" >&2
  echo "         field: value" >&2
  echo "         ---" >&2
  echo "         Content..." >&2
  exit 1
fi
echo "  [ok] Frontmatter markers present"

# Check 4: Extract and validate frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")

if [[ -z "$FRONTMATTER" ]]; then
  echo "  [FAIL] Empty frontmatter (nothing between --- markers)" >&2
  exit 1
fi
echo "  [ok] Frontmatter not empty"

# Check 5: Frontmatter has valid YAML-like structure
if ! echo "$FRONTMATTER" | grep -q ':'; then
  echo "  [WARN] Frontmatter has no key:value pairs"
fi

# Check 6: Show detected fields
echo ""
echo "Detected fields:"
echo "$FRONTMATTER" | grep '^[a-z_][a-z0-9_]*:' | while IFS=':' read -r key value; do
  echo "  - $key: ${value:0:50}"
done

# Check 7: Validate common boolean fields
for field in enabled strict_mode; do
  VALUE=$(echo "$FRONTMATTER" | grep "^${field}:" | sed "s/${field}: *//" || true)
  if [[ -n "$VALUE" ]]; then
    if [[ "$VALUE" != "true" ]] && [[ "$VALUE" != "false" ]]; then
      echo "  [WARN] Field '$field' should be boolean (true/false), got: $VALUE"
    fi
  fi
done

# Check 8: Check body exists
BODY=$(awk '/^---$/{i++; next} i>=2' "$SETTINGS_FILE")

echo ""
if [[ -n "$BODY" ]]; then
  BODY_LINES=$(echo "$BODY" | wc -l | tr -d ' ')
  echo "  [ok] Markdown body present ($BODY_LINES lines)"
else
  echo "  [WARN] No markdown body (frontmatter only)"
fi

echo ""
echo "========================================"
echo "Settings file structure is valid"
echo ""
echo "Reminder: Changes to this file require restarting Claude Code"
exit 0
