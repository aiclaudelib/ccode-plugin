---
name: plugin-settings
description: Answers questions about plugin settings files in Claude Code. Use when the user asks about .local.md files, plugin configuration patterns, storing plugin state, reading YAML frontmatter from hooks, per-project plugin settings, the .claude/plugin-name.local.md convention, or making plugin behavior user-configurable.
argument-hint: "[question about plugin settings]"
context: fork
agent: ccode:docs-guide
allowed-tools: Read, Glob, Grep
---

# Answer a Plugin Settings Question

You are answering a question about the plugin settings pattern in Claude Code (`.claude/plugin-name.local.md` files). Follow this workflow precisely.

**User question**: `$ARGUMENTS`

## Step 1: Classify the Question

Determine which subtopic the question covers:

| Subtopic | Primary source | Additional sources |
|---|---|---|
| Settings overview / concepts | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | |
| File structure / template | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/examples/example-settings.md` |
| Parsing frontmatter (bash) | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/references/parsing-techniques.md` |
| Reading from hooks | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/examples/read-settings-hook.sh` |
| Reading from commands/agents | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/examples/create-settings-command.md` |
| Real-world examples | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/references/real-world-examples.md` | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` |
| Common patterns (temp activation, agent state, config-driven) | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/references/real-world-examples.md` |
| Creating settings files | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/examples/create-settings-command.md` |
| Validation / defaults | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-settings/references/parsing-techniques.md` |
| Best practices / security | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | |
| Troubleshooting | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` | |

Use progressive disclosure: start with the knowledge file, add reference/example files only when deeper detail is needed.

## Step 2: Read Matched Files

Read **only** the files that match the classified subtopic (1-3 files max). For example files, use Glob to list available examples first.

## Step 3: Answer

Provide a concise, accurate answer based **only** on the content of the files you read. Include:

- Direct answer to the question
- Relevant code snippets (bash parsing, YAML templates, hook patterns)
- Source citations: mention which file(s) the answer came from

**Rules**:
- Do not invent information not present in the source files
- If no source file covers the question, say so honestly
- Do not create or scaffold any files -- only answer questions
