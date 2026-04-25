---
name: work-on-ticket
description: Fetches issue tracker ticket details (Jira or Linear), creates an appropriately named branch, and initiates the task planning workflow. Use when the user says "work on [TICKET_ID]" or similar phrases.
allowed-tools: Bash(git *:*), mcp__atlassian__getJiraIssue, mcp__linear-server__get_issue
---

# Work on Ticket

Streamlined workflow to start work on an issue tracker ticket (Jira or Linear) by fetching ticket details, creating a branch, and initiating task planning.

## When to Use This Skill

Activate this skill when:
- The user says "work on PROJ-123" or "start work on PROJ-123"
- The user says "pick up PROJ-123" or "begin PROJ-123"
- The user mentions starting work on a specific ticket ID
- Pattern: `work on [TICKET_ID]` or similar intent

## Workflow

### 1. Parse Ticket ID

Extract the ticket ID from the user's message. Common patterns:
- `work on PROJ-782`
- `start PROJ-782`
- `pick up PROJ-123`

Ticket ID format: `[A-Z]+-[0-9]+` (e.g., PROJ-782, PROJ-123)

### 2. Fetch Ticket Details

Fetch ticket details using the appropriate MCP tool:

- **Jira**: Use `mcp__atlassian__getJiraIssue` with `cloudId` (your Jira site URL or cloud ID) and `issueIdOrKey` (the ticket ID).
- **Linear**: Use `mcp__linear-server__get_issue` with `id` set to the ticket identifier (e.g., `PROJ-123`).

If neither MCP tool is connected, ask the user to paste the ticket details or describe the task.

**Extract from response:**
- Summary (title)
- Description
- Issue type
- Status
- Any other relevant context

### 3. Generate Branch Name

Create a branch name using this format:
```
[type]/[TICKET_ID]-[kebab-case-summary]
```

**Derive type from the issue type:**
- Bug / Bug Fix → `fix`
- Feature / Task / Story → `feat`
- Chore / Maintenance / Spike / Research → `chore`
- Refactor → `refactor`
- Docs → `docs`

**Branch Naming Rules:**
- Format: `type/TICKET-ID-kebab-summary`
- Convert summary to kebab-case (lowercase, dashes instead of spaces)
- Remove special characters
- Keep it concise (max 60 characters total)
- Use meaningful words from the summary

**Examples:**
- `feat/PROJ-782-migrate-existing-mcp-server`
- `fix/PROJ-123-fix-auth-token-expiry`
- `feat/PROJ-456-add-user-settings-page`
- `chore/CLC-1959-update-dependencies`

**Implementation:**
```bash
# Convert summary to kebab-case
# Example: "Migrate existing MCP server" -> "migrate-existing-mcp-server"
# Full branch: feat/PROJ-782-migrate-existing-mcp-server
```

### 4. Check Current Git State

Before creating a branch, check the current state:

```bash
# Check current branch
git branch --show-current

# Check for uncommitted changes
git status --porcelain
```

**If uncommitted changes exist:**
- STOP and inform User
- Suggest: "You have uncommitted changes. Should I commit them first, stash them, or continue anyway?"
- Wait for User's decision

**If not on main:**
- STOP and inform User
- Suggest: "You're currently on branch [CURRENT_BRANCH]. Should I switch to main first?"
- Wait for User's decision

### 5. Create Branch

Once it's safe to proceed:

```bash
# Ensure we're on the latest main
git checkout main
git pull origin main

# Create and checkout new branch
git checkout -b [TICKET_ID]-[kebab-case-summary]
```

Confirm to User: "Created and checked out branch: [BRANCH_NAME]"

### 6. Build Task Planning Prompt

Analyze the ticket and create a comprehensive task breakdown:

**Prompt should include:**
- The ticket summary
- Key details from the description
- Any acceptance criteria mentioned
- Relevant technical context

**Example prompt construction:**
```
Summary: [ticket.summary]

Description: [ticket.description]

Acceptance Criteria:
[extracted criteria if present]
```

### 7. Execute Task Planning

Create a structured task breakdown using TodoWrite:

1. Break the ticket into discrete, actionable subtasks
2. Each task should be small enough to implement in a single focused session
3. Order tasks by dependency (prerequisites first)
4. Include acceptance criteria for each subtask where applicable

Present the task breakdown to the user and ask for confirmation before starting implementation.

**Example task breakdown:**
- Task 1: Set up data models for [feature]
- Task 2: Implement repository interface and local storage
- Task 3: Create use case layer
- Task 4: Build UI components
- Task 5: Write tests for critical paths

## Error Handling

**If ticket not found:**
- Inform User: "Couldn't find ticket [TICKET_ID] in your issue tracker. Please check the ticket ID."
- STOP - don't proceed with branch creation

**If branch already exists:**
- Inform User: "Branch [BRANCH_NAME] already exists."
- Ask: "Should I check it out, create a new branch with a different name, or stop?"
- Wait for decision

**If git operations fail:**
- Show the error to User
- STOP - don't proceed to task planning

## Example Usage

### Example 1: Simple Ticket

**User:** "work on PROJ-782"

