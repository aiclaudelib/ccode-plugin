# MCP Server Types: Deep Dive

Complete reference for all MCP server types supported in Claude Code plugins.

> **Note**: Claude Code supports three transport types: **stdio**, **HTTP** (streamable-http, recommended for remote servers), and **SSE** (deprecated). WebSocket is not a supported MCP transport.

## stdio (Standard Input/Output)

### Overview

Execute local MCP servers as child processes with communication via stdin/stdout. Best choice for local tools, custom servers, and NPM packages. Claude Code spawns the process, communicates via JSON-RPC, and manages the process lifecycle.

### Configuration

**Basic NPM package:**
```json
{
  "my-server": {
    "command": "npx",
    "args": ["-y", "my-mcp-server"]
  }
}
```

**Custom server bundled with plugin:**
```json
{
  "my-server": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/custom-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "API_KEY": "${MY_API_KEY}",
      "LOG_LEVEL": "debug",
      "DATABASE_URL": "${DB_URL}"
    }
  }
}
```

**Python server:**
```json
{
  "python-server": {
    "command": "python",
    "args": ["-m", "my_mcp_server"],
    "env": {
      "PYTHONUNBUFFERED": "1"
    }
  }
}
```

**Node.js server with custom entry point:**
```json
{
  "node-server": {
    "command": "node",
    "args": ["${CLAUDE_PLUGIN_ROOT}/servers/my-server/index.js", "--port", "0"],
    "env": {
      "NODE_ENV": "production",
      "LOG_FORMAT": "json"
    }
  }
}
```

### Process Lifecycle

1. **Startup**: Claude Code spawns process with `command` and `args`
2. **Initialization**: Server performs setup (loading config, connecting to databases)
3. **Tool Registration**: Server declares available tools via MCP protocol
4. **Communication**: JSON-RPC messages via stdin/stdout throughout session
5. **Lifecycle**: Process runs for entire Claude Code session
6. **Shutdown**: Process terminated (SIGTERM, then SIGKILL) when Claude Code exits

### Configuration Fields

| Field | Required | Description |
|---|---|---|
| `command` | Yes | Executable to run (binary path, `npx`, `node`, `python`, etc.) |
| `args` | No | Array of command-line arguments |
| `env` | No | Object of environment variables to set for the process |
| `cwd` | No | Working directory for the process (supports `${CLAUDE_PLUGIN_ROOT}`) |

Note: stdio servers are the **default type**. If you omit `type`, Claude Code assumes stdio and expects `command` to be present.

### Use Cases

