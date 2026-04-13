---
name: bamboohr
description: "BambooHR people ops via MCP. Employee directory, time off, absences, goals, company docs. Use for who is out, time off balances, employee lookups, or team capacity planning."
allowed-tools: mcp__bamboohr__get-employee, mcp__bamboohr__get-employee-photo, mcp__bamboohr__get-employee-directory, mcp__bamboohr__get-employee-goals, mcp__bamboohr__estimate-time-off-balance, mcp__bamboohr__get-time-off-requests, mcp__bamboohr__get-whos-out, mcp__bamboohr__list-company-files, mcp__bamboohr__get-company-file, mcp__bamboohr__get-meta-fields
---

# BambooHR — People Ops for Team Leads

## When to Use This Skill

Activate when:
- User asks "who is out", "who's out today/this week/next week"
- User asks about time off, PTO, leave, absence, vacation for a person or the team
- User asks to look up an employee or the team directory
- User asks about someone's goals or performance targets
- User asks about company files or documents
- User asks about team capacity or sprint staffing
- User mentions BambooHR by name

## References — Read Before Acting

Before any people-related query, read `references/team.md` to resolve nicknames to BambooHR employee IDs directly — no directory lookups needed.

## MCP Tool Namespace

All tools use the `mcp__bamboohr__*` namespace. The server runs locally via npx (`mcp-bamboohr`).

If tools are not available, check that the MCP server is running and the API token is valid.

**Note:** Tool names below are from the npm package docs. If the actual tool names differ (e.g., underscores instead of hyphens), adapt accordingly.

## Date Calculation Guide

Use the `currentDate` from the system context to compute date ranges for natural language queries. All dates must be `YYYY-MM-DD`.

| User says | Start date | End date |
|-----------|-----------|----------|
| "today" | today | today |
| "tomorrow" | today + 1 | today + 1 |
| "this week" | Monday of current week | Sunday of current week |
| "next week" | Monday of next week | Sunday of next week |
| "this month" | 1st of current month | last day of current month |
| "next two weeks" | today | today + 14 days |
| "upcoming" (no range) | today | today + 14 days (default) |

## Tools Reference

### get-whos-out
Who is out of office during a date range.
- `start` (date, YYYY-MM-DD) — range start
- `end` (date, YYYY-MM-DD) — range end
- Returns: list of employees out with reason and dates

### get-time-off-requests
Time off requests with filters.
- `start` (date) — range start
- `end` (date) — range end
- `employeeId` (number, optional) — filter to specific employee
- `status` (string, optional) — approved/pending/denied/cancelled
- Returns: list of requests with dates, type, status, duration

### estimate-time-off-balance
Project future PTO balance for an employee.
- `employeeId` (number, required)
- `date` (date, YYYY-MM-DD) — estimate balance as of this date
- Returns: balance breakdown by time off type (vacation, sick, etc.)

### get-employee
Employee details with customisable fields.
- `employeeId` (number, required)
- `fields` (string, optional) — comma-separated field names
- Useful fields: `firstName`, `lastName`, `jobTitle`, `department`, `workEmail`, `mobilePhone`, `hireDate`, `supervisorId`

### get-employee-directory
Complete company directory. No parameters.
- Returns: all employees with basic profile info
- Use when employee ID is unknown or for broad lookups

### get-employee-photo
Employee photo.
- `employeeId` (number, required)
- Use only when user explicitly asks for a photo

### get-employee-goals
Performance goals for an employee.
- `employeeId` (number, required)
- Returns: goals with status, due dates, progress

### list-company-files
Browse company document categories. No parameters.
- Returns: file categories and files

### get-company-file
Download a specific company document.
- `fileId` (number, required)
- Use after `list-company-files` to fetch a specific file

### get-meta-fields
All available BambooHR data fields. No parameters.
- Use when you need to know what fields are available for `get-employee`

## Common Workflows

