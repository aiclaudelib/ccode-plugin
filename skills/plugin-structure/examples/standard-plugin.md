# Standard Plugin Example

A well-structured plugin with commands, agents, skills, and hooks.

## Directory Structure

```
code-quality/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── lint.md
│   ├── test.md
│   └── review.md
├── agents/
│   ├── code-reviewer.md
│   └── test-generator.md
├── skills/
│   ├── code-standards/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── style-guide.md
│   └── testing-patterns/
│       ├── SKILL.md
│       └── examples/
│           ├── unit-test.js
│           └── integration-test.js
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── validate-commit.sh
└── scripts/
    ├── run-linter.sh
    └── generate-report.py
```

## File Contents

### .claude-plugin/plugin.json

```json
{
  "name": "code-quality",
  "version": "1.0.0",
  "description": "Comprehensive code quality tools including linting, testing, and review automation",
  "author": {
    "name": "Quality Team",
    "email": "quality@example.com"
  },
  "homepage": "https://docs.example.com/plugins/code-quality",
  "repository": "https://github.com/example/code-quality-plugin",
  "license": "MIT",
  "keywords": ["code-quality", "linting", "testing", "code-review", "automation"]
}
```

### commands/lint.md

```markdown
---
name: lint
description: Run linting checks on the codebase
---

# Lint Command

Run comprehensive linting checks on the project codebase.

## Process

1. Detect project type and installed linters
2. Run appropriate linters (ESLint, Pylint, RuboCop, etc.)
3. Collect and format results
4. Report issues with file locations and severity

## Output

Present issues organized by:
- Critical issues (must fix)
- Warnings (should fix)
- Style suggestions (optional)
```

### commands/review.md

```markdown
---
name: review
description: Run a code review on recent changes
---

# Review Command

Review recent code changes for quality, bugs, and security.

## Process

1. Identify changed files (git diff)
2. Analyze each file for issues
3. Check against project coding standards
4. Generate review report with prioritized findings
```

### agents/code-reviewer.md

```markdown
---
description: Expert code reviewer for quality analysis, bug detection, and security review
capabilities:
  - Analyze code for potential bugs and logic errors
  - Identify security vulnerabilities
  - Suggest performance improvements
  - Ensure code follows project standards
---

# Code Reviewer Agent

Specialized agent for comprehensive code review.

## Review Process

1. Initial scan for obvious issues
2. Deep analysis of changed code
3. Context evaluation for related impact
4. Prioritized recommendations
```

### hooks/hooks.json

```json
{
  "description": "Code quality enforcement hooks",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Verify the code being written meets coding standards. Check formatting, naming conventions, and documentation.",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate-commit.sh",
            "timeout": 45
          }
        ]
      }
    ]
  }
}
```

## Key Points

1. **Complete manifest**: all recommended metadata fields
2. **Multiple components**: commands, agents, skills, hooks
3. **Rich skills**: references and examples for detailed information
4. **Automation**: hooks enforce standards automatically
5. **Integration**: components work together cohesively

## When to Use This Pattern

- Production plugins for distribution
- Team collaboration tools
- Plugins requiring consistency enforcement
- Complex workflows with multiple entry points
