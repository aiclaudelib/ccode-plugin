# Skills reference

Skills extend Claude Code's capabilities. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or users invoke with `/skill-name`.

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, which works across multiple AI tools. Claude Code extends the standard with invocation control, subagent execution, and dynamic context injection.

> **Custom slash commands have been merged into skills.** A file at `.claude/commands/review.md` and a skill at `.claude/skills/review/SKILL.md` both create `/review` and work the same way. Existing `.claude/commands/` files keep working. Skills add optional features: supporting files directory, frontmatter for invocation control, and automatic loading when relevant. If a skill and a command share the same name, the skill takes precedence.

## Skill locations

| Location | Path | Scope |
|---|---|---|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

Priority: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespace, so they cannot conflict with other levels.

Nested `.claude/skills/` directories in subdirectories are auto-discovered (monorepo support).

### Hot-reload

Skills in `~/.claude/skills/` and `.claude/skills/` hot-reload automatically -- editing a SKILL.md takes effect immediately without restarting the session. The same applies to skills in directories added via `--add-dir`.

## Skill structure

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

## Frontmatter reference

```yaml
---
name: my-skill
description: What this skill does
disable-model-invocation: true
allowed-tools: Read, Grep
---

Your skill instructions here...
```

Full example with all fields:

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
| `name` | No | Display name for the skill. If omitted, uses directory name. Lowercase letters, numbers, and hyphens only (max 64 chars). |
| `description` | Recommended | What the skill does AND when to use it. Claude uses this to decide when to apply the skill. If omitted, uses the first paragraph of markdown content. |
| `argument-hint` | No | Shown during slash command autocomplete. Example: `[issue-number]` |
| `disable-model-invocation` | No | Set to `true` to prevent Claude from automatically loading this skill. Use for workflows you want to trigger manually with `/name`. Default: `false`. |
| `user-invocable` | No | Set to `false` to hide from the `/` menu. Use for background knowledge users shouldn't invoke directly. Default: `true`. |
| `allowed-tools` | No | Tools Claude can use without permission when skill is active. Supports wildcard `*` for Bash rules: `Bash(npm *)`, `Bash(git *)`, `Bash(gh *)`. |
| `model` | No | Model to use when this skill is active. |
| `context` | No | `fork` = run in isolated subagent context. |
| `agent` | No | When `context: fork`: `Explore`, `Plan`, `general-purpose`, or custom agent name. |
| `hooks` | No | Lifecycle hooks scoped to this skill's execution. Supports `PreToolUse`, `PostToolUse`, and `Stop` hook types. Hooks activate when the skill is loaded and deactivate when it finishes. |

## String substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All arguments. If not present in content, appended as `ARGUMENTS: <value>`. |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index. |
| `${CLAUDE_SESSION_ID}` | Current session ID. |

## Invocation control

Typing `/` anywhere in the input line triggers slash command autocomplete (not just at the beginning of input). The `argument-hint` field appears next to the skill name in the autocomplete menu.

| Frontmatter | User invokes | Claude invokes | When loaded into context |
|---|---|---|---|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, full skill loads when you invoke |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

> In a regular session, skill descriptions are loaded into context so Claude knows what's available, but full skill content only loads when invoked. Subagents with preloaded skills work differently: the full skill content is injected at startup.

## Dynamic context injection

The `` !`command` `` syntax runs shell commands before skill content is sent to Claude:

```yaml
---
name: pr-summary
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`
```

Commands run first, output replaces the placeholder. This is preprocessing.

> **Tip:** To enable extended thinking in a skill, include the word "ultrathink" anywhere in your skill content.

## Forked context skills

Add `context: fork` to run in an isolated subagent. The skill content becomes the subagent's prompt (no conversation history).

> **Warning:** `context: fork` only makes sense for skills with explicit instructions. If your skill contains guidelines like "use these API conventions" without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output.

| Approach | System prompt | Task | Also loads |
|---|---|---|---|
| Skill with `context: fork` | From agent type (`Explore`, `Plan`, etc.) | SKILL.md content | CLAUDE.md |
| Subagent with `skills` field | Subagent's body | Claude's delegation message | Preloaded skills + CLAUDE.md |

The `agent` field specifies which subagent config: built-in (`Explore`, `Plan`, `general-purpose`) or custom from `.claude/agents/`. Default: `general-purpose`.

### When `context: fork` is required

**Orchestrator skills** — skills that spawn subagents via `Task` tool — **must** use `context: fork`. Without it, every subagent completion sends a notification to the main session, triggering a new turn. Each turn fires all Stop hooks (project + plugin). With many subagents this creates a cascade:

- 40 subagents × 7 Stop hooks = 280 hook executions
- Each notification triggers a "Standing by" turn in the main session
- User sees a flood of empty messages instead of a clean result

With `context: fork`, all subagent notifications stay inside the forked orchestrator. The main session receives a single result when the orchestrator finishes.

### When `context: fork` must NOT be used

**Interactive skills** — skills that use `AskUserQuestion` to prompt the user — must stay inline (no fork). `AskUserQuestion` does not work from a forked context because the forked subagent cannot interact with the user.

### Decision guide

| Skill type | `context: fork` | Why |
|---|---|---|
| Spawns subagents via `Task` | **Required** | Prevents notification flooding and hook cascading |
| Uses `AskUserQuestion` | **No** | User interaction doesn't work from fork |
| Explicit task instructions | Recommended | Isolates execution, cleaner output |
| Guidelines / reference only | No | No task to execute in isolation |

## Supporting files

Keep SKILL.md under 500 lines. Move detailed reference to separate files:

```markdown
## Additional resources
- For complete API details, see `reference.md`
- For usage examples, see `examples.md`
```

Keep references one level deep from SKILL.md.

## Restrict skill access

Built-in commands like `/compact` and `/init` are not available through the Skill tool.

Three ways to control which skills Claude can invoke:

- **Deny all skills**: add `Skill` to deny rules in `/permissions`
- **Allow/deny specific**: `Skill(commit)` for exact match, `Skill(deploy *)` for prefix match with any arguments
- **Hide from Claude**: `disable-model-invocation: true` removes the skill from Claude's context entirely

> The `user-invocable` field only controls menu visibility, not Skill tool access. Use `disable-model-invocation: true` to block programmatic invocation.

## Troubleshooting

- **Skill not triggering**: Check description includes keywords users would say. Verify skill appears in `What skills are available?`. Try invoking directly with `/skill-name`.
- **Skill triggers too often**: Make description more specific. Add `disable-model-invocation: true` for manual-only invocation.
- **Claude doesn't see all skills**: Skill descriptions may exceed the character budget (2% of context window, fallback 16,000 chars). Run `/context` to check for excluded skills. Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env variable.
