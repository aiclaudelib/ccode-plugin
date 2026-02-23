# Custom subagents reference

Subagents are specialized AI assistants that run in their own context window with a custom system prompt, tool access, and permissions. Claude delegates tasks to subagents based on their `description` field.

**Key constraint**: Subagents cannot spawn other subagents.

## Built-in subagents

| Agent | Model | Tools | Purpose |
|---|---|---|---|
| **Explore** | Haiku | Read-only | Fast codebase search/exploration |
| **Plan** | Inherits | Read-only | Plan mode research |
| **general-purpose** | Inherits | All | Complex multi-step tasks |
| Bash | Inherits | Bash | Terminal commands in separate context |
| statusline-setup | Sonnet | — | When you run `/statusline` to configure status line |
| Claude Code Guide | Haiku | — | When you ask questions about Claude Code features |

## Subagent locations (priority order)

| Location | Scope | Priority |
|---|---|---|
| `--agents` CLI flag | Current session | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All projects | 3 |
| Plugin `agents/` | Where plugin enabled | 4 (lowest) |

## Frontmatter fields

Markdown files with YAML frontmatter. Only `name` and `description` are required.

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Unique identifier, lowercase + hyphens |
| `description` | Yes | When Claude should delegate. Include "use proactively" to encourage proactive delegation |
| `tools` | No | Allowlist of tools. Inherits all if omitted. Use `Task(agent_type)` to restrict spawnable subagents |
| `disallowedTools` | No | Denylist, removed from inherited/specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` (default). Claude can dynamically choose the model at spawn time if not hardcoded |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | Maximum number of agentic turns before the subagent stops |
| `skills` | No | Skills to preload (full content injected at startup, not just available) |
| `mcpServers` | No | MCP servers available to this subagent (name reference or inline definition) |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | `user`, `project`, or `local` — persistent memory scope |
| `background` | No | Set to `true` to always run as a background task (default: `false`) |
| `isolation` | No | Set to `worktree` to run in a temporary git worktree (auto-cleaned if no changes) |

## File format

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

System prompt goes here. This becomes the subagent's instructions.
```

The body is the system prompt. Subagents receive only this prompt (plus environment details), not the full Claude Code system prompt.

## CLI-defined subagents

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer.",
    "prompt": "You are a senior code reviewer.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

Use `prompt` for system prompt (equivalent to markdown body). Supports all frontmatter fields: `description`, `prompt`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `memory`. Session-only, not saved to disk.

## Model selection behavior

- If `model` is omitted or set to `inherit`, the subagent uses the same model as the parent session.
- Claude can **dynamically choose** the model at spawn time based on task complexity (e.g., use `haiku` for simple lookups, `opus` for deep analysis) when the agent definition doesn't hardcode a model.
- The custom `model` field in agent definitions is **respected when spawning teammates** (multi-agent team members), not just regular subagents.

## Tool restriction: Task(agent_type)

When an agent runs as main thread with `claude --agent`, restrict which subagents it can spawn:

```yaml
tools: Task(worker, researcher), Read, Bash
```

This is an allowlist — only `worker` and `researcher` can be spawned. Use `Task` without parentheses to allow all. Omit `Task` entirely to prevent spawning any subagents. This only applies to agents running as main thread; subagents cannot spawn other subagents, so `Task(agent_type)` has no effect in subagent definitions.

## Permission modes

| Mode | Behavior |
|---|---|
| `default` | Standard permission prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny prompts (explicitly allowed tools still work) |
| `bypassPermissions` | Skip all checks (parent `bypassPermissions` overrides) |
| `plan` | Read-only exploration |

## Memory

The `memory` field enables a persistent directory across conversations.

| Scope | Location | Use when |
|---|---|---|
| `user` | `~/.claude/agent-memory/<name>/` | Cross-project learnings (recommended default) |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via VCS |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, private |

When enabled: system prompt includes memory instructions, first 200 lines of `MEMORY.md` included, Read/Write/Edit tools auto-enabled.

## Hooks in subagents

Two ways to configure hooks:

### 1. In subagent frontmatter (scoped to subagent lifecycle)

Supported events in frontmatter:

| Event | Matcher input | When it fires |
|---|---|---|
| `PreToolUse` | Tool name | Before the subagent uses a tool |
| `PostToolUse` | Tool name | After the subagent uses a tool |
| `Stop` | (none) | When the subagent finishes (converted to `SubagentStop` at runtime) |

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
```

`Stop` hooks in frontmatter are auto-converted to `SubagentStop`.

### 2. In settings.json (project-level, main session)

| Event | Matcher input | When it fires |
|---|---|---|
| `SubagentStart` | Agent type name | When a subagent begins execution |
| `SubagentStop` | Agent type name | When a subagent completes |

Both support matchers to target specific agent types by name.

## Foreground vs background

- **Foreground**: blocks main conversation, permission prompts and `AskUserQuestion` pass through
- **Background**: concurrent, pre-approves permissions upfront, auto-denies unapproved. No MCP tools. `AskUserQuestion` calls fail but subagent continues. Press **Ctrl+B** to background a running task
- Use `background: true` in frontmatter to always run as background
- If a background subagent fails due to missing permissions, you can resume it in the foreground
- Disable all background tasks: `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`

## Disable subagents

Add to `permissions.deny` array in settings: `"Task(subagent-name)"`, or use `--disallowedTools "Task(Explore)"` CLI flag.

## Managing subagents

- Use `/agents` command to view, create, edit, and delete subagents interactively
- Use `claude agents` CLI to list all configured subagents without interactive session
- Subagents are loaded at session start. If you add a file manually, restart session or use `/agents` to load immediately

## Resuming subagents

Each invocation creates a new instance with fresh context. To continue an existing subagent's work, ask Claude to resume it. Resumed subagents retain full conversation history.

When using `--resume` with `--agent`, the session automatically reuses the `--agent` value from the prior conversation — you don't need to specify the agent again.

Subagent transcripts are stored at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`. They persist independently of the main conversation — main conversation compaction does not affect them.

Subagents support auto-compaction (triggers at ~95% capacity). Override with `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (e.g., `50`).

## Example subagent

```markdown
---
name: code-reviewer
description: Expert code review specialist. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Review for quality, security, performance

Provide feedback by priority: Critical > Warnings > Suggestions.
Include specific fix examples.
```
