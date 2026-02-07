---
name: ask
description: Answers general questions about Claude Code features, configuration, CLI, prompting strategies, plugins, skills, hooks, agents, teams, containers, and enterprise governance. Use when the user asks how something works or needs documentation guidance — not when they want to create or scaffold something.
argument-hint: "[question]"
context: fork
agent: ccode:docs-guide
allowed-tools: Read, Glob, Grep
---

# Answer a Claude Code Question

You are answering a question about Claude Code. Follow this workflow precisely.

**User question**: `$ARGUMENTS`

## Step 1: Classify the Question

Determine which topic category the question falls into:

| Category | Knowledge files |
|---|---|
| Skills (reference) | `${CLAUDE_PLUGIN_ROOT}/knowledge/skills.md` |
| Skills (authoring) | `${CLAUDE_PLUGIN_ROOT}/knowledge/skills-best-practices.md` |
| Skills (concepts) | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/agent-skills.md` |
| Skills (enterprise) | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/skills-for-enterprise.md` |
| Hooks (guide) | `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks.md` |
| Hooks (config schema) | `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks-reference-core.md` |
| Hooks (event schemas) | `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks-reference-events.md` |
| Plugins (creation) | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugins.md`, `${CLAUDE_PLUGIN_ROOT}/knowledge/plugins-reference.md` |
| Plugins (installation) | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/plugins-installation.md` |
| Subagents | `${CLAUDE_PLUGIN_ROOT}/knowledge/subagents.md` |
| Teams | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/agent-teams.md` |
| CLI | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/claude-cli.md` |
| Containers | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/claude-container.md` |
| Prompting (thinking) | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/prompting-for-thinking.md` |
| Prompting (context) | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/prompting-for-context.md` |
| Prompting (hallucinations) | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/prompting-hallucinations.md` |
| Prompting (output) | `${CLAUDE_PLUGIN_ROOT}/knowledge/archive/prompting-output-style.md` |
| MCP Integration | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` |
| Plugin Settings | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` |
| Plugin Structure | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` |

For hooks questions, use progressive disclosure: start with `hooks.md`, add `hooks-reference-core.md` only if config details are needed, add `hooks-reference-events.md` only if event-specific schemas are needed.

For deep dives on MCP, settings, or structure, also read the corresponding skill's references/ directory.

## Step 2: Read Matched Knowledge Files

Read **only** the files that match the classified category (1–3 files max). Do not read files from unrelated categories.

## Step 3: Answer

Provide a concise, accurate answer based **only** on the content of the files you read. Include:

- Direct answer to the question
- Relevant code examples or configuration snippets from the docs
- Source citations: mention which knowledge file(s) the answer came from

**Rules**:
- Do not invent information not present in the knowledge files
- If no knowledge file covers the question, say so honestly
- Do not create or scaffold any files — only answer questions
