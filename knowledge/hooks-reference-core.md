# Hooks reference — core

Configuration schema, handler fields, exit codes, JSON I/O formats, and decision control.

## Hook lifecycle

| Event                | When it fires                                        |
| :------------------- | :--------------------------------------------------- |
| `SessionStart`       | When a session begins or resumes                     |
| `UserPromptSubmit`   | When you submit a prompt, before Claude processes it |
| `PreToolUse`         | Before a tool call executes. Can block it            |
| `PermissionRequest`  | When a permission dialog appears                     |
| `PostToolUse`        | After a tool call succeeds                           |
| `PostToolUseFailure` | After a tool call fails                              |
| `Notification`       | When Claude Code sends a notification                |
| `SubagentStart`      | When a subagent is spawned                           |
| `SubagentStop`       | When a subagent finishes                             |
| `Stop`               | When Claude finishes responding                      |
| `TeammateIdle`       | When an agent team teammate is about to go idle      |
| `TaskCompleted`      | When a task is being marked as completed             |
| `ConfigChange`       | When a configuration file changes during a session   |
| `WorktreeCreate`     | When a worktree is being created (replaces default git behavior) |
| `WorktreeRemove`     | When a worktree is being removed                     |
| `PreCompact`         | Before context compaction                            |
| `SessionEnd`         | When a session terminates                            |

## Configuration

Three levels of nesting: hook event -> matcher group -> hook handler(s).

### Hook locations

| Location                       | Scope                         | Shareable                          |
| :----------------------------- | :---------------------------- | :--------------------------------- |
| `~/.claude/settings.json`      | All your projects             | No, local to your machine          |
| `.claude/settings.json`        | Single project                | Yes, can be committed to the repo  |
| `.claude/settings.local.json`  | Single project                | No, gitignored                     |
| Managed policy settings        | Organization-wide             | Yes, admin-controlled              |
| Plugin `hooks/hooks.json`      | When plugin is enabled        | Yes, bundled with the plugin       |
| Skill or agent frontmatter     | While the component is active | Yes, defined in the component file |

Enterprise administrators can use `allowManagedHooksOnly` to block user, project, and plugin hooks.

### Matcher patterns

The `matcher` field is a regex. Use `"*"`, `""`, or omit to match all occurrences.

| Event                                                                  | What the matcher filters  | Example matcher values                                                         |
| :--------------------------------------------------------------------- | :------------------------ | :----------------------------------------------------------------------------- |
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest` | tool name                 | `Bash`, `Edit\|Write`, `mcp__.*`                                               |
| `SessionStart`                                                         | how the session started   | `startup`, `resume`, `clear`, `compact`                                        |
| `SessionEnd`                                                           | why the session ended     | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |
| `Notification`                                                         | notification type         | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`       |
| `SubagentStart`                                                        | agent type                | `Bash`, `Explore`, `Plan`, or custom agent names                               |
| `SubagentStop`                                                         | agent type                | same values as `SubagentStart`                                                 |
| `ConfigChange`                                                         | configuration source      | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` |
| `PreCompact`                                                           | what triggered compaction | `manual`, `auto`                                                               |
| `UserPromptSubmit`, `Stop`, `TeammateIdle`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove` | no matcher support | always fires on every occurrence                                  |

MCP tools follow the naming pattern `mcp__<server>__<tool>` (e.g. `mcp__memory__create_entities`). Use `mcp__memory__.*` to match all tools from one server.

### Hook handler fields

Three types:
- **Command hooks** (`type: "command"`): shell command, receives JSON on stdin, returns exit codes + stdout.
- **Prompt hooks** (`type: "prompt"`): single-turn LLM evaluation, returns yes/no decision.
- **Agent hooks** (`type: "agent"`): multi-turn subagent with Read/Grep/Glob access.

#### Common fields

