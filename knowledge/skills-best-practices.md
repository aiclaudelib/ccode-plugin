# Skill Authoring Best Practices

## Core Principles

### Conciseness

The context window is shared across system prompt, conversation history, other Skills' metadata, and the user request. Only SKILL.md is loaded when triggered; additional files load on demand.

**Default assumption**: Claude is already very smart. Only add context Claude doesn't already have. Challenge each piece: "Does this justify its token cost?"

````markdown
## Extract PDF text

Use pdfplumber for text extraction:

```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

### Degrees of Freedom

Match specificity to the task's fragility:

| Level | When to use | Example |
|-------|------------|---------|
| **High** (text instructions) | Multiple valid approaches, context-dependent | Code review guidelines |
| **Medium** (pseudocode/parameterized) | Preferred pattern exists, some variation OK | Report generation template |
| **Low** (exact scripts) | Fragile operations, consistency critical | `python scripts/migrate.py --verify --backup` |

### Testing

Test with all models you plan to use. What works for Opus may need more detail for Haiku.

---

## Skill Structure

### YAML Frontmatter

| Field | Constraints |
|-------|------------|
| `name` | Max 64 chars, lowercase letters/numbers/hyphens only, no XML tags, no reserved words ("anthropic", "claude") |
| `description` | Recommended. Max 1024 chars, no XML tags. If omitted, uses the first paragraph of markdown content. |

### Naming Conventions

Use **gerund form** (verb + -ing): `processing-pdfs`, `analyzing-spreadsheets`, `testing-code`

Acceptable alternatives: noun phrases (`pdf-processing`), action-oriented (`process-pdfs`)

Avoid: vague (`helper`, `utils`), overly generic (`documents`, `data`), reserved words

### Writing Effective Descriptions

- **Always third person.** The description is injected into the system prompt. First/second person causes discovery problems.
- **Be specific and include key terms.** Claude uses descriptions to select from potentially 100+ Skills.
- Include both **what** the Skill does and **when** to use it.

```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

```yaml
description: Generate descriptive commit messages by analyzing git diffs. Use when the user asks for help writing commit messages or reviewing staged changes.
```

---

## Progressive Disclosure

SKILL.md is a table of contents that points Claude to detailed materials as needed. Keep SKILL.md body under 500 lines; split content into separate files beyond that.

### Pattern 1: High-level guide with references

````markdown
---
name: pdf-processing
description: Extracts text and tables from PDF files, fills forms, and merges documents. Use when working with PDF files.
---

# PDF Processing

## Quick start

```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

## Advanced features

**Form filling**: See [FORMS.md](FORMS.md)
**API reference**: See [REFERENCE.md](REFERENCE.md)
**Examples**: See [EXAMPLES.md](EXAMPLES.md)
````

### Pattern 2: Domain-specific organization

Split by domain so Claude loads only relevant context:

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md
    ├── sales.md
    └── product.md
```

### Pattern 3: Conditional details

```markdown
## Creating documents
Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents
For simple edits, modify the XML directly.
**For tracked changes**: See [REDLINING.md](REDLINING.md)
```

### Key rules

- **Keep references one level deep** from SKILL.md. Deeply nested references cause partial reads.
- **Add a table of contents** to reference files longer than 100 lines so Claude can see scope even on partial reads.
- **Name files descriptively**: `form_validation_rules.md`, not `doc2.md`.

---

## Workflows and Feedback Loops

### Workflow pattern

Break complex operations into sequential steps with a checklist:

````markdown
## PDF form filling workflow

```
Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)
```

**Step 1**: Run `python scripts/analyze_form.py input.pdf`
**Step 2**: Edit `fields.json` to add values for each field.
**Step 3**: Run `python scripts/validate_fields.py fields.json` -- fix errors before continuing.
**Step 4**: Run `python scripts/fill_form.py input.pdf fields.json output.pdf`
**Step 5**: Run `python scripts/verify_output.py output.pdf` -- if fails, return to Step 2.
````

### Conditional workflow pattern

```markdown
1. Determine the modification type:
   **Creating new content?** -> Follow "Creation workflow"
   **Editing existing content?** -> Follow "Editing workflow"
```

If workflows become large, push them into separate files.

### Feedback loops

**Core pattern**: Run validator -> fix errors -> repeat

```markdown
## Document editing process

1. Make edits to `word/document.xml`
2. **Validate**: `python ooxml/scripts/validate.py unpacked_dir/`
3. If validation fails: fix issues, run validation again
4. **Only proceed when validation passes**
5. Rebuild: `python ooxml/scripts/pack.py unpacked_dir/ output.docx`
```

---

## Content Guidelines

- **Avoid time-sensitive info.** Use a "Current method" / "Old patterns" structure instead of date-based conditionals.
- **Use consistent terminology.** Pick one term per concept and use it throughout. Don't mix "API endpoint" / "URL" / "API route" / "path".

---

## Common Patterns

### Template pattern

Provide output templates. Use "ALWAYS use this exact template" for strict requirements, or "sensible default, use your judgment" for flexible guidance.

````markdown
## Report structure

ALWAYS use this exact template structure:

```markdown
# [Analysis Title]

## Executive summary
[One-paragraph overview of key findings]

## Key findings
- Finding 1 with supporting data
- Finding 2 with supporting data

## Recommendations
1. Specific actionable recommendation
2. Specific actionable recommendation
```
````

### Examples pattern

Provide input/output pairs for output quality:

````markdown
## Commit message format

**Example:**
Input: Added user authentication with JWT tokens
Output:
```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

Follow this style: type(scope): brief description, then detailed explanation.
````

---

## Skills with Executable Code

### Solve, don't punt

Scripts should handle errors explicitly rather than failing and letting Claude figure it out. Document configuration constants with rationale (avoid magic numbers).

### Utility scripts

Pre-made scripts are more reliable, save tokens, save time, and ensure consistency. Make execution intent clear:

- "Run `analyze_form.py` to extract fields" (execute)
- "See `analyze_form.py` for the extraction algorithm" (read as reference)

### Visual analysis

When inputs can be rendered as images, convert and have Claude analyze them visually.

### Verifiable intermediate outputs

For complex batch operations, use "plan-validate-execute": create a structured plan file (e.g., `changes.json`), validate it with a script, then execute. Catches errors before destructive changes.

### Package dependencies

- **claude.ai**: Can install packages from npm/PyPI and pull from GitHub
- **Anthropic API**: No network access, no runtime package installation

List required packages in SKILL.md and verify availability.
