---
name: linear
description: "Linear issue tracking via MCP. Reading issues, searching, managing projects and statuses. Use when working with Linear issues, projects, cycles, or team management."
allowed-tools: mcp__linear__get_issue, mcp__linear__search_issues, mcp__linear__get_project, mcp__linear__list_projects, mcp__linear__get_team, mcp__linear__list_teams
---

# Linear — Issue Tracking via MCP

## When to Use This Skill

Activate when:
- User mentions Linear or links to `linear.app`
- User provides a ticket ID matching a known Linear project prefix (see `references/projects.md`)
- User asks to manage issues, projects, or cycles in Linear

## Linear vs Jira

If a ticket ID is given without context:
1. Check if it matches known Linear project prefixes in `references/projects.md`
2. Check if it matches known Jira project keys in the `jira` skill references
3. If the URL contains `linear.app` → Linear
4. If the URL contains `atlassian.net` or `.jira.com` → Jira (delegate to `jira` skill)
5. If ambiguous → ask the user

## MCP Tool Namespace

All Linear tools use the `mcp__linear__*` namespace. The MCP server is hosted at `https://mcp.linear.app/mcp` and requires OAuth authentication.

If authentication is needed, use `mcp__linear__authenticate` to initiate the OAuth flow.

**Note:** Exact tool names may vary. If a listed tool is not available, check what tools are discoverable under the `mcp__linear__` prefix.

## Read Operations

### Get Issue
Fetch full issue details including title, description, status, assignee, priority, labels, and comments.

Tool: `mcp__linear__get_issue`
Parameter: `id` — the ticket identifier (e.g., `PROJ-123`)

### Search Issues
Search across the Linear workspace.

Tool: `mcp__linear__search_issues`
Parameters: query string, optional filters (project, status, assignee, etc.)

### Projects
- `mcp__linear__list_projects` — list all projects
- `mcp__linear__get_project` — get project details

### Teams
- `mcp__linear__list_teams` — list all teams
- `mcp__linear__get_team` — get team details

## Write Operations

**All write operations require user approval before execution.**

### Create Issue
Create a new issue in a project/team.

Required: title, team
Optional: description, assignee, priority, labels, project, cycle, estimate

### Update Issue
Update fields on an existing issue (title, description, status, assignee, priority, labels, etc.).

### Update Status / Transition
Change issue status (e.g., Todo → In Progress → Done). Linear uses a workflow state model.

### Add Comment
Add a comment to an issue. Supports markdown formatting.

### Create Project
Create a new project within a team.

## Common Workflows

### Look up an issue
1. Fetch issue: `get_issue(id: "PROJ-123")`
2. Review title, description, status, and comments

### Search across workspace
1. Search: `search_issues(query: "authentication bug")`
2. Review matching issues

### Update issue status
1. Fetch issue to see current status
2. Present new status to user for approval
3. Update status

### Add a comment
1. Fetch issue to see context
2. Draft comment content
3. Present to user for approval
4. Post comment

## Linear Concepts

| Concept | Description |
|---------|-------------|
| **Workspace** | Top-level organisation containing all teams and projects |
| **Team** | A group of people working together (has its own issue prefix) |
| **Project** | A collection of related issues spanning one or more teams |
| **Cycle** | Time-boxed iteration (like a sprint) |
| **Issue** | A task or bug with status, assignee, priority, labels |
| **Workflow State** | Issue statuses (Backlog, Todo, In Progress, Done, Cancelled) |
| **Label** | Tags for categorising issues |
| **Priority** | Urgent, High, Medium, Low, No Priority |

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Authentication required | OAuth not completed | Use `mcp__linear__authenticate` to start auth flow |
| Issue not found | Wrong ID or no access | Verify the issue identifier |
| Permission denied | Insufficient workspace access | Check workspace membership |
| Rate limited | Too many requests | Wait and retry |
