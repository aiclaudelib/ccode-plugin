# MCP integration guide

Model Context Protocol (MCP) enables Claude Code plugins to connect with external services and APIs by providing structured tool access. MCP servers expose tools that Claude can call directly, making external service capabilities available within Claude Code sessions. For deeper details on specific server types, authentication flows, or tool usage patterns, see the plugin-dev mcp-integration skill and its references.

## MCP server types

| Type | Transport | Config key | Auth method | Best for |
|---|---|---|---|---|
| stdio | Child process (stdin/stdout) | `command` + `args` | Environment variables | Local tools, custom servers, NPM packages |
| SSE | HTTP + Server-Sent Events | `type: "sse"` + `url` | OAuth (automatic) | Hosted services (Asana, GitHub) |
| HTTP | REST requests | `type: "http"` + `url` | Bearer tokens, API keys | REST API backends, stateless calls |
| WebSocket | Persistent bidirectional | `type: "ws"` + `url` | Bearer tokens | Real-time streaming, low-latency |

### Comparison matrix

| Feature | stdio | SSE | HTTP | WebSocket |
|---|---|---|---|---|
| Direction | Bidirectional | Server-to-client | Request/response | Bidirectional |
| State | Stateful | Stateful | Stateless | Stateful |
| Latency | Lowest | Medium | Medium | Low |
| Setup complexity | Easy | Medium | Easy | Medium |
| Reconnection | Process respawn | Automatic | N/A | Automatic |

### stdio

Claude Code spawns a local process and communicates via JSON-RPC over stdin/stdout. The process runs for the entire session and terminates when Claude Code exits.

**NPM package server**:
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"],
    "env": {
      "LOG_LEVEL": "debug"
    }
  }
}
```

**Custom server bundled with plugin**:
```json
{
  "custom": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "API_KEY": "${MY_API_KEY}"
    }
  }
}
```

**Python server**:
```json
{
  "python-server": {
    "command": "python",
    "args": ["-m", "my_mcp_server"],
    "env": {
      "PYTHONUNBUFFERED": "1",
      "DATABASE_URL": "${DB_URL}"
    }
  }
}
```

**stdio best practices**:
- Use `${CLAUDE_PLUGIN_ROOT}` for all file paths (portability)
- Set `PYTHONUNBUFFERED=1` for Python servers to avoid output buffering
- Log to stderr, not stdout (stdout is reserved for the MCP JSON-RPC protocol)
- Pass configuration via `args` or `env`, not stdin
- Handle server crashes gracefully

### SSE

Connect to hosted MCP servers via HTTP with server-sent events for streaming. OAuth is handled automatically by Claude Code: the user is prompted in a browser on first use, tokens are stored securely and refreshed automatically.

**Basic (OAuth)**:
```json
{
  "asana": {
    "type": "sse",
    "url": "https://mcp.asana.com/sse"
  }
}
```

**With custom headers**:
```json
{
  "service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse",
    "headers": {
      "X-API-Version": "v1",
      "X-Client-ID": "${CLIENT_ID}"
    }
  }
}
```

Known OAuth-enabled MCP servers include Asana (`https://mcp.asana.com/sse`) and GitHub (`https://mcp.github.com/sse`).

**SSE best practices**:
- Always use HTTPS, never HTTP
- Let OAuth handle authentication when available
- Document required OAuth scopes in your README
- Handle connection failures gracefully

### HTTP

Stateless request/response pattern. Each tool call is an independent HTTP request. Best for REST API backends and token-based authentication.

**With bearer token**:
```json
{
  "api-service": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}",
      "Content-Type": "application/json",
      "X-API-Version": "2024-01-01"
    }
  }
}
```

**With API key**:
```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "X-API-Key": "${API_KEY}",
      "X-API-Secret": "${API_SECRET}"
    }
  }
}
```

Request flow: GET for tool discovery, POST for tool invocation, JSON response with results or errors.

### WebSocket

Persistent bidirectional channel via WebSocket. Supports automatic reconnection, heartbeat/keep-alive, and message buffering during disconnection.

```json
{
  "realtime": {
    "type": "ws",
    "url": "wss://mcp.example.com/ws",
    "headers": {
      "Authorization": "Bearer ${TOKEN}",
      "X-Client-ID": "${CLIENT_ID}"
    }
  }
}
```

Use cases: real-time data streaming, live updates, collaborative editing, push notifications from server.

**WebSocket best practices**:
- Always use WSS (secure WebSocket), never WS
- Handle reconnection and message buffering
- Set connection timeouts

## Configuration methods

Plugins can bundle MCP servers in two ways.

### Method 1: .mcp.json at plugin root (recommended)

Create `.mcp.json` at the plugin root level. Best for multi-server setups and clean separation of concerns.

```json
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "DB_URL": "${DB_URL}"
    }
  },
  "cloud-api": {
    "type": "sse",
    "url": "https://mcp.example.com/sse"
  }
}
```

### Method 2: Inline in plugin.json

Add `mcpServers` field directly to plugin.json. Good for simple single-server plugins.

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

Use `.mcp.json` for multi-server setups or cleaner separation. Use inline for simple single-server plugins.

