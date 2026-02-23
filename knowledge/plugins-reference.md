# Plugins reference

Complete technical reference for the Claude Code plugin system.

## Plugin manifest schema

The `.claude-plugin/plugin.json` file defines plugin metadata. Optional — if omitted, components are auto-discovered and name derives from directory name.

### Complete schema

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

> **Note**: `outputStyles` is deprecated since 2.0.30. Use `--system-prompt-file`, CLAUDE.md, or plugins instead.

### Required fields

Only `name` is required (kebab-case, no spaces). Used for namespacing: `/plugin-name:skill-name`.

### Metadata fields

| Field | Type | Description |
|---|---|---|
| `version` | string | Semantic version (`MAJOR.MINOR.PATCH`) |
| `description` | string | Brief explanation |
| `author` | object | `{name, email?, url?}` |
| `homepage` | string | Documentation URL |
| `repository` | string | Source code URL |
| `license` | string | `"MIT"`, `"Apache-2.0"`, etc. |
| `keywords` | array | Discovery tags |

### Component path fields

Custom paths supplement default directories — they don't replace them. All paths relative to plugin root, starting with `./`.

| Field | Type | Description |
|---|---|---|
| `commands` | string\|array | Additional command files/dirs |
| `agents` | string\|array | Additional agent files |
| `skills` | string\|array | Additional skill dirs |
| `hooks` | string\|array\|object | Hook config paths or inline |
| `mcpServers` | string\|array\|object | MCP config paths or inline |
| `outputStyles` | string\|array | Output style files/dirs (**deprecated** since 2.0.30 — use `--system-prompt-file`, CLAUDE.md, or plugins instead) |
| `lspServers` | string\|array\|object | LSP config paths or inline |

### Environment variable

`${CLAUDE_PLUGIN_ROOT}`: absolute path to plugin directory. Use in hooks, scripts, MCP configs.

## Plugin components

### Skills

Location: `skills/` directory. Each skill is a directory with `SKILL.md`. Auto-discovered when plugin is installed.

### Agents

Location: `agents/` directory. Markdown files with YAML frontmatter (`name` + `description` required).

### Hooks

Location: `hooks/hooks.json`, or inline in `plugin.json`. Same format as settings.json hooks with optional `description` field.

```json
{
  "description": "Automatic code formatting",
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh", "timeout": 30}]
    }]
  }
}
```

Available events: PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, UserPromptSubmit, Notification, Stop, SubagentStart, SubagentStop, SessionStart, SessionEnd, TeammateIdle, TaskCompleted, ConfigChange, WorktreeCreate, WorktreeRemove, PreCompact.

Hook types: `command` (execute shell commands), `prompt` (evaluate with LLM using `$ARGUMENTS`), `agent` (run agentic verifier with tools).

### MCP servers

Location: `.mcp.json` at plugin root.

```json
{
  "mcpServers": {
    "server-name": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": { "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data" }
    }
  }
}
```

### LSP servers

Location: `.lsp.json` at plugin root. Required fields: `command`, `extensionToLanguage`.

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

**Note**: Language server binary must be installed separately.

## Installation scopes

| Scope | Settings file | Use case |
|---|---|---|
| `user` | `~/.claude/settings.json` | Personal, all projects (default) |
| `project` | `.claude/settings.json` | Team, via version control |
| `local` | `.claude/settings.local.json` | Project-specific, gitignored |
| `managed` | `managed-settings.json` | Managed plugins (read-only, update only) |

## Plugin directory structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Only manifest here (optional)
├── commands/                # Command markdown files (legacy; use skills/)
├── agents/                  # Agent markdown files
├── skills/                  # Skill directories with SKILL.md
├── hooks/
│   └── hooks.json           # Hook configuration
├── settings.json            # Default settings (only `agent` key supported)
├── scripts/                 # Hook and utility scripts
├── .mcp.json                # MCP server definitions
├── .lsp.json                # LSP server configurations
└── LICENSE
```

**Critical**: Components at plugin root, NOT inside `.claude-plugin/`.

## File locations reference

| Component | Default Location | Purpose |
|---|---|---|
| Manifest | `.claude-plugin/plugin.json` | Plugin metadata (optional) |
| Commands | `commands/` | Skill files (legacy; use `skills/`) |
| Agents | `agents/` | Subagent files |
| Skills | `skills/` | Skills with `<name>/SKILL.md` |
| Hooks | `hooks/hooks.json` | Hook configuration |
| Settings | `settings.json` | Default config (only `agent` key supported) |
| MCP | `.mcp.json` | MCP server definitions |
| LSP | `.lsp.json` | Language server configs |

## Plugin caching

Marketplace plugins are copied to a local cache directory (`~/.claude/plugins/cache`) rather than used in-place. Paths traversing outside the plugin root (`../`) won't work after install. Symlinks are honored during the copy process, so use them for external dependencies.

## Version management

Follow semantic versioning. Set version in `plugin.json`. Start at `1.0.0`.

## CLI commands

```bash
claude plugin install <plugin> [--scope user|project|local]
claude plugin uninstall <plugin> [--scope user|project|local]  # aliases: remove, rm
claude plugin enable <plugin> [--scope user|project|local]
claude plugin disable <plugin> [--scope user|project|local]
claude plugin update <plugin> [--scope user|project|local|managed]
```

Install `<plugin>` format: `plugin-name` or `plugin-name@marketplace-name`.

To pin a specific branch or tag, append `#ref` to a Git source URL:

```bash
claude plugin install https://github.com/owner/repo#v2.0.0
claude plugin install https://github.com/owner/repo#feature-branch
```

## Debugging

Use `claude --debug` (or `/debug` within the TUI) to see plugin loading details. Use `claude plugin validate` (or `/plugin validate`) to validate manifest JSON.

## Environment and security notes

**`CLAUDE_CODE_SIMPLE` environment variable** (since 2.1.50): When set, disables plugins, hooks, MCP servers, and other extensions. Sessions run in a minimal mode. Plugin authors should be aware that their plugins will not load when this variable is active.

**`allowUnsandboxedCommands` setting** (since 2.0.30): When set to `false` in settings, prevents hook scripts and MCP servers from using the `dangerouslyDisableSandbox` escape. This is a policy-level control that organizations can use to enforce sandboxed execution even if a plugin requests unsandboxed access.

## Common issues

| Issue | Solution |
|---|---|
| Plugin not loading | Validate JSON syntax with `claude plugin validate` or `/plugin validate` |
| Commands not appearing | Ensure `commands/` at root, not in `.claude-plugin/` |
| Hooks not firing | `chmod +x script.sh` |
| MCP server fails | Use `${CLAUDE_PLUGIN_ROOT}` for all paths |
| Path errors | All paths relative, starting with `./` |
