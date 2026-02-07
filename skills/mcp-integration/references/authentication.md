# MCP Authentication Patterns

Complete guide to authentication methods for MCP servers in Claude Code plugins.

## Overview

MCP servers support multiple authentication methods depending on the server type and service requirements. Choose the method that matches your use case and security requirements.

| Auth Method | Server Types | User Experience | Best For |
|---|---|---|---|
| OAuth (automatic) | SSE, HTTP | Browser consent flow | Cloud services |
| Bearer tokens | HTTP, SSE, WS | Set env var | REST APIs |
| API keys | HTTP, SSE, WS | Set env var | Simple APIs |
| Environment variables | stdio | Set env var | Local servers |
| Dynamic headers | SSE, HTTP, WS | Script generates headers | Rotating tokens, JWT, HMAC |

## OAuth (Automatic)

### How It Works

Claude Code handles the complete OAuth 2.0 flow automatically for SSE and HTTP servers. No extra configuration is needed -- just specify the server URL and Claude Code does the rest.

The OAuth flow proceeds as follows:

1. User attempts to use an MCP tool for the first time
2. Claude Code sends a request to the MCP server
3. Server responds with 401 Unauthorized, including OAuth discovery metadata
4. Claude Code detects authentication is needed and initiates the OAuth flow
5. Opens the user's default browser to the OAuth consent screen
6. User reviews the requested scopes (permissions) and authorizes
7. Browser redirects back to Claude Code with an authorization code
8. Claude Code exchanges the code for access and refresh tokens
9. Tokens stored securely by Claude Code (encrypted at rest)
10. Automatic token refresh when access tokens expire

### Configuration

No extra auth configuration is needed. Just specify the server URL:

```json
{
  "service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse"
  }
}
```

Claude Code automatically:
- Discovers the OAuth endpoints from the server
- Handles the authorization code flow
- Manages token storage and refresh
- Re-authenticates if refresh tokens expire

### Supported Services

Known OAuth-enabled MCP servers that work out of the box:

| Service | URL | Notes |
|---|---|---|
| Asana | `https://mcp.asana.com/sse` | Task and project management |
| GitHub | `https://mcp.github.com/sse` | Repository and issue management |

Custom OAuth servers are also supported as long as they implement the standard OAuth 2.0 authorization code flow with MCP's discovery mechanism.

### OAuth Scopes

OAuth scopes are determined by the MCP server. Users see the required scopes during the consent flow in their browser. As a plugin developer, you should document what scopes your plugin needs and why.

**Document required scopes in your plugin README:**

```markdown
## Authentication

This plugin requires the following permissions when connecting to Asana:
- **Read tasks and projects**: View task details, project membership, and status
- **Create and update tasks**: Create new tasks and modify existing ones
- **Access workspace data**: List workspaces and team members

You will be prompted to authorize in your browser on first use. No API tokens
or environment variables are needed.
```

### Token Storage and Lifecycle

Claude Code manages OAuth tokens securely:

- **Storage**: Tokens encrypted at rest in Claude Code's secure storage
- **Access**: Not accessible to plugins directly -- Claude Code injects tokens into requests automatically
- **Refresh**: Automatic refresh before expiration. Claude Code tracks token TTL and refreshes proactively
- **Revocation**: Tokens cleared when the user signs out of Claude Code
- **Multi-account**: Each Claude Code installation has its own token set
- **Persistence**: Tokens survive Claude Code restarts -- users do not need to re-authenticate each session

### Troubleshooting OAuth

**Authentication loop (keeps prompting):**
- Clear cached tokens by signing out and signing back in to Claude Code
- Check that the OAuth redirect URLs are correctly configured on the server
- Verify the server's OAuth setup is correct and the authorization endpoint responds
- Look for errors in `claude --debug` output during the OAuth flow

**Scope issues (tool calls fail after authentication):**
- User may need to re-authorize if the server added new scopes since last authorization
- Check server documentation for the exact scopes each tool requires
- Some servers require admin consent for certain scopes -- check with your OAuth provider

**Token expiration (tools stop working after some time):**
- Claude Code auto-refreshes tokens using the refresh token
- If the refresh token itself has expired, the user is prompted to re-authenticate
- Check if the OAuth provider has a refresh token lifetime limit
- Some providers require the `offline_access` scope for long-lived refresh tokens

**Browser does not open:**
- Check that a default browser is configured on the system
- Ensure Claude Code has permission to open URLs
- Try manually navigating to the authorization URL shown in `claude --debug` output

## Token-Based Authentication

### Bearer Tokens

The most common authentication method for HTTP and WebSocket servers. Tokens are passed in the standard `Authorization` header with the `Bearer` prefix.