| Field           | Required | Description                                                                   |
| :-------------- | :------- | :---------------------------------------------------------------------------- |
| `type`          | yes      | `"command"`, `"prompt"`, or `"agent"`                                         |
| `timeout`       | no       | Seconds before canceling. Defaults: 600 command, 30 prompt, 60 agent          |
| `statusMessage` | no       | Custom spinner message displayed while the hook runs                          |
| `once`          | no       | If `true`, runs only once per session then removed. Skills only, not agents   |

#### Command hook fields

| Field     | Required | Description                                        |
| :-------- | :------- | :------------------------------------------------- |
| `command` | yes      | Shell command to execute                           |
| `async`   | no       | If `true`, runs in the background without blocking |

#### Prompt and agent hook fields

| Field    | Required | Description                                                                                 |
| :------- | :------- | :------------------------------------------------------------------------------------------ |
| `prompt` | yes      | Prompt text to send to the model. Use `$ARGUMENTS` as a placeholder for the hook input JSON |
| `model`  | no       | Model to use for evaluation. Defaults to a fast model                                       |

All matching hooks run in parallel; identical handlers are deduplicated. Handlers run in the current directory with Claude Code's environment. `$CLAUDE_CODE_REMOTE` is `"true"` in remote web environments.

### Reference scripts by path

Use `$CLAUDE_PROJECT_DIR` for project-relative paths and `${CLAUDE_PLUGIN_ROOT}` for plugin-bundled scripts:

```json
{ "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-style.sh" }
```

Plugin hooks go in `hooks/hooks.json` with an optional top-level `description` field.

### Hooks in skills and agents

Hooks can be defined in skill/agent YAML frontmatter, scoped to the component's lifecycle. All events are supported. For subagents, `Stop` hooks are automatically converted to `SubagentStop`.

```yaml
---
name: secure-operations
description: Perform operations with security checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
---
```

## Hook input and output

### Common input fields

All hook events receive these fields via stdin as JSON:

| Field             | Description                                                                                            |
| :---------------- | :----------------------------------------------------------------------------------------------------- |
| `session_id`      | Current session identifier                                                                             |
| `transcript_path` | Path to conversation JSON                                                                              |
| `cwd`             | Current working directory when the hook is invoked                                                     |
| `permission_mode` | `"default"`, `"plan"`, `"acceptEdits"`, `"dontAsk"`, or `"bypassPermissions"`                          |
| `hook_event_name` | Name of the event that fired                                                                           |

### Exit code output

- **Exit 0**: success. stdout parsed for JSON. For most events stdout is verbose-mode only. Exceptions: `UserPromptSubmit` and `SessionStart` add stdout as context for Claude.
- **Exit 2**: blocking error. stderr fed to Claude as error. Effect depends on event (see table).
- **Any other exit code**: non-blocking error. stderr shown in verbose mode, execution continues.

#### Exit code 2 behavior per event

| Hook event           | Can block? | What happens on exit 2                                    |
| :------------------- | :--------- | :-------------------------------------------------------- |
| `PreToolUse`         | Yes        | Blocks the tool call                                      |
| `PermissionRequest`  | Yes        | Denies the permission                                     |
| `UserPromptSubmit`   | Yes        | Blocks prompt processing and erases the prompt            |
| `Stop`               | Yes        | Prevents Claude from stopping, continues the conversation |
| `SubagentStop`       | Yes        | Prevents the subagent from stopping                       |
| `TeammateIdle`       | Yes        | Prevents the teammate from going idle (continues working) |
| `TaskCompleted`      | Yes        | Prevents the task from being marked as completed          |
| `ConfigChange`       | Yes        | Blocks the configuration change (except `policy_settings`) |
| `PostToolUse`        | No         | Shows stderr to Claude (tool already ran)                 |
| `PostToolUseFailure` | No         | Shows stderr to Claude (tool already failed)              |
| `Notification`       | No         | Shows stderr to user only                                 |
| `SubagentStart`      | No         | Shows stderr to user only                                 |
| `SessionStart`       | No         | Shows stderr to user only                                 |
| `SessionEnd`         | No         | Shows stderr to user only                                 |
| `PreCompact`         | No         | Shows stderr to user only                                 |
| `WorktreeCreate`     | Yes        | Any non-zero exit code causes worktree creation to fail   |
| `WorktreeRemove`     | No         | Failures are logged in debug mode only                    |

