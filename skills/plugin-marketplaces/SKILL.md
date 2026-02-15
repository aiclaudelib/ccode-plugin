---
name: plugin-marketplaces
description: Answers questions about creating and distributing Claude Code plugin marketplaces. Use when the user asks about marketplace.json schema, marketplace file structure, plugin sources (GitHub, git URL, relative paths), hosting marketplaces, team marketplace configuration, strictKnownMarketplaces, extraKnownMarketplaces, marketplace validation, marketplace catalogs, or distributing plugins via catalogs.
argument-hint: "[question about plugin marketplaces]"
user-invocable: false
context: fork
agent: ccode:docs-guide
allowed-tools: Read, Glob, Grep
---

# Answer a Plugin Marketplace Question

You are answering a question about creating and distributing Claude Code plugin marketplaces. Follow this workflow precisely.

**User question**: `$ARGUMENTS`

## Step 1: Classify the Question

Determine which subtopic the question covers:

| Subtopic | Primary source | Additional sources |
|---|---|---|
| Marketplace overview / concepts | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | |
| marketplace.json schema | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/references/marketplace-schema.md` |
| Plugin entry fields | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/references/marketplace-schema.md` |
| Plugin sources (GitHub, git, relative) | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/references/plugin-sources.md` |
| Hosting / distribution | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/references/plugin-sources.md` |
| Private repository authentication | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/references/plugin-sources.md` |
| Team configuration (extraKnownMarketplaces) | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | |
| Managed restrictions (strictKnownMarketplaces) | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | |
| Minimal marketplace example | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/examples/minimal-marketplace.md` | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` |
| Advanced marketplace example | `${CLAUDE_PLUGIN_ROOT}/skills/plugin-marketplaces/examples/advanced-marketplace.md` | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` |
| Validation and testing | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | |
| Troubleshooting | `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-marketplaces.md` | |

Use progressive disclosure: start with the knowledge file, add reference/example files only when deeper detail is needed.

## Step 2: Read Matched Files

Read **only** the files that match the classified subtopic (1-3 files max). For example files, use Glob to list available examples first.

## Step 3: Answer

Provide a concise, accurate answer based **only** on the content of the files you read. Include:

- Direct answer to the question
- Relevant JSON configuration snippets or directory structures
- Source citations: mention which file(s) the answer came from

**Rules**:
- Do not invent information not present in the source files
- If no source file covers the question, say so honestly
- Do not create or scaffold any files -- only answer questions
