# Plugins guide

Plugins extend Claude Code with skills, agents, hooks, and MCP servers that can be shared across projects and teams.

## Standalone vs plugin

| Approach | Skill names | Best for |
|---|---|---|
| Standalone (`.claude/`) | `/hello` | Personal, project-specific, experiments |
| Plugin (`.claude-plugin/plugin.json`) | `/plugin-name:hello` | Sharing, distribution, versioned releases |

## Plugin structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json      # Manifest (only file here)
├── skills/              # Skill directories with SKILL.md
├── agents/              # Agent markdown files
├── hooks/
│   └── hooks.json       # Hook configurations
├── scripts/             # Hook and utility scripts
├── .mcp.json            # MCP server configs (optional)
└── .lsp.json            # LSP server configs (optional)
```

**Critical**: Components go at plugin root, NOT inside `.claude-plugin/`. Only `plugin.json` goes in `.claude-plugin/`.

## Creating a plugin

1. Create plugin directory with `.claude-plugin/plugin.json`
2. Add components at root level (skills/, agents/, hooks/, etc.)
3. Test with `claude --plugin-dir ./my-plugin`

### Manifest (`plugin.json`)

Only `name` is required (kebab-case). Name determines namespace: `/plugin-name:skill-name`.

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Brief plugin description",
  "author": { "name": "Author Name" },
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

Components at default locations are auto-discovered. Custom path fields (`commands`, `agents`, `skills`, `hooks`, `mcpServers`, `lspServers`) supplement defaults.

### Skills in plugins

Same as standalone but namespaced. Create `skills/<name>/SKILL.md` with frontmatter.

### Hooks in plugins

Create `hooks/hooks.json` with optional `description`:

```json
{
  "description": "What these hooks do",
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"}]
    }]
  }
}
```

Use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths.

### MCP servers

Create `.mcp.json` at plugin root:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```

## Testing

```bash
claude --plugin-dir ./my-plugin
# Multiple plugins:
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

## Converting standalone to plugin

1. Create plugin directory with `.claude-plugin/plugin.json`
2. Copy commands/, agents/, skills/ from `.claude/`
3. Move hooks from settings.json to `hooks/hooks.json`
4. Test with `--plugin-dir`
