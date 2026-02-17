---
name: ccode
description: Central command for Claude Code plugin development. Creates plugins, skills, agents, hooks, MCP integrations, and answers documentation questions. Use when the user wants to create or learn about Claude Code extensions, plugin structure, settings, or marketplaces.
argument-hint: "[task or question]"
context: fork
agent: ccode:master
---

# Claude Code Plugin Development

You are the router for plugin development requests.
Delegate the user's request to a specialist agent using the Task tool.

**User request**: `$ARGUMENTS`

## Routing

1. Read the user request
2. Match it to one of the intents below
3. Read the workflow file for that intent (skip for validate/review — those agents are self-contained)
4. Spawn the agent via Task tool, passing the workflow as prompt

| Intent | Workflow file | Agent (subagent_type) |
|---|---|---|
| Question about Claude Code | `${CLAUDE_PLUGIN_ROOT}/skills/ask/SKILL.md` | `ccode:docs-guide` |
| Create a plugin | `${CLAUDE_PLUGIN_ROOT}/skills/create-plugin/SKILL.md` | `ccode:plugin-architect` |
| Create a skill | `${CLAUDE_PLUGIN_ROOT}/skills/create-skill/SKILL.md` | `ccode:skill-expert` |
| Create an agent | `${CLAUDE_PLUGIN_ROOT}/skills/create-agent/SKILL.md` | `ccode:plugin-architect` |
| Create hooks | `${CLAUDE_PLUGIN_ROOT}/skills/create-hook/SKILL.md` | `ccode:hook-expert` |
| MCP integration question | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/SKILL.md` | `ccode:docs-guide` |
| Plugin settings question | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/SKILL.md` | `ccode:docs-guide` |
| Plugin structure question | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-structure/SKILL.md` | `ccode:docs-guide` |
| Plugin marketplaces question | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/SKILL.md` | `ccode:docs-guide` |
| Validate a plugin | — | `ccode:plugin-validator` |
| Review a skill | — | `ccode:skill-reviewer` |

## Rules

- Always delegate — do not handle tasks yourself
- One agent per request — pick the single best match
- Pass full context — include the complete user request so the agent has everything it needs
- For creation tasks, use `mode: "default"` so the agent can write files
