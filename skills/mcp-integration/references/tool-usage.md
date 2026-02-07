# Using MCP Tools in Commands and Agents

Complete guide to using MCP tools effectively in Claude Code plugin commands and agents.

## Tool Naming Convention

### Format

When MCP servers provide tools, they are automatically prefixed with a namespaced identifier that includes the plugin name and server name:

```
mcp__plugin_<plugin-name>_<server-name>__<tool-name>
```

This naming convention ensures:
- No collisions between tools from different plugins
- No collisions between tools from different servers in the same plugin
- Clear identification of which plugin and server provides each tool

### Examples

| Plugin | Server | Tool | Full Name |
|---|---|---|---|
| `asana` | `asana` | `asana_create_task` | `mcp__plugin_asana_asana__asana_create_task` |
| `asana` | `asana` | `asana_search_tasks` | `mcp__plugin_asana_asana__asana_search_tasks` |
| `myplug` | `database` | `query` | `mcp__plugin_myplug_database__query` |
| `myplug` | `database` | `list_tables` | `mcp__plugin_myplug_database__list_tables` |
| `devops` | `k8s` | `get_pods` | `mcp__plugin_devops_k8s__get_pods` |
| `devops` | `github-actions` | `trigger_workflow` | `mcp__plugin_devops_github-actions__trigger_workflow` |