### JSON output

Exit 0 and print a JSON object to stdout. Only processed on exit 0. stdout must contain only the JSON object.

| Field            | Default | Description                                                                |
| :--------------- | :------ | :------------------------------------------------------------------------- |
| `continue`       | `true`  | If `false`, Claude stops entirely. Takes precedence over decision fields   |
| `stopReason`     | none    | Message shown to user when `continue` is `false`. Not shown to Claude      |
| `suppressOutput` | `false` | If `true`, hides stdout from verbose mode                                  |
| `systemMessage`  | none    | Warning message shown to the user                                          |

#### Decision control

| Events                                                                              | Decision pattern     | Key fields                                                        |
| :---------------------------------------------------------------------------------- | :------------------- | :---------------------------------------------------------------- |
| UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SubagentStop, ConfigChange | Top-level `decision` | `decision: "block"`, `reason`                                     |
| TeammateIdle, TaskCompleted                                                         | Exit code only       | Exit code 2 blocks the action, stderr is fed back as feedback     |
| PreToolUse                                                                          | `hookSpecificOutput` | `permissionDecision` (allow/deny/ask), `permissionDecisionReason` |
| PermissionRequest                                                                   | `hookSpecificOutput` | `decision.behavior` (allow/deny)                                  |
| WorktreeCreate                                                                      | stdout path          | Hook prints absolute path to created worktree. Non-zero exit fails creation |
| WorktreeRemove, Notification, SessionEnd, PreCompact                                | None                 | No decision control. Used for side effects like logging or cleanup |

**Top-level decision** (UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SubagentStop):

```json
{ "decision": "block", "reason": "Test suite must pass before proceeding" }
```

**PreToolUse** (allow, deny, or escalate to user; can modify tool input):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Database writes are not allowed"
  }
}
```

**PermissionRequest** (allow or deny on behalf of the user):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": { "behavior": "allow", "updatedInput": { "command": "npm run lint" } }
  }
}
```

## Prompt-based hooks

Set `type: "prompt"` with a `prompt` string. Use `$ARGUMENTS` to inject hook input. The LLM returns a structured decision.

Supported events (all three hook types): `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `TaskCompleted`.

Command-only events: `ConfigChange`, `Notification`, `PreCompact`, `SessionEnd`, `SessionStart`, `SubagentStart`, `TeammateIdle`, `WorktreeCreate`, `WorktreeRemove`.

**Response schema**: `{ "ok": true }` to allow, `{ "ok": false, "reason": "..." }` to block.

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Evaluate if Claude should stop: $ARGUMENTS. Check if all tasks are complete. Respond with JSON: {\"ok\": true} or {\"ok\": false, \"reason\": \"...\"}.",
        "timeout": 30
      }]
    }]
  }
}
```

## Agent-based hooks

Set `type: "agent"`. Like prompt hooks but with multi-turn tool access (Read, Grep, Glob). Up to 50 turns. Same response schema. Supported on the same events as prompt hooks.

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "agent",
        "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
        "timeout": 120
      }]
    }]
  }
}
```

## Async hooks

Set `"async": true` on a command hook to run in the background. Only `type: "command"` supports async.

- Cannot return decisions (action has already proceeded)
- Output (`systemMessage`, `additionalContext`) delivered on the next conversation turn
- Each execution creates a separate background process (no deduplication)
- Default timeout: 600 seconds

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/run-tests-async.sh",
        "async": true,
        "timeout": 300
      }]
    }]
  }
}
```
