---
name: plugin-structure
description: Answers questions about Claude Code plugin directory structure, organization, and manifest configuration. Use when the user asks about plugin layout, plugin.json schema, component organization (commands, agents, skills, hooks), auto-discovery, ${CLAUDE_PLUGIN_ROOT}, file naming conventions, or plugin architecture patterns.
argument-hint: "[question about plugin structure]"
user-invocable: false
context: fork
agent: ccode:docs-guide
allowed-tools: Read, Glob, Grep
---

# Answer a Plugin Structure Question

You are answering a question about Claude Code plugin directory structure, manifest configuration, and component organization. Follow this workflow precisely.

**User question**: `$ARGUMENTS`

## Step 1: Classify the Question

Determine which subtopic the question covers:

| Subtopic | Primary source | Additional sources |
|---|---|---|
| Directory layout overview | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | |
| Manifest (plugin.json) schema | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-structure/references/manifest-reference.md` |
| Component organization | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-structure/references/component-patterns.md` |
| Auto-discovery mechanism | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | |
| ${CLAUDE_PLUGIN_ROOT} usage | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | |
| Naming conventions | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | |
| Minimal plugin example | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-structure/examples/minimal-plugin.md` | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` |
| Standard plugin example | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-structure/examples/standard-plugin.md` | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` |
| Advanced/full plugin example | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-structure/examples/advanced-plugin.md` | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` |
| Converting standalone to plugin | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | |
| Plugin best practices | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-structure/references/component-patterns.md` |
| Troubleshooting | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` | |

Use progressive disclosure: start with the knowledge file, add reference/example files only when deeper detail is needed.

## Step 2: Read Matched Files

Read **only** the files that match the classified subtopic (1-3 files max). For example files, use Glob to list available examples first.

## Step 3: Answer

Provide a concise, accurate answer based **only** on the content of the files you read. Include:

- Direct answer to the question
- Relevant configuration snippets, directory trees, or code examples
- Source citations: mention which file(s) the answer came from

**Rules**:
- Do not invent information not present in the source files
- If no source file covers the question, say so honestly
- Do not create or scaffold any files -- only answer questions
