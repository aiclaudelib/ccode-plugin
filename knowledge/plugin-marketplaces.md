# Plugin marketplaces guide

A plugin marketplace is a catalog that distributes plugins to teams and communities. Marketplaces provide centralized discovery, version tracking, automatic updates, and support for multiple source types (git repositories, local paths, and more).

## Overview

Creating and distributing a marketplace involves:

1. **Creating plugins** — build one or more plugins with commands, agents, hooks, MCP servers, or LSP servers
2. **Creating a marketplace file** — define a `marketplace.json` that lists your plugins and where to find them
3. **Hosting the marketplace** — push to GitHub, GitLab, or another git host
4. **Sharing with users** — users add your marketplace with `/plugin marketplace add` and install plugins

## Marketplace file location

Create `.claude-plugin/marketplace.json` in your repository root. This file defines your marketplace's name, owner information, and a list of plugins with their sources.

### Minimal marketplace

```json
{
  "name": "my-plugins",
  "owner": {
    "name": "Your Name"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "What this plugin does"
    }
  ]
}
```

### Full marketplace example

```json
{
  "name": "company-tools",
  "owner": {
    "name": "DevTools Team",
    "email": "devtools@example.com"
  },
  "metadata": {
    "description": "Internal DevTools plugins for the engineering team",
    "version": "1.0.0",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "formatter",
      "description": "Automatic code formatting on save",
      "version": "2.1.0",
      "author": { "name": "DevTools Team" }
    },
    {
      "name": "deployment-tools",
      "source": {
        "source": "github",
        "repo": "company/deploy-plugin"
      },
      "description": "Deployment automation tools"
    }
  ]
}
```

## Required fields

| Field | Type | Description | Example |
|---|---|---|---|
| `name` | string | Marketplace identifier (kebab-case, no spaces). Users see this when installing: `/plugin install my-tool@marketplace-name` | `"acme-tools"` |
| `owner` | object | Marketplace maintainer info (see owner fields) | |
| `plugins` | array | List of available plugins | |

### Owner fields

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Name of the maintainer or team |
| `email` | string | No | Contact email |

### Optional metadata

| Field | Type | Description |
|---|---|---|
| `metadata.description` | string | Brief marketplace description |
| `metadata.version` | string | Marketplace version |
| `metadata.pluginRoot` | string | Base directory prepended to relative plugin source paths (e.g., `"./plugins"` lets you write `"source": "formatter"` instead of `"source": "./plugins/formatter"`) |

## Reserved marketplace names

These names are reserved for official Anthropic use: `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`. Names that impersonate official marketplaces (like `official-claude-plugins` or `anthropic-tools-v2`) are also blocked.

## Plugin entries

Each plugin entry needs at minimum a `name` and `source`. You can also include any field from the plugin manifest schema (`description`, `version`, `author`, `commands`, `hooks`, etc.), plus marketplace-specific fields: `source`, `category`, `tags`, and `strict`.

### Required plugin fields

| Field | Type | Description |
|---|---|---|
| `name` | string | Plugin identifier (kebab-case). Users see it when installing: `/plugin install my-plugin@marketplace` |
| `source` | string or object | Where to fetch the plugin from |

### Optional plugin fields

**Standard metadata:**

| Field | Type | Description |
|---|---|---|
| `description` | string | Brief plugin description |
| `version` | string | Plugin version |
| `author` | object | Plugin author info (`name` required, `email` optional) |
| `homepage` | string | Plugin homepage or documentation URL |
| `repository` | string | Source code repository URL |
| `license` | string | SPDX license identifier (MIT, Apache-2.0) |
| `keywords` | array | Tags for discovery and categorization |
| `category` | string | Plugin category for organization |
| `tags` | array | Tags for searchability |
| `strict` | boolean | When true (default), marketplace fields merge with plugin.json. When false, the marketplace entry defines the plugin entirely and plugin.json must not declare components. |

**Component configuration:**

| Field | Type | Description |
|---|---|---|
| `commands` | string or array | Custom paths to command files or directories |
| `agents` | string or array | Custom paths to agent files |
| `hooks` | string or object | Hook configuration or path to hooks file |
| `mcpServers` | string or object | MCP server configurations or path |
| `lspServers` | string or object | LSP server configurations or path |

