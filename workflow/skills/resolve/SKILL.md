---
name: resolve
description: "Full ticket lifecycle — from ticket ID to merged MR/PR with QA notes. Parses ticket ID or link, detects Jira vs Linear, orchestrates planning, implementation, review, and delivery directly in the main chat."
allowed-tools: Agent, AskUserQuestion, Bash(git *:*), Bash(glab *:*), Bash(gh *:*), Bash(obsidian *:*), Bash(cd *), Bash(ls:*), Bash(pwd), Read, Glob, Grep, Write, Edit, mcp__atlassian__getJiraIssue, mcp__claude_ai_Atlassian_2__getJiraIssue, mcp__atlassian__getTransitionsForJiraIssue, mcp__atlassian__transitionJiraIssue, mcp__claude_ai_Atlassian_2__getTransitionsForJiraIssue, mcp__claude_ai_Atlassian_2__transitionJiraIssue, mcp__linear__get_issue, mcp__linear__save_issue
---

# Resolve — Full Ticket Lifecycle Orchestrator

You are the orchestrator. When this skill activates, you manage the full lifecycle of a ticket — from fetch through merged MR/PR with QA notes. You delegate coding to specialist agents, keep the user informed at natural pause points, and ask the user anything you need to clarify. You follow the phases yourself directly in the main chat.

## When to Use This Skill

Activate when:
- User types `/resolve TICKET-ID` (e.g., `/resolve CLC-2001`)
- User types `/resolve <URL>` with an atlassian.net or linear.app link

## Input Parsing

Extract the ticket identifier from the argument:

### Ticket ID (pattern: `[A-Z]+-[0-9]+`)

Examples: `CLC-2001`, `SAP-456`, `PROJ-123`

### URL

Extract the ticket ID from the URL:
- **Jira:** `https://tabby.atlassian.net/browse/CLC-2001` → `CLC-2001`
- **Linear:** `https://linear.app/team/PROJ-123` → `PROJ-123`

### Invalid Input

If the argument doesn't match a ticket ID or a recognised URL, ask the user to provide a valid ticket ID or link.

## Tracker Detection

Determine whether the ticket is in Jira or Linear:

1. **URL-based** (highest priority):
   - Contains `atlassian.net` or `.jira.com` → **Jira**
   - Contains `linear.app` → **Linear**

2. **Project key-based**:
   - Known Jira project keys: `CLC`, `SAP` (from `skills/jira/references/projects.md`)
   - Known Linear project prefixes: check `skills/linear/references/projects.md`

3. **Ambiguous**: If the project key is not in either list, ask the user:
   > "Is `PROJ-123` a Jira or Linear ticket?"

## State Detection

Before starting, detect the current state to support re-entry:

1. Check if a worktree already exists: `ls .worktrees/ | grep <TICKET-ID>`
2. Check if a branch exists: `git branch -a | grep <TICKET-ID>` (branches follow `type/<TICKET-ID>-kebab-summary` format)
3. Check if an MR/PR is open: `glab mr list --source-branch <branch>` or `gh pr list --head <branch>`

Based on state:
- **No worktree, no branch** → start from Phase 1
- **Worktree exists, no MR/PR** → resume from where the work left off (check for uncommitted changes, plan presence, etc.)
- **MR/PR open** → jump to Phase 7 (review loop) — read MR/PR comments for review feedback
- **MR/PR merged** → jump to Phase 8 (close out)

## Ticket Status Transitions (Jira)

At key lifecycle points, transition the Jira ticket to reflect the current phase. Use `getTransitionsForJiraIssue` to find available transitions, then `transitionJiraIssue` with the matching transition ID.

**Jira workflow:** `To Do → Developing → Review → Need testing → Testing → Ready for release → Done`

| Phase | Target Status | When |
|-------|--------------|------|
| Phase 1 (Setup) | **Developing** | After worktree and branch are created |
| Phase 6 (Ship) | **Review** | After MR/PR is created |
| Phase 8 (Close Out) | **Need testing** | After QA notes are written |

**How to transition:**
1. Get available transitions: `getTransitionsForJiraIssue(cloudId: "tabby.atlassian.net", issueIdOrKey: "<TICKET-ID>")`
2. Find the transition whose `to.name` matches the target status
3. Execute: `transitionJiraIssue(cloudId: "tabby.atlassian.net", issueIdOrKey: "<TICKET-ID>", transitionId: "<id>")`

