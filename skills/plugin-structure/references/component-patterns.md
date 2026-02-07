# Component Organization Patterns

Advanced patterns for organizing plugin components effectively.

## Component Lifecycle

### Discovery Phase

When Claude Code starts:

1. **Scan enabled plugins**: read `.claude-plugin/plugin.json` for each
2. **Discover components**: look in default and custom paths
3. **Parse definitions**: read YAML frontmatter and configurations
4. **Register components**: make available to Claude Code
5. **Initialize**: start MCP servers, register hooks

Registration happens during Claude Code initialization, not continuously.

### Activation Phase

When components are used:

- **Commands**: user types slash command, Claude Code looks up and executes
- **Agents**: task arrives, Claude Code evaluates capabilities and selects agent
- **Skills**: task context matches description, Claude Code loads skill content
- **Hooks**: event occurs, Claude Code calls matching hooks
- **MCP servers**: tool call matches server capability, forwards to server

## Command Organization

### Flat Structure

All commands in a single directory:

```
commands/
├── build.md
├── test.md
├── deploy.md
├── review.md
└── docs.md
```

When to use: 5-15 commands, all at the same abstraction level, no clear categorization.

### Categorized Structure

Multiple directories for different command types:

```
commands/              # Core commands
├── build.md
└── test.md

admin-commands/        # Administrative
├── configure.md
└── manage.md

workflow-commands/     # Workflow automation
├── review.md
└── deploy.md
```

Manifest configuration:
```json
{
  "commands": ["./commands", "./admin-commands", "./workflow-commands"]
}
```

When to use: 15+ commands, clear functional categories, different permission levels.

### Hierarchical Structure

Nested organization for complex plugins:

```
commands/
├── ci/
│   ├── build.md
│   ├── test.md
│   └── lint.md
├── deployment/
│   ├── staging.md
│   └── production.md
└── management/
    ├── config.md
    └── status.md
```

Note: Claude Code does not support nested command auto-discovery. Use custom paths:

```json
{
  "commands": ["./commands/ci", "./commands/deployment", "./commands/management"]
}
```

When to use: 20+ commands, multi-level categorization.

## Agent Organization

### Role-Based

Organize agents by their primary role:

```
agents/
├── code-reviewer.md
├── test-generator.md
├── documentation-writer.md
└── refactorer.md
```

When to use: agents have distinct, non-overlapping roles.

### Capability-Based

Organize by specific expertise:

```
agents/
├── python-expert.md
├── typescript-expert.md
├── api-specialist.md
└── database-specialist.md
```

When to use: technology-specific agents, automatic agent selection.

### Workflow-Based

Organize by workflow stage:

```
agents/
├── planning-agent.md
├── implementation-agent.md
├── testing-agent.md
└── deployment-agent.md
```

When to use: sequential workflows, stage-specific expertise.

## Skill Organization

### Topic-Based

Each skill covers a specific topic:

```
skills/
├── api-design/
│   └── SKILL.md
├── error-handling/
│   └── SKILL.md
└── testing-strategies/
    └── SKILL.md
```

When to use: knowledge-based skills, educational/reference content.

### Skill with Rich Resources

Comprehensive skill with all resource types:

```
skills/
└── api-testing/
    ├── SKILL.md              # Core skill (under 500 lines)
    ├── references/
    │   ├── rest-api-guide.md
    │   ├── graphql-guide.md
    │   └── authentication.md
    ├── examples/
    │   ├── basic-test.js
    │   ├── authenticated-test.js
    │   └── integration-test.js
    ├── scripts/
    │   ├── run-tests.sh
    │   └── generate-report.py
    └── assets/
        └── test-template.json
```

Resource usage:
- **SKILL.md**: overview and routing to resources
- **references/**: detailed guides (loaded as needed)
- **examples/**: copy-paste code samples
- **scripts/**: executable helpers
- **assets/**: templates and configurations

## Hook Organization

### Monolithic Configuration

Single hooks.json with all hooks:

```
hooks/
├── hooks.json     # All hook definitions
└── scripts/
    ├── validate-write.sh
    ├── validate-bash.sh
    └── load-context.sh
```

When to use: 5-10 hooks, simple logic, centralized configuration.

### Purpose-Based Script Organization

Group scripts by functional purpose:

```
hooks/
├── hooks.json
└── scripts/
    ├── security/
    │   ├── validate-paths.sh
    │   ├── check-credentials.sh
    │   └── scan-secrets.sh
    ├── quality/
    │   ├── lint-code.sh
    │   ├── check-tests.sh
    │   └── verify-docs.sh
    └── workflow/
        ├── notify-team.sh
        └── update-status.sh
```

When to use: many hook scripts, clear functional boundaries, team specialization.

## Cross-Component Patterns

### Shared Resources

Components sharing common utilities:

```
plugin/
├── commands/
│   └── test.md        # References lib/test-utils.sh
├── hooks/
│   └── scripts/
│       └── pre-test.sh # Sources lib/test-utils.sh
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

Benefits: code reuse, consistent behavior, easier maintenance.

### Layered Architecture

Separate concerns into layers:

```
plugin/
├── commands/          # User interface layer
├── agents/            # Orchestration layer
├── skills/            # Knowledge layer
└── lib/
    ├── core/         # Core business logic
    ├── integrations/ # External services
    └── utils/        # Helper functions
```

When to use: large plugins (100+ files), multiple developers.

## Best Practices

### Naming

1. **Consistent naming**: match file names to component purpose
2. **Descriptive names**: indicate what component does
3. **Avoid abbreviations**: use full words for clarity

### Organization

1. **Start simple**: use flat structure, reorganize when needed
2. **Group related items**: keep related components together
3. **Separate concerns**: do not mix unrelated functionality

### Scalability

1. **Plan for growth**: choose structure that scales
2. **Refactor early**: reorganize before it becomes painful
3. **Document structure**: explain organization in README

### Performance

1. **Avoid deep nesting**: impacts discovery time
2. **Minimize custom paths**: use defaults when possible
3. **Keep configurations small**: large configs slow loading
