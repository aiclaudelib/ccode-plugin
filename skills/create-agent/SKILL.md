---
name: create-agent
description: Scaffold a new Claude Code custom subagent with correct frontmatter, tool configuration, and system prompt. Creates the agent markdown file.
argument-hint: "[agent-name]"
user-invocable: false
context: fork
agent: ccode:plugin-architect
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Create a New Claude Code Subagent

You are creating a new custom subagent for Claude Code. Follow this workflow precisely.

## Step 1: Gather Requirements

Ask the user these questions (skip any already answered via arguments):

1. **Agent name**: What should this agent be called? (lowercase, hyphens)
   - Suggested name from arguments: `$ARGUMENTS`
2. **Specialization**: What should this agent specialize in? What tasks should Claude delegate to it?
3. **Tools**: Which tools does it need?
   - All tools (inherit everything) — for full-capability agents
   - Read-only (`Read, Grep, Glob, Bash`) — for research/review agents
   - Specific tools — list them
   - Any tools to explicitly deny?
4. **Model**: Which model should it use?
   - `inherit` (default) — same as main conversation
   - `haiku` — fast, economical (good for search/exploration)
   - `sonnet` — balanced
   - `opus` — powerful reasoning
5. **Memory**: Should it learn across sessions?
   - `user` — remembers across all projects
   - `project` — project-specific, shareable via version control
   - `local` — project-specific, private
   - None (default)
6. **Permission mode**: `default`, `acceptEdits`, `dontAsk`, `plan`
7. **Target location**: Personal (`~/.claude/agents/`) or Project (`.claude/agents/`)

## Step 2: Consult Knowledge Base

If needed for detailed specs, read:
- `${CLAUDE_PLUGIN_ROOT}/knowledge/subagents.md` — full subagent documentation

## Step 3: Generate, Verify, and Report

Generate the agent markdown file following the agent's embedded schema. Verify correctness, then tell the user what was created, where, and how to test it.
