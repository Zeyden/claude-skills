---
name: lokalise
description: "Lokalise localisation management via MCP (PM toolkit). Managing translation keys, projects, languages, tasks, contributors, and workflows. Use when working with Lokalise projects, translation keys, localisation tasks, or i18n workflows."
allowed-tools: mcp__lokalise_pm__*, AskUserQuestion
---

# Lokalise — Localisation Management via MCP

## When to Use This Skill

Activate when:
- User mentions Lokalise, translation keys, or localisation management
- User asks to create, search, update, or delete translation keys
- User asks about translation progress or project status
- User wants to manage languages, tasks, or contributors in Lokalise
- User references `lokalise.com` links or Lokalise project IDs

## MCP Tool Namespace

All Lokalise PM tools use the `mcp__lokalise_pm__*` namespace. The MCP server is an HTTP endpoint at `https://mcp.lokalise.com/mcp/project-management`.

The PM toolkit covers: projects, keys, translations, languages, tasks, contributors, comments, branches, files, translation memory, QA rules, and bulk operations.

**Note:** Exact tool names are discovered at runtime. If a tool is not available, check what tools are discoverable under the `mcp__lokalise_pm__` prefix.

## Key Naming Conventions (CRITICAL)

When creating or suggesting translation keys, **always** follow structured semantic naming:

### Pattern: `section.component.element`

| Pattern | Example | Use Case |
|---------|---------|----------|
| `section.element.type` | `homepage.welcome_message.title` | Page-specific content |
| `component.element` | `login.label_username` | Component-scoped labels |
| `global.action` | `global.cancel`, `global.save` | Shared reusable UI actions |
| `feature.action` | `checkout.buttons.confirm_order` | Feature-specific actions |

### Rules

1. **Descriptive, purpose-driven names** — `welcoming_message` not `label2`. Key names stay stable even if translation text changes.
2. **One casing convention** — use `snake_case` consistently across the entire project.
3. **Organise hierarchically** — reflect the app structure. Include page/component name before the element.
4. **Keep keys concise** — `welcome.search.label` not `welcome.search.enter-your-name-or-booking-id-here`.
5. **Use `global.*` namespace** for truly shared strings like `global.cancel`, `global.save`, `global.error`.
6. **Separate keys for different contexts** — even if the English text is identical, "Continue" on a form step vs. "Continue" on a media player may need different translations. Create separate keys when contexts differ.
7. **Never split sentences into fragments** — `"There are {count} errors in the form"` must be a single key, not split parts. Translators need full sentence context for grammar.
8. **Add context** — always include descriptions, comments, or screenshots when creating keys to help translators understand usage.

## Confirmed MCP Read Tools

These tools have been verified to work. Use `ToolSearch` to load them before calling.

### `mcp__lokalise_pm__list_lokalise_projects`

List/search projects. Params: `filter_names` (string), `limit` (number), `page` (number). All optional.

### `mcp__lokalise_pm__list_lokalise_keys`

List keys with filters. Params:
- `project_id` (string, **required**)
- `filter_keys` — **exact match** on key names (comma-separated). Does NOT do prefix search.
- `filter_tags` — filter by tags (comma-separated). Use this for prefix-style searches if keys share a tag.
- `include_translations` — `0` or `1`
- `include_comments` — `0` or `1`
- `filter_platforms` — comma-separated
- `limit`, `page`, `cursor` — pagination

**Known project IDs:**
- Tabby app: `362651255f2a692e59d3d4.62804533`

## Read Operations

### Projects
- List all projects in the workspace
- Get project details (languages, progress, settings)
- Project health and statistics

### Keys
- List keys with filtering (by platform, tag, filename)
- Get key details (translations, platforms, tags, comments)
- Search keys by name or value

### Translations
- List translations for a key or language
- Check translation completion status
- Translation progress per language

### Languages
- List project languages with completion stats
- Get language details

### Tasks
- List tasks (translation, review tasks)
- Get task details and assignees
- Check task completion status

### Contributors
- List project contributors and their roles
- Get contributor permissions

### Files
- List uploaded files
- Get file details

### Branches
- List project branches
- Get branch details

## Write Operations

**All write operations require user approval before execution.**

### Keys
- **Create keys** — with name, description, platforms, tags, and base translation
- **Update keys** — modify name, description, platforms, tags
- **Delete keys** — remove keys (destructive, always confirm)
- **Bulk update keys** — batch operations on multiple keys

