# Minimal marketplace example

A single-plugin marketplace with local relative source. Good for getting started or testing.

## Directory structure

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    └── review-plugin/
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
            └── review/
                └── SKILL.md
```

## marketplace.json

```json
{
  "name": "my-plugins",
  "owner": {
    "name": "Your Name"
  },
  "plugins": [
    {
      "name": "review-plugin",
      "source": "./plugins/review-plugin",
      "description": "Adds a /review skill for quick code reviews"
    }
  ]
}
```

## Plugin manifest (plugins/review-plugin/.claude-plugin/plugin.json)

```json
{
  "name": "review-plugin",
  "description": "Adds a /review skill for quick code reviews",
  "version": "1.0.0"
}
```

## Skill file (plugins/review-plugin/skills/review/SKILL.md)

```markdown
---
description: Review code for bugs, security, and performance
disable-model-invocation: true
---

Review the code I've selected or the recent changes for:
- Potential bugs or edge cases
- Security concerns
- Performance issues
- Readability improvements

Be concise and actionable.
```

## Testing

```
/plugin marketplace add ./my-marketplace
/plugin install review-plugin@my-plugins
/review
```
