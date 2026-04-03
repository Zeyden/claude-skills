---
name: jira
description: "Jira issue tracking via Atlassian MCP. Reading issues, JQL search, browsing projects, creating/editing issues, transitions, comments, worklogs. Use when working with Jira tickets, sprints, backlogs, issue tracking, or project management via Jira."
allowed-tools: mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getVisibleJiraProjects, mcp__claude_ai_Atlassian__getJiraProjectIssueTypesMetadata, mcp__claude_ai_Atlassian__getTransitionsForJiraIssue, mcp__claude_ai_Atlassian__getIssueLinkTypes, mcp__claude_ai_Atlassian__getJiraIssueRemoteIssueLinks, mcp__claude_ai_Atlassian__atlassianUserInfo, mcp__claude_ai_Atlassian__lookupJiraAccountId, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__searchAtlassian, mcp__claude_ai_Atlassian__fetchAtlassian, mcp__claude_ai_Atlassian__getJiraIssueTypeMetaWithFields, mcp__atlassian__get_issue, mcp__atlassian__search_issues
---

# Jira — Issue Tracking via Atlassian MCP

## When to Use This Skill

Activate when:
- User mentions Jira, Jira ticket, or Jira issue
- User provides a URL containing `atlassian.net` or `.jira.com`
- User asks to search with JQL, browse sprints/backlogs, or manage Jira issues
- Ticket ID matches a known Jira project key (see `references/projects.md`)

## Jira vs Linear

If a ticket ID is given without context:
1. Check if it matches known Jira project keys in `references/projects.md`
2. Check if it matches known Linear project prefixes in the `linear` skill references
3. If the URL contains `atlassian.net` or `.jira.com` → Jira
4. If the URL contains `linear.app` → Linear (delegate to `linear` skill)
5. If ambiguous → ask the user

## Defaults

- **Cloud ID:** `tabby.atlassian.net` — use for all `cloudId` parameters
- **Default project:** CLC (unless user specifies otherwise)
- **No subtasks** in CLC — never create them

## References — Read Before Acting

Before creating/editing issues or looking up users:

1. **`references/team.md`** — resolve user nicknames (e.g. "Sasha" → account ID) directly. No `lookupJiraAccountId` calls needed.
2. **`references/fields.md`** — all field IDs, priority IDs, issue type IDs. No `getJiraIssueTypeMetaWithFields` or `getJiraProjectIssueTypesMetadata` calls needed.
3. **`references/projects.md`** — project keys and boards.
4. **`references/workflows.md`** — statuses, transitions, issue types.
5. **`references/jql-templates.md`** — common JQL queries.

## MCP Tool Availability

Two tool namespaces may be available:
- **`mcp__claude_ai_Atlassian__*`** — Claude AI built-in Atlassian integration
- **`mcp__atlassian__*`** — locally configured MCP server

Try whichever is available. The built-in integration has more tools; the local MCP has `get_issue` and `search_issues`.

## Read Operations

### Get Issue Details
Fetch full issue details including summary, description, status, assignee, priority, labels, and comments.

**Built-in:** `mcp__claude_ai_Atlassian__getJiraIssue` — requires `cloudId` and `issueIdOrKey`
**Local:** `mcp__atlassian__get_issue` — requires `issueIdOrKey`

### Search Issues (JQL)
Query issues using Jira Query Language.

**Built-in:** `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql` — requires `cloudId` and `jql`
**Local:** `mcp__atlassian__search_issues` — requires `jql`

### Browse Projects
- `getVisibleJiraProjects` — list all accessible projects
- `getJiraProjectIssueTypesMetadata` — issue types for a project

### Issue Metadata
- `getTransitionsForJiraIssue` — available status transitions for an issue
- `getIssueLinkTypes` — available link types (blocks, is blocked by, relates to, etc.)
- `getJiraIssueRemoteIssueLinks` — external links on an issue
- `getJiraIssueTypeMetaWithFields` — field metadata for creating issues

### User & Resource Info
- `atlassianUserInfo` — current authenticated user
- `lookupJiraAccountId` — find user by name or email
- `getAccessibleAtlassianResources` — list connected Jira sites (use to find `cloudId`)

### General
- `searchAtlassian` — cross-product search (Jira, Confluence, etc.)
- `fetchAtlassian` — raw API access to any Atlassian endpoint

## Write Operations

**All write operations require user approval before execution.**

### Create Issue
`mcp__claude_ai_Atlassian__createJiraIssue`

Required fields: `project`, `issueType`, `summary`
Optional: `description`, `assignee`, `priority`, `labels`, `components`, `fixVersions`, custom fields

### Edit Issue
`mcp__claude_ai_Atlassian__editJiraIssue`

Update any field on an existing issue (summary, description, assignee, priority, labels, etc.)

### Transition Issue
`mcp__claude_ai_Atlassian__transitionJiraIssue`

Change issue status. Always fetch available transitions first with `getTransitionsForJiraIssue`.

### Add Comment
`mcp__claude_ai_Atlassian__addCommentToJiraIssue`

Add a comment to an issue. Supports Atlassian Document Format (ADF) for rich text.

### Log Work
`mcp__claude_ai_Atlassian__addWorklogToJiraIssue`

Log time spent on an issue. Requires `timeSpent` (e.g., "2h", "30m").

### Link Issues
`mcp__claude_ai_Atlassian__createIssueLink`

Create a link between two issues. Fetch available link types first with `getIssueLinkTypes`.

## JQL Quick Reference

```
# By project
project = PROJ

# By assignee
assignee = currentUser()
assignee = "user@example.com"

# By status
status = "In Progress"
status in ("To Do", "In Progress")
status != Done

# By sprint
sprint in openSprints()
sprint = "Sprint 42"

# By date
created >= -7d
updated >= "2026-03-01"
due <= endOfWeek()

# Text search
text ~ "authentication"
summary ~ "login bug"

# Labels and priority
labels in ("frontend", "urgent")
priority in (Highest, High)

# Combined
project = PROJ AND status = "In Progress" AND assignee = currentUser()
project = PROJ AND created >= -7d ORDER BY priority DESC

# Unresolved
resolution = Unresolved AND project = PROJ
```

See `references/jql-templates.md` for team-specific saved queries.

## Common Workflows

### Look up a ticket
1. Fetch issue: `getJiraIssue(issueIdOrKey: "PROJ-123")`
2. Review summary, description, status, and comments

### Search related issues
1. Query: `searchJiraIssuesUsingJql(jql: "project = PROJ AND text ~ 'search term'")`
2. Review results

### Create a new issue
1. Resolve field IDs, issue type IDs, and user account IDs from `references/fields.md` and `references/team.md` — no API calls needed
2. Draft issue fields (project, type, summary, description, assignee, developer, QA, priority, story points)
3. Present to user for approval
4. Create: `createJiraIssue(...)`

### Transition an issue
1. Get available transitions: `getTransitionsForJiraIssue(issueIdOrKey: "PROJ-123")`
2. Present options to user
3. Transition: `transitionJiraIssue(issueIdOrKey: "PROJ-123", transitionId: "...")`

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| cloudId not found | Haven't identified the Jira site | Use `getAccessibleAtlassianResources` to list sites |
| 404 / Issue not found | Wrong issue key or no access | Verify the issue key and project permissions |
| 400 / Invalid JQL | Syntax error in query | Check JQL syntax — common issues: unquoted strings, wrong field names |
| 403 / Permission denied | No access to project or operation | Inform user about permission requirements |
| Authentication required | MCP not authenticated | Use `mcp__atlassian__authenticate` if available |
