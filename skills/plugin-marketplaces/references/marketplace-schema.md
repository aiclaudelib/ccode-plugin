# Marketplace schema reference

Complete field reference for `.claude-plugin/marketplace.json`.

## Top-level structure

```json
{
  "name": "string (required)",
  "owner": { "name": "string (required)", "email": "string (optional)" },
  "metadata": {
    "description": "string (optional)",
    "version": "string (optional)",
    "pluginRoot": "string (optional)"
  },
  "plugins": []
}
```

## Required top-level fields

### `name` (string, required)

Marketplace identifier. Must be kebab-case, no spaces. Public-facing — users see it when installing plugins: `/plugin install my-tool@marketplace-name`.

**Regex**: `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`

**Reserved names** (cannot be used):
- `claude-code-marketplace`
- `claude-code-plugins`
- `claude-plugins-official`
- `anthropic-marketplace`
- `anthropic-plugins`
- `agent-skills`
- `life-sciences`

Names that impersonate official marketplaces (like `official-claude-plugins` or `anthropic-tools-v2`) are also blocked.

### `owner` (object, required)

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Name of the maintainer or team |
| `email` | string | No | Contact email for the maintainer |

### `plugins` (array, required)

Array of plugin entry objects. Each entry describes a plugin and where to find it.

## Optional metadata

The `metadata` object provides marketplace-level configuration:

### `metadata.description` (string)

Brief description of the marketplace purpose. Helps users understand what kind of plugins they'll find.

### `metadata.version` (string)

Marketplace catalog version. Use semantic versioning.

### `metadata.pluginRoot` (string)

Base directory prepended to relative plugin source paths. Simplifies source paths when all plugins share a common parent directory.

**Without pluginRoot**:
```json
{
  "plugins": [
    { "name": "a", "source": "./plugins/a" },
    { "name": "b", "source": "./plugins/b" }
  ]
}
```

**With pluginRoot**:
```json
{
  "metadata": { "pluginRoot": "./plugins" },
  "plugins": [
    { "name": "a", "source": "a" },
    { "name": "b", "source": "b" }
  ]
}
```

## Plugin entry schema

### Required fields

| Field | Type | Description |
|---|---|---|
| `name` | string | Plugin identifier (kebab-case). Users see it when installing: `/plugin install my-plugin@marketplace` |
| `source` | string or object | Where to fetch the plugin from |

### Optional standard metadata

| Field | Type | Description |
|---|---|---|
| `description` | string | Brief plugin description |
| `version` | string | Semantic version |
| `author` | object | `{ "name": "string", "email": "string (optional)" }` |
| `homepage` | string | Plugin homepage or documentation URL |
| `repository` | string | Source code repository URL |
| `license` | string | SPDX license identifier (MIT, Apache-2.0, GPL-3.0) |
| `keywords` | array | Tags for discovery and categorization |

### Optional marketplace-specific fields

| Field | Type | Description |
|---|---|---|
| `category` | string | Plugin category for organization |
| `tags` | array | Tags for searchability |
| `strict` | boolean | Merge behavior with plugin.json (see below) |

### `strict` field behavior

- **`strict: true` (default)**: Marketplace component fields (`commands`, `agents`, `hooks`, `mcpServers`, `lspServers`) are merged with the plugin's own `plugin.json`. Both sources contribute components.
- **`strict: false`**: The marketplace entry defines the plugin entirely. The plugin's `plugin.json` must NOT also declare components. Useful when the marketplace fully controls plugin configuration.

### Optional component configuration

| Field | Type | Description |
|---|---|---|
| `commands` | string or array | Custom paths to command files or directories |
| `agents` | string or array | Custom paths to agent files |
| `hooks` | string or object | Hook configuration or path to hooks file |
| `mcpServers` | string or object | MCP server configurations or path to MCP config |
| `lspServers` | string or object | LSP server configurations or path to LSP config |

## Advanced plugin entry example

```json
{
  "name": "enterprise-tools",
  "source": {
    "source": "github",
    "repo": "company/enterprise-plugin"
  },
  "description": "Enterprise workflow automation tools",
  "version": "2.1.0",
  "author": {
    "name": "Enterprise Team",
    "email": "enterprise@example.com"
  },
  "homepage": "https://docs.example.com/plugins/enterprise-tools",
  "repository": "https://github.com/company/enterprise-plugin",
  "license": "MIT",
  "keywords": ["enterprise", "workflow", "automation"],
  "category": "productivity",
  "commands": [
    "./commands/core/",
    "./commands/enterprise/",
    "./commands/experimental/preview.md"
  ],
  "agents": [
    "./agents/security-reviewer.md",
    "./agents/compliance-checker.md"
  ],
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
          }
        ]
      }
    ]
  },
  "mcpServers": {
    "enterprise-db": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  },
  "strict": false
}
```

Key points:
- `commands` and `agents` accept multiple directories or individual files
- `${CLAUDE_PLUGIN_ROOT}` is required for paths in hooks and MCP server configs
- `strict: false` means the marketplace entry fully defines the plugin