If the target transition is not available (ticket is already in that status or workflow doesn't allow it), skip silently — do not fail.

For **Linear** tickets, use `mcp__linear__save_issue` to update the status field instead.

---

## Phase 1 — Setup

### Fetch Ticket

**Jira:**
Use `mcp__claude_ai_Atlassian_2__getJiraIssue` with `cloudId: "tabby.atlassian.net"` and `issueIdOrKey: "<TICKET-ID>"`.

Fallback: `mcp__atlassian__getJiraIssue` with the same parameters.

**Linear:**
Use `mcp__linear__get_issue` with `id: "<TICKET-ID>"`.

If no MCP tool is connected, ask the user to paste ticket details.

**Extract:**
- Summary (title)
- Description
- Acceptance criteria (if present)
- Issue type
- Status
- Assignee

### Create Worktree and Branch

Derive the branch type from the issue type:
- Bug / Bug Fix → `fix`
- Feature / Task / Story → `feat`
- Chore / Maintenance / Spike / Research → `chore`
- Refactor → `refactor`
- Docs → `docs`

```bash
# Generate branch name: type/TICKET-ID-kebab-case-summary (max 60 chars total)
BRANCH="<type>/<TICKET-ID>-<kebab-summary>"

# Example: feat/CLC-1959-add-super-button

# Create worktree
git worktree add ".worktrees/<TICKET-ID>" -b "$BRANCH"
```

If worktree already exists, ask user: reuse or clean + recreate.

### Transition Ticket → Developing

Transition the ticket to **Developing** status (see Ticket Status Transitions section).

### Linear QA Notes Section

For Linear tickets only: check if the issue description has a `# QA Notes` section. If not, add one (empty) via the writer agent. This section will be updated throughout the lifecycle.

## Phase 2 — Planning

Create an implementation plan based on the ticket details:

1. Analyse the ticket — summary, description, acceptance criteria
2. Break into discrete, ordered subtasks
3. Each subtask: what to implement + what to test
4. Consider dependencies between subtasks

### Save Plan

Decide where to save based on ticket content:
- **Keywords in ticket:** ADR, RFC, migration, architecture, design doc → **repo-related** → save `plan.md` in the worktree root, open in IDE
- **Otherwise** → save as a note in `~/Obsidian/` using the Write tool directly (do not use the obsidian CLI — it is unreliable for file creation)

### PAUSE

Ask the user:
> "Plan ready. Read it and let me know when to proceed — or leave any notes."

Wait for user response. Incorporate any notes they provide.

## Phase 3 — Implementation

Spawn the `developer` agent:

```
Agent(
  subagent_type: "developer",
  prompt: "<calibrated prompt — see Effort Calibration>"
)
```

**Context to pass:**
- Worktree path (absolute)
- Plan content
- User notes (if any)
- Ticket summary, description, acceptance criteria

Wait for the developer to complete.

## Phase 4 — Quality Gate

**HARD GATE: Phase 6 (Ship) MUST NOT execute until Phase 4 passes.**

Spawn three agents in **parallel**:

```
Agent(
  subagent_type: "code-reviewer",
  prompt: "<calibrated prompt>"
)

Agent(
  subagent_type: "test-runner",
  prompt: "Run tests in <worktree-path>. Report results."
)

Agent(
  subagent_type: "general-purpose",
  prompt: "Run the linter in <worktree-path> and report all errors and warnings.
    Auto-detect the linter: try ktlint, detekt, eslint, golangci-lint, swiftlint in that order.
    Run from the worktree root. Report: tool used, exit code, full output.
    If no linter is found, report that clearly."
)
```

**Context for code-reviewer:**
- Worktree path
- Plan summary (what was supposed to be implemented)
- Ticket acceptance criteria

**Context for test-runner:**
- Worktree path (it auto-detects build tool and test commands)

**Context for linter agent:**
- Worktree path (it auto-detects the linter)

### Evaluate Results

- **All three pass** (reviewer: PASS or PASS_WITH_SUGGESTIONS, tests green, linter clean) → proceed to Phase 5
- **Fixes needed** (reviewer: NEEDS_FIXES, tests fail, or linter errors) → spawn `developer` to apply fixes → re-run quality gate
- **Linter warnings only** (no errors, exit code 0) → treat as pass, include warnings in the reviewer summary
- **After 2 failed cycles** → PAUSE, ask user for guidance:
  > "Quality gate has failed twice. Here's what's happening: [summary]. How would you like to proceed?"

### Gate Enforcement Checklist

Before proceeding to Phase 6 (Ship), verify ALL of the following:
- [ ] code-reviewer returned PASS or PASS_WITH_SUGGESTIONS
- [ ] test-runner reported all tests green
- [ ] linter reported no errors (warnings are allowed)
- [ ] If fixes were applied, the quality gate was re-run after fixes

If any of these are not met, DO NOT proceed to Phase 6.

## Phase 5 — Source Sync (Conditional)

Compare the implementation against the original ticket description and acceptance criteria.

**How to detect divergence:**
- Read the original ticket (from Phase 1 extraction)
- Read the implementation summary (from developer agent output)
- If the implementation added/removed/changed functionality not in the original ticket → diverged

If diverged, spawn `writer` agents in **parallel**:

```
Agent(
  subagent_type: "writer",
  prompt: "Update ticket <ticketId> in <tracker>.
    Original description: <original>
    What was actually implemented: <implementation summary>
    Update the description and acceptance criteria to reflect the implementation.
    For Linear tickets: also update the # QA Notes section."
)

Agent(
  subagent_type: "writer",
  prompt: "Check if there are ADR or tech doc files in <worktree-path>.
    Look for: docs/adr/*, docs/*.md, ADR-*.md, *.adr.md
    If found, update them to reflect: <implementation summary>
    If none found, skip."
)
```

If no divergence, skip this phase.

## Phase 6 — Ship

### Commit

Follow the git-commit skill methodology:

1. Stage changed files: `git add <specific files>` (never `git add -A` or `git add .`)
2. Construct a Conventional Commits message:

```
type(scope): concise subject

Why this change was needed:
[from ticket context and implementation summary]

What changed:
[technical summary from developer output]

Problem solved:
[from ticket description]

Refs: <TICKET-ID>
```

3. Commit using heredoc:
```bash
cd <worktree-path> && git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

4. Push: `cd <worktree-path> && git push -u origin <branch>`

**Critical commit rules:**
- Never commit directly to `main` or `master`.
- Never add Co-Author or mention Claude Code.
- Never use `git add -A` or `git add .`.
- **Only stage files related to the current task.** Before staging, review `git status` and exclude:
  - `plan.md` or any plan files created during planning
  - Generated mocks not related to this ticket
  - Proto generation results not related to this ticket
  - Any other artefacts that aren't part of the implementation
- When in doubt, stage files explicitly by name.

### Detect Platform

```bash
git remote get-url origin
```

- Contains `github.com` → GitHub → use `gh`
- Contains `gitlab` → GitLab → use `glab`
- Ambiguous → ask user

### Create MR/PR

**GitLab:**
```bash
cd <worktree-path> && glab mr create \
  --title "[<TICKET-ID>] <type>(<scope>): <description>" \
  --description "$(cat <<'EOF'
## Summary
<bullet points>

## Ticket
<tracker link>

## Test plan
<what to verify>
EOF
)"
```

**GitHub:**
```bash
cd <worktree-path> && gh pr create \
  --title "[<TICKET-ID>] <type>(<scope>): <description>" \
  --body "$(cat <<'EOF'
