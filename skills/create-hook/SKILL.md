---
name: create-hook
description: Create Claude Code hook configurations and validation scripts. Supports all 12 hook events, command/prompt/agent types, and proper JSON schemas.
argument-hint: "[event-name]"
context: fork
agent: ccode:hook-expert
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Create a New Claude Code Hook

You are creating a new hook for Claude Code. Follow this workflow precisely.

## Step 1: Gather Requirements

Ask the user these questions (skip any already answered via arguments):

1. **Event**: Which lifecycle event to hook into?
   - Suggested event from arguments: `$ARGUMENTS`
   - Available events: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `Notification`, `SubagentStart`, `SubagentStop`, `Stop`, `PreCompact`, `SessionEnd`

2. **Matcher**: What should trigger this hook?
   - For tool events: tool name regex (e.g., `Bash`, `Edit|Write`, `mcp__.*`)
   - For SessionStart: `startup`, `resume`, `clear`, `compact`
   - For Notification: `permission_prompt`, `idle_prompt`, etc.
   - Empty/omit to match everything

3. **Hook type**: `command` (shell script), `prompt` (LLM evaluation), or `agent` (multi-turn LLM with tools)

4. **Purpose**: What should the hook do? (format, validate, block, notify, inject context, log)

5. **Target location**:
   - User settings: `~/.claude/settings.json`
   - Project settings: `.claude/settings.json`
   - Plugin hooks: `hooks/hooks.json`
   - Skill/agent frontmatter

## Step 2: Consult Knowledge Base

If needed for detailed event schemas and examples, read:
- `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks.md` — hook guide with examples
- `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks-reference-core.md` — config schema, handler fields, exit codes, JSON I/O, decision control
- `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks-reference-events.md` — per-event input schemas (read only if you need event-specific details)

## Step 3: Generate, Verify, and Report

Generate the hook config and any scripts following the agent's embedded schemas. Verify correctness (valid events, proper exit codes, Stop hook loop prevention), then tell the user what was created, where, and how to test it.
