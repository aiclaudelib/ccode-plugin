---
name: create-plugin
description: Scaffold a complete Claude Code plugin with manifest, skills, agents, hooks, and scripts. Creates the full directory structure ready for testing.
argument-hint: "[plugin-name]"
user-invocable: false
context: fork
agent: ccode:plugin-architect
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Create a New Claude Code Plugin

You are scaffolding a complete Claude Code plugin. Follow this workflow precisely.

**Important**: Since subagents cannot spawn other subagents, you must generate ALL component files directly — do not attempt to invoke other skills or agents.

## Phase 1: Discovery

Ask the user these questions (skip any already answered via arguments):

1. **Plugin name**: What should this plugin be called? (kebab-case, no spaces)
   - Suggested name from arguments: `$ARGUMENTS`
2. **Purpose**: What does this plugin do? Who is it for?
3. **Components needed** (select all that apply):
   - Skills — slash commands and reusable knowledge
   - Agents — specialized subagents
   - Hooks — lifecycle event handlers
   - MCP servers — external tool integrations
   - Settings — user-configurable options via `.local.md`
4. **For each skill**: name, purpose, invocation mode (manual/auto/both)
5. **For each agent**: name, specialization, tools, model
6. **For each hook**: event, matcher, type, purpose
7. **For each MCP server**: type (stdio/SSE/HTTP/WebSocket), purpose, authentication method
8. **Author info**: name, email, URL (optional)
9. **License**: MIT, Apache-2.0, etc.

## Phase 2: Component Planning

Based on the user's answers, determine the complete component list:

1. List all skills with their names and whether they need references/examples directories
2. List all agents with their roles and tool requirements
3. List all hooks with events, matchers, and script locations
4. List MCP servers with types and configuration needs
5. Identify shared resources (lib/, config/, scripts/) needed across components
6. Determine if settings (`.local.md` pattern) are needed

Present the component plan to the user for confirmation before proceeding.

## Phase 3: Detailed Design

For each component, clarify implementation details:

- **Skills**: What knowledge files do they need? Do they route to references? What agent do they use?
- **Agents**: What system prompt? What tools? What model?
- **Hooks**: What do the scripts validate or enforce? What are the timeout values?
- **MCP servers**: What environment variables are needed? What tools do they expose?
- **Settings**: What fields should the `.local.md` template include?

## Phase 4: Consult Knowledge Base

Read relevant knowledge files for detailed specs:
- `${CLAUDE_PLUGIN_ROOT}/knowledge/plugins.md` — plugin creation guide
- `${CLAUDE_PLUGIN_ROOT}/knowledge/plugins-reference.md` — full manifest schema
- `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-structure.md` — directory layout and organization patterns
- `${CLAUDE_PLUGIN_ROOT}/knowledge/skills.md` — skill specs (if creating skills)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/subagents.md` — agent specs (if creating agents)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/hooks-reference-core.md` — hook specs (if creating hooks)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/mcp-integration.md` — MCP server config (if creating MCP servers)
- `${CLAUDE_PLUGIN_ROOT}/knowledge/plugin-settings.md` — settings pattern (if creating settings)

## Phase 5: Structure Creation

Scaffold the complete directory structure and manifest:

1. Create the plugin root directory
2. Create `.claude-plugin/plugin.json` with all metadata
3. Create component directories (`skills/`, `agents/`, `hooks/`, `scripts/`)
4. Create `.mcp.json` if MCP servers are needed
5. Use `${CLAUDE_PLUGIN_ROOT}` for all internal paths

## Phase 6: Component Implementation

Generate all component files following the agent's embedded schemas:

1. Generate all skill SKILL.md files with correct frontmatter
2. Generate all agent markdown files with system prompts
3. Generate hooks.json and hook scripts
4. Generate MCP server configurations
5. Generate settings template if needed
6. Make all scripts executable (`chmod +x`)

**Critical**: Generate ALL files directly — subagents cannot spawn other subagents.

## Phase 7: Validation

Verify the scaffolded plugin for correctness:

1. `plugin.json` has valid `name` (kebab-case) and all declared fields
2. Components are at plugin root, NOT inside `.claude-plugin/`
3. All frontmatter is valid YAML with required fields
4. All `${CLAUDE_PLUGIN_ROOT}` paths are correct
5. Hook scripts are executable
6. MCP server configurations reference valid commands and environment variables

Suggest running the `plugin-validator` agent for comprehensive validation: "You can validate the plugin by asking Claude to use the plugin-validator agent."

## Phase 8: Testing and Documentation

Provide the user with:

1. **Testing checklist**:
   - Load the plugin: `claude --plugin-dir ./plugin-name`
   - Test each skill by running its slash command
   - Verify hooks fire on the correct events
   - Check MCP servers connect (run `/mcp`)
   - Verify agents are available for delegation
2. **Files created**: list all generated files with brief descriptions
3. **README**: ensure the plugin has a README.md with installation, usage, and configuration
4. **Next steps**: suggest enhancements, adding knowledge files, publishing