**NPM packages (published MCP servers):**
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
  }
}
```

**Custom Node.js servers bundled with plugin:**
```json
{
  "custom": {
    "command": "node",
    "args": ["${CLAUDE_PLUGIN_ROOT}/servers/my-server.js", "--verbose"]
  }
}
```

**Python servers:**
```json
{
  "python-server": {
    "command": "python",
    "args": ["-m", "my_mcp_server"],
    "env": {
      "PYTHONUNBUFFERED": "1"
    }
  }
}
```

**SQLite database access:**
```json
{
  "database": {
    "command": "npx",
    "args": ["-y", "mcp-server-sqlite", "${CLAUDE_PLUGIN_ROOT}/data/app.db"]
  }
}
```

**Go binary server:**
```json
{
  "go-server": {
    "command": "${CLAUDE_PLUGIN_ROOT}/bin/mcp-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.yaml"]
  }
}
```

### Environment Variable Expansion

The `${VAR}` syntax expands from the user's shell environment at startup time. Two special variables are always available:

- `${CLAUDE_PLUGIN_ROOT}` -- absolute path to the plugin root directory
- `${HOME}` -- user's home directory

**Default values with fallback syntax:**
```json
{
  "env": {
    "LOG_LEVEL": "${LOG_LEVEL:-info}",
    "PORT": "${PORT:-8080}"
  }
}
```

If `LOG_LEVEL` is not set in the user's shell, it defaults to `info`.

### Best Practices

1. **Use `${CLAUDE_PLUGIN_ROOT}` for all file paths** -- ensures portability across installations
2. **Set `PYTHONUNBUFFERED=1` for Python servers** -- avoids output buffering that delays MCP communication
3. **Log to stderr, not stdout** -- stdout is reserved for MCP JSON-RPC protocol. Any stray output breaks communication
4. **Pass configuration via `args` or `env`** -- do not send config through stdin
5. **Handle server crashes gracefully** -- Claude Code will attempt to restart on failure
6. **Use `npx -y` for NPM packages** -- the `-y` flag auto-confirms installation, avoiding interactive prompts that block stdio
7. **Keep server startup fast** -- slow initialization delays tool availability. Defer heavy setup until first tool call if possible
8. **Validate environment variables on startup** -- exit early with a clear error message if required variables are missing

### Troubleshooting

**Server won't start:**
- Check command exists and is executable (`chmod +x` for scripts and binaries)
- Verify file paths are correct (use `echo $CLAUDE_PLUGIN_ROOT` in a hook script to debug)
- Check permissions on the server binary or script
- Review `claude --debug` logs for startup errors
- Ensure required runtime is installed (Node.js, Python, Go)

**Communication fails:**
- Ensure server uses stdin/stdout correctly for JSON-RPC
- Check for stray `print()` or `console.log()` statements that corrupt the protocol
- Verify JSON-RPC message format matches MCP specification
- Python: ensure `PYTHONUNBUFFERED=1` is set to prevent buffering
- Node.js: do not use `console.log()` for debugging -- use `console.error()` or write to a log file

**Server exits immediately:**
- Check for missing dependencies (run the command manually first)
- Verify environment variables are set in the user's shell
- Look for crash logs in stderr output
- Check for port conflicts if the server binds to a port
- Ensure the working directory is correct

**Server hangs on startup:**
- Check for interactive prompts that block the process (use `-y` flags where available)
- Verify the server does not wait for stdin input during initialization
- Check for network calls during startup that may time out

---

## SSE (Server-Sent Events) -- Deprecated

> **Deprecated**: SSE transport is deprecated. Use HTTP (streamable-http) servers instead, where available.

### Overview

Connect to hosted MCP servers via HTTP with server-sent events for streaming. Still supported for backward compatibility with existing SSE-only endpoints. The server runs externally (not managed by Claude Code) and Claude Code connects to it over the network.

### Configuration

**Basic (OAuth-enabled):**
```json
{
  "hosted-service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse"
  }
}
```

**With custom headers:**
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

**With dynamic headers from a helper script:**
```json
{
  "service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse",
    "headersHelper": "${CLAUDE_PLUGIN_ROOT}/scripts/get-headers.sh"
  }
}
```

### Configuration Fields

| Field | Required | Description |
|---|---|---|
| `type` | Yes | Must be `"sse"` |
| `url` | Yes | HTTPS URL of the SSE MCP endpoint |
| `headers` | No | Additional HTTP headers (supports `${VAR}` expansion) |
| `headersHelper` | No | Path to script that outputs JSON headers to stdout |

Note: `headers` and `headersHelper` are mutually exclusive. If both are specified, `headersHelper` takes precedence.

### Connection Lifecycle

1. **Initialization**: HTTP connection established to URL
2. **Handshake**: MCP protocol negotiation via initial messages
3. **Streaming**: Server sends events (tool results, notifications) via SSE stream
4. **Requests**: Client sends HTTP POST for tool calls to a separate endpoint
5. **Keep-alive**: Server sends periodic heartbeat events to maintain connection
6. **Reconnection**: Automatic reconnection on disconnect with exponential backoff

### Authentication

Claude Code handles OAuth 2.0 automatically:
1. User attempts to use an MCP tool
2. Claude Code detects authentication needed (server responds with 401)
3. Opens browser for OAuth consent screen
4. User reviews scopes and authorizes in browser
5. Tokens stored securely by Claude Code
6. Automatic token refresh when tokens expire

No additional configuration needed for OAuth. For custom headers (non-OAuth), use the `headers` field.

### Known OAuth-Enabled MCP Servers

- Asana: `https://mcp.asana.com/sse` (SSE)
- GitHub: `https://api.githubcopilot.com/mcp/` (HTTP -- preferred over SSE)
- Sentry: `https://mcp.sentry.dev/mcp` (HTTP)
- Notion: `https://mcp.notion.com/mcp` (HTTP)

These servers are pre-configured for OAuth and work with no authentication setup. Users simply approve the consent screen in their browser on first use. Prefer HTTP endpoints over SSE where both are available.

### SSE Protocol Details

The SSE connection uses two communication channels:

1. **SSE stream (server to client)**: Server pushes events containing tool results, progress updates, and protocol messages. Events follow the standard SSE format with `event:` and `data:` fields.

2. **HTTP POST (client to server)**: Claude Code sends tool invocation requests as HTTP POST to a URL provided during the handshake. The request body contains the JSON-RPC message.

This split architecture means SSE servers can scale horizontally -- the POST endpoint can be load-balanced independently of the streaming endpoint.

### Best Practices

1. **Always use HTTPS, never HTTP** -- insecure connections are rejected by Claude Code
2. **Let OAuth handle authentication when available** -- no credential management needed
3. **Use environment variables for any custom tokens** -- never hardcode
4. **Document required OAuth scopes** in plugin README so users know what they are authorizing
5. **Handle connection failures gracefully** -- network issues are common with long-lived connections
6. **Test with slow networks** -- SSE connections can be affected by proxies and corporate firewalls
7. **Document the server URL clearly** -- users need to know exactly which URL to use

