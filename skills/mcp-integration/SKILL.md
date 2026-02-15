---
name: mcp-integration
description: Answers questions about MCP server integration in Claude Code plugins. Use when the user asks about adding MCP servers, configuring .mcp.json, MCP server types (stdio, SSE, HTTP, WebSocket), MCP tool naming, MCP authentication patterns, environment variable expansion, or connecting external services via Model Context Protocol.
argument-hint: "[question about MCP integration]"
user-invocable: false
context: fork
agent: ccode:docs-guide
allowed-tools: Read, Glob, Grep
---

# Answer an MCP Integration Question

You are answering a question about MCP (Model Context Protocol) integration in Claude Code plugins. Follow this workflow precisely.

**User question**: `$ARGUMENTS`

## Step 1: Classify the Question

Determine which subtopic the question covers:

| Subtopic | Primary source | Additional sources |
|---|---|---|
| Server types overview | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | |
| stdio configuration | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/references/server-types.md` |
| SSE configuration | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/references/server-types.md` |
| HTTP configuration | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/references/server-types.md` |
| WebSocket configuration | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/references/server-types.md` |
| Authentication (OAuth, tokens) | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/references/authentication.md` |
| Tool naming and usage | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/references/tool-usage.md` |
| .mcp.json setup | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | |
| Environment variables | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | |
| Troubleshooting | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` | |
| Working examples | `${CLAUDE_PLUGIN_ROOT}/skills/mcp-integration/examples/` | `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` |

Use progressive disclosure: start with the knowledge file, add reference files only when deeper detail is needed.

## Step 2: Read Matched Files

Read **only** the files that match the classified subtopic (1-3 files max). For example files, use Glob to list available examples first.

## Step 3: Answer

Provide a concise, accurate answer based **only** on the content of the files you read. Include:

- Direct answer to the question
- Relevant JSON configuration snippets or code examples
- Source citations: mention which file(s) the answer came from

**Rules**:
- Do not invent information not present in the source files
- If no source file covers the question, say so honestly
- Do not create or scaffold any files -- only answer questions
