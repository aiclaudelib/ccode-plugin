---
name: create-plugin
description: Scaffold a complete Claude Code plugin with manifest, skills, agents, hooks, and scripts. Creates the full directory structure ready for testing.
argument-hint: "[plugin-name]"
context: fork
agent: ccode:plugin-architect
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Create a New Claude Code Plugin

You are scaffolding a complete Claude Code plugin. Follow this workflow precisely.

**Important**: Since subagents cannot spawn other subagents, you must generate ALL component files directly — do not attempt to invoke other skills or agents.

## Step 1: Gather Requirements

Ask the user these questions (skip any already answered via arguments):

1. **Plugin name**: What should this plugin be called? (kebab-case, no spaces)
   - Suggested name from arguments: `$ARGUMENTS`
2. **Purpose**: What does this plugin do? Who is it for?
3. **Components needed** (select all that apply):
   - Skills — slash commands and reusable knowledge
   - Agents — specialized subagents
   - Hooks — lifecycle event handlers
   - MCP servers — external tool integrations
4. **For each skill**: name, purpose, invocation mode (manual/auto/both)
5. **For each agent**: name, specialization, tools, model
6. **For each hook**: event, matcher, type, purpose
7. **Author info**: name, email, URL (optional)
8. **License**: MIT, Apache-2.0, etc.

## Step 2: Consult Knowledge Base

If needed for detailed specs, read:
- `${CLAUDE_PLUGIN_ROOT}/knowledge/plugins.md` — plugin creation guide
- `${CLAUDE_PLUGIN_ROOT}/knowledge/plugins-reference.md` — full manifest schema
- `${CLAUDE_PLUGIN_ROOT}/knowledge/skills.md` — skill specs (if creating plugin skills)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/subagents.md` — agent specs (if creating plugin agents)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks-reference-core.md` — hook specs (if creating plugin hooks)

## Step 3: Generate, Verify, and Report

Scaffold the complete directory structure with all requested components following the agent's embedded schemas. Verify correctness (components at root, not inside `.claude-plugin/`; valid frontmatter; `${CLAUDE_PLUGIN_ROOT}` paths), then tell the user all files created and how to test: `claude --plugin-dir ./plugin-name`