**Configuration:**
```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

**User sets the environment variable before starting Claude Code:**
```bash
export API_TOKEN="your-secret-token-here"
```

The `${API_TOKEN}` is expanded at Claude Code startup time from the user's shell environment. If the variable is not set, it expands to an empty string, which will likely cause 401 errors.

### API Keys

Alternative to bearer tokens. API keys are typically passed in custom headers rather than the standard `Authorization` header.

**Single key:**
```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "X-API-Key": "${API_KEY}"
    }
  }
}
```

**Key and secret pair:**
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

### Custom Header Schemes

Services may use non-standard authentication headers. Any header can be set in the `headers` object.

```json
{
  "service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse",
    "headers": {
      "X-Auth-Token": "${AUTH_TOKEN}",
      "X-User-ID": "${USER_ID}",
      "X-Tenant-ID": "${TENANT_ID}"
    }
  }
}
```

### Basic Authentication

For services that use HTTP Basic authentication:

```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Basic ${BASE64_CREDENTIALS}"
    }
  }
}
```

Users create the base64 credentials:
```bash
export BASE64_CREDENTIALS=$(echo -n "username:password" | base64)
```

### Documenting Token Requirements

Always document authentication requirements clearly in your plugin README. Users need to know what tokens to set, where to obtain them, and what permissions they need.

**Comprehensive documentation template:**

```markdown
## Setup

### Required Environment Variables

Set these before starting Claude Code:

\`\`\`bash
# Required: API access token
export API_TOKEN="your-token-here"

# Required: API secret for write operations
export API_SECRET="your-secret-here"

# Optional: Custom workspace (defaults to personal workspace)
export WORKSPACE_ID="your-workspace-id"
\`\`\`

### Obtaining Tokens

1. Sign in to https://api.example.com/settings/tokens
2. Click "Create New API Token"
3. Name the token (e.g., "Claude Code Plugin")
4. Select the following permissions:
   - Read access to resources
   - Write access for creating and updating items
   - Delete access (optional, only needed for cleanup commands)
5. Click "Generate"
6. Copy the token and secret immediately (secret shown only once)
7. Set environment variables as shown above

### Verifying Setup

After setting variables, verify with:
\`\`\`bash
echo $API_TOKEN  # Should show your token
echo $API_SECRET # Should show your secret
\`\`\`

Then start Claude Code and use the plugin. If authentication fails, check
that the variables are set in the same shell session where you launch Claude.
```

## Environment Variable Authentication (stdio)

### Passing Credentials to Server Processes

For stdio servers, pass credentials via the `env` block in the server configuration. These variables are injected into the child process environment.

```json
{
  "database": {
    "command": "python",
    "args": ["-m", "mcp_server_db"],
    "env": {
      "DATABASE_URL": "${DATABASE_URL}",
      "DB_USER": "${DB_USER}",
      "DB_PASSWORD": "${DB_PASSWORD}",
      "DB_SSL_MODE": "${DB_SSL_MODE:-require}"
    }
  }
}
```

The `${VAR}` syntax expands from the user's shell environment at startup. The `${VAR:-default}` syntax provides a fallback value if the variable is not set.

### Multiple Credential Sets

For servers that connect to multiple services:

```json
{
  "multi-service": {
    "command": "node",
    "args": ["${CLAUDE_PLUGIN_ROOT}/servers/multi-service.js"],
    "env": {
      "GITHUB_TOKEN": "${GITHUB_TOKEN}",
      "SLACK_TOKEN": "${SLACK_TOKEN}",
      "JIRA_TOKEN": "${JIRA_TOKEN}",
      "JIRA_URL": "${JIRA_URL}"
    }
  }
}
```

### Server-Side Validation

MCP servers should validate credentials on startup and provide clear error messages:

```python
# Example: Python MCP server startup validation
import os
import sys

required_vars = ["DATABASE_URL", "DB_USER", "DB_PASSWORD"]
missing = [var for var in required_vars if not os.environ.get(var)]

if missing:
    print(f"Error: Missing required environment variables: {', '.join(missing)}", file=sys.stderr)
    print("Set them before starting Claude Code:", file=sys.stderr)
    for var in missing:
        print(f"  export {var}='your-value-here'", file=sys.stderr)
    sys.exit(1)
```

### Documentation Template for stdio Auth

```markdown
## Database Configuration

Set these environment variables before starting Claude Code:

\`\`\`bash
export DATABASE_URL="postgresql://host:port/database"
export DB_USER="username"
export DB_PASSWORD="password"
\`\`\`

Or add them to your shell profile (~/.bashrc, ~/.zshrc) for persistence:

\`\`\`bash
echo 'export DATABASE_URL="postgresql://localhost:5432/mydb"' >> ~/.zshrc
echo 'export DB_USER="myuser"' >> ~/.zshrc
echo 'export DB_PASSWORD="mypassword"' >> ~/.zshrc
source ~/.zshrc
\`\`\`

**Security note**: Avoid storing passwords in shell profiles for production
use. Consider using a secrets manager or credential helper instead.
```