### Translations
- **Create/update translations** — set translation values per language
- **Bulk translation updates** — batch translation changes

### Languages
- **Add language** to a project
- **Remove language** from a project (destructive, always confirm)

### Tasks
- **Create task** — assign translation/review work to contributors
- **Update task** — modify task details, reassign
- **Close task** — mark task as complete

### Projects
- **Create project** — new localisation project
- **Update project** — modify project settings
- **Delete project** — remove entire project (destructive, always confirm)

### Contributors
- **Add contributor** — invite to project with role
- **Remove contributor** — revoke access (always confirm)

### Files
- **Upload file** — import translation files (JSON, XLIFF, PO, etc.)
- **Download file** — export translations in specified format

## Common Workflows

### Look up translation keys
1. List or search keys in the target project
2. Review key names, translations, and completion status
3. Report findings to user

### Create new translation keys
1. Discuss key naming with user (follow naming conventions above)
2. Confirm key name, description, platforms, and tags
3. Create key with base language translation
4. Optionally create a translation task for other languages

### Check translation progress
1. List project languages
2. Get completion statistics per language
3. Identify languages with missing or incomplete translations
4. Suggest creating tasks for gaps

### Bulk key creation (e.g., new feature)
1. Discuss the feature scope and required keys with user
2. Draft key names following `section.component.element` convention
3. Present the full list for user approval
4. Create keys in batch with descriptions and base translations
5. Create translation tasks for target languages

### Release readiness audit
1. List all keys tagged for the release (e.g., `release-2.0`)
2. Check translation completion across all target languages
3. Identify missing or recently modified translations needing review
4. Report blockers and suggest remediation (tasks, assignments)

### Add a new language to a project
1. Confirm the language code and project with the user
2. Add the language to the project
3. Report the number of keys needing translation
4. Optionally create a translation task

### Translation task management
1. List open tasks and their status
2. Check assignees and deadlines
3. Create new tasks for untranslated content
4. Close completed tasks

## Best Practices

### Workflow Automation
- **Chain tasks** for multi-stage review: AI/machine translation first, then human review
- **Use tags** to group keys by feature, release, or platform for targeted workflows
- **Create tasks proactively** — don't let untranslated keys accumulate
- **Schedule regular progress audits** to catch gaps early

### Branching Strategy
- Lokalise branches are separate versions of the translation project
- **Branch merges cannot be reverted** — use with caution
- For hotfix/feature branches with minor changes, prefer **tags** over branches
- When using with Git integration, rely on Git for conflict resolution

### Quality Assurance
- Enable QA checks for placeholder mismatches, HTML issues, and spelling
- Review AI/machine translations before publishing — ~80% baseline accuracy
- Use translation memory to maintain consistency across projects

### Platform Tags
- Tag keys with their target platforms (iOS, Android, Web)
- Use per-platform key names when conventions differ (`LoginButton` vs `login_button`)
- Filter by platform when exporting to avoid shipping unused strings

### Dynamic Content
- Store dynamic (database-driven) content translations in a **separate project** from static UI translations
- Use unique database identifiers in key names (e.g., `form.{id}.title`)
- Establish routine sync processes

## Rate Limits

Lokalise API allows **6 requests per second** per token per IP, with max **10 concurrent requests** per project. Exceeding this returns HTTP 429.

When performing bulk operations:
- Break large batches into chunks
- Allow time between batch requests
- If rate limited, wait and retry

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| 401 Unauthorized | Invalid or expired API token | Regenerate token at Profile settings > API tokens |
| 403 Forbidden | Token lacks permissions for this action | Check token permissions (read/write) and project access |
| 404 Not found | Wrong project ID or key ID | Verify the identifier |
| 429 Too many requests | Rate limit exceeded | Wait 1-2 seconds and retry |
| Key name conflict | Key with same name already exists | Use a different name or update existing key |
| Branch merge failed | Conflict between branches | Resolve conflicts manually or use tags instead |

## Integration with Other Skills

| Scenario | Delegate To |
|----------|-------------|
| Committing downloaded translation files | `git-commit` |
| Tracking localisation tasks in Jira | `jira` |
| Tracking localisation tasks in Linear | `linear` |
| Documenting localisation conventions in Notion | `notion` |
| Noting localisation decisions in Obsidian | `obsidian` |
