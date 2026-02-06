# ccode

Claude Code plugin for creating skills, agents, hooks, and plugins with guided workflows, validation, and precise documentation knowledge.

## Installation

```bash
claude plugin add aiclaudelib/ccode-plugin
```

## Commands

| Command | Description |
|---------|-------------|
| `/ccode:ask` | Answers questions about Claude Code features, configuration, CLI, prompting strategies, plugins, skills, hooks, agents, teams, containers, and enterprise governance |
| `/ccode:create-plugin` | Scaffold a complete Claude Code plugin with manifest, skills, agents, hooks, and scripts |
| `/ccode:create-skill` | Scaffold a new skill with correct SKILL.md frontmatter, progressive disclosure, and best practices |
| `/ccode:create-agent` | Scaffold a new custom subagent with correct frontmatter, tool configuration, and system prompt |
| `/ccode:create-hook` | Create hook configurations and validation scripts for all 12 hook events |

## Structure

```
ccode/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── skills/
│   ├── ask/                  # Knowledge Q&A skill
│   ├── create-plugin/        # Plugin scaffolding
│   ├── create-skill/         # Skill scaffolding
│   ├── create-agent/         # Agent scaffolding
│   └── create-hook/          # Hook scaffolding
├── agents/
│   ├── docs-guide.md         # Documentation router
│   ├── hook-expert.md        # Hook & automation specialist
│   ├── plugin-architect.md   # Plugin lead architect
│   └── skill-expert.md       # Skill authoring specialist
├── hooks/
│   └── hooks.json            # Validation hooks config
├── knowledge/                # 18 documentation files
└── scripts/                  # Validation scripts
```

## License

[MIT](LICENSE)
