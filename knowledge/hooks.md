# Hooks guide

Hooks are user-defined shell commands, LLM prompts, or agent evaluations that execute at specific lifecycle points in Claude Code. They provide deterministic control over behavior. For full event schemas and JSON formats, see hooks-reference-core.md and hooks-reference-events.md.

## Hook events

| Event | When it fires | Can block? |
|---|---|---|
| `SessionStart` | Session begins/resumes | No |
| `UserPromptSubmit` | User submits prompt | Yes (exit 2) |
| `PreToolUse` | Before tool executes | Yes (exit 2 or JSON deny) |
| `PermissionRequest` | Permission dialog shown | Yes (JSON deny) |
| `PostToolUse` | After tool succeeds | No (shows feedback) |
| `PostToolUseFailure` | After tool fails | No |
| `Notification` | Claude sends notification | No |
| `SubagentStart` | Subagent spawned | No |
| `SubagentStop` | Subagent finishes | Yes |
| `Stop` | Claude finishes responding | Yes |
| `PreCompact` | Before compaction | No |
| `SessionEnd` | Session terminates | No |

## Hook types

- **`command`** — shell script. Receives JSON on stdin, uses exit codes + stdout/stderr.
- **`prompt`** — single-turn LLM evaluation (Haiku default). Returns `{"ok": true/false, "reason": "..."}`.
- **`agent`** — multi-turn subagent with tool access. Same response format.

## Configuration format

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

## Hook locations

| Location | Scope |
|---|---|
| `~/.claude/settings.json` | All your projects |
| `.claude/settings.json` | Single project (committable) |
| `.claude/settings.local.json` | Single project (gitignored) |
| Plugin `hooks/hooks.json` | When plugin enabled |
| Skill/agent frontmatter | While component active |

## Input and output

**Input**: JSON on stdin with `session_id`, `cwd`, `hook_event_name`, plus event-specific fields (`tool_name`, `tool_input` for tool events, `prompt` for UserPromptSubmit, etc.).

**Exit codes**: 0 = proceed (stdout parsed for JSON), 2 = block (stderr fed to Claude), other = non-blocking error.

**JSON output** (exit 0): For `PreToolUse`, use `hookSpecificOutput` with `permissionDecision` (`allow`/`deny`/`ask`). For `PostToolUse`/`Stop`, use top-level `decision: "block"` + `reason`.

## Matchers

| Event | What matcher filters | Examples |
|---|---|---|
| Tool events (`Pre/Post/Failure/Permission`) | Tool name | `Bash`, `Edit\|Write`, `mcp__.*` |
| `SessionStart` | How session started | `startup`, `resume`, `compact` |
| `SessionEnd` | Why session ended | `clear`, `logout`, `other` |
| `Notification` | Notification type | `permission_prompt`, `idle_prompt` |
| `SubagentStart`/`Stop` | Agent type | `Bash`, `Explore`, custom names |
| `PreCompact` | Trigger | `manual`, `auto` |
| `UserPromptSubmit`, `Stop` | No matcher support | Always fires |

MCP tools follow naming `mcp__<server>__<tool>`. Match with `mcp__memory__.*`.

## Common patterns

**Auto-format after edits**: `PostToolUse` + `Edit|Write` matcher + prettier command.

**Block protected files**: `PreToolUse` + `Edit|Write` + script checking file paths, exit 2 to block.

**Re-inject context after compaction**: `SessionStart` + `compact` matcher + echo context to stdout.

**Desktop notifications**: `Notification` + platform notification command.

## Stop hook loop prevention

Always check `stop_hook_active` in Stop hooks:

```bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi
```

## Troubleshooting

- **Hook not firing**: Check matcher case-sensitivity, verify event type, check `/hooks` menu
- **JSON validation failed**: Shell profile `echo` statements interfere — wrap in `if [[ $- == *i* ]]`
- **Stop hook loops**: Must check `stop_hook_active` field
- **Debug**: `claude --debug` or toggle verbose mode with `Ctrl+O`
