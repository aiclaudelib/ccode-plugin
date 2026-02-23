# Advanced marketplace example

Multi-plugin marketplace using mixed source types: relative paths, GitHub repos, and git URLs. Includes team configuration and managed restrictions.

## Directory structure

```
company-marketplace/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── code-formatter/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── hooks/
│   │   │   ├── hooks.json
│   │   │   └── scripts/
│   │   │       └── format.sh
│   │   └── skills/
│   │       └── format/
│   │           └── SKILL.md
│   └── lint-tools/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── lint/
│               └── SKILL.md
└── README.md
```

## marketplace.json

```json
{
  "name": "company-tools",
  "owner": {
    "name": "DevTools Team",
    "email": "devtools@company.com"
  },
  "metadata": {
    "description": "Internal developer tools for the engineering team",
    "version": "2.0.0",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "code-formatter",
      "description": "Automatic code formatting with hooks",
      "version": "2.1.0",
      "author": { "name": "DevTools Team" },
      "license": "MIT",
      "keywords": ["formatting", "code-style"],
      "category": "code-quality"
    },
    {
      "name": "lint-tools",
      "source": "lint-tools",
      "description": "Linting integration for CI pipelines",
      "version": "1.3.0",
      "keywords": ["linting", "ci"],
      "category": "code-quality"
    },
    {
      "name": "deploy-automation",
      "source": {
        "source": "github",
        "repo": "company/deploy-plugin",
        "ref": "v3.0.0"
      },
      "description": "Kubernetes deployment automation",
      "category": "devops"
    },
    {
      "name": "security-scanner",
      "source": {
        "source": "url",
        "url": "https://gitlab.company.com/security/scanner-plugin.git",
        "ref": "main"
      },
      "description": "Security vulnerability scanning",
      "category": "security"
    },
    {
      "name": "api-docs-generator",
      "source": {
        "source": "github",
        "repo": "company/api-docs-plugin"
      },
      "description": "Auto-generate API documentation from code",
      "strict": false,
      "commands": ["./commands/"],
      "agents": ["./agents/docs-writer.md"],
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Write|Edit",
            "hooks": [
              {
                "type": "command",
                "command": "${CLAUDE_PLUGIN_ROOT}/scripts/update-docs.sh"
              }
            ]
          }
        ]
      }
    }
  ]
}
```

## Team configuration (.claude/settings.json)

Add to your project's settings so team members auto-discover:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": {
        "source": "github",
        "repo": "company/company-marketplace"
      }
    }
  },
  "enabledPlugins": {
    "code-formatter@company-tools": true,
    "lint-tools@company-tools": true
  }
}
```

## Managed restrictions (for admins)

Lock users to only approved marketplaces:

```json
{
  "strictKnownMarketplaces": [
    {
      "source": "github",
      "repo": "company/company-marketplace"
    },
    {
      "source": "github",
      "repo": "company/security-tools",
      "ref": "v2.0"
    },
    {
      "source": "url",
      "url": "https://plugins.company.com/marketplace.json"
    },
    {
      "source": "hostPattern",
      "hostPattern": "^gitlab\\.company\\.com$"
    }
  ]
}
```

The allowlist uses exact matching: for GitHub sources `repo` is required and `ref`/`path` must match if specified; for URL sources the full URL must match; for `hostPattern` the host is matched against the regex. These restrictions are set in managed settings and cannot be overridden by users or project configs.

## Testing

```bash
# Validate
claude plugin validate .

# Test locally
/plugin marketplace add ./company-marketplace
/plugin install code-formatter@company-tools
/plugin install deploy-automation@company-tools

# After pushing to GitHub
/plugin marketplace add company/company-marketplace
```

## Key patterns demonstrated

- **`metadata.pluginRoot`**: Simplifies relative paths — write `"source": "code-formatter"` instead of `"source": "./plugins/code-formatter"`
- **Mixed sources**: Local plugins (relative paths), GitHub repos, GitLab repos in the same marketplace
- **Version pinning**: `"ref": "v3.0.0"` on deploy-automation for stable releases
- **`strict: false`**: api-docs-generator fully defined in marketplace entry; if plugin.json also declares components, the plugin fails to load
- **Inline hooks**: Hook configuration embedded directly in marketplace entry
- **Team configuration**: Auto-discovery via `extraKnownMarketplaces`, pre-enabled plugins via `enabledPlugins`
- **Managed restrictions**: `strictKnownMarketplaces` locks down allowed sources
