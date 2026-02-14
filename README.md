# ccode

Claude Code plugin for creating skills, agents, hooks, MCP integrations, plugins, and marketplaces with guided
workflows, validation, documentation knowledge, and review agents.

## Installation

```
/plugin marketplace add aiclaudelib/marketplace
/plugin install ccode@aiclaudelib
```

## Commands

| Command                      | Description                                                                                                                                                          |
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/ccode:ask`                 | Answers questions about Claude Code features, configuration, CLI, prompting strategies, plugins, skills, hooks, agents, teams, containers, and enterprise governance |
| `/ccode:create-plugin`       | Scaffold a complete Claude Code plugin with manifest, skills, agents, hooks, and scripts (8-phase guided workflow)                                                   |
| `/ccode:create-skill`        | Scaffold a new skill with correct SKILL.md frontmatter, progressive disclosure, and best practices                                                                   |
| `/ccode:create-agent`        | Scaffold a new custom subagent with correct frontmatter, tool configuration, and system prompt                                                                       |
| `/ccode:create-hook`         | Create hook configurations and validation scripts for all 12 hook events                                                                                             |
| `/ccode:mcp-integration`     | Guidance on MCP server types (stdio, SSE, HTTP, WebSocket), authentication, tool naming, and configuration                                                           |
| `/ccode:plugin-settings`     | Guidance on the `.local.md` settings pattern, YAML frontmatter parsing, and reading settings from hooks/commands/agents                                              |
| `/ccode:plugin-structure`    | Guidance on plugin directory layout, manifest schema, component organization, and auto-discovery                                                                     |
| `/ccode:plugin-marketplaces` | Guidance on creating and distributing plugin marketplaces, marketplace.json schema, plugin sources, hosting, and team configuration                                  |

## Structure

```
ccode/
├── .claude-plugin/
│   └── plugin.json            # Plugin manifest
├── skills/
│   ├── ask/                   # Knowledge Q&A skill
│   ├── create-plugin/         # Plugin scaffolding (8-phase workflow)
│   ├── create-skill/          # Skill scaffolding
│   ├── create-agent/          # Agent scaffolding
│   ├── create-hook/           # Hook scaffolding
│   ├── mcp-integration/       # MCP server guidance with references and examples
│   ├── plugin-settings/       # Plugin settings guidance with references and examples
│   ├── plugin-structure/      # Plugin structure guidance with references and examples
│   └── plugin-marketplaces/   # Marketplace creation guidance with references and examples
├── agents/
│   ├── docs-guide.md          # Documentation router
│   ├── hook-expert.md         # Hook & automation specialist
│   ├── plugin-architect.md    # Plugin lead architect
│   ├── plugin-validator.md    # Plugin structure and component validator
│   ├── skill-expert.md        # Skill authoring specialist
│   └── skill-reviewer.md      # Skill quality reviewer
├── hooks/
│   └── hooks.json             # Validation hooks config
├── knowledge/                 # 22 documentation files
├── scripts/
│   ├── clean-knowledge.sh     # Knowledge file cleanup
│   ├── hook-linter.sh         # Lint hooks.json for common issues
│   ├── parse-frontmatter.sh   # Extract YAML frontmatter fields from markdown
│   ├── test-hook.sh           # Test hook scripts with simulated events
│   ├── validate-agent.sh      # Validate agent markdown files
│   ├── validate-hooks-json.sh # Validate hooks.json structure
│   ├── validate-settings.sh   # Validate .local.md settings files
│   └── validate-skill-frontmatter.sh  # Validate skill SKILL.md frontmatter
└── README.md
```

## License

[MIT](LICENSE)
