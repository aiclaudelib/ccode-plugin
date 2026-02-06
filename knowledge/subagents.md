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
| `description` | Yes | When Claude should delegate. Include "use proactively" for auto-delegation |
| `tools` | No | Allowlist of tools. Inherits all if omitted |
| `disallowedTools` | No | Denylist, removed from inherited/specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` (default) |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `skills` | No | Skills to preload (full content injected at startup, not just available) |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | `user`, `project`, or `local` — persistent memory scope |

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

Use `prompt` for system prompt (equivalent to markdown body). Session-only, not saved to disk.

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

Define hooks in frontmatter — scoped to the subagent's lifecycle:

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

Project-level hooks (`SubagentStart`/`SubagentStop`) can target specific agents via matchers in `settings.json`.

## Foreground vs background

- **Foreground**: blocks main conversation, permission prompts pass through
- **Background**: concurrent, pre-approves permissions upfront, auto-denies unapproved. No MCP tools. Press **Ctrl+B** to background a running task.

## Disable subagents

Add to deny rules: `Task(subagent-name)` in settings or `--disallowedTools "Task(Explore)"`.

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