## Summary
<bullet points>

## Ticket
<tracker link>

## Test plan
<what to verify>
EOF
)"
```

### Transition Ticket → Review

Transition the ticket to **Review** status (see Ticket Status Transitions section).

### Monitor MR (GitLab only)

After creating the MR, set up recurring monitoring using the `/loop` skill:

```
/loop 60m bash ~/.claude/scripts/check-mr.sh --verbose <MR_NUMBER> <REPO>
```

Where:
- `MR_NUMBER` is extracted from the `glab mr create` output
- `REPO` is derived from `git remote get-url origin` (strip protocol prefix and `.git` suffix, e.g. `gitlab.com/tabby.ai/services/clc-widgets`)

The check-mr.sh script:
- Reports MR state changes (pipeline status, new comments, merge/close)
- Is silent when nothing has changed (unless `--verbose`)
- Outputs `STOP: MR is merged/closed` when the MR is no longer active

When the loop reports the MR is merged, proceed to Phase 8 (Close Out).

**Note:** For GitHub repos, skip `/loop` setup — the user monitors PRs via GitHub notifications.

### PAUSE

Tell the user:
> "MR/PR created: <link>. Monitoring set up. Let me know when review is done, or I'll notify you of changes."

## Phase 7 — Review Loop

When the user returns with review feedback:

1. **Read review comments:**
   - GitLab: `glab mr view <mr-number> --comments`
   - GitHub: `gh pr view <pr-number> --comments`

2. **Spawn developer** to implement feedback:
   ```
   Agent(
     subagent_type: "developer",
     prompt: "Apply review feedback in <worktree-path>.
       Review comments: <comments>
       Fix each issue. Update tests if behaviour changed."
   )
   ```

3. **Re-run quality gate** (Phase 4)

4. **Commit** (same methodology as Phase 6)

5. **Sync all sources in parallel:**
   - Writer: update ticket
   - Writer: update doc/ADR
   - Update MR/PR description:
     - GitLab: `glab mr update <mr-number> --description "..."`
     - GitHub: `gh pr edit <pr-number> --body "..."`

6. **PAUSE:**
   > "MR/PR updated. Let me know when it's merged."

## Phase 8 — Close Out

When the user confirms merge (or `/loop` reports merged):

1. **Write QA notes** to the ticket's QA Notes field (not as a comment):
   - **Jira:** Use `editJiraIssue` with `customfield_10213` in ADF format (Atlassian Document Format JSON — not plain strings or markdown). Never use `addCommentToJiraIssue` for QA notes.
   - **Linear:** Use `save_issue` to update the `# QA Notes` section in the issue description.
   - Content: what was implemented, what to test, MR link.