Note that some MCP servers include their own prefix in tool names (e.g., Asana's tools are named `asana_create_task` not just `create_task`). This means the full qualified name includes the server name twice, which is expected.

### Discovering Tool Names

Use the `/mcp` command in Claude Code to see all available MCP servers and their tools:

```
/mcp
```

This displays:
- All connected MCP servers and their connection status
- Tools provided by each server with full names
- Tool input schemas (parameter types, required fields, descriptions)
- Tool descriptions explaining what each tool does

This is the authoritative source for tool names -- always verify tool names with `/mcp` rather than guessing.

## Using Tools in Commands

### Pre-Allowing Specific Tools

Commands must explicitly declare which MCP tools they use in the YAML frontmatter `allowed-tools` field. Without this declaration, Claude Code prompts the user for permission each time the tool is called, which disrupts the workflow.

```markdown
---
name: create-task
description: Create a new Asana task
allowed-tools: [
  "mcp__plugin_asana_asana__asana_create_task"
]
---

# Create Task Command

Steps:
1. Gather task details from user (title, description, project)
2. Validate that required fields are provided (title and workspace)
3. Use mcp__plugin_asana_asana__asana_create_task with the validated details
4. Check the response for success or error
5. Confirm creation and show the task link to the user
```

### Multiple Tools in a Command

When a command needs several tools, list them all in the `allowed-tools` array:

```markdown
---
name: manage-tasks
description: Search, create, and update Asana tasks
allowed-tools: [
  "mcp__plugin_asana_asana__asana_create_task",
  "mcp__plugin_asana_asana__asana_search_tasks",
  "mcp__plugin_asana_asana__asana_get_project",
  "mcp__plugin_asana_asana__asana_update_task"
]
---

# Task Management

## Searching Tasks
1. Ask user for search criteria (project, assignee, status, keyword)
2. Use mcp__plugin_asana_asana__asana_search_tasks with the filters
3. Display results in a formatted table

## Creating Tasks
1. Gather task details:
   - Title (required)
   - Description (optional)
   - Project (required)
   - Assignee (optional)
   - Due date (optional, format YYYY-MM-DD)
2. Validate required fields
3. Use mcp__plugin_asana_asana__asana_create_task
4. Show confirmation with task link

## Updating Tasks
1. Identify the task to update (by ID or search)
2. Gather changes from user
3. Use mcp__plugin_asana_asana__asana_update_task
4. Confirm the update
```

### Wildcard Tool Access

Use a wildcard pattern to allow all tools from a specific server:

```markdown
---
allowed-tools: ["mcp__plugin_asana_asana__*"]
---
```

**Use wildcards sparingly.** They grant access to every tool the server provides, including potentially destructive operations (delete, modify, admin functions). Prefer explicit tool lists for security and clarity. Only use wildcards when the command genuinely needs access to all tools from a server and the server is trusted.

### Tools from Multiple Servers

A command can use tools from different MCP servers in the same plugin:

```markdown
---
description: Cross-reference Asana tasks with GitHub issues
allowed-tools: [
  "mcp__plugin_devops_asana__asana_search_tasks",
  "mcp__plugin_devops_github__search_issues",
  "mcp__plugin_devops_github__create_issue"
]
---
```

### Referencing Tools in Command Instructions

When writing command instructions, reference MCP tools by their full qualified name. Claude uses these names to invoke the correct tools:

```markdown
---
description: Generate project status report from Asana
allowed-tools: [
  "mcp__plugin_asana_asana__asana_search_tasks",
  "mcp__plugin_asana_asana__asana_get_project"
]
---

# Project Status Report

## Process

1. **Get project info**: Call mcp__plugin_asana_asana__asana_get_project with the
   project GID to get the project name, description, and team
2. **Fetch all tasks**: Call mcp__plugin_asana_asana__asana_search_tasks with filters:
   - project: the project GID
   - limit: 100
   - opt_fields: name,completed,due_on,assignee.name
3. **Calculate metrics**:
   - Total tasks
   - Completed tasks and completion percentage
   - Overdue tasks (due_on in the past, not completed)
   - Tasks due this week
4. **Generate report**: Format as markdown with sections for summary, metrics,
   overdue items, and upcoming deadlines
5. **Present to user**: Display the formatted report
```

## Using Tools in Agents

### Agent Configuration

Agents have broader tool access than commands. They can use MCP tools autonomously without declaring them in `allowed-tools` in the frontmatter. However, you should document which tools the agent typically uses so its behavior is predictable.

```markdown
---
name: asana-status-updater
description: This agent should be used when the user asks to "update Asana status", "generate project report", or "sync Asana tasks"
model: inherit
---

## Role

Autonomous agent for generating Asana project status reports and posting updates.

## Available MCP Tools

This agent uses the following Asana MCP tools:
- mcp__plugin_asana_asana__asana_search_tasks -- Query tasks with filters
- mcp__plugin_asana_asana__asana_get_project -- Get project details
- mcp__plugin_asana_asana__asana_create_comment -- Post status updates

## Process

1. **Query tasks**: Use mcp__plugin_asana_asana__asana_search_tasks to get all tasks
   in the target project
2. **Get project info**: Use mcp__plugin_asana_asana__asana_get_project for context
3. **Analyze progress**: Calculate completion rates, identify blockers, note overdue items
4. **Generate report**: Create a formatted status update with metrics and highlights
5. **Post update**: Use mcp__plugin_asana_asana__asana_create_comment to post the
   report as a comment on the project
```

### Agent vs Command Tool Access

| Aspect | Commands | Agents |
|---|---|---|
| Tool declaration | Must use `allowed-tools` in frontmatter | No `allowed-tools` needed |
| Permission prompts | Suppressed for declared tools | May prompt user for sensitive tools |
| Tool scope | Limited to declared tools | Can use any available tool |
| Security | Explicit allowlist | Broader access |
| Best for | Focused operations | Autonomous workflows |

### When to Use Agents vs Commands

**Use commands when:**
- The operation is well-defined with specific tool calls
- You want to restrict tool access for security
- The user initiates the action with a slash command

**Use agents when:**
- The workflow requires flexibility in tool selection
- The agent needs to adapt its approach based on results
- Multiple tools may be needed depending on the situation

## Tool Call Patterns

### Pattern 1: Simple Validation + Call

Single tool call with input validation. The simplest pattern -- validate inputs, call one tool, handle the result.

```markdown
Steps:
1. Validate user provided required fields:
   - Title is not empty
   - Workspace ID is provided
   - Date format is valid (YYYY-MM-DD) if provided
2. If validation fails, tell user which fields are missing and ask for them
3. Call mcp__plugin_api_server__create_item with validated data
4. Check response for errors (auth failure, validation error, server error)
5. On success: display confirmation with item ID and link
6. On failure: display specific error message and suggest remediation
```

### Pattern 2: Sequential Tool Calls

Chain multiple MCP operations where each step depends on the previous result:

```markdown
Steps:
1. Search for existing item: mcp__plugin_api_server__search
   - If found, ask user if they want to update or create new
2. If creating new: mcp__plugin_api_server__create_item
   - Use the item ID from the response in subsequent steps
3. Add metadata to the new item: mcp__plugin_api_server__update_metadata
   - Pass the item ID from step 2
4. Link to parent resource: mcp__plugin_api_server__create_link
   - Pass both the new item ID and parent ID
5. Return final item ID and link to user
```

### Pattern 3: Batch Operations

Multiple calls with the same tool, processing a list of items:

```markdown
Steps:
1. Get list of items to process (from user input or previous search)
2. For each item in the list:
   a. Call mcp__plugin_api_server__update_item with the item's changes
   b. Record success or failure with the item ID
   c. If rate limited (429), pause briefly before continuing
3. After all items processed, report results:
   - "Successfully updated 8 of 10 items"
   - "Failed items: [item1, item2] -- reason: rate limited"
   - Offer to retry failed items
```

### Pattern 4: Parallel Tool Calls

When tools do not depend on each other, Claude can call them in parallel for better performance:

```markdown
Steps:
1. Make parallel calls (Claude handles parallelism automatically):
   - mcp__plugin_api_server__get_project (fetch project details)
   - mcp__plugin_api_server__get_users (fetch team members)
   - mcp__plugin_api_server__get_tags (fetch available tags)
2. Wait for all three to complete
3. Combine results: show project details with team members and tag options
4. Use combined data for the next step of the workflow
```

### Pattern 5: Error Handling and Retry

Graceful degradation when tools fail:

```markdown
Steps:
1. Attempt to call mcp__plugin_api_server__get_data
2. If error occurs, check error type:
   - **Rate limit (429)**: Inform user, suggest waiting a moment, offer to retry
   - **Authentication (401)**: Tell user to check their API token is set correctly
   - **Forbidden (403)**: Token valid but lacks permissions, suggest checking scopes
   - **Not found (404)**: Resource does not exist, ask user to verify the ID
   - **Server error (500+)**: Server-side issue, suggest trying again later
   - **Network error**: Check connectivity, suggest verifying the server URL
3. On success: process data and present results
4. If fallback is available: use cached data or alternative approach
```

### Pattern 6: Search, Filter, and Transform

Common workflow for data retrieval and presentation:

```markdown
Steps:
1. **Search**: Call mcp__plugin_api_server__search with user-provided filters
   - project_id, status, assignee, date range, keyword
2. **Filter**: Apply additional local filtering if needed
   - Remove items that don't match complex criteria
   - Deduplicate results
3. **Enrich**: For each result, optionally fetch additional details
   - Only fetch details for items the user will see (respect pagination)
4. **Transform**: Process each result into display format
   - Extract relevant fields
   - Calculate derived values (age, days until due, completion percentage)
5. **Present**: Format and display to user
   - Use tables for structured data
   - Highlight important items (overdue, blocked, high priority)
   - Include pagination info if results are truncated
```

### Pattern 7: Multi-Step Workflow with Confirmation

Complex operations that require user confirmation at key points:

```markdown
Steps:
1. **Setup**: Gather all required information from user
2. **Validate**: Check data completeness and correctness
3. **Preview**: Show what will be created/changed and ask for confirmation
4. **Execute**: Chain of MCP tool calls:
   a. Create parent resource
   b. Create child resources (loop)
   c. Link resources together
   d. Add metadata and tags
5. **Verify**: Call read operations to confirm all steps succeeded
6. **Report**: Provide summary to user with links to created resources
```

## Tool Parameters

### Understanding Tool Schemas

Each MCP tool has a JSON schema defining its parameters. View schemas with `/mcp`. Understanding the schema is essential for writing correct tool calls.

**Example schema:**
```json
{
  "name": "asana_create_task",
  "description": "Create a new Asana task",
  "inputSchema": {
    "type": "object",
    "properties": {
      "name": { "type": "string", "description": "Task title" },
      "notes": { "type": "string", "description": "Task description in markdown" },
      "workspace": { "type": "string", "description": "Workspace GID" },
      "assignee": { "type": "string", "description": "Assignee user GID" },
      "due_on": { "type": "string", "description": "Due date (YYYY-MM-DD)" },
      "projects": { "type": "array", "items": { "type": "string" }, "description": "Project GIDs" }
    },
    "required": ["name", "workspace"]
  }
}
```

Key schema elements to understand:
- **required**: Fields that must be provided (call will fail without them)
- **type**: Expected data type (string, number, boolean, array, object)
- **description**: Explains what the field is for and expected format
- **enum**: Restricted set of allowed values
- **items**: Schema for array elements

### Parameter Validation in Commands

Validate inputs before calling MCP tools to avoid unhelpful error messages from the server:

```markdown
Steps:
1. Check required parameters:
   - Title is not empty (required by schema)
   - Workspace ID is provided (required by schema)
   - Due date, if provided, is valid YYYY-MM-DD format
   - Assignee, if provided, is a valid user GID (numeric string)
2. If validation fails:
   - Tell user specifically which fields are missing or invalid
   - Provide the expected format for each invalid field
   - Ask user to provide the corrected data
3. If validation passes, call the MCP tool
4. Handle tool errors gracefully (see Error Handling pattern)
```

### Handling Complex Parameters

Some MCP tools accept nested objects or arrays:

```markdown
Steps:
1. Gather all configuration options from user
2. Structure the parameters correctly:
   - Simple fields: pass as strings or numbers
   - Lists: collect items and pass as arrays
   - Nested config: build the object structure before calling
3. Call the tool with the structured parameters
4. Parse the structured response
```

## Response Handling

### Success Responses

```markdown
Steps:
1. Call MCP tool
2. On success:
   - Extract relevant data from the response (ID, name, URL, status)
   - Format for user display (tables, bullet lists, links)
   - Provide a clear confirmation message ("Task created successfully")
   - Include actionable links or IDs for follow-up
   - Store IDs if needed for subsequent tool calls
```

### Error Responses

```markdown
Steps:
1. Call MCP tool
2. On error:
   - Parse the error type from the response
   - Provide a user-friendly error message (not raw error details)
   - Suggest specific remediation steps based on error type
   - Offer alternatives when available
   - Do not expose internal error details, stack traces, or sensitive information
```

### Partial Success (Batch Operations)

```markdown
Steps:
1. Batch operation with multiple MCP calls
2. Track successes and failures separately with item IDs
3. Report summary:
   - "Successfully processed 8 of 10 items"
   - "Failed items: [item-123, item-456]"
   - "Failure reason: rate limited after 8 requests"
   - "Would you like to retry the failed items?"
4. Offer retry for failed items
5. Provide links to successfully processed items
```

## Performance Optimization

### Batching Requests

Prefer single queries with filters over many individual calls. This reduces network round-trips and avoids rate limits.

```markdown
# Good: Single query with filters
Use mcp__plugin_api_server__search with parameters:
  project_id: "123"
  status: "active"
  limit: 100
  fields: "id,name,status,assignee"

# Avoid: Many individual queries that could be one search
For each of the 50 item IDs:
  Call mcp__plugin_api_server__get_item
```

### Caching Results Within a Session

```markdown
Steps:
1. Call expensive MCP operation: mcp__plugin_api_server__get_all_projects
2. Store results for reuse in subsequent steps of this command
3. When another step needs project data, use the cached results
4. Only re-fetch if the user explicitly requests fresh data
5. Note: cache is only valid within the current command execution
```

### Parallel Tool Calls

When tools do not depend on each other, describe them as parallel in your command instructions. Claude will automatically execute independent tool calls concurrently.

```markdown
Steps:
1. Fetch data from three independent sources (parallel):
   - mcp__plugin_api_server__get_project (project metadata)
   - mcp__plugin_api_server__list_members (team members)
   - mcp__plugin_api_server__get_milestones (timeline data)
2. Combine all three results into the report
```

### Minimize Tool Calls

Request only the fields you need using the tool's field selection parameters (often `fields` or `opt_fields`):

```markdown
# Good: Request only needed fields
Call mcp__plugin_asana_asana__asana_search_tasks with:
  opt_fields: "name,completed,due_on,assignee.name"

# Avoid: Requesting all fields when you only need a few
Call mcp__plugin_asana_asana__asana_search_tasks (returns all fields by default)
```

## CRUD Pattern

Common pattern for full resource management in a single command:

```markdown
---
description: Manage project items (create, read, update, delete)
allowed-tools: [
  "mcp__plugin_api_server__create_item",
  "mcp__plugin_api_server__read_item",
  "mcp__plugin_api_server__update_item",
  "mcp__plugin_api_server__delete_item",
  "mcp__plugin_api_server__list_items"
]
---

# Item Management

Determine what the user wants to do and execute the appropriate operation.

## List Items
1. Call mcp__plugin_api_server__list_items with optional filters
2. Display results in a formatted table with ID, name, status

## Create Item
1. Gather required fields from user (name, type, description)
2. Call mcp__plugin_api_server__create_item
3. Show the created item with its new ID

## Read Item
1. Get item ID from user
2. Call mcp__plugin_api_server__read_item with the ID
3. Display all item details

## Update Item
1. Get item ID and desired changes from user
2. Call mcp__plugin_api_server__read_item first to show current state
3. Confirm changes with user
4. Call mcp__plugin_api_server__update_item with changes
5. Show updated item

## Delete Item
1. Get item ID from user
2. Call mcp__plugin_api_server__read_item to show what will be deleted
3. **Ask for explicit confirmation before deleting**
4. Call mcp__plugin_api_server__delete_item
5. Confirm deletion
```

## Testing MCP Tool Usage

### Local Testing Workflow

1. **Configure MCP server** in `.mcp.json` at the plugin root
2. **Install plugin locally** (ensure `.claude-plugin/plugin.json` exists)
3. **Start Claude Code** and run `/mcp` to verify tools appear
4. **Test each tool** by running the command that uses it
5. **Check debug output**: `claude --debug` for detailed logs
6. **Test error cases**: invalid parameters, missing auth, non-existent resources

### Test Scenarios

**Success cases:**
- Create test data in the external service
- Run the command that queries or modifies the data
- Verify the correct results are returned and displayed

**Error cases:**
- Unset the authentication environment variable and test graceful failure
- Provide invalid parameters (wrong types, missing required fields)
- Reference non-existent resources (invalid IDs)
- Verify the error messages are helpful and suggest remediation

**Edge cases:**
- Test with empty results (search with no matches)
- Test with maximum results (large result sets, pagination)
- Test with special characters in input (unicode, quotes, newlines)
- Test rate limiting behavior (if the API enforces limits)

### Debugging Tool Calls

When a tool call fails unexpectedly:

1. **Check tool name**: Run `/mcp` and verify the exact tool name matches
2. **Check parameters**: Compare your parameters against the tool schema from `/mcp`
3. **Check authentication**: Verify environment variables are set (`echo $API_TOKEN`)
4. **Enable debug mode**: Run `claude --debug` to see the full request/response
5. **Test directly**: Use `curl` to test the MCP endpoint outside of Claude Code

## Troubleshooting

**Tools not available (not shown in /mcp):**
- Verify the MCP server is configured in `.mcp.json`
- Check that the server process started successfully (for stdio servers)
- Restart Claude Code after configuration changes
- Check `claude --debug` for server connection errors

**Tool calls failing with errors:**
- Authentication issue: verify tokens are set and valid
- Parameter mismatch: check parameters against the tool schema in `/mcp`
- Required parameters missing: ensure all required fields are provided
- Review `claude --debug` logs for detailed error information

**Tool calls returning unexpected results:**
- Check parameter values (correct IDs, valid date formats, proper field names)
- Verify the external service has the expected data
- Check for API version mismatches (wrong `X-API-Version` header)
- Test the same operation in the service's own UI to compare

**Performance issues:**
- Batch queries instead of individual calls
- Use field selection to reduce response size
- Cache results when the same data is needed multiple times
- Use parallel calls when tools are independent of each other
- Check if the MCP server or external service is experiencing slowness