**Claude:**
1. Fetches PROJ-782 from issue tracker
2. Finds summary: "Migrate existing MCP server"
3. Checks git state (clean, on main)
4. Creates branch: `PROJ-782-migrate-existing-mcp-server`
5. Creates task breakdown and presents to user for confirmation

### Example 2: With Uncommitted Changes

**User:** "work on PROJ-456"

**Claude:**
1. Fetches PROJ-456 from issue tracker
2. Checks git state - finds uncommitted changes
3. **STOPS** and asks: "You have uncommitted changes. Should I commit them first, stash them, or continue anyway?"
4. Waits for User's decision

### Example 3: Ticket Not Found

**User:** "work on PROJ-999"

**Claude:**
1. Tries to fetch PROJ-999 from issue tracker
2. Ticket not found
3. Informs User: "Couldn't find ticket PROJ-999 in your issue tracker. Please check the ticket ID."
4. STOPS

## Coding Standards

**CRITICAL RULE - NESTED CONDITIONALS:**
- **NEVER EVER EVER USE NESTED CONDITIONALS** when working on tickets
- If you find yourself nesting if statements, STOP immediately
- Refactor using early returns, guard clauses, or extract functions
- This rule applies to all code written while working on any ticket
- Violation of this rule is FAILURE

**Why this matters:**
- Nested conditionals reduce readability and increase cognitive load
- They make code harder to test and maintain
- Early returns and guard clauses are always clearer

**Instead of:**
```kotlin
if (condition1) {
    if (condition2) {
        // do something
    }
}
```

**Do this:**
```kotlin
if (!condition1) return
if (!condition2) return
// do something
```

**CRITICAL RULE - NO UNNECESSARY INLINE COMMENTS:**
- **NEVER add simple, obvious inline comments** that just restate what the code does
- Code should be self-documenting through clear variable names, function names, and structure
- Only add comments when they explain **WHY** something is done, not **WHAT** is being done
- Remove unnecessary comments during refactoring
- This rule applies to all code written while working on any ticket
- Violation of this rule is FAILURE

**Bad comments (obvious, unnecessary):**
```kotlin
// Set the user's name
user.name = "Alice"

// Loop through the items
for (item in items) {
    processItem(item)
}

// Return true if valid
return isValid
```

**Good comments (explain WHY, add context):**
```kotlin
// Cache user data for 5 minutes to reduce API calls
val cachedUser = cache.get(userId, ttl = 300)

// Process items in batches to avoid memory issues with large datasets
items.chunked(100).forEach { batch ->
    processBatch(batch)
}

// Skip validation for admin users per security requirement SEC-123
if (user.isAdmin) return true
```

**When comments ARE appropriate:**
- Explaining non-obvious business logic or requirements
- Documenting workarounds for external bugs (with issue links)
- Clarifying performance optimizations
- Noting security considerations
- Referencing ticket numbers or external documentation

**When to use NO comments:**
- If the code is self-explanatory
- If a better variable/function name would make it clear
- If the comment just repeats what the code obviously does

**CRITICAL RULE - TESTING:**
- Follow project testing conventions and frameworks
- Prefer TDD (test-driven development) when acceptance criteria are clear
- Test behavior, not implementation details
- Write tests that are fast, independent, and repeatable
- Cover edge cases and error paths
- Avoid brittle tests that break on refactoring
- Avoid excessive mocking — prefer real implementations where practical

## Creating a Merge Request / Pull Request

When the user asks to create an MR or PR for the current ticket branch:

### MR Title Format

**ALWAYS prefix the MR title with the ticket ID in square brackets:**

```
[TICKET_ID] type(scope): description
```

**Examples:**
- `[CLC-1924] feat(paylaterwidget): add merchant data to icons and server-side overdue flag`
- `[PROJ-782] chore(mcp): migrate existing MCP server configuration`
- `[PROJ-123] fix(auth): prevent token refresh race condition`

**How to derive the title:**
1. Extract the ticket ID from the current branch name (e.g., `feature/CLC-1924-...` → `CLC-1924`)
2. Generate a Conventional Commits subject line from the ticket summary and changes
3. Prepend `[TICKET_ID] ` to the subject line

**NEVER omit the `[TICKET_ID]` prefix from the MR/PR title.**

### MR Body

Include:
- A brief description of what was changed and why
- Reference to the ticket (e.g., `Closes CLC-1924`)
- Any notable implementation decisions

## Important Notes

- **Always check git state** before creating branches
- **Never force-create branches** or overwrite existing branches
- **Never proceed** if there are uncommitted changes without User's approval
- **Keep branch names concise** - aim for clarity over completeness
- **Include ticket context** in the task planning prompt to give the planner maximum context
- **The task breakdown gives the user visibility into the implementation plan before work begins**
- **Always prefix MR/PR titles with `[TICKET_ID]`** — e.g. `[CLC-1924] feat(...):`

## Success Criteria

The skill is successful when:
1. Ticket details are fetched successfully (or provided by user)
2. Appropriate branch name is generated
3. Git state is verified (no uncommitted changes or user approved)
4. New branch is created and checked out
5. Task breakdown is created and confirmed by user
6. User is informed of each major step
