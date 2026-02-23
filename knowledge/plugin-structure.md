# Plugin structure guide

Claude Code plugins follow a standardized directory structure with automatic component discovery. Understanding this structure is essential for creating well-organized, maintainable plugins that integrate seamlessly with Claude Code. For advanced component patterns, manifest field details, and full examples, see the plugin-dev plugin-structure skill and its references.

## Directory layout

Every Claude Code plugin follows this organizational pattern:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (only file here, optional)
├── commands/                 # Skills as Markdown files (legacy; use skills/)
├── agents/                   # Subagent definitions (.md files)
├── skills/                   # Skills (subdirectories with SKILL.md)
│   └── skill-name/
│       ├── SKILL.md          # Required per skill
│       └── references/       # Optional supporting files
├── hooks/
│   ├── hooks.json            # Event handler configuration
│   └── scripts/              # Hook scripts
├── settings.json             # Default settings (only `agent` key supported)
├── .mcp.json                 # MCP server definitions
├── .lsp.json                 # LSP server definitions (optional)
├── scripts/                  # Shared utility scripts
└── LICENSE
```

**Critical rules**:
1. The manifest (`plugin.json`) is optional but if present MUST be in `.claude-plugin/`. If omitted, components are auto-discovered and name derives from directory name.
2. All component directories (commands, agents, skills, hooks) MUST be at plugin root, NOT inside `.claude-plugin/`
3. Only create directories for components the plugin actually uses
4. Use kebab-case for all directory and file names

## Plugin manifest (plugin.json)

Located at `.claude-plugin/plugin.json`. Only `name` is required. The manifest defines plugin identity, metadata, and optional custom component paths.

### Minimal manifest

```json
{
  "name": "my-plugin"
}
```

Relies entirely on default directory discovery.

### Recommended manifest

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Brief explanation of plugin purpose",
  "author": {
    "name": "Author Name",
    "email": "author@example.com"
  },
  "homepage": "https://docs.example.com/my-plugin",
  "repository": "https://github.com/user/my-plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

### Complete manifest (all features)

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
  "keywords": ["devops", "ci-cd", "automation", "kubernetes"],
  "commands": ["./commands", "./admin-commands"],
  "agents": "./specialized-agents",
  "hooks": "./config/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

### Name requirements

- Kebab-case only (lowercase letters, numbers, hyphens)
- Must start with a letter, end with a letter or number
- Must be unique across installed plugins
- Determines namespace: `/plugin-name:skill-name`
- Regex: `/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`
- Good: `api-tester`, `code-review`, `git-workflow-automation`
- Bad: `API Tester`, `code_review`, `-git-workflow`, `test-`

### Metadata fields

| Field | Type | Description |
|---|---|---|
| `name` | string (required) | Plugin identifier, kebab-case |
| `version` | string | Semantic version (`MAJOR.MINOR.PATCH`) |
| `description` | string | Brief explanation (50-200 chars recommended) |
| `author` | object or string | `{name, email?, url?}` or `"Name <email> (url)"` |
| `homepage` | string | Documentation URL |
| `repository` | string or object | Source code URL or `{type, url, directory?}` |
| `license` | string | SPDX identifier (`MIT`, `Apache-2.0`, `GPL-3.0`, etc.) |
| `keywords` | array | Discovery and categorization tags (5-10 recommended) |

**Version format**: follow semantic versioning. MAJOR for breaking changes, MINOR for new features (backward-compatible), PATCH for bug fixes. If version is also set in the marketplace entry, `plugin.json` takes priority. You only need to set it in one place.

**Description tips**: focus on what the plugin does, not how. Use active voice. Keep under 200 characters for marketplace display.

### Component path fields

Custom paths supplement default directories -- they do not replace them. All paths must be relative and start with `./`.

| Field | Type | Default | Purpose |
|---|---|---|---|
| `commands` | string or array | `./commands` | Additional command files/dirs |
| `agents` | string or array | `./agents` | Additional agent files/dirs |
| `skills` | string or array | `./skills` | Additional skill dirs |
| `hooks` | string or object | `./hooks/hooks.json` | Hook config path or inline |
| `mcpServers` | string or object | `./.mcp.json` | MCP config path or inline |
| `outputStyles` | string or array | `./styles/` | Additional output style files/dirs |
| `lspServers` | string or object | `./.lsp.json` | LSP config path or inline |

**Path rules**:
- Must be relative (no absolute paths)
- Must start with `./`
- Cannot use `../` (no parent directory navigation)
- Forward slashes only (even on Windows)
- Support arrays for multiple locations

**Examples**:
- `"commands": "./custom-commands"` -- single custom path
- `"commands": ["./commands", "./admin-commands"]` -- multiple paths
- `"hooks": "./config/hooks.json"` -- custom hook location

## Component organization

### Commands

**Location**: `commands/*.md` (auto-discovered)
**Format**: Markdown files with YAML frontmatter
**Naming**: `review.md` becomes `/plugin-name:review`

```markdown
---
name: review
description: Review current changes
allowed-tools: ["Read", "Grep"]
---

Review instructions here...
```

All `.md` files in `commands/` load automatically. Claude Code doesn't support nested command discovery automatically -- use custom paths for subdirectories:

```json
{
  "commands": ["./commands/ci", "./commands/deployment"]
}
```

### Agents

**Location**: `agents/*.md` (auto-discovered)
**Format**: Markdown files with YAML frontmatter

```markdown
---
name: code-reviewer
description: Expert code reviewer for quality analysis
capabilities:
  - Code style analysis
  - Bug detection
---

Agent instructions and knowledge here...
```

Claude Code selects agents automatically based on task context, or users can invoke them manually.

### Skills

**Location**: `skills/<name>/SKILL.md` (auto-discovered)
**Format**: Each skill in its own directory with a `SKILL.md` file

```
skills/
└── api-testing/
    ├── SKILL.md              # Required (keep under 500 lines)
    ├── references/           # Detailed guides (loaded as needed)
    │   ├── rest-api-guide.md
    │   └── authentication.md
    ├── examples/             # Copy-paste code samples
    │   └── basic-test.js
    └── scripts/              # Executable helpers
        └── run-tests.sh
```

**SKILL.md format**:
```markdown
---
name: api-testing
description: When to use this skill (task context matching)
version: 1.0.0
---

Skill instructions and guidance...

## Additional resources
- For complete API details, see [reference.md](references/rest-api-guide.md)
```

Skills activate automatically when task context matches the SKILL.md description. Keep SKILL.md under 500 lines; move detailed content to `references/`. Supporting files should be one level deep from SKILL.md.

### Hooks

**Location**: `hooks/hooks.json`
**Format**: JSON configuration defining event handlers
**Registration**: Hooks register automatically when the plugin is enabled

```json
{
  "description": "What these hooks do",
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate.sh",
        "timeout": 30
      }]
    }]
  }
}
```

Available events: PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, Stop, SubagentStart, SubagentStop, SessionStart, SessionEnd, UserPromptSubmit, PreCompact, Notification, TeammateIdle, TaskCompleted.

Hook types: `command` (execute shell commands), `prompt` (evaluate with LLM using `$ARGUMENTS`), `agent` (run agentic verifier with tools).

Hook scripts should be organized in `hooks/scripts/` or `scripts/`. Use `${CLAUDE_PLUGIN_ROOT}` for all script paths.

### Default settings

**Location**: `settings.json` at plugin root
**Format**: JSON configuration with default settings applied when the plugin is enabled
**Supported keys**: Only `agent` is currently supported

```json
{
  "agent": "security-reviewer"
}
```

Setting `agent` activates one of the plugin's custom agents as the main thread, applying its system prompt, tool restrictions, and model. Settings from `settings.json` take priority over `settings` declared in `plugin.json`. Unknown keys are silently ignored.

### MCP servers

**Location**: `.mcp.json` at plugin root
**Format**: JSON configuration for MCP server definitions
**Auto-start**: Servers start automatically when plugin is enabled

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/server.js"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

See the mcp-integration knowledge file for detailed server type configuration.

### LSP servers

**Location**: `.lsp.json` at plugin root
**Required fields**: `command`, `extensionToLanguage`

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": { ".go": "go" }
  }
}
```

Optional fields: `args`, `transport` (`stdio`/`socket`), `env`, `initializationOptions`, `settings`, `workspaceFolder`, `startupTimeout`, `shutdownTimeout`, `restartOnCrash`, `maxRestarts`.

The language server binary must be installed separately by the user.

## ${CLAUDE_PLUGIN_ROOT}

Environment variable containing the absolute path to the plugin directory. Use it for all intra-plugin path references to ensure portability.

**Where to use**:
- Hook command paths in `hooks.json`
- MCP server `command` and `args`
- Script execution references
- Resource file paths from within scripts

**In JSON configuration**:
```json
{
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/run.sh"
}
```

**In component markdown**:
```markdown
Reference scripts at: ${CLAUDE_PLUGIN_ROOT}/scripts/helper.py
```

**In executed scripts**:
```bash
#!/bin/bash
# Available as environment variable
source "${CLAUDE_PLUGIN_ROOT}/lib/common.sh"
```

**Why it matters**: Plugins install in different locations depending on installation method (marketplace, local, npm), operating system, and user preferences. Hardcoded paths break after installation.

**Never use**: hardcoded absolute paths (`/Users/name/plugins/...`), relative paths from working directory (`./scripts/...` in hook commands), or home directory shortcuts (`~/plugins/...`).

## Auto-discovery mechanism

When Claude Code loads a plugin:

1. Reads `.claude-plugin/plugin.json` for manifest and metadata
2. Scans `commands/` for `.md` files and registers as slash commands
3. Scans `agents/` for `.md` files and registers as subagents
4. Scans `skills/` for subdirectories containing `SKILL.md`
5. Loads `hooks/hooks.json` configuration and registers event handlers
6. Loads `.mcp.json` MCP server definitions and starts servers
7. Loads `.lsp.json` LSP server definitions
8. Loads `settings.json` default settings
9. Loads custom paths from manifest (supplements defaults, does not replace)

**Timing**: Component registration happens during Claude Code initialization. Changes take effect on the next session, not during a running session.

**Override behavior**: Custom paths in `plugin.json` add to defaults. Components from all locations load. Name conflicts cause errors.

**Plugin caching**: Marketplace plugins are copied to a local cache directory (`~/.claude/plugins/cache`) rather than used in-place. Paths traversing outside the plugin root (`../`) will not work after install. Symlinks are honored during the copy process, so use them for external dependencies if needed.

## File naming conventions

| Component | Convention | Examples |
|---|---|---|
| Commands | kebab-case `.md` | `code-review.md`, `run-tests.md`, `api-docs.md` |
| Agents | kebab-case `.md` (role-based) | `code-reviewer.md`, `test-generator.md` |
| Skills | kebab-case directory name | `api-testing/`, `error-handling/`, `database-migrations/` |
| Scripts | kebab-case with extension | `validate-input.sh`, `generate-report.py` |
| Config | standard names | `hooks.json`, `.mcp.json`, `plugin.json` |
| Documentation | kebab-case `.md` | `api-reference.md`, `migration-guide.md` |

## Common plugin patterns

### Minimal plugin

Single command, no dependencies:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json    # {"name": "my-plugin"}
└── commands/
    └── hello.md
```

### Standard plugin

Commands, agents, and hooks:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── review.md
│   └── test.md
├── agents/
│   └── code-reviewer.md
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── validate.sh
└── scripts/
    └── shared-utils.sh
```

### Full-featured plugin

All component types with MCP and LSP integration:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
├── agents/
├── skills/
│   └── domain-knowledge/
│       ├── SKILL.md
│       └── references/
├── hooks/
│   ├── hooks.json
│   └── scripts/
├── settings.json
├── .mcp.json
├── .lsp.json
├── scripts/
└── LICENSE
```

### Skill-focused plugin

Only provides knowledge/skills:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    ├── topic-one/
    │   ├── SKILL.md
    │   └── references/
    └── topic-two/
        └── SKILL.md
```

### Shared resources pattern

Components sharing common utilities:

```
my-plugin/
├── commands/
│   └── test.md          # References lib/test-utils.sh
├── hooks/
│   └── scripts/
│       └── pre-test.sh  # Sources lib/test-utils.sh
└── lib/
    ├── test-utils.sh
    └── deploy-utils.sh
```

Usage in scripts:
```bash
#!/bin/bash
source "${CLAUDE_PLUGIN_ROOT}/lib/test-utils.sh"
run_tests
```

## Best practices

### Organization

- Start with a flat structure; reorganize when complexity grows
- Group related components together
- Keep directory depth shallow (deep nesting impacts discovery time)
- Rely on auto-discovery for standard layouts; only use custom paths when necessary
- Only create directories for components the plugin actually has
- Separate stable from experimental commands using custom paths if needed

### Naming

- Use consistent naming across components (e.g., `test-runner` command, `test-runner-agent` agent)
- Use descriptive names that indicate purpose
- Avoid abbreviations and generic names (`utils/`, `misc.md`, `temp.sh`)
- Commands: 2-3 words (`review-pr`, `run-ci`)
- Agents: describe the role clearly (`code-reviewer`, `test-generator`)
- Skills: topic-focused (`error-handling`, `api-design`)

### Portability

- Always use `${CLAUDE_PLUGIN_ROOT}` for paths, never hardcode
- Avoid system-specific features; use portable shell constructs
- Document required external tools and versions in README
- Test on multiple systems (macOS, Linux)

### Maintenance

- Follow semantic versioning in `plugin.json`
- Bump version on changes
- Document breaking changes for users
- Keep README current with actual capabilities
- Maintain a changelog for version history

### Manifest

- Keep `plugin.json` lean; use defaults when possible
- Always include `version` for tracking changes
- Write clear, concise descriptions (50-200 chars)
- Provide contact information for user support
- Choose appropriate license

## Testing

```bash
# Load plugin from local directory
claude --plugin-dir ./my-plugin

# Multiple plugins
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

Verify: commands appear in `/` menu, agents are selectable, skills match on relevant tasks, hooks fire on correct events, MCP servers show in `/mcp`.

## Converting standalone to plugin

1. Create plugin directory with `.claude-plugin/plugin.json`
2. Copy `commands/`, `agents/`, `skills/` from `.claude/`
3. Move hooks from `settings.json` to `hooks/hooks.json`
4. Replace all relative paths with `${CLAUDE_PLUGIN_ROOT}`
5. Test with `claude --plugin-dir ./my-plugin`

## Troubleshooting

| Problem | Solution |
|---|---|
| Plugin not loading | Validate JSON syntax in `plugin.json`, check `name` field exists |
| Commands not appearing | Ensure `commands/` is at plugin root, not inside `.claude-plugin/` |
| Skills not discovered | Verify each skill has `SKILL.md` (not `README.md` or other name) |
| Hooks not firing | Check `chmod +x` on scripts, verify matcher patterns, check event names |
| Path resolution errors | Replace hardcoded paths with `${CLAUDE_PLUGIN_ROOT}` |
| Auto-discovery not working | Confirm directories at plugin root, check naming conventions |
| Name conflicts between plugins | Use unique, descriptive component names; namespace if needed |
| Plugin cache stale | Reinstall plugin or clear cache directory |
| Components in wrong location | Move out of `.claude-plugin/` to plugin root |
| Custom paths not loading | Verify paths start with `./`, are relative, and files exist |
| Version format invalid | Use `MAJOR.MINOR.PATCH` (e.g., `1.0.0`, not `1.0`) |