### Troubleshooting

**Connection refused:**
- Check URL is correct and accessible from user's network
- Verify HTTPS certificate is valid (self-signed certificates are rejected)
- Check network connectivity and firewall settings
- Verify the SSE endpoint path is correct (often `/sse` but varies by server)

**OAuth fails:**
- Clear cached tokens (sign out and back in to Claude Code)
- Check OAuth scopes match server requirements
- Verify redirect URLs in OAuth configuration
- Re-authenticate from scratch by removing cached credentials
- Check if the OAuth provider requires specific redirect URI registration

**Connection drops frequently:**
- SSE connections can be affected by proxies and load balancers that have idle timeouts
- Check server-side timeout configuration (increase keep-alive interval)
- Claude Code will auto-reconnect with exponential backoff
- Corporate proxies may terminate long-lived HTTP connections -- check proxy configuration
- Some CDNs buffer SSE responses; the server should disable buffering with appropriate headers

**Slow tool responses:**
- SSE adds network latency compared to stdio
- Check server-side processing time
- Consider using stdio for latency-sensitive operations
- Verify there are no proxy or CDN layers adding latency

---

## HTTP (Streamable HTTP) -- Recommended for Remote Servers

### Overview

The recommended transport for all remote MCP servers. Connect via standard HTTP requests with support for OAuth, bearer tokens, and API keys. Each tool call is an independent HTTP request/response cycle with no persistent connection.

### Configuration

