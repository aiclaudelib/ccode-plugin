# Settings File Parsing Techniques

Complete guide to parsing `.claude/plugin-name.local.md` files in bash scripts.

## File Structure Recap

Settings files use markdown with YAML frontmatter:

```markdown
---
field1: value1
field2: "value with spaces"
numeric_field: 42
boolean_field: true
list_field: ["item1", "item2", "item3"]
---

# Markdown Content

This body content can be extracted separately.
It is useful for prompts, documentation, or additional context.
```

## Parsing Frontmatter

### Extract Frontmatter Block

```bash
#!/bin/bash
FILE=".claude/my-plugin.local.md"

# Extract everything between --- markers (excluding the markers themselves)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")
```

**How it works:**
- `sed -n` -- suppress automatic printing
- `/^---$/,/^---$/` -- range from first `---` to second `---`
- `{ /^---$/d; p; }` -- delete the `---` lines, print everything else

### Extract Individual Fields

**String fields:**
```bash
# Simple value
VALUE=$(echo "$FRONTMATTER" | grep '^field_name:' | sed 's/field_name: *//')

# Quoted value (removes surrounding quotes)
VALUE=$(echo "$FRONTMATTER" | grep '^field_name:' | sed 's/field_name: *//' | sed 's/^"\(.*\)"$/\1/')
```

**Boolean fields:**
```bash
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')

# Use in condition
if [[ "$ENABLED" == "true" ]]; then
  # Enabled
fi
```

**Numeric fields:**
```bash
MAX=$(echo "$FRONTMATTER" | grep '^max_value:' | sed 's/max_value: *//')

# Validate it's a number
if [[ "$MAX" =~ ^[0-9]+$ ]]; then
  if [[ $MAX -gt 100 ]]; then
    echo "Too large" >&2
  fi
fi
```

**List fields (simple string check):**
```bash
# YAML: list: ["item1", "item2", "item3"]
LIST=$(echo "$FRONTMATTER" | grep '^list:' | sed 's/list: *//')

# Simple contains check
if [[ "$LIST" == *"item1"* ]]; then
  # List contains item1
fi
```

**List fields (proper parsing with yq):**
```bash
# Requires: brew install yq
LIST=$(echo "$FRONTMATTER" | yq -o json '.list' 2>/dev/null)

# Iterate over items
echo "$LIST" | jq -r '.[]' | while read -r item; do
  echo "Processing: $item"
done
```

## Parsing Markdown Body

### Extract Body Content

```bash
#!/bin/bash
FILE=".claude/my-plugin.local.md"

# Extract everything after the closing ---
BODY=$(awk '/^---$/{i++; next} i>=2' "$FILE")
```

**How it works:**
- `/^---$/` -- match `---` lines
- `{i++; next}` -- increment counter and skip the `---` line
- `i>=2` -- print all lines after second `---`

This correctly handles `---` appearing in the body because only the first two are treated as frontmatter delimiters.

### Use Body as Prompt

```bash
PROMPT=$(awk '/^---$/{i++; next} i>=2' "$FILE")

# Safe JSON construction with jq
jq -n --arg prompt "$PROMPT" '{
  "decision": "block",
  "reason": $prompt
}'
```

Always use `jq -n --arg` for JSON construction with user content to prevent injection.

## Common Parsing Patterns

### Field with Default

```bash
VALUE=$(echo "$FRONTMATTER" | grep '^field:' | sed 's/field: *//' | sed 's/^"\(.*\)"$/\1/')

# Use default if empty
if [[ -z "$VALUE" ]]; then
  VALUE="default_value"
fi

# Or with bash parameter expansion
VALUE=${VALUE:-default_value}
```

### Optional Field

```bash
OPTIONAL=$(echo "$FRONTMATTER" | grep '^optional_field:' | sed 's/optional_field: *//' | sed 's/^"\(.*\)"$/\1/')

# Only use if present and not null
if [[ -n "$OPTIONAL" ]] && [[ "$OPTIONAL" != "null" ]]; then
  echo "Optional field: $OPTIONAL"
fi
```

### Multiple Fields at Once

```bash
# Parse all fields in one pass
while IFS=': ' read -r key value; do
  value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
  case "$key" in
    enabled) ENABLED="$value" ;;
    mode) MODE="$value" ;;
    max_size) MAX_SIZE="$value" ;;
  esac
done <<< "$FRONTMATTER"
```

## Updating Settings Files

### Atomic Updates

Always use temp file + atomic move to prevent corruption:

