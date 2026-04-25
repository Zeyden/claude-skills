---
name: jira
description: "Jira issue tracking via Atlassian MCP. Reading issues, JQL search, browsing projects, creating/editing issues, transitions, comments, worklogs. Use when working with Jira tickets, sprints, backlogs, issue tracking, or project management via Jira."
allowed-tools: mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getVisibleJiraProjects, mcp__claude_ai_Atlassian__getJiraProjectIssueTypesMetadata, mcp__claude_ai_Atlassian__getTransitionsForJiraIssue, mcp__claude_ai_Atlassian__getIssueLinkTypes, mcp__claude_ai_Atlassian__getJiraIssueRemoteIssueLinks, mcp__claude_ai_Atlassian__atlassianUserInfo, mcp__claude_ai_Atlassian__lookupJiraAccountId, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__searchAtlassian, mcp__claude_ai_Atlassian__fetchAtlassian, mcp__claude_ai_Atlassian__getJiraIssueTypeMetaWithFields, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Atlassian__editJiraIssue, mcp__claude_ai_Atlassian__transitionJiraIssue, mcp__claude_ai_Atlassian__addCommentToJiraIssue, mcp__claude_ai_Atlassian__addWorklogToJiraIssue, mcp__claude_ai_Atlassian__createIssueLink, mcp__atlassian__get_issue, mcp__atlassian__search_issues, mcp__atlassian__lookupJiraAccountId, mcp__atlassian__searchJiraIssuesUsingJql
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
- **"Assign to someone":** When user says "assign to X", set **both** `assignee` AND `customfield_10035` (Developer) to that person — not just assignee
- **Linked Issues:** When creating an issue from a specific ticket (e.g. action item from QA testing, bug found during another ticket's work), link it to the original ticket using `createIssueLink` after creation. Use appropriate link type (e.g. "is caused by", "relates to")
- **Images:** If struggling to copy, create, or update images in a task description, ask the user explicitly what to do with the images rather than guessing

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

### Create a new issue — Interactive Workflow

Every issue creation MUST go through this interactive flow. **Never silently pick defaults** — always ask via `AskUserQuestion` for each mandatory field. Fields already provided by the user in their request can be skipped.

#### Phase 1: Gather context & fetch data (parallel)

Run these in parallel before asking anything:

1. **Extract** summary and description from the user's request. Note if there's a source ticket (for linking later).
2. **Fetch sprints** via Agile API:
   ```
   fetchAtlassian(url: "/rest/agile/1.0/board/292/sprint?state=active,future")
   ```
   This returns sprint IDs and names for CLC board. Parse the response for the options list.
3. **Fetch active epics** for parent selection:
   ```
   searchJiraIssuesUsingJql(jql: "project = CLC AND issuetype = Epic AND status != Done AND status != Cancelled ORDER BY updated DESC")
   ```

#### Phase 2: Interactive field selection

Ask each field via `AskUserQuestion`. Skip fields the user already specified in their request. Present options as a numbered list.

**Step 1 — Issue Type:**
List CLC platform-specific types first (most common), then general types:
```
1. BE Task
2. BE Bug
3. Android Task
4. Android Bug
5. iOS Task
6. iOS Bug
7. Web Task
8. Web Bug
9. Epic
10. Task (general — spikes, research)
```

**Step 2 — Priority:**
Rank by inferred probability based on the summary/description context:
- Signal words "crash", "blocking", "data loss", "production", "P0" → suggest **Highest/High** first
- Signal words "improvement", "nice to have", "refactor", "cleanup" → suggest **Low/Lowest** first
- Default ranking when no strong signal: **Medium > High > Low > Highest > Lowest**

Show all 5 with the most likely one marked:
```
1. Medium ← likely
2. High
3. Low
4. Highest
5. Lowest
```

**Step 3 — Sprint:**
List sprints fetched in Phase 1. Active sprints first, then future sprints, then Backlog:
```
1. CLC Sprint 42 (active) ← current
2. CLC Sprint 43 (future)
3. Backlog (no sprint)
```
Remember: sprint value is a plain number, not an object. "Backlog" means omit the sprint field entirely.

**Step 4 — Parent / Epic:**
List active epics fetched in Phase 1, ranked by **relevance to the issue being created**:
- Match keywords from the new issue's summary/description against epic summaries
- Epics with keyword overlap appear first, marked with `← likely`
- Example: if the issue mentions "BNPL" and there's an epic "BNPL Improvements", that epic goes to line 1

```
1. CLC-1637 — BNPL Improvements ← likely
2. CLC-1580 — Payment Methods Revamp
3. CLC-1492 — Money Tab Redesign
...
N. None (no parent)
N+1. Other (I'll type the key)
```

**Step 5 — Assignee:**
List team members **filtered by the chosen issue type** (see `references/team.md` assignment rules):
- BE Task/Bug → Azat, Daniil, Igor
- Android Task/Bug → Danila, Azat
- iOS Task/Bug → Evgenii, Azat
- Web Task/Bug → Azat
- Epic/Task → all developers (Azat, Daniil, Igor, Danila, Evgenii)

```
1. Azat
2. Daniil
3. Igor
```

**Step 6 — Developer:**
Same filtered list as Assignee. If the user picked the same person for Assignee, suggest that person first:
```
1. Azat ← same as assignee
2. Daniil
3. Igor
```

**Step 7 — QA:**
List QA team members:
```
1. Ars (Arsenii)
2. Sasha (Aleksandr)
```

**Step 8 — Story Points:**
Ask with Fibonacci-like options. For Bug types, pre-highlight lower range; for Task types, full range:
```
1. 1
2. 2
3. 3 ← typical for bugs
4. 5
5. 8
6. 13
7. Skip (don't set)
```

**Step 9 — Description (for Bug types only):**
If the chosen issue type is a Bug (BE Bug, Android Bug, iOS Bug, Web Bug) and the user hasn't already provided a structured description, offer to structure it:
```
Shall I structure the description as:
1. Yes — use template (Expected / Actual / Steps to reproduce / Environment)
2. No — keep as-is
```
If "Yes", reformat the user's description into the template, preserving all original information.

#### Phase 3: Confirmation summary

Before creating, display a formatted summary of ALL fields:

```
┌─────────────┬──────────────────────────────────┐
│ Field       │ Value                            │
├─────────────┼──────────────────────────────────┤
│ Project     │ CLC                              │
│ Type        │ BE Bug                           │
│ Summary     │ [Money Tab] PayLater deeplink...  │
│ Priority    │ High                             │
│ Sprint      │ CLC Sprint 42 (id: 34385)       │
│ Parent      │ CLC-1637                         │
│ Assignee    │ Azat                             │
│ Developer   │ Azat                             │
│ QA          │ Ars                              │
│ Story Points│ 3                                │
│ Link to     │ CLC-1971 (relates to)            │
│ Description │ (first 2 lines...)               │
└─────────────┴──────────────────────────────────┘
```

Ask: **"Create this issue? (Yes / change field name)"**

#### Phase 4: Create & link

1. **Create** the issue via `createJiraIssue(...)`.
   - Sprint field: plain number (e.g. `34385`), NOT `{ id: 34385 }`.
   - All `{ accountId }` fields: use IDs from `references/team.md`.
   - All `{ id }` fields (issuetype, priority): use IDs from `references/fields.md`.
2. **Link** to source ticket if applicable, via `createIssueLink(...)`.
3. **Report** the created issue key and URL to the user.

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