## Dynamic Headers

### headersHelper Script

For tokens that change, expire, or require computation, use a `headersHelper` script. Claude Code executes this script before each request and uses the output as HTTP headers.

```json
{
  "api": {
    "type": "sse",
    "url": "https://api.example.com",
    "headersHelper": "${CLAUDE_PLUGIN_ROOT}/scripts/get-headers.sh"
  }
}
```

The script must:
1. Be executable (`chmod +x`)
2. Output a valid JSON object to stdout
3. Exit with code 0 on success
4. Output nothing on stdout on failure (write errors to stderr)
5. Complete within a reasonable time (under 5 seconds)

**Basic example:**
```bash
#!/bin/bash
# get-headers.sh - Generate dynamic authentication headers

TOKEN=$(get-fresh-token-from-somewhere)

cat <<EOF
{
  "Authorization": "Bearer $TOKEN",
  "X-Timestamp": "$(date -Iseconds)"
}
EOF
```

### Use Cases for Dynamic Headers

**Short-lived tokens that expire frequently:**
```bash
#!/bin/bash
# refresh-token.sh
# Token is cached and refreshed every 30 minutes

CACHE_FILE="${HOME}/.cache/mcp-token"
MAX_AGE=1800  # 30 minutes in seconds

if [ -f "$CACHE_FILE" ]; then
  AGE=$(( $(date +%s) - $(stat -f%m "$CACHE_FILE" 2>/dev/null || stat -c%Y "$CACHE_FILE") ))
  if [ "$AGE" -lt "$MAX_AGE" ]; then
    TOKEN=$(cat "$CACHE_FILE")
  fi
fi

if [ -z "$TOKEN" ]; then
  TOKEN=$(curl -s -X POST "https://auth.example.com/token" \
    -d "client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&grant_type=client_credentials" \
    | jq -r '.access_token')
  echo "$TOKEN" > "$CACHE_FILE"
fi

echo "{\"Authorization\": \"Bearer $TOKEN\"}"
```

**JWT token generation:**
```bash
#!/bin/bash
# generate-jwt.sh - Generate a signed JWT token

# Create JWT payload
HEADER=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-')
PAYLOAD=$(echo -n "{\"sub\":\"plugin\",\"iat\":$(date +%s),\"exp\":$(( $(date +%s) + 3600 ))}" | base64 | tr -d '=' | tr '/+' '_-')
SIGNATURE=$(echo -n "${HEADER}.${PAYLOAD}" | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | base64 | tr -d '=' | tr '/+' '_-')

JWT="${HEADER}.${PAYLOAD}.${SIGNATURE}"
echo "{\"Authorization\": \"Bearer $JWT\"}"
```

**HMAC request signing:**
```bash
#!/bin/bash
# generate-hmac.sh - Sign requests with HMAC

TIMESTAMP=$(date -Iseconds)
NONCE=$(uuidgen | tr '[:upper:]' '[:lower:]')
SIGNATURE=$(echo -n "${TIMESTAMP}${NONCE}" | openssl dgst -sha256 -hmac "$SECRET_KEY" | cut -d' ' -f2)

cat <<EOF
{
  "X-Timestamp": "$TIMESTAMP",
  "X-Nonce": "$NONCE",
  "X-Signature": "$SIGNATURE",
  "X-API-Key": "$API_KEY"
}
EOF
```

**AWS Signature V4 (simplified):**
```bash
#!/bin/bash
# aws-sign.sh - Generate AWS-style request signing headers

# Use AWS CLI to generate temporary credentials
CREDS=$(aws sts get-session-token --output json)
ACCESS_KEY=$(echo "$CREDS" | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo "$CREDS" | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo "$CREDS" | jq -r '.Credentials.SessionToken')

cat <<EOF
{
  "X-AWS-Access-Key": "$ACCESS_KEY",
  "X-AWS-Secret-Key": "$SECRET_KEY",
  "X-AWS-Session-Token": "$SESSION_TOKEN"
}
EOF
```

**Workspace/tenant selection based on configuration:**
```bash
#!/bin/bash
# select-workspace.sh - Read workspace from plugin settings

SETTINGS_FILE="${HOME}/.claude/my-plugin.local.md"
if [ -f "$SETTINGS_FILE" ]; then
  WORKSPACE=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" | grep '^workspace:' | awk '{print $2}')
fi

cat <<EOF
{
  "Authorization": "Bearer $API_TOKEN",
  "X-Workspace-ID": "${WORKSPACE:-default}"
}
EOF
```

## Multi-Tenancy Patterns

### Workspace Selection via Headers

When the same API serves multiple workspaces or tenants, use headers to specify the target:

```json
{
  "api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}",
      "X-Workspace-ID": "${WORKSPACE_ID}"
    }
  }
}
```

### Workspace Selection via URL

Some APIs use subdomain-based routing:

```json
{
  "api": {
    "type": "http",
    "url": "https://${TENANT_ID}.api.example.com/mcp"
  }
}
```

### Per-User Configuration

Users set their workspace before starting Claude Code:

```bash
export WORKSPACE_ID="my-workspace-123"
export TENANT_ID="my-company"
```

### Switching Workspaces

To switch workspaces, the user must:
1. Set the new environment variable value
2. Restart Claude Code (environment variables are read at startup, not dynamically)

Alternatively, use a `headersHelper` script that reads the workspace from a settings file, which can be changed at runtime without restarting.

## Security Best Practices

### Do

- Use environment variables for all tokens and secrets (`${VAR}` syntax)
- Document all required variables in the plugin README with clear instructions
- Use HTTPS/WSS for all network connections
- Let OAuth handle authentication when the service supports it
- Rotate tokens regularly and document the rotation process
- Use different tokens for development and production environments
- Validate tokens on the server side (do not trust client-provided tokens blindly)
- Use the principle of least privilege -- request only the scopes/permissions your plugin actually needs
- Implement token expiration and refresh mechanisms
- Log authentication events (without logging the actual token values)

### Do Not

- Hardcode tokens in configuration files or source code
- Commit tokens to git (add `.env` and credential files to `.gitignore`)
- Share tokens in documentation, examples, or screenshots
- Use HTTP instead of HTTPS for any network connection
- Store tokens in plugin files that are distributed to users
- Log tokens or sensitive headers (even in debug mode)
- Reuse the same token across multiple plugins or services
- Skip SSL/TLS certificate verification
- Use weak or predictable API keys

## Migration Patterns

### From Hardcoded Tokens to Environment Variables

**Before (insecure):**
```json
{
  "headers": {
    "Authorization": "Bearer sk-hardcoded-secret-token"
  }
}
```

**After (secure):**
```json
{
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

**Migration steps:**
1. Identify all hardcoded tokens in `.mcp.json` and configuration files
2. Replace each token with `${VARIABLE_NAME}` syntax
3. Document the required variables in the plugin README
4. Test with the variables set in the shell environment
5. Remove hardcoded values from version control history (use `git filter-branch` or `bfg`)
6. Rotate the compromised tokens since they were in version control

### From Basic Auth to OAuth

**Before (token-based):**
```json
{
  "headers": {
    "Authorization": "Basic ${BASE64_CREDENTIALS}"
  }
}
```

**After (OAuth):**
```json
{
  "type": "sse",
  "url": "https://mcp.example.com/sse"
}
```

**Benefits:**
- Better security (tokens are short-lived and scoped)
- No credential management for users
- Automatic token refresh
- Scoped permissions visible to users during consent

### From Static Tokens to Dynamic Headers

**Before (static):**
```json
{
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

**After (dynamic):**
```json
{
  "headersHelper": "${CLAUDE_PLUGIN_ROOT}/scripts/get-headers.sh"
}
```

**Benefits:**
- Tokens can be refreshed without restarting Claude Code
- Supports short-lived tokens and computed signatures
- Can read configuration from files or external sources
- Enables complex auth flows (JWT, HMAC, STS)

## Debugging Authentication

### Enable Debug Mode

```bash
claude --debug
```

Look for in the debug output:
- Authentication header presence (values are sanitized/masked)
- OAuth flow progress (redirect URLs, token exchange)
- Token refresh attempts and results
- HTTP status codes on MCP requests
- Error messages from the MCP server

### Test Authentication Separately

Before debugging within Claude Code, verify authentication works directly:

**Test HTTP endpoint:**
```bash
curl -v -H "Authorization: Bearer $API_TOKEN" \
     https://api.example.com/mcp/health
```

**Test with full request:**
```bash
curl -X POST \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' \
  https://api.example.com/mcp
```

**Verify environment variable is set:**
```bash
echo "API_TOKEN is: ${API_TOKEN:-(not set)}"
```

### Common Authentication Errors

| Error | Likely Cause | Fix |
|---|---|---|
| 401 Unauthorized | Token missing, expired, or invalid | Check `echo $API_TOKEN`, regenerate if expired |
| 403 Forbidden | Token valid but lacks permissions | Check required scopes, request additional permissions |
| Token not found | Environment variable not set | Set the variable in the current shell session |
| Wrong format | Missing `Bearer ` prefix or wrong header name | Check the exact header format required by the API |
| OAuth loop | Cached tokens invalid | Sign out of Claude Code and re-authenticate |
| CORS error | Server missing CORS headers | Fix server-side CORS configuration |