```bash
#!/bin/bash
FILE=".claude/my-plugin.local.md"
NEW_VALUE="updated_value"

# Create temp file with process ID for uniqueness
TEMP_FILE="${FILE}.tmp.$$"

# Update field using sed
sed "s/^field_name: .*/field_name: $NEW_VALUE/" "$FILE" > "$TEMP_FILE"

# Atomic replace
mv "$TEMP_FILE" "$FILE"
```

### Update Single Field

```bash
CURRENT=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
NEXT=$((CURRENT + 1))

TEMP_FILE="${FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT/" "$FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$FILE"
```

### Update Multiple Fields

```bash
TEMP_FILE="${FILE}.tmp.$$"
sed -e "s/^iteration: .*/iteration: $NEXT_ITERATION/" \
    -e "s/^pr_number: .*/pr_number: $PR_NUMBER/" \
    -e "s/^status: .*/status: $NEW_STATUS/" \
    "$FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$FILE"
```

Never use `sed -i` -- it is not atomic and can corrupt the file if interrupted.

## Validation Techniques

### Validate File Exists and Is Readable

```bash
FILE=".claude/my-plugin.local.md"

if [[ ! -f "$FILE" ]]; then
  echo "Settings file not found" >&2
  exit 1
fi

if [[ ! -r "$FILE" ]]; then
  echo "Settings file not readable" >&2
  exit 1
fi
```

### Validate Frontmatter Structure

```bash
MARKER_COUNT=$(grep -c '^---$' "$FILE" 2>/dev/null || echo "0")

if [[ $MARKER_COUNT -lt 2 ]]; then
  echo "Invalid settings file: missing frontmatter markers" >&2
  exit 1
fi
```

### Validate Field Values

```bash
MODE=$(echo "$FRONTMATTER" | grep '^mode:' | sed 's/mode: *//')

case "$MODE" in
  strict|standard|lenient)
    # Valid mode
    ;;
  *)
    echo "Invalid mode: $MODE (must be strict, standard, or lenient)" >&2
    exit 1
    ;;
esac
```

### Validate Numeric Ranges

```bash
MAX_SIZE=$(echo "$FRONTMATTER" | grep '^max_size:' | sed 's/max_size: *//')

if ! [[ "$MAX_SIZE" =~ ^[0-9]+$ ]]; then
  echo "max_size must be a number" >&2
  exit 1
fi

if [[ $MAX_SIZE -lt 1 ]] || [[ $MAX_SIZE -gt 10000000 ]]; then
  echo "max_size out of range (1-10000000)" >&2
  exit 1
fi
```

## Edge Cases and Gotchas

### Quotes in Values

YAML allows both quoted and unquoted strings:

```yaml
field1: value
field2: "value"
field3: 'value'
```

Handle both:

```bash
VALUE=$(echo "$FRONTMATTER" | grep '^field:' | sed 's/field: *//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\\(.*\\)'$/\\1/")
```

### Empty Values

```yaml
field1:
field2: ""
field3: null
```

```bash
VALUE=$(echo "$FRONTMATTER" | grep '^field1:' | sed 's/field1: *//')
# VALUE will be empty string

if [[ -z "$VALUE" ]] || [[ "$VALUE" == "null" ]]; then
  VALUE="default"
fi
```

### Special Characters

Values with special characters need careful handling:

```yaml
message: "Error: Something went wrong!"
path: "/path/with spaces/file.txt"
```

Always quote variables when using them: `echo "$VALUE"` not `echo $VALUE`.

### Performance: Cache Parsed Values

Parse frontmatter once, then extract multiple fields:

```bash
# Parse once
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")

# Extract multiple fields from cached string
FIELD1=$(echo "$FRONTMATTER" | grep '^field1:' | sed 's/field1: *//')
FIELD2=$(echo "$FRONTMATTER" | grep '^field2:' | sed 's/field2: *//')
FIELD3=$(echo "$FRONTMATTER" | grep '^field3:' | sed 's/field3: *//')
```

Do not re-parse the file for each field.

## Alternative: Using yq

For complex YAML structures, consider `yq`:

```bash
# Install: brew install yq
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")

ENABLED=$(echo "$FRONTMATTER" | yq '.enabled')
MODE=$(echo "$FRONTMATTER" | yq '.mode')
LIST=$(echo "$FRONTMATTER" | yq -o json '.list_field')
```

**Pros**: proper YAML parsing, handles nested structures, better list support.
**Cons**: requires yq installation, additional dependency.

Recommendation: use sed/grep for simple fields, yq for complex structures.
