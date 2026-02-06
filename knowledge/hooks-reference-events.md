# Hooks reference — per-event details

Event-specific input schemas, decision control fields, and examples for each of the 12 hook events.

For configuration schema, handler fields, exit codes, and JSON I/O format, see `hooks-reference-core.md`.

## SessionStart

Runs when a session begins or resumes. Matcher values: `startup`, `resume`, `clear`, `compact`.

**Input**: common fields + `source`, `model`, optionally `agent_type`.

```json
{ "hook_event_name": "SessionStart", "source": "startup", "model": "claude-sonnet-4-5-20250929" }
```

**Decision control**: return `additionalContext` (string added to Claude's context):

```json
{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": "..." } }
```

**Persist environment variables**: write `export` statements to `$CLAUDE_ENV_FILE` (SessionStart only):

```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

## UserPromptSubmit

Runs when the user submits a prompt, before Claude processes it. No matcher support.

**Input**: common fields + `prompt` (the submitted text).

**Decision control**: plain text stdout adds context, or use JSON. `decision: "block"` prevents processing and erases the prompt. `additionalContext` adds context.

```json
{
  "decision": "block",
  "reason": "Explanation",
  "hookSpecificOutput": { "hookEventName": "UserPromptSubmit", "additionalContext": "..." }
}
```

## PreToolUse

Runs before a tool call. Matches on tool name: `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Task`, `WebFetch`, `WebSearch`, and MCP tool names.

**Input**: common fields + `tool_name`, `tool_input`, `tool_use_id`. Tool input fields by tool:

- **Bash**: `command` (string), `description` (string, optional), `timeout` (number, optional), `run_in_background` (boolean, optional)
- **Write**: `file_path` (string), `content` (string)
- **Edit**: `file_path` (string), `old_string` (string), `new_string` (string), `replace_all` (boolean, optional)
- **Read**: `file_path` (string), `offset` (number, optional), `limit` (number, optional)
- **Glob**: `pattern` (string), `path` (string, optional)
- **Grep**: `pattern` (string), `path` (string, optional), `glob` (string, optional), `output_mode` (string, optional), `-i` (boolean, optional), `multiline` (boolean, optional)
- **WebFetch**: `url` (string), `prompt` (string)
- **WebSearch**: `query` (string), `allowed_domains` (array, optional), `blocked_domains` (array, optional)
- **Task**: `prompt` (string), `description` (string), `subagent_type` (string), `model` (string, optional)

**Decision control** via `hookSpecificOutput`:

| Field                      | Description                                                                                    |
| :------------------------- | :--------------------------------------------------------------------------------------------- |
| `permissionDecision`       | `"allow"` bypasses permissions, `"deny"` prevents the call, `"ask"` prompts user to confirm   |
| `permissionDecisionReason` | For allow/ask: shown to user. For deny: shown to Claude                                        |
| `updatedInput`             | Modifies tool input before execution                                                           |
| `additionalContext`        | String added to Claude's context before the tool executes                                      |

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Reason",
    "updatedInput": { "field": "new value" },
    "additionalContext": "..."
  }
}
```

Note: Top-level `decision`/`reason` are deprecated for PreToolUse. Use `hookSpecificOutput.permissionDecision` instead.

## PermissionRequest

Runs when a permission dialog is shown. Matches on tool name.

**Input**: common fields + `tool_name`, `tool_input` (no `tool_use_id`), optional `permission_suggestions` array.

```json
{
  "hook_event_name": "PermissionRequest",
  "tool_name": "Bash",
  "tool_input": { "command": "rm -rf node_modules" },
  "permission_suggestions": [{ "type": "toolAlwaysAllow", "tool": "Bash" }]
}
```

**Decision control** via `hookSpecificOutput.decision`:

| Field                | Description                                                                    |
| :------------------- | :----------------------------------------------------------------------------- |
| `behavior`           | `"allow"` grants permission, `"deny"` denies it                               |
| `updatedInput`       | For allow: modifies tool input                                                 |
| `updatedPermissions` | For allow: applies permission rule updates (equivalent to "always allow")      |
| `message`            | For deny: tells Claude why                                                     |
| `interrupt`          | For deny: if `true`, stops Claude                                              |

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": { "behavior": "allow", "updatedInput": { "command": "npm run lint" } }
  }
}
```

## PostToolUse

Runs after a tool completes successfully. Matches on tool name.

**Input**: common fields + `tool_name`, `tool_input`, `tool_response`, `tool_use_id`.

**Decision control**:

| Field                  | Description                                                         |
| :--------------------- | :------------------------------------------------------------------ |
| `decision`             | `"block"` prompts Claude with `reason`. Omit to allow              |
| `reason`               | Shown to Claude when blocking                                       |
| `additionalContext`    | Additional context for Claude                                       |
| `updatedMCPToolOutput` | For MCP tools only: replaces the tool's output                      |

```json
{
  "decision": "block",
  "reason": "Explanation",
  "hookSpecificOutput": { "hookEventName": "PostToolUse", "additionalContext": "..." }
}
```

## PostToolUseFailure

Runs when a tool execution fails. Matches on tool name.

**Input**: common fields + `tool_name`, `tool_input`, `tool_use_id`, `error` (string), `is_interrupt` (boolean, optional).

**Decision control**: return `additionalContext` via `hookSpecificOutput`.

```json
{ "hookSpecificOutput": { "hookEventName": "PostToolUseFailure", "additionalContext": "..." } }
```

## Notification

Runs when Claude Code sends notifications. Matches on: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`.

**Input**: common fields + `message`, optional `title`, `notification_type`.

Cannot block or modify notifications. Can return `additionalContext`.

## SubagentStart

Runs when a subagent is spawned. Matches on agent type (`Bash`, `Explore`, `Plan`, or custom names).

**Input**: common fields + `agent_id`, `agent_type`.

Cannot block creation. Can return `additionalContext` to inject into the subagent.

## SubagentStop

Runs when a subagent finishes. Matches on agent type.

**Input**: common fields + `stop_hook_active`, `agent_id`, `agent_type`, `agent_transcript_path`.

Uses same decision control as Stop (top-level `decision: "block"` + `reason`).

## Stop

Runs when the main agent finishes responding. Does not run on user interrupt. No matcher support.

**Input**: common fields + `stop_hook_active` (true when already continuing from a stop hook -- check to prevent infinite loops).

**Decision control**:

| Field      | Description                                                                |
| :--------- | :------------------------------------------------------------------------- |
| `decision` | `"block"` prevents Claude from stopping. Omit to allow                     |
| `reason`   | Required when blocking. Tells Claude why it should continue                |

```json
{ "decision": "block", "reason": "All tests must pass before stopping" }
```

## PreCompact

Runs before a compact operation. Matcher values: `manual` (`/compact`), `auto` (context window full).

**Input**: common fields + `trigger`, `custom_instructions` (user input for manual, empty for auto).

## SessionEnd

Runs when a session ends. Cannot block termination. Matcher values: `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`.

**Input**: common fields + `reason`.
