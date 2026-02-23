# Real-World Plugin Settings Examples

Detailed analysis of how production plugins use the `.claude/plugin-name.local.md` pattern.

## multi-agent-swarm Plugin

### Settings File

**.claude/multi-agent-swarm.local.md:**

```markdown
---
agent_name: auth-implementation
task_number: 3.5
pr_number: 1234
coordinator_session: team-leader
enabled: true
dependencies: ["Task 3.4"]
additional_instructions: "Use JWT tokens, not sessions"
---

# Task: Implement Authentication

Build JWT-based authentication for the REST API.

## Requirements
- JWT token generation and validation
- Refresh token flow
- Secure password hashing

## Success Criteria
- Auth endpoints implemented
- Tests passing (100% coverage)
- PR created and CI green
- Documentation updated

## Coordination
Depends on Task 3.4 (user model).
Report status to 'team-leader' session.
```

### How It Is Used

**Hook: `hooks/agent-stop-notification.sh`**

Purpose: send notifications to coordinator when agent becomes idle.

```bash
#!/bin/bash
set -euo pipefail

SWARM_STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/multi-agent-swarm.local.md"

# Quick exit if no swarm active
if [[ ! -f "$SWARM_STATE_FILE" ]]; then
  exit 0
fi

# Parse frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SWARM_STATE_FILE")

# Extract configuration
COORDINATOR_SESSION=$(echo "$FRONTMATTER" | grep '^coordinator_session:' | sed 's/coordinator_session: *//' | sed 's/^"\(.*\)"$/\1/')
AGENT_NAME=$(echo "$FRONTMATTER" | grep '^agent_name:' | sed 's/agent_name: *//' | sed 's/^"\(.*\)"$/\1/')
TASK_NUMBER=$(echo "$FRONTMATTER" | grep '^task_number:' | sed 's/task_number: *//' | sed 's/^"\(.*\)"$/\1/')
PR_NUMBER=$(echo "$FRONTMATTER" | grep '^pr_number:' | sed 's/pr_number: *//' | sed 's/^"\(.*\)"$/\1/')
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')

# Check if enabled
if [[ "$ENABLED" != "true" ]]; then
  exit 0
fi

# Send notification to coordinator
NOTIFICATION="Agent ${AGENT_NAME} (Task ${TASK_NUMBER}, PR #${PR_NUMBER}) is idle."

if tmux has-session -t "$COORDINATOR_SESSION" 2>/dev/null; then
  tmux send-keys -t "$COORDINATOR_SESSION" "$NOTIFICATION" Enter
  sleep 0.5
  tmux send-keys -t "$COORDINATOR_SESSION" Enter
fi

exit 0
```

**Key patterns:**
1. **Quick exit** (lines 7-9): returns immediately if file does not exist
2. **Field extraction** (lines 14-19): parses each frontmatter field
3. **Enabled check** (lines 22-24): respects the enabled flag
4. **Action based on settings** (lines 27-32): uses coordinator_session to send tmux notification

### Creation

Settings files are created during swarm launch:

```bash
cat > "$WORKTREE_PATH/.claude/multi-agent-swarm.local.md" <<EOF
---
agent_name: $AGENT_NAME
task_number: $TASK_ID
pr_number: TBD
coordinator_session: $COORDINATOR_SESSION
enabled: true
dependencies: [$DEPENDENCIES]
additional_instructions: "$EXTRA_INSTRUCTIONS"
---

# Task: $TASK_DESCRIPTION

$TASK_DETAILS
EOF
```

### Updates

PR number updated after PR creation:

```bash
TEMP_FILE=".claude/multi-agent-swarm.local.md.tmp.$$"
sed "s/^pr_number: .*/pr_number: $PR_NUM/" \
  ".claude/multi-agent-swarm.local.md" > "$TEMP_FILE"
mv "$TEMP_FILE" ".claude/multi-agent-swarm.local.md"
```

---

## ralph-loop Plugin

### Settings File

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
Document any changes needed in CLAUDE.md.
```

### How It Is Used

**Hook: `hooks/stop-hook.sh`**

Purpose: prevent session exit and loop Claude's output back as input.

```bash
#!/bin/bash
set -euo pipefail

RALPH_STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/ralph-loop.local.md"

# Quick exit if no active loop
if [[ ! -f "$RALPH_STATE_FILE" ]]; then
  exit 0
fi

# Parse frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$RALPH_STATE_FILE")

# Extract configuration
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Ralph loop: Max iterations ($MAX_ITERATIONS) reached."
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Continue loop - increment iteration
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt from markdown body
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$RALPH_STATE_FILE")

# Update iteration counter
TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# Block exit and feed prompt back
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "Ralph iteration $NEXT_ITERATION" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
```

**Key patterns:**
1. **Quick exit** (lines 7-9): skip if not active
2. **Iteration tracking** (lines 19-23): count and enforce max iterations
3. **Prompt extraction** (line 28): read markdown body as next prompt
4. **State update** (lines 31-33): increment iteration atomically
5. **Loop continuation** (lines 36-42): block exit and feed prompt back to Claude

### Creation

```bash
cat > ".claude/ralph-loop.local.md" <<EOF
---
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: "$COMPLETION_PROMISE"
started_at: "$(date -Iseconds)"
---

$PROMPT
EOF
```

---

## Pattern Comparison

| Feature | multi-agent-swarm | ralph-loop |
|---|---|---|
| **File** | `.claude/multi-agent-swarm.local.md` | `.claude/ralph-loop.local.md` |
| **Purpose** | Agent coordination state | Loop iteration state |
| **Frontmatter** | Agent metadata, coordination | Loop config, iteration |
| **Body** | Task assignment details | Prompt to repeat each loop |
| **Updates** | PR number, status | Iteration counter |
| **Deletion** | Manual or on completion | On loop exit (max iterations or promise) |
| **Hook type** | Stop (notifications) | Stop (loop control) |

## Common Best Practices from Real Plugins

### 1. Quick Exit Pattern

Both plugins check file existence first:

```bash
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi
```

Why: avoids errors when plugin is not configured, runs fast.

### 2. Enabled Flag

Use an explicit `enabled` field:

```yaml
enabled: true
```

Why: allows temporary deactivation without deleting the file.

### 3. Atomic Updates

Use temp file + atomic move:

```bash
TEMP_FILE="${FILE}.tmp.$$"
sed "s/^field: .*/field: $NEW_VALUE/" "$FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$FILE"
```

Why: prevents corruption if process is interrupted.

### 4. Quote Handling

Strip surrounding quotes from YAML values:

```bash
sed 's/^"\(.*\)"$/\1/'
```

Why: YAML allows both `field: value` and `field: "value"`.

### 5. Graceful Error Handling

Handle missing or corrupt files without crashing:

```bash
if [[ ! -f "$FILE" ]]; then
  exit 0  # No error, just not configured
fi

if [[ -z "$CRITICAL_FIELD" ]]; then
  echo "Settings file corrupt" >&2
  rm "$FILE"
  exit 0
fi
```