## Environment variable expansion

All MCP configuration fields support `${VAR}` substitution.

| Variable | Source | Example |
|---|---|---|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin directory (always available) | `"${CLAUDE_PLUGIN_ROOT}/servers/run.sh"` |
| `${MY_API_KEY}` | User's shell environment | `"env": {"API_KEY": "${MY_API_KEY}"}` |

**In command/args**:
```json
{
  "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server"
}
```

**In env block**:
```json
{
  "env": {
    "API_KEY": "${MY_API_KEY}",
    "DATABASE_URL": "${DB_URL}"
  }
}
```

**In headers**:
```json
{
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

Document all required environment variables in the plugin README, including where users can obtain them.

## Tool naming

MCP tools are automatically prefixed when registered with Claude Code.

**Format**: `mcp__plugin_<plugin-name>_<server-name>__<tool-name>`

**Examples**:

| Plugin | Server | Tool | Full name |
|---|---|---|---|
| `asana` | `asana` | `create_task` | `mcp__plugin_asana_asana__asana_create_task` |
| `myplug` | `database` | `query` | `mcp__plugin_myplug_database__query` |
| `myplug` | `database` | `list_tables` | `mcp__plugin_myplug_database__list_tables` |

Discover all available tool names by running `/mcp` in Claude Code.

### Pre-allowing MCP tools in commands

Specify MCP tools in command frontmatter so Claude can use them without permission prompts:

```yaml
---
description: Create a new task
allowed-tools: [
  "mcp__plugin_asana_asana__asana_create_task",
  "mcp__plugin_asana_asana__asana_search_tasks"
]
---
```

Wildcard `mcp__plugin_asana_asana__*` is supported but discouraged for security -- prefer explicit tool lists.

### Using MCP tools in agents

Agents have broader tool access and do not require `allowed-tools` in frontmatter. Document which tools the agent typically uses in its instructions:

```markdown
---
name: status-updater
description: Generates project status reports from Asana
---
Process:
1. Query tasks via mcp__plugin_asana_asana__asana_search_tasks
2. Analyze completion rates
3. Generate formatted report
```

## Authentication patterns

### OAuth (SSE/HTTP)

No extra configuration needed. Claude Code handles the complete OAuth 2.0 flow:
1. User triggers an MCP tool
2. Claude Code detects authentication is needed
3. Browser opens for OAuth consent
4. User authorizes in browser
5. Tokens stored securely and refreshed automatically

Document required OAuth scopes in your README so users know what they are authorizing.

### Bearer tokens / API keys

Pass via `headers` field with environment variable references:

```json
{
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

Or for API key patterns:

```json
{
  "headers": {
    "X-API-Key": "${API_KEY}"
  }
}
```

### Environment variables (stdio)

Pass credentials to local processes via the `env` block:

```json
{
  "env": {
    "DATABASE_URL": "${DB_URL}",
    "DB_USER": "${DB_USER}",
    "DB_PASSWORD": "${DB_PASSWORD}"
  }
}
```

Users set these in their shell before starting Claude Code:

```bash
export DATABASE_URL="postgresql://localhost/mydb"
export DB_USER="myuser"
export DB_PASSWORD="mypassword"
```

### Dynamic headers

Use `headersHelper` for tokens that change, expire, or require computation (HMAC, JWT):

```json
{
  "type": "sse",
  "url": "https://api.example.com",
  "headersHelper": "${CLAUDE_PLUGIN_ROOT}/scripts/get-headers.sh"
}
```

The script must output a JSON object of header key/value pairs to stdout:

```bash
#!/bin/bash
TOKEN=$(get-fresh-token-from-somewhere)
cat <<EOF
{
  "Authorization": "Bearer $TOKEN",
  "X-Timestamp": "$(date -Iseconds)"
}
EOF
```

Use cases: short-lived tokens, HMAC request signing, JWT generation, time-based authentication.

### Multi-tenancy

Support workspace selection via environment variables:

```json
{
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}",
    "X-Workspace-ID": "${WORKSPACE_ID}"
  }
}
```

Or via URL:

```json
{
  "url": "https://${TENANT_ID}.api.example.com/mcp"
}
```

## Lifecycle

1. Plugin loads and MCP configuration is parsed
2. Server process starts (stdio) or connection established (SSE/HTTP/WS)
3. Tools are discovered and registered with the `mcp__plugin_...` prefix
4. Tools become available to commands, agents, and skills
5. Server shuts down when Claude Code exits

**Lazy loading**: not all servers connect at startup. First tool use may trigger connection establishment. Connection pooling is managed automatically.

View all active servers and their tools with `/mcp`. Use `claude --debug` for detailed connection logs.

Configuration changes require restarting Claude Code.

## Integration patterns

### Pattern 1: Simple tool wrapper (command)

Commands that add validation or preprocessing before MCP calls:

```markdown
---
description: Create a new Asana task
allowed-tools: ["mcp__plugin_asana_asana__asana_create_task"]
---
1. Gather task details from user (title, description, project)
2. Validate required fields are not empty
3. Call mcp__plugin_asana_asana__asana_create_task
4. Confirm creation and show task link
```

### Pattern 2: Sequential tool calls

Chain multiple MCP operations:

```markdown
---
allowed-tools: [
  "mcp__plugin_api_server__search",
  "mcp__plugin_api_server__create",
  "mcp__plugin_api_server__update_metadata"
]
---
1. Search for existing items: mcp__plugin_api_server__search
2. If not found, create new: mcp__plugin_api_server__create
3. Add metadata: mcp__plugin_api_server__update_metadata
4. Return final item ID
```

### Pattern 3: Autonomous agent

Agents use MCP tools autonomously without pre-allowing:

```markdown
---
name: data-analyzer
description: Analyzes data from external database
---
1. Query data via mcp__plugin_db_server__query
2. Process and analyze results
3. Generate insights report
```

### Pattern 4: Multi-server plugin

Combine different server types for workflows spanning multiple services:

```json
{
  "local-db": {
    "command": "npx",
    "args": ["-y", "mcp-server-sqlite", "./data.db"]
  },
  "github": {
    "type": "sse",
    "url": "https://mcp.github.com/sse"
  },
  "internal-api": {
    "type": "http",
    "url": "https://api.internal.com/mcp",
    "headers": {
      "Authorization": "Bearer ${INTERNAL_TOKEN}"
    }
  }
}
```

## Performance considerations

### Batching requests

Prefer single queries with filters over many individual calls:

```
# Good: Single query with filters
search_tasks(project="X", assignee="me", limit=50)

# Avoid: Many individual queries
for id in task_ids:
    get_task(id)
```

### Parallel tool calls

When tools do not depend on each other, Claude can call them in parallel automatically. Structure commands to enable this:

```markdown
1. Make parallel calls:
   - mcp__plugin_api_server__get_project
   - mcp__plugin_api_server__get_users
   - mcp__plugin_api_server__get_tags
2. Combine results
```

### Error handling in commands

Provide graceful degradation:

```markdown
1. Try mcp__plugin_api_server__get_data
2. If error (rate limit, network, auth):
   - Inform user of the issue
   - Suggest checking configuration
   - Provide fallback behavior if possible
3. On success, process data
```

## Security best practices

| Do | Do not |
|---|---|
| Use `${VAR}` for all tokens and secrets | Hardcode tokens in configuration |
| Use HTTPS / WSS for network servers | Use HTTP / WS |
| Pre-allow specific tools in commands | Use wildcard `*` for tool permissions |
| Document required env vars in README | Commit credentials to git |
| Let OAuth handle auth when available | Store tokens in plugin files |
| Rotate tokens regularly | Log tokens or sensitive headers |
| Validate command paths for stdio | Execute user-provided commands |

## Choosing a server type

**Use stdio when** you distribute a server with the plugin, need lowest latency, or work with local resources (files, databases). Ideal for NPM-packaged servers (`npx -y my-mcp-server`), custom Python/Node servers, and local database connections.

**Use SSE when** connecting to hosted services with OAuth, especially official MCP endpoints (Asana, GitHub). No local installation needed. Best when the service provider hosts the MCP endpoint.

**Use HTTP when** integrating with REST APIs using token auth for stateless request/response patterns. Good for internal services, microservices, and serverless functions.

**Use WebSocket when** you need real-time bidirectional streaming, push notifications from server, or very low latency. Best for collaborative features and live data updates.

## Testing MCP integration

1. Configure `.mcp.json` at plugin root
2. Load plugin with `claude --plugin-dir ./my-plugin`
3. Run `/mcp` to verify server and tools appear
4. Test tool calls from commands
5. Check `claude --debug` for connection issues
6. Verify authentication works (OAuth flow or token)
7. Test error cases (connection failures, bad auth, rate limiting)

### Validation checklist

- MCP configuration is valid JSON
- Server URL is correct and accessible (or command exists and is executable)
- Required environment variables documented in README
- Tools appear in `/mcp` output
- Authentication works (OAuth consent or token headers)
- Tool calls succeed from commands
- Error cases handled gracefully
- `${CLAUDE_PLUGIN_ROOT}` used for all plugin-relative paths

## Common issues

| Problem | Solution |
|---|---|
| Server not connecting | Check URL, verify server is running (stdio), review `claude --debug` logs |
| Tools not appearing | Run `/mcp`, check tool names exactly, restart Claude Code after config changes |
| Authentication failing | Clear cached tokens, re-authenticate, verify env vars are set |
| OAuth authentication loop | Sign out, clear cached tokens, re-authenticate |
| stdio server crashes | Check command exists and is executable, verify paths use `${CLAUDE_PLUGIN_ROOT}` |
| Stray output breaking protocol | Ensure server logs to stderr, not stdout (stdio servers) |
| Communication failures (stdio) | Check for stray `print`/`console.log` statements, verify JSON-RPC format |
| HTTP 401 | Check token is set and not expired, verify header format |
| HTTP 403 | Token valid but lacks permissions, check scopes |
| HTTP 429 | Rate limiting, implement backoff or reduce request frequency |
| Environment variables not expanding | Verify variables are exported in shell before starting Claude Code |
