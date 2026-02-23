---
description: "Create plugin settings file with user preferences"
allowed-tools: ["Write", "Read"]
---

# Create Plugin Settings

This command helps users create a `.claude/my-plugin.local.md` settings file.

## Steps

### Step 1: Ask User for Preferences

Ask the user the following questions:

1. **Enable plugin?** (Yes / No)
2. **Validation mode?** (Strict / Standard / Lenient)
3. **Max file size?** (default: 1000000 bytes)

### Step 2: Create Settings File

Use Write tool to create `.claude/my-plugin.local.md`:

```markdown
---
enabled: <true if Yes, false if No>
validation_mode: <strict, standard, or lenient>
max_file_size: <user value or default 1000000>
notify_on_errors: true
---

# Plugin Configuration

Your plugin is configured with <mode> validation mode.

To modify settings, edit this file and restart Claude Code.
```

### Step 3: Inform User

Tell the user:
- Settings file created at `.claude/my-plugin.local.md`
- Current configuration summary
- How to edit manually if needed
- Reminder: restart Claude Code (or review via `/hooks` menu) for hook changes to take effect
- Settings file is gitignored (will not be committed)

## Implementation Notes

Always validate user input before writing:
- Check mode is one of: strict, standard, lenient
- Validate numeric fields are positive numbers
- Ensure paths do not have traversal attempts (..)
- Sanitize any free-text fields (escape quotes)
