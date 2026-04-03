---
name: notion
description: "Notion workspace operations via MCP across personal and work accounts. Reading pages, searching, creating/updating content. Use when working with Notion pages, databases, comments, or workspace content."
allowed-tools: mcp__claude_ai_Notion__notion-search, mcp__claude_ai_Notion__notion-fetch, mcp__claude_ai_Notion__notion-get-comments, mcp__claude_ai_Notion__notion-get-teams, mcp__claude_ai_Notion__notion-get-users
---

# Notion — Workspace Operations via MCP

## When to Use This Skill

Activate when:
- User mentions Notion, workspace, Notion page, or Notion database
- User asks to read, search, create, or update content in Notion
- User references content that lives in a Notion workspace

## Account Architecture

Two Notion accounts are connected:

| Account | Namespace | Purpose |
|---------|-----------|---------|
| Personal | `mcp__notion-personal__*` | Cooking, hobbies, notes, personal projects |
| Work | `mcp__notion-work__*` | Job tasks, work documentation, team content |

The Claude AI built-in integration uses `mcp__claude_ai_Notion__*`. If local MCP servers are available, prefer them for account-specific operations.

## Account Selection Rule

**Read operations** — proceed without confirmation. If a specific account is needed, use topic heuristics:
- Personal topics (cooking, hobbies, notes, personal life, recipes, journals) → `notion-personal`
- Professional topics (work, job, team, projects, documentation) → `notion-work`

**Write operations** — ALWAYS confirm the target account with the user before proceeding:
1. If the target account has been explicitly established in the conversation → proceed
2. If ambiguous or not yet established → ask the user which account to use
3. Suggest the likely account based on topic but never write without explicit approval

## Read Operations

### Search
`mcp__claude_ai_Notion__notion-search`

Search across workspace for pages and databases. Accepts a query string and optional filter by object type (page or database).

### Fetch Content
`mcp__claude_ai_Notion__notion-fetch`

Retrieve full page content, block children, or database entries. Can fetch by page ID or URL.

### Comments
`mcp__claude_ai_Notion__notion-get-comments`

Get discussion comments on a page or block.

### Teams
`mcp__claude_ai_Notion__notion-get-teams`

List workspace teams.

### Users
`mcp__claude_ai_Notion__notion-get-users`

List workspace members.

## Write Operations

**All write operations require user approval AND account confirmation before execution.**

### Create Pages
`mcp__claude_ai_Notion__notion-create-pages`

Create a new page in a parent page or database. Provide title and content blocks.

### Update Page
`mcp__claude_ai_Notion__notion-update-page`

Modify page properties (title, status, tags, dates, etc.).

### Create Database
`mcp__claude_ai_Notion__notion-create-database`

Create a new database with schema definition (properties, types, etc.).

### Create Comment
`mcp__claude_ai_Notion__notion-create-comment`

Add a discussion comment to a page.

### Create View
`mcp__claude_ai_Notion__notion-create-view`

Add a view (table, board, calendar, etc.) to a database.

### Update View
`mcp__claude_ai_Notion__notion-update-view`

Modify database view configuration (filters, sorts, visible properties).

### Update Data Source
`mcp__claude_ai_Notion__notion-update-data-source`

Update a connected data source.

### Move Pages
`mcp__claude_ai_Notion__notion-move-pages`

Move pages to a different parent page or workspace section.

### Duplicate Page
`mcp__claude_ai_Notion__notion-duplicate-page`

Create a copy of an existing page.

## Content Block Types

When creating or updating page content, use these block types:

| Block Type | Description |
|-----------|-------------|
| `paragraph` | Body text |
| `heading_1` | Large heading |
| `heading_2` | Medium heading |
| `heading_3` | Small heading |
| `bulleted_list_item` | Bullet point |
| `numbered_list_item` | Numbered item |
| `to_do` | Checkbox item |
| `toggle` | Collapsible section |
| `code` | Code block (with language) |
| `quote` | Block quote |
| `callout` | Highlighted callout box |
| `divider` | Horizontal rule |
| `table` | Table |
| `table_row` | Table row |
| `bookmark` | URL bookmark |
| `embed` | Embedded content |
| `image` | Image block |

## Common Workflows

### Search for a page
1. Search: `notion-search(query: "project roadmap")`
2. Review results and pick the relevant page

### Read page content
1. Fetch: `notion-fetch(url: "<page-url>")` or `notion-fetch(pageId: "<id>")`
2. Review content blocks

### Create a new page
1. Identify parent page or database
2. Draft title and content blocks
3. Confirm target account with user
4. Create: `notion-create-pages(...)`

### Update database entry
1. Fetch current properties: `notion-fetch(pageId: "<id>")`
2. Draft property changes
3. Confirm target account with user
4. Update: `notion-update-page(pageId: "<id>", properties: {...})`

### Move pages
1. Identify source pages and target parent
2. Confirm target account with user
3. Move: `notion-move-pages(pageIds: [...], parentId: "<id>")`

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Page not found | Wrong ID/URL or no access | Verify page ID and workspace permissions |
| Permission denied | Insufficient access to workspace or page | Check account permissions; may need different account |
| Rate limited | Too many requests | Wait and retry; batch operations where possible |
| Invalid block format | Malformed content blocks | Verify block type and required fields |
| Authentication required | MCP not connected | Check MCP server status |