**With bearer token:**
```json
{
  "api": {
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

**With API key:**
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

**With dynamic headers:**
```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headersHelper": "${CLAUDE_PLUGIN_ROOT}/scripts/get-auth-headers.sh"
  }
}
```

### Configuration Fields

| Field | Required | Description |
|---|---|---|
| `type` | Yes | Must be `"http"` |
| `url` | Yes | HTTPS URL of the HTTP MCP endpoint (supports `${VAR}` expansion) |
| `headers` | No | HTTP headers for authentication and metadata (supports `${VAR}` expansion) |
| `headersHelper` | No | Path to script that outputs JSON headers to stdout |
| `oauth` | No | OAuth configuration object with `clientId` and optional `callbackPort` (for pre-configured OAuth apps) |

### Request/Response Flow

1. **Tool Discovery**: POST request to discover available tools (sent once at initialization)
2. **Tool Invocation**: POST request with JSON-RPC body containing tool name and parameters
3. **Response**: JSON response with tool results or error information
4. **Stateless**: Each request is independent (no session state maintained between calls)

### Conditional Configuration with Environment Variables

Use environment variables to switch between dev and production endpoints:

```json
{
  "api": {
    "type": "http",
    "url": "${API_BASE_URL}/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

Users set the appropriate URL:
```bash
# Development
export API_BASE_URL="http://localhost:8080"
export API_TOKEN="dev-token"

# Production
export API_BASE_URL="https://api.production.com"
export API_TOKEN="prod-token"
```

### Use Cases

- REST API backends with existing MCP support
- Internal company services behind VPN
- Microservices with MCP endpoints
- Serverless functions (AWS Lambda, Google Cloud Functions, Azure Functions)
- Services using API key authentication
- Existing REST APIs wrapped with an MCP adapter

### Best Practices

1. **Use HTTPS for all connections** -- HTTP is insecure and may be rejected
2. **Store all tokens in environment variables** -- never hardcode credentials
3. **Document token acquisition** -- tell users exactly where to get tokens and what permissions to request
4. **Handle rate limiting** -- APIs may return 429 Too Many Requests. Commands should handle this gracefully
5. **Set appropriate timeouts** -- slow APIs can block Claude Code from responding
6. **Version your API** -- use `X-API-Version` headers or URL versioning for stability
7. **Use `headersHelper` for short-lived tokens** -- when tokens expire frequently

### Troubleshooting

**HTTP errors:**
- 401 Unauthorized: Check authentication headers and token validity. Ensure `Bearer ` prefix is present
- 403 Forbidden: Token valid but lacks permissions. Check required scopes or roles
- 404 Not Found: Verify URL is correct, including path
- 429 Too Many Requests: Rate limited. Reduce request frequency or implement backoff
- 500 Internal Server Error: Server-side issue. Check server logs if you control the server
- 502/503: Server may be down or deploying. Retry after a brief delay

**Timeout issues:**
- Check server response time -- if consistently slow, investigate server performance
- Optimize tool implementations on the server side
- Consider using SSE for long-running operations that need streaming
- Check if corporate firewalls or proxies add latency

**Empty responses:**
- Verify the server returns proper JSON-RPC responses
- Check Content-Type header on the response (should be `application/json`)
- Ensure the server handles the MCP protocol correctly

---

---

## Comparison Matrix

| Feature | stdio | HTTP (recommended) | SSE (deprecated) |
|---|---|---|---|
| **Transport** | Process stdin/stdout | Streamable HTTP | HTTP + SSE stream |
| **Direction** | Bidirectional | Request/response | Server-push + client POST |
| **State** | Stateful (process) | Stateless | Stateful (connection) |
| **Auth** | Environment variables | OAuth, headers (tokens) | OAuth (automatic) |
| **Latency** | Lowest | Medium | Medium |
| **Setup** | Easy | Easy | Medium |
| **Best for** | Local tools, custom servers | All remote services | Legacy SSE-only endpoints |
| **Reconnect** | Process respawn | N/A (stateless) | Automatic |
| **Server managed by** | Claude Code (child process) | External | External |
| **Network required** | No | Yes | Yes |
| **Offline capable** | Yes | No | No |

## Choosing the Right Type

**Use stdio when:**
- Running local tools or custom servers bundled with plugin
- Need lowest possible latency (no network overhead)
- Working with file systems or local databases
- Distributing server code with the plugin
- Using NPM-packaged MCP servers (most common case)
- Working offline or in restricted network environments
- Building plugins that need to access local resources

**Use HTTP when (recommended for all remote servers):**
- Connecting to hosted cloud services (SaaS products)
- Need OAuth authentication (simplest for users -- no tokens to manage)
- Using official MCP servers (GitHub, Sentry, Notion, Stripe, etc.)
- Integrating with existing REST APIs or microservices
- Using token-based authentication (API keys, bearer tokens)
- Backend is serverless (AWS Lambda, Cloud Functions)
- Deploying a previously local server to production

**Use SSE only when:**
- The service does not yet offer an HTTP (streamable-http) endpoint
- Connecting to legacy SSE-only MCP servers (e.g., `https://mcp.asana.com/sse`)
- SSE transport is deprecated; migrate to HTTP when possible

## Migrating Between Types

### From stdio to HTTP

Deploy your local server as a hosted service, then change configuration:

**Before (stdio):**
```json
{
  "local-server": {
    "command": "node",
    "args": ["server.js"]
  }
}
```

**After (HTTP):**
```json
{
  "hosted-server": {
    "type": "http",
    "url": "https://mcp.example.com/mcp"
  }
}
```

**Migration steps:**
1. Add HTTP transport to your server code
2. Deploy server to a hosting platform
3. Configure HTTPS and authentication
4. Update `.mcp.json` to use HTTP type
5. Test with the hosted endpoint
6. Keep stdio as a fallback for local development

### From SSE to HTTP

Migrate from deprecated SSE to the recommended HTTP transport:

**Before (SSE):**
```json
{
  "service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse"
  }
}
```

**After (HTTP):**
```json
{
  "service": {
    "type": "http",
    "url": "https://mcp.example.com/mcp"
  }
}
```

**Benefits of migration:**
- HTTP is the recommended and actively supported transport
- Full OAuth support including pre-configured credentials
- Simpler architecture (no persistent connection to manage)
- Better compatibility with proxies, CDNs, and load balancers

## Multiple Server Types in One Plugin

Combine different types for different use cases in a single `.mcp.json`:

```json
{
  "local-db": {
    "command": "npx",
    "args": ["-y", "mcp-server-sqlite", "${CLAUDE_PLUGIN_ROOT}/data/app.db"]
  },
  "cloud-api": {
    "type": "http",
    "url": "https://mcp.example.com/mcp"
  },
  "internal-service": {
    "type": "http",
    "url": "https://api.internal.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

This allows a single plugin to work with local databases (stdio), cloud services (HTTP with OAuth), and internal APIs (HTTP with tokens) simultaneously. Each server provides its own set of tools, all available under the `mcp__plugin_<plugin>_<server>__<tool>` naming convention.

## Security Considerations

### stdio Security

- Validate command paths -- do not allow user-controlled command injection
- Restrict environment variable access to what the server needs
- Use `${CLAUDE_PLUGIN_ROOT}` instead of hardcoded paths
- Do not execute user-provided command strings
- Limit file system access in the server to necessary directories

### Network Security (HTTP, SSE)

- Always use HTTPS -- Claude Code rejects insecure connections
- Validate SSL certificates -- do not skip certificate verification
- Use secure token storage (environment variables, not files)
- Implement proper CORS headers on server endpoints
- Use authentication on all endpoints, even health checks in production

### Token Management

- Never hardcode tokens in configuration files or source code
- Use `${VAR}` environment variable expansion
- Rotate tokens regularly and document the rotation process
- Use different tokens for development and production environments
- Document required token scopes and permissions in the plugin README
- Consider using `headersHelper` scripts for short-lived or computed tokens