2. **Transition Ticket → Need testing** (see Ticket Status Transitions section)

3. **Clean up worktree:**
   ```bash
   git worktree remove ".worktrees/<TICKET-ID>"
   ```

4. **Clean up state file:**
   ```bash
   rm -f "/tmp/mr_<MR_NUMBER>_state"
   ```

5. **Report to user:**
   > "Done. QA notes written, worktree cleaned up."

---

## Effort Calibration

Before spawning each sub-agent, assess the task and calibrate the prompt accordingly.

**Signals to assess:**

| Signal | Light | Medium | Heavy |
|--------|-------|--------|-------|
| Diff size | < 100 lines | 100–500 lines | > 500 lines |
| Risk | Config, UI cosmetic | Standard feature | Auth, payments, data |
| Complexity | Simple CRUD, single file | Multi-file, clear patterns | Cross-system, business logic |
| AC count | 1–2 criteria | 3–5 criteria | 6+ criteria or ambiguous |

**How to calibrate:**

- **Light:** brief prompt, tell agent to focus on correctness only, skip deep analysis. Example for code-reviewer: "Quick review — small config change, focus on correctness."
- **Medium:** standard prompt with full context. No special instructions.
- **Heavy:** detailed prompt, ask for thorough analysis. Example for code-reviewer: "This touches payment logic. Full security and performance review. Consider edge cases."

This applies to all sub-agents:
- **Developer:** light → implement directly; heavy → break into steps, verify each
- **Code Reviewer:** light → correctness only; heavy → full security + performance + architecture
- **Test Runner:** always standard — mechanical task, no calibration needed
- **Writer:** light → update only changed fields; heavy → rewrite description to reflect new understanding

Decide autonomously based on the signals. No user input needed.

## Autonomy Rules

### Auto-proceed (no user input)
- Worktree creation
- Platform detection (glab vs gh)
- Routine commits
- Source sync after divergence detection
- Effort calibration decisions

### Ask user
- Plan approval (PAUSE after Phase 2)
- After 2 failed quality gate cycles
- First MR/PR creation (show link)
- Ambiguous tracker or platform
- Worktree already exists (reuse or recreate?)

### Always inform
- Divergence detected (what changed from ticket)
- Quality gate results (pass/fail summary)
- MR/PR link
- QA notes written
- Worktree cleaned up

## Error Handling

| Error | Recovery |
|-------|----------|
| Ticket not found | Ask user to paste ticket details or check the ID |
| MCP not connected | Ask user to paste ticket details manually |
| Worktree already exists | Ask user: reuse existing or clean + recreate |
| Branch already exists | Ask user: checkout existing or create new with suffix |
| MR/PR creation fails | Show error, ask user to resolve (e.g., push permissions) |
| Agent spawn fails | Retry once, then ask user |
| Merge conflicts in worktree | Inform user, ask for guidance |
| Tests require missing env/setup | Report what's needed, ask user |

## Coding Standards

The developer agent has coding standards baked into its definition (no nested conditionals, no obvious comments, tests alongside logic). You do not need to repeat them in spawn prompts — the developer enforces them automatically.

If the code-reviewer flags a standards violation, route it back to the developer as a fix. No need to explain the rule — the developer already knows it.