### 1. Who is out today?
1. Calculate today's date from currentDate
2. Call `get-whos-out(start: today, end: today)`
3. Cross-reference results with `references/team.md` — show **team members first**, then others
4. Present as a clean list: Name, reason (vacation/sick/etc.), return date if available
5. If nobody is out, say so clearly

### 2. Who is out this week / next week?
1. Calculate Monday-to-Sunday range for the requested week
2. Call `get-whos-out(start: Monday, end: Sunday)`
3. Present as a **day-by-day view** for team members, marking who is out on which days
4. **Highlight days where multiple team members are absent** (capacity risk)

### 3. Check [name]'s time off
1. Resolve name → employee ID via `references/team.md`
2. Call `get-time-off-requests(employeeId: ID, start: "YYYY-01-01", end: "YYYY-12-31")` — default to current year
3. Filter by status if user asks for pending/approved specifically
4. Present as chronological list: dates, type, duration, status

### 4. [name]'s PTO balance
1. Resolve name → employee ID
2. Call `estimate-time-off-balance(employeeId: ID, date: today)` — or future date if user specifies
3. Present balance by type (vacation days remaining, sick days remaining, etc.)
4. If user asks about multiple people, loop through team members

### 5. Look up [name]
1. Resolve name → employee ID via references or directory search
2. Call `get-employee(employeeId: ID, fields: "firstName,lastName,jobTitle,department,workEmail,mobilePhone,hireDate,supervisor")`
3. Present a clean profile card

### 6. Team directory
1. Read `references/team.md` for team member IDs
2. Call `get-employee` for each team member (or `get-employee-directory` once and filter)
3. Present as table: Name | Role | Email | Phone | Hire Date

### 7. [name]'s goals
1. Resolve name → employee ID
2. Call `get-employee-goals(employeeId: ID)`
3. Present goals with status, due date, progress percentage
4. **Flag any overdue goals**

### 8. Company files / Find [document]
1. Call `list-company-files` to get categories and file list
2. If user asks for a specific document, search results by name
3. If found, call `get-company-file(fileId: ID)` to retrieve it
4. Present grouped by category

### 9. Team capacity for [period]
1. Determine planning period (ask user or derive from Jira sprint / Linear cycle)
2. Call `get-whos-out(start: periodStart, end: periodEnd)`
3. Cross-reference with team members from `references/team.md`
4. Calculate available person-days per member: working days (Mon-Fri) minus absent days
5. Present capacity summary table:

| Name | Role | Working Days | Absent Days | Available Days |
|------|------|-------------|-------------|----------------|

6. Total team capacity and **highlight critical gaps** (e.g., no QA available, single-point-of-failure roles)
7. If Jira/Linear skill is active, suggest comparing against sprint backlog

## Presentation Guidelines

- Always present **team members first**, company-wide data second
- Use **tables** for structured data (directories, capacity plans)
- Use **lists** for sequential data (upcoming absences)
- For calendar-style views, use a day-by-day grid with names
- Clearly distinguish between **approved** and **pending** time off
- When showing balances, include the unit (days/hours) and time off type name
- For capacity planning, highlight when a role has zero available people

## Integration with Other Skills

| Scenario | Delegate To |
|----------|-------------|
| Sprint dates from Jira for capacity planning | `jira` |
| Cycle dates from Linear for capacity planning | `linear` |
| Recording absence notes in Obsidian daily note | `obsidian` |
| Checking if absent team member has open tickets to reassign | `jira` |

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| 401 Unauthorized | Invalid or expired API token | Check `BAMBOO_API_TOKEN` in `~/.claude.json` |
| 403 Forbidden | Token lacks permissions | Verify API token has appropriate BambooHR permissions |
| 404 Not found | Wrong employee ID or domain | Verify `BAMBOO_COMPANY_DOMAIN` and employee ID |
| Employee not found by name | Name not in `references/team.md` | Search directory or ask user for BambooHR employee ID |
| MCP server not running | npx failed to start | Check npm/node installation and network connectivity |
| Empty results for who's out | No absences in date range | Confirm date range is correct — nobody may simply be out |
