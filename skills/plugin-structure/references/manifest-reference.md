# Plugin Manifest Reference

Complete reference for `.claude-plugin/plugin.json` configuration.

## File Location

**Required path**: `.claude-plugin/plugin.json`

The manifest MUST be in the `.claude-plugin/` directory at the plugin root. Claude Code will not recognize plugins without this file in the correct location.

## Core Fields

### name (required)

**Type**: String
**Format**: kebab-case
**Example**: `"test-automation-suite"`

The unique identifier for the plugin. Used for plugin identification, conflict detection, and command namespacing (`/plugin-name:skill-name`).

**Requirements**:
- Only lowercase letters, numbers, and hyphens
- Must start with a letter
- Must end with a letter or number
- No spaces or special characters
- Must be unique across installed plugins

**Regex**: `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`

**Good**: `api-tester`, `code-review`, `git-workflow-automation`
**Bad**: `API Tester`, `code_review`, `-git-workflow`, `test-`

### version

**Type**: String
**Format**: Semantic versioning (MAJOR.MINOR.PATCH)
**Example**: `"2.1.0"`
**Default**: `"0.1.0"` if not specified

Semantic versioning guidelines:
- **MAJOR**: Incompatible API changes, breaking changes
- **MINOR**: New functionality, backward-compatible
- **PATCH**: Bug fixes, backward-compatible

Pre-release versions: `"1.0.0-alpha.1"`, `"1.0.0-beta.2"`, `"1.0.0-rc.1"`

### description

**Type**: String
**Length**: 50-200 characters recommended
**Example**: `"Automates code review workflows with style checks and automated feedback"`

Brief explanation of plugin purpose. Focus on what it does, not how. Use active voice. Keep under 200 characters for marketplace display.

## Metadata Fields

### author

**Type**: Object or String

**Object format**:
```json
{
  "author": {
    "name": "Jane Developer",
    "email": "jane@example.com",
    "url": "https://janedeveloper.com"
  }
}
```

**String format**:
```json
{
  "author": "Jane Developer <jane@example.com> (https://janedeveloper.com)"
}
```

### homepage

**Type**: String (URL)
**Example**: `"https://docs.example.com/plugins/my-plugin"`

Link to plugin documentation or landing page.

### repository

**Type**: String (URL) or Object

**String format**:
```json
{
  "repository": "https://github.com/user/plugin-name"
}
```

**Object format** (for monorepos):
```json
{
  "repository": {
    "type": "git",
    "url": "https://github.com/user/plugin-name.git",
    "directory": "packages/plugin-name"
  }
}
```

### license

**Type**: String
**Format**: SPDX identifier

Common licenses: `"MIT"`, `"Apache-2.0"`, `"GPL-3.0"`, `"BSD-3-Clause"`, `"ISC"`, `"UNLICENSED"`

Full list: https://spdx.org/licenses/

### keywords

**Type**: Array of strings
**Example**: `["testing", "automation", "ci-cd", "quality-assurance"]`

Tags for plugin discovery and categorization. Use 5-10 keywords covering functionality, technologies, workflows, and domains.

## Component Path Fields

Custom paths **supplement** default directories -- they do not replace them. All paths relative to plugin root, starting with `./`.

### commands

**Type**: String or Array of strings
**Default**: `["./commands"]`

```json
{
  "commands": "./custom-commands"
}
```

```json
{
  "commands": ["./commands", "./admin-commands", "./experimental"]
}
```

### agents

**Type**: String or Array of strings
**Default**: `["./agents"]`

Same format as `commands`.

### skills

**Type**: String or Array of strings
**Default**: `["./skills"]`

Same format as `commands`.

### hooks

**Type**: String (path to JSON file) or Object (inline configuration)
**Default**: `"./hooks/hooks.json"`

**File path**:
```json
{
  "hooks": "./config/hooks.json"
}
```

**Inline configuration**:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
        "timeout": 30
      }]
    }]
  }
}
```

### mcpServers

**Type**: String (path to JSON file) or Object (inline configuration)
**Default**: `"./.mcp.json"`

Same patterns as `hooks` -- file path or inline.

### lspServers

**Type**: String (path to JSON file) or Object (inline configuration)
**Default**: `"./.lsp.json"`

Same patterns as `hooks` -- file path or inline.

## Path Resolution Rules

1. All paths **must be relative** (no absolute paths)
2. All paths **must start with `./`**
3. Paths **cannot use `../`** (no parent directory navigation)
4. Use **forward slashes only** (even on Windows)

**Good**: `"./commands"`, `"./src/commands"`, `"./configs/hooks.json"`
**Bad**: `"/Users/name/plugin/commands"`, `"commands"` (missing `./`), `"../shared/commands"`

### Resolution Order

When Claude Code loads components:

1. **Default directories**: scans `./commands/`, `./agents/`, `./skills/`, `./hooks/hooks.json`, `./.mcp.json`
2. **Custom paths**: scans paths specified in manifest
3. **Merge behavior**: components from all locations load, no overwriting, name conflicts cause errors

## Validation

Claude Code validates the manifest on plugin load:

**Syntax**: valid JSON, no syntax errors, correct field types
**Fields**: `name` present and valid format, `version` follows semver (if present), paths relative with `./` prefix, URLs valid (if present)
**Components**: referenced paths exist, hook and MCP configurations are valid

### Common Validation Errors

| Error | Cause | Fix |
|---|---|---|
| Invalid name format | Spaces, underscores, uppercase | Use kebab-case |
| Absolute path | Path starts with `/` | Use `./` relative path |
| Missing ./ prefix | Path like `"hooks/hooks.json"` | Add `./` prefix |
| Invalid version | Format like `"1.0"` | Use `MAJOR.MINOR.PATCH` |

## Examples

### Minimal

```json
{
  "name": "hello-world"
}
```

### Recommended

```json
{
  "name": "code-review-assistant",
  "version": "1.0.0",
  "description": "Automates code review with style checks and suggestions",
  "author": { "name": "Jane Developer" },
  "license": "MIT",
  "keywords": ["code-review", "automation", "quality"]
}
```

### Complete

```json
{
  "name": "enterprise-devops",
  "version": "2.3.1",
  "description": "Comprehensive DevOps automation for enterprise CI/CD pipelines",
  "author": {
    "name": "DevOps Team",
    "email": "devops@company.com",
    "url": "https://company.com/devops"
  },
  "homepage": "https://docs.company.com/plugins/devops",
  "repository": {
    "type": "git",
    "url": "https://github.com/company/devops-plugin.git"
  },
  "license": "Apache-2.0",
  "keywords": ["devops", "ci-cd", "automation", "kubernetes", "docker", "deployment"],
  "commands": ["./commands", "./admin-commands"],
  "agents": "./specialized-agents",
  "hooks": "./config/hooks.json",
  "mcpServers": "./.mcp.json"
}
```
