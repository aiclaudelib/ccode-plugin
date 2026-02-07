# Advanced Plugin Example

A full-featured, enterprise-grade plugin with MCP integration, multiple agent types, and advanced organization.

## Directory Structure

```
enterprise-devops/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── ci/
│   │   ├── build.md
│   │   ├── test.md
│   │   └── deploy.md
│   └── admin/
│       ├── configure.md
│       └── status.md
├── agents/
│   ├── deployment-orchestrator.md
│   └── security-auditor.md
├── skills/
│   ├── kubernetes-ops/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   └── deployment-patterns.md
│   │   └── examples/
│   │       └── basic-deployment.yaml
│   └── ci-cd-pipelines/
│       ├── SKILL.md
│       └── references/
│           └── pipeline-patterns.md
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── security/
│       │   ├── scan-secrets.sh
│       │   └── validate-permissions.sh
│       ├── quality/
│       │   └── check-config.sh
│       └── workflow/
│           └── notify-team.sh
├── .mcp.json
├── servers/
│   ├── kubernetes-mcp/
│   │   ├── index.js
│   │   └── package.json
│   └── github-actions-mcp/
│       ├── server.js
│       └── package.json
├── lib/
│   ├── core/
│   │   └── logger.js
│   └── integrations/
│       └── slack.js
└── config/
    └── environments/
        ├── production.json
        ├── staging.json
        └── development.json
```

## File Contents

### .claude-plugin/plugin.json

```json
{
  "name": "enterprise-devops",
  "version": "2.3.1",
  "description": "Comprehensive DevOps automation for enterprise CI/CD pipelines and infrastructure",
  "author": {
    "name": "DevOps Platform Team",
    "email": "devops-platform@company.com",
    "url": "https://company.com/teams/devops"
  },
  "homepage": "https://docs.company.com/plugins/devops",
  "repository": {
    "type": "git",
    "url": "https://github.com/company/devops-plugin.git"
  },
  "license": "Apache-2.0",
  "keywords": ["devops", "ci-cd", "kubernetes", "automation", "deployment"],
  "commands": ["./commands/ci", "./commands/admin"],
  "hooks": "./hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

Note: `commands` uses custom paths because commands are organized in subdirectories. Claude Code does not auto-discover nested command directories.

### .mcp.json

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/kubernetes-mcp/index.js"],
      "env": {
        "KUBECONFIG": "${KUBECONFIG}",
        "K8S_NAMESPACE": "${K8S_NAMESPACE:-default}"
      }
    },
    "github-actions": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/github-actions-mcp/server.js"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}",
        "GITHUB_ORG": "${GITHUB_ORG}"
      }
    }
  }
}
```

### hooks/hooks.json

```json
{
  "description": "Enterprise DevOps security and quality hooks",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/security/scan-secrets.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/security/validate-permissions.sh",
            "timeout": 20
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/workflow/notify-team.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Key Features

### Multi-Level Command Organization

Commands organized by function (CI, admin), using custom paths in manifest. Avoids a flat directory with 10+ unrelated commands.

### MCP Integration

Multiple custom MCP servers for different infrastructure concerns. Each server bundled with the plugin and started automatically.

### Shared Libraries

Reusable code in `lib/`:
- **core/**: logging, config, auth utilities
- **integrations/**: external service clients (Slack, etc.)

### Security Automation

Layered security hooks:
- Secret scanning before file writes
- Permission validation on session start
- Team notifications on completion

### Environment Configuration

Per-environment configs in `config/environments/`. Different settings for dev, staging, and production.

## When to Use This Pattern

- Large-scale enterprise deployments
- Multiple environment management
- Complex CI/CD workflows with MCP tools
- Security-critical infrastructure
- Team collaboration with notifications
