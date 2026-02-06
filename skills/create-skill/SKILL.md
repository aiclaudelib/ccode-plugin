---
name: create-skill
description: Scaffold a new Claude Code skill with correct SKILL.md frontmatter, progressive disclosure, and best practices. Creates the skill directory and files.
argument-hint: "[skill-name]"
context: fork
agent: ccode:skill-expert
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Create a New Claude Code Skill

You are creating a new skill for Claude Code. Follow this workflow precisely.

## Step 1: Gather Requirements

Ask the user these questions (skip any already answered via arguments):

1. **Skill name**: What should this skill be called? (lowercase, hyphens, max 64 chars, no "anthropic" or "claude")
   - Suggested name from arguments: `$ARGUMENTS`
2. **Purpose**: What should this skill do? What problem does it solve?
3. **Invocation mode**:
   - User-only (`disable-model-invocation: true`) — for workflows with side effects like deploy, commit
   - Claude-only (`user-invocable: false`) — for background knowledge
   - Both (default) — Claude loads when relevant, user can invoke with `/name`
4. **Execution context**:
   - Inline (default) — runs in main conversation, good for reference content
   - Forked (`context: fork`) — runs in isolated subagent, good for task-oriented skills
5. **Tools needed**: Which tools should be allowed without permission? (e.g., `Read, Grep, Glob, Bash`)
6. **Target location**:
   - Personal: `~/.claude/skills/$ARGUMENTS/SKILL.md`
   - Project: `.claude/skills/$ARGUMENTS/SKILL.md`
   - Plugin: specify plugin directory

## Step 2: Consult Knowledge Base

If needed for detailed specs, read:
- `${CLAUDE_PLUGIN_ROOT}/knowledge/skills.md` — full skill reference
- `${CLAUDE_PLUGIN_ROOT}/knowledge/skills-best-practices.md` — authoring best practices

## Step 3: Generate, Verify, and Report

Generate the skill directory and SKILL.md following the agent's embedded schema and rules. Verify correctness, then tell the user what was created, where, and how to test it.
