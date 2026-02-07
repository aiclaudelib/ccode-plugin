# Minimal Plugin Example

A bare-bones plugin with a single command.

## Directory Structure

```
hello-world/
├── .claude-plugin/
│   └── plugin.json
└── commands/
    └── hello.md
```

## File Contents

### .claude-plugin/plugin.json

```json
{
  "name": "hello-world"
}
```

### commands/hello.md

```markdown
---
name: hello
description: Prints a friendly greeting message
---

# Hello Command

Print a friendly greeting to the user.

## Implementation

Output the following message:

> Hello! This is a simple command from the hello-world plugin.
>
> Use this as a starting point for building more complex plugins.

Include the current timestamp to show the command executed successfully.
```

## Key Points

1. **Minimal manifest**: only the required `name` field
2. **Single command**: one markdown file in `commands/`
3. **Auto-discovery**: Claude Code finds the command automatically
4. **No dependencies**: no scripts, hooks, or external resources

## When to Use This Pattern

- Quick prototypes
- Single-purpose utilities
- Learning plugin development
- Internal team tools with one specific function

## Extending

To add more functionality:

1. **Add commands**: create more `.md` files in `commands/`
2. **Add metadata**: update `plugin.json` with version, description, author
3. **Add agents**: create `agents/` directory with agent definitions
4. **Add hooks**: create `hooks/hooks.json` for event handling
