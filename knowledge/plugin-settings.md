# Plugin settings guide

## Official plugin settings vs local settings files

Claude Code plugins support an **official** `settings.json` file at the plugin root that provides default configuration when the plugin is enabled. Currently, only `agent` settings are supported in this file. See the [official plugin structure](#official-plugin-settingsjson) section below.

For **user-configurable per-project settings and state**, plugins use `.claude/plugin-name.local.md` files within the project directory. This is a community-established pattern (not a built-in Claude Code feature) that uses YAML frontmatter for structured configuration and markdown content for prompts or additional context. For advanced parsing techniques and production examples, see the plugin-dev plugin-settings skill and its references.

## Official plugin settings.json

Plugins can include a `settings.json` at the plugin root directory. This file provides default configuration that is applied when the plugin is enabled. Currently only [`agent`](https://code.claude.com/docs/en/sub-agents) settings are supported. This is part of the official plugin structure defined in the Claude Code plugin manifest schema.

## Local settings files (.local.md pattern)

### Core concepts

- **Location**: `.claude/plugin-name.local.md` in the project root
- **Structure**: YAML frontmatter (between `---` markers) + optional markdown body
- **Scope**: Per-project, per-user (not committed to git)
- **Consumers**: Hooks, commands, agents, and skills can all read settings
- **Lifecycle**: User-managed; hooks are snapshotted at session startup, so changes require either restarting Claude Code or reviewing changes via the `/hooks` menu mid-session

## File structure

### Basic template

```markdown
---
enabled: true
setting1: value1
setting2: value2
numeric_setting: 42
list_setting: ["item1", "item2"]
---

# Additional Context

This markdown body can contain:
- Task descriptions
- Additional instructions
- Prompts to feed back to Claude
- Documentation or notes
```

### Example: Plugin state file

**.claude/my-plugin.local.md:**
```markdown
---
enabled: true
strict_mode: false
max_retries: 3
notification_level: info
coordinator_session: team-leader
---

# Plugin Configuration

This plugin is configured for standard validation mode.
Contact @team-lead with questions.
```

### Supported value types

| Type | Example | Parsing |
|---|---|---|
| String | `mode: standard` or `mode: "standard"` | `grep '^mode:' \| sed 's/mode: *//'` |
| Boolean | `enabled: true` | Compare against `"true"` string |
| Numeric | `max_retries: 3` | Validate with `[[ "$VAL" =~ ^[0-9]+$ ]]` |
| List (simple) | `items: ["a", "b", "c"]` | String contains check or use `yq` |

YAML allows both quoted and unquoted strings (`field: value` and `field: "value"` are equivalent). Strip surrounding quotes during parsing with `sed 's/^"\(.*\)"$/\1/'`.

## Reading settings from hooks

### Environment variables for paths

Use these environment variables in hook scripts for reliable path resolution:

- **`$CLAUDE_PROJECT_DIR`**: the project root directory. Always wrap in quotes to handle paths with spaces.
- **`${CLAUDE_PLUGIN_ROOT}`**: the plugin's root directory, for scripts bundled with a plugin.

### Quick-exit pattern

Every hook that reads settings should start with a file-existence check. This ensures the hook does nothing when the plugin is not configured for the project:

```bash
#!/bin/bash
set -euo pipefail

STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/my-plugin.local.md"

# Quick exit if not configured
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi
```

### Parsing frontmatter

Extract the YAML block between `---` markers, then read individual fields:

```bash
# Extract YAML between --- markers
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")

# Read individual fields
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')
MODE=$(echo "$FRONTMATTER" | grep '^mode:' | sed 's/mode: *//' | sed 's/^"\(.*\)"$/\1/')
MAX=$(echo "$FRONTMATTER" | grep '^max_retries:' | sed 's/max_retries: *//')
```

**How the sed command works**:
- `sed -n` suppresses automatic printing
- `/^---$/,/^---$/` matches the range from first `---` to second `---`
- `{ /^---$/d; p; }` deletes the `---` lines, prints everything else

### Parsing the markdown body

```bash
# Everything after the second --- marker
BODY=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")
```

The `awk` pattern counts `---` occurrences and prints everything after the second one. This correctly handles `---` appearing inside the body content.

### Checking enabled flag

```bash
if [[ "$ENABLED" != "true" ]]; then
  exit 0  # Disabled, skip
fi
```

### Parsing multiple fields at once

For efficiency, parse all fields in a single pass:

```bash
while IFS=': ' read -r key value; do
  value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
  case "$key" in
    enabled) ENABLED="$value" ;;
    mode) MODE="$value" ;;
    max_size) MAX_SIZE="$value" ;;
  esac
done <<< "$FRONTMATTER"
```

### Using yq for complex structures

For complex YAML (nested objects, proper list handling), use `yq`:

```bash
# Requires: brew install yq
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")

ENABLED=$(echo "$FRONTMATTER" | yq '.enabled')
MODE=$(echo "$FRONTMATTER" | yq '.mode')
LIST=$(echo "$FRONTMATTER" | yq -o json '.list_field')

# Iterate list properly
echo "$LIST" | jq -r '.[]' | while read -r item; do
  echo "Processing: $item"
done
```

Use sed/grep for simple fields, yq for complex structures. yq adds a dependency, so only use it when needed.

## Reading settings from commands and agents

Commands and agents read settings using the Read tool, then parse YAML frontmatter inline.

**Command example**:
```markdown
---
description: Process data with plugin configuration
allowed-tools: ["Read", "Bash"]
---
1. Check if `.claude/my-plugin.local.md` exists
2. Read the file and parse YAML frontmatter
3. Apply settings to processing logic
4. Execute with configured behavior
```

**Agent example**:
```markdown
---
name: configured-agent
description: Adapts to project settings
---
Check for plugin settings at `.claude/my-plugin.local.md`.
If present, parse YAML frontmatter and adapt behavior according to:
- enabled: Whether plugin is active
- mode: Processing mode (strict, standard, lenient)
- Additional configuration fields
```

## Common patterns

### Pattern 1: Temporarily active hooks

Use the `enabled` field to toggle hook behavior without editing `hooks.json`. This avoids needing to modify configuration files and reinstall the plugin:

```bash
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')
if [[ "$ENABLED" != "true" ]]; then
  exit 0
fi
# Run hook logic only when enabled
```

Use case: enable/disable security scanning, formatting, or notifications per-project.

### Pattern 2: Agent state management

Store agent coordination state for multi-agent workflows:

**.claude/multi-agent-swarm.local.md:**
```markdown
---
agent_name: auth-agent
task_number: 3.5
pr_number: 1234
coordinator_session: team-leader
enabled: true
dependencies: ["Task 3.4"]
additional_instructions: "Use JWT tokens, not sessions"
---

# Task: Implement Authentication

Build JWT-based authentication for the REST API.

## Success Criteria
- Authentication endpoints created
- Tests passing
- PR created and CI green
```

Hooks read this to coordinate agents:

```bash
AGENT_NAME=$(echo "$FRONTMATTER" | grep '^agent_name:' | sed 's/agent_name: *//' | sed 's/^"\(.*\)"$/\1/')
COORDINATOR=$(echo "$FRONTMATTER" | grep '^coordinator_session:' | sed 's/coordinator_session: *//' | sed 's/^"\(.*\)"$/\1/')

# Send notification to coordinator
NOTIFICATION="Agent ${AGENT_NAME} is idle."
if tmux has-session -t "$COORDINATOR" 2>/dev/null; then
  tmux send-keys -t "$COORDINATOR" "$NOTIFICATION" Enter
fi
```

### Pattern 3: Configuration-driven validation

Use settings to control validation strictness per-project:

**.claude/my-plugin.local.md:**
```markdown
---
validation_level: strict
max_file_size: 1000000
allowed_extensions: [".js", ".ts", ".tsx"]
enable_logging: true
---

# Validation Configuration

Strict mode enabled for this project.
All writes validated against security policies.
```

Hook reads validation level and branches:

```bash
LEVEL=$(echo "$FRONTMATTER" | grep '^validation_level:' | sed 's/validation_level: *//')

case "$LEVEL" in
  strict)
    # Apply strict validation
    ;;
  standard)
    # Apply standard validation
    ;;
  lenient)
    # Apply lenient validation
    ;;
esac
```

### Pattern 4: Loop iteration state

Store loop configuration for iterative workflows (e.g., ralph-loop plugin):

**.claude/ralph-loop.local.md:**
```markdown
---
iteration: 1
max_iterations: 10
completion_promise: "All tests passing and build successful"
started_at: "2025-01-15T14:30:00Z"
---

Fix all the linting errors in the project.
Make sure tests pass after each fix.
```

A Stop hook reads `iteration`, checks `max_iterations`, extracts the markdown body as the next prompt, increments the counter, and blocks exit to continue the loop. When `completion_promise` matches output or `max_iterations` is reached, the file is deleted and the loop terminates.

## Creating settings files

### From commands

```markdown
---
description: Set up plugin configuration
---
1. Ask user for configuration preferences
2. Create `.claude/my-plugin.local.md` with YAML frontmatter
3. Set values based on user input
4. Remind user to restart Claude Code for hooks to pick up changes
```

### From scripts (programmatic creation)

```bash
cat > ".claude/my-plugin.local.md" <<EOF
---
enabled: true
mode: standard
max_retries: 3
---

# Plugin Configuration

Default settings applied.
EOF
```

### Template in README

Provide a copy-paste template in the plugin README so users can create the file manually:

```markdown
## Configuration

Create `.claude/my-plugin.local.md` in your project:

\`\`\`markdown
---
enabled: true
mode: standard
max_retries: 3
---

# Plugin Configuration

Your settings are active.
\`\`\`

After creating or editing, restart Claude Code for changes to take effect.
```

## Updating settings atomically

Always use a temp file and atomic move to prevent corruption if the process is interrupted:

```bash
# Update a single field
NEXT=$((ITERATION + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"
```

For multiple fields:

```bash
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed -e "s/^iteration: .*/iteration: $NEXT/" \
    -e "s/^pr_number: .*/pr_number: $PR_NUM/" \
    -e "s/^status: .*/status: $NEW_STATUS/" \
    "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"
```

Never use `sed -i` directly on the file -- it is not atomic and can corrupt the file if interrupted.

## Defaults and validation

### Provide sensible defaults

When the settings file does not exist, use defaults so the plugin functions:

```bash
if [[ ! -f "$STATE_FILE" ]]; then
  # Use defaults
  ENABLED=true
  MODE=standard
  MAX_SIZE=1000000
else
  # Parse from file
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
  MODE=$(echo "$FRONTMATTER" | grep '^mode:' | sed 's/mode: *//' | sed 's/^"\(.*\)"$/\1/')
  MAX_SIZE=$(echo "$FRONTMATTER" | grep '^max_size:' | sed 's/max_size: *//')

  # Apply defaults for missing fields
  MODE=${MODE:-standard}
  MAX_SIZE=${MAX_SIZE:-1000000}
fi
```

### Validate values

**Numeric range**:
```bash
if ! [[ "$MAX" =~ ^[0-9]+$ ]] || [[ $MAX -lt 1 ]] || [[ $MAX -gt 100 ]]; then
  echo "Invalid max_value in settings (must be 1-100)" >&2
  MAX=10  # Fallback to default
fi
```

**Enum validation**:
```bash
case "$MODE" in
  strict|standard|lenient) ;;
  *)
    echo "Invalid mode: $MODE (must be strict, standard, or lenient)" >&2
    MODE=standard
    ;;
esac
```

**Boolean validation**:
```bash
if [[ "$ENABLED" != "true" ]] && [[ "$ENABLED" != "false" ]]; then
  echo "Invalid enabled value, using default" >&2
  ENABLED=true
fi
```

### Validate file structure

Check for valid frontmatter before parsing:

```bash
MARKER_COUNT=$(grep -c '^---$' "$FILE" 2>/dev/null || echo "0")
if [[ $MARKER_COUNT -lt 2 ]]; then
  echo "Invalid settings file: missing frontmatter markers" >&2
  exit 1
fi
```

## Best practices

### File naming

| Do | Do not |
|---|---|
| Use `.claude/plugin-name.local.md` format | Use a different directory |
| Match the plugin name exactly | Use inconsistent naming |
| Use `.local.md` suffix (gitignored by convention) | Use `.md` without `.local` (risks committing) |

### Gitignore

Add to `.gitignore` (document in plugin README):

```gitignore
.claude/*.local.md
.claude/*.local.json
```

### Restart requirement

Claude Code snapshots hooks at session startup. Changes to settings files that affect hook behavior require either restarting Claude Code or reviewing changes via the `/hooks` menu. If hooks are modified externally during a session, Claude Code detects the change and warns you, requiring review in the `/hooks` menu before changes apply. Document this clearly:

```markdown
After editing `.claude/my-plugin.local.md`:
1. Save the file
2. Either restart Claude Code, or open the `/hooks` menu to review and apply changes
3. New settings will be active
```

### Security

- Sanitize user input when writing settings programmatically (escape quotes)
- Validate file paths in settings for path traversal (`..`)
- Keep settings files readable by user only (`chmod 600`)
- Never commit `.local.md` files to git
- Use `jq -n --arg` for safe JSON construction from user content

### Performance

- Parse frontmatter once, cache the result, then extract multiple fields
- Use lazy loading: do quick checks (tool name, etc.) before reading the settings file
- Quick-exit early when the file does not exist or the plugin is disabled

## Parsing reference

| Operation | Code |
|---|---|
| Extract frontmatter | `sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE"` |
| Read string field | `echo "$FM" \| grep '^field:' \| sed 's/field: *//' \| sed 's/^"\(.*\)"$/\1/'` |
| Read boolean field | `echo "$FM" \| grep '^enabled:' \| sed 's/enabled: *//'` |
| Read numeric field | `echo "$FM" \| grep '^max:' \| sed 's/max: *//'` |
| Extract body | `awk '/^---$/{i++; next} i>=2' "$FILE"` |
| Safe JSON output | `jq -n --arg val "$VAR" '{"key": $val}'` |
| Default fallback | `MODE=${MODE:-standard}` |
| Atomic update | `sed "s/^field: .*/field: $NEW/" "$FILE" > tmp && mv tmp "$FILE"` |

## Complete example

A full settings-reading hook combining all best practices:

```bash
#!/bin/bash
set -euo pipefail

SETTINGS_FILE="$CLAUDE_PROJECT_DIR/.claude/my-plugin.local.md"

# Quick exit if not configured
if [[ ! -f "$SETTINGS_FILE" ]]; then
  ENABLED=true
  MODE=standard
  MAX_SIZE=1000000
else
  # Parse frontmatter
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")

  # Extract fields with defaults
  ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')
  ENABLED=${ENABLED:-true}

  MODE=$(echo "$FRONTMATTER" | grep '^mode:' | sed 's/mode: *//' | sed 's/^"\(.*\)"$/\1/')
  MODE=${MODE:-standard}

  MAX_SIZE=$(echo "$FRONTMATTER" | grep '^max_size:' | sed 's/max_size: *//')
  MAX_SIZE=${MAX_SIZE:-1000000}

  # Validate
  if [[ "$ENABLED" != "true" ]] && [[ "$ENABLED" != "false" ]]; then
    ENABLED=true
  fi
  if ! [[ "$MAX_SIZE" =~ ^[0-9]+$ ]]; then
    MAX_SIZE=1000000
  fi
fi

# Quick exit if disabled
if [[ "$ENABLED" != "true" ]]; then
  exit 0
fi

# Use configuration
case "$MODE" in
  strict)  ;; # strict logic
  standard) ;; # standard logic
  lenient) ;; # lenient logic
esac
```

## Hook types and events reference

### Hook types

Hooks support three handler types:

| Type | Description | Use case |
|---|---|---|
| `command` | Execute a shell command or script | Most common; reads stdin JSON, returns exit code and optional JSON stdout |
| `prompt` | Send a prompt to an LLM for single-turn evaluation | Quick yes/no decisions without writing scripts |
| `agent` | Spawn a subagent with tool access (Read, Grep, Glob) for multi-turn verification | Complex verification that requires inspecting files or running searches |

### Available hook events

| Event | When it fires | Can block? |
|---|---|---|
| `SessionStart` | Session begins or resumes | No |
| `UserPromptSubmit` | User submits a prompt | Yes |
| `PreToolUse` | Before a tool call executes | Yes |
| `PermissionRequest` | Permission dialog appears | Yes |
| `PostToolUse` | After a tool call succeeds | No (tool already ran) |
| `PostToolUseFailure` | After a tool call fails | No |
| `Notification` | Claude Code sends a notification | No |
| `SubagentStart` | A subagent is spawned | No |
| `SubagentStop` | A subagent finishes | Yes |
| `Stop` | Claude finishes responding | Yes |
| `TeammateIdle` | Agent team teammate about to go idle | Yes |
| `TaskCompleted` | Task being marked as completed | Yes |
| `ConfigChange` | Configuration file changes during session | Yes (except policy_settings) |
| `WorktreeCreate` | Worktree being created (replaces default git behavior) | Yes (non-zero exit fails creation) |
| `WorktreeRemove` | Worktree being removed | No |
| `PreCompact` | Before context compaction | No |
| `SessionEnd` | Session terminates | No |

Not all events support all hook types. `prompt` and `agent` types are supported for: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `TaskCompleted`. All other events only support `command` type.

### Key environment variables for hooks

| Variable | Description |
|---|---|
| `$CLAUDE_PROJECT_DIR` | Project root directory |
| `${CLAUDE_PLUGIN_ROOT}` | Plugin root directory (for plugin-bundled scripts) |
| `$CLAUDE_ENV_FILE` | File path for persisting env vars (SessionStart hooks only) |
| `$CLAUDE_CODE_REMOTE` | Set to `"true"` in remote web environments |

## Troubleshooting

| Problem | Solution |
|---|---|
| Hook not reading settings | Check file path matches `.claude/plugin-name.local.md` exactly |
| Settings changes not applied | Restart Claude Code or review changes via the `/hooks` menu |
| Frontmatter parse errors | Verify file starts with `---` on first line, no leading whitespace |
| Empty field values | Use `${VAR:-default}` bash syntax for fallback defaults |
| Quotes in values | Strip with `sed 's/^"\(.*\)"$/\1/'` -- handles both quoted and unquoted |
| JSON output malformed | Use `jq -n --arg` for safe construction with user content |
| --- in body content | The `awk '/^---$/{i++; next} i>=2'` pattern handles this correctly |
| Special characters in values | Always quote variables when using them (`"$VALUE"`) |
| File corruption on update | Use temp file + atomic move, never `sed -i` |
