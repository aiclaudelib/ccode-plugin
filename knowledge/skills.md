# Skills reference

Skills extend Claude Code's capabilities. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or users invoke with `/skill-name`.

## Skill locations

| Location | Path | Scope |
|---|---|---|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

Priority: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespace.

Nested `.claude/skills/` directories in subdirectories are auto-discovered (monorepo support).

## Skill structure

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── reference.md       # Optional detailed docs
├── examples.md        # Optional examples
└── scripts/
    └── helper.sh      # Optional executable scripts
```

## Frontmatter reference

```yaml
---
name: my-skill
description: What this skill does and when to use it
argument-hint: "[arg1] [arg2]"
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Grep, Glob
model: sonnet
context: fork
agent: Explore
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/check.sh"
---
```

| Field | Required | Description |
|---|---|---|
| `name` | No | Lowercase, hyphens, max 64 chars. No "anthropic"/"claude". Defaults to directory name. |
| `description` | Recommended | Max 1024 chars. What the skill does AND when to use it. Third person. |
| `argument-hint` | No | Shown during autocomplete. Example: `[issue-number]` |
| `disable-model-invocation` | No | `true` = only user can invoke. Default: `false`. |
| `user-invocable` | No | `false` = hidden from `/` menu. Default: `true`. |
| `allowed-tools` | No | Tools Claude can use without permission when skill is active. |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit`. |
| `context` | No | `fork` = run in isolated subagent context. |
| `agent` | No | When `context: fork`: `Explore`, `Plan`, `general-purpose`, or custom agent name. |
| `hooks` | No | Lifecycle hooks scoped to this skill. |

## String substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All arguments. If not present in content, appended as `ARGUMENTS: <value>`. |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index. |
| `${CLAUDE_SESSION_ID}` | Current session ID. |

## Invocation control

| Frontmatter | User invokes | Claude invokes | Description loaded |
|---|---|---|---|
| (default) | Yes | Yes | Always in context |
| `disable-model-invocation: true` | Yes | No | NOT in context |
| `user-invocable: false` | No | Yes | Always in context |

## Dynamic context injection

The `` !`command` `` syntax runs shell commands before skill content is sent to Claude:

```yaml
---
name: pr-summary
context: fork
agent: Explore
---

## PR context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`
```

Commands run first, output replaces the placeholder. This is preprocessing.

## Forked context skills

Add `context: fork` to run in an isolated subagent. The skill content becomes the subagent's prompt (no conversation history).

**Important**: `context: fork` only makes sense for skills with explicit task instructions, not just guidelines.

| Approach | System prompt | Task |
|---|---|---|
| Skill with `context: fork` | From agent type | SKILL.md content |
| Subagent with `skills` field | Subagent's body | Claude's delegation message |

The `agent` field specifies which subagent config: built-in (`Explore`, `Plan`, `general-purpose`) or custom from `.claude/agents/`. Default: `general-purpose`.

## Supporting files

Keep SKILL.md under 500 lines. Move detailed reference to separate files:

```markdown
## Additional resources
- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

Keep references one level deep from SKILL.md.

## Restrict skill access

- Deny all skills: add `Skill` to deny rules
- Allow/deny specific: `Skill(commit)`, `Skill(deploy *)`
- Hide from Claude: `disable-model-invocation: true`