## Plugin sources

### Relative paths

For plugins in the same repository:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin"
}
```

**Note**: Relative paths only work when users add your marketplace via Git (GitHub, GitLab, or git URL). They do NOT work with URL-based marketplaces.

### GitHub repositories

```json
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo"
  }
}
```

Pin to a specific version:

```json
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo",
    "ref": "v2.0.0",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

| Field | Type | Description |
|---|---|---|
| `repo` | string | Required. GitHub repo in `owner/repo` format |
| `ref` | string | Optional. Git branch or tag |
| `sha` | string | Optional. Full 40-character commit SHA |

### Git URL repositories

```json
{
  "name": "git-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git"
  }
}
```

| Field | Type | Description |
|---|---|---|
| `url` | string | Required. Full git repository URL (must end with `.git`) |
| `ref` | string | Optional. Git branch or tag |
| `sha` | string | Optional. Full 40-character commit SHA |

## Hosting and distribution

### GitHub (recommended)

1. Create a repository for your marketplace
2. Add `.claude-plugin/marketplace.json` with plugin definitions
3. Users add with: `/plugin marketplace add owner/repo`

### Other git services

Any git host works (GitLab, Bitbucket, self-hosted):

```
/plugin marketplace add https://gitlab.com/company/plugins.git
```

### Private repositories

Claude Code uses existing git credential helpers for manual install/updates. If `git clone` works in your terminal, it works in Claude Code.

For background auto-updates, set authentication tokens in your environment:

| Provider | Environment variables | Notes |
|---|---|---|
| GitHub | `GITHUB_TOKEN` or `GH_TOKEN` | Personal access token or GitHub App token |
| GitLab | `GITLAB_TOKEN` or `GL_TOKEN` | Personal access token or project token |
| Bitbucket | `BITBUCKET_TOKEN` | App password or repository access token |

## Team configuration

### Require marketplaces for your team

Add to `.claude/settings.json` so team members are prompted to install:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    }
  }
}
```

Enable plugins by default:

```json
{
  "enabledPlugins": {
    "code-formatter@company-tools": true,
    "deployment-tools@company-tools": true
  }
}
```

### Managed marketplace restrictions (strictKnownMarketplaces)

Administrators can restrict which marketplaces users can add:

| Value | Behavior |
|---|---|
| Undefined (default) | No restrictions — users can add any marketplace |
| Empty array `[]` | Complete lockdown — no new marketplaces allowed |
| List of sources | Users can only add marketplaces matching the allowlist |

```json
{
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "acme-corp/approved-plugins" },
    { "source": "hostPattern", "hostPattern": "^github\\.example\\.com$" }
  ]
}
```

## Validation and testing

```bash
# Validate marketplace JSON
claude plugin validate .
# or from within Claude Code:
/plugin validate .

# Test locally
/plugin marketplace add ./path/to/marketplace
/plugin install test-plugin@marketplace-name
```

## Marketplace directory structure

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json    # Marketplace catalog (required)
├── plugins/
│   ├── plugin-one/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── skills/
│   └── plugin-two/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── commands/
└── README.md
```

## Troubleshooting

| Problem | Solution |
|---|---|
| Marketplace not loading | Verify URL is accessible, check `.claude-plugin/marketplace.json` exists, validate JSON syntax |
| Plugin installation fails | Verify plugin source URLs are accessible, check plugin directories contain required files |
| Relative paths fail in URL-based marketplaces | Use GitHub/git URL sources instead, or host marketplace as git repo |
| Private repo auth fails | Verify git credentials (`gh auth status`), set `GITHUB_TOKEN`/`GITLAB_TOKEN` for auto-updates |
| Files not found after install | Plugins are copied to cache — paths referencing outside plugin directory won't work. Use symlinks or restructure. |
| Duplicate plugin name error | Each plugin in the marketplace must have a unique `name` |
| Path traversal not allowed | Source paths cannot contain `..` — use paths relative to marketplace root |
