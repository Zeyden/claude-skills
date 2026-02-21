# Engineering & Development Skills

This project contains Skills that enhance Claude's ability to handle engineering workflows (ticket tracking, code review, version control) and provide expert guidance for Kotlin Multiplatform (KMP) development with Compose Multiplatform, as well as Figma design automation.

## Automatic Skill Triggers

Automatically invoke these skills when you detect matching patterns:

### Workflow Skills

| Trigger | Skill |
|---------|-------|
| "work on [TICKET_ID]", "start on [TICKET_ID]", "pick up [TICKET_ID]", "[TICKET_ID]" | `work-on-ticket` |
| "commit", "git commit", asks to commit changes, work is complete and ready to commit | `git-commit` |
| "review MR", "review PR", "summarize MR", "PR context", shares MR/PR link | `code-review` |
| "execute figma script", "run figma script", references a Figma Plugin API script file | `execute-figma-script` |

Ticket IDs follow the pattern `[A-Z]+-[0-9]+` (e.g., `SUB-123`, `PROJ-42`). This covers both Jira and Linear-style identifiers.

### KMP Development Expert Skills

| Trigger | Skill |
|---------|-------|
| StateFlow/SharedFlow patterns, sealed classes/interfaces, @Immutable usage, DSL builders, inline/reified functions, Kotlin idioms and performance | `kotlin-expert` |
| Structured concurrency (supervisorScope, coroutineScope), advanced Flow operators (flatMapLatest, combine, merge, shareIn, stateIn), channels, callbackFlow, dispatchers, CoroutineExceptionHandler, testing async code (runTest, Turbine) | `kotlin-coroutines` |
| "should I share this?", source set placement (commonMain vs platform-specific), expect/actual patterns, KMP abstraction decisions, incorrect placement detection | `kotlin-multiplatform` |
| Gradle build files (build.gradle.kts, settings.gradle), version catalog (libs.versions.toml), build errors, dependency conflicts, desktop packaging (DMG/MSI/DEB), build performance, Proguard/R8 config | `gradle-expert` |
| Composable UI components, state management (remember, derivedStateOf, produceState), recomposition optimisation (@Stable/@Immutable visual usage), Material3 theming, custom ImageVector icons, shared vs platform-specific UI decisions | `compose-expert` |
| Desktop-specific APIs (Window, Tray, MenuBar, Dialog), composeApp/ module files, keyboard shortcuts, desktop navigation (NavigationRail, multi-window), file system integration, OS-specific behaviour | `desktop-expert` |
| Android navigation (Navigation Compose, routes, bottom nav), runtime permissions, platform APIs (Intent, Context, Activity), Android lifecycle (ViewModel, collectAsStateWithLifecycle), Android build config, edge-to-edge UI | `android-expert` |

Never perform these workflows manually when a skill exists - always invoke the appropriate skill.

## Skill Invocation Guidelines

When a user's request matches a skill trigger:

1. **Invoke the skill immediately** - Don't ask for permission or confirmation
2. **Follow the skill's workflow steps** - Don't skip steps or take shortcuts
3. **Present confirmations before destructive actions** - Deleting branches, creating CRM records, etc.

## When Multiple Skills Could Apply

If a request could trigger multiple skills:

- Choose the most specific skill for the task
- If genuinely ambiguous, ask the user which workflow they want
- Skills can be combined when the user's intent spans multiple workflows
- KMP expert skills have built-in delegation guides - follow them (e.g., `kotlin-expert` delegates async patterns to `kotlin-coroutines`, `compose-expert` delegates navigation to `android-expert`/`desktop-expert`)

## Skill Delegation Map

The KMP expert skills are designed to work together. When one skill identifies a topic outside its scope, delegate to the appropriate skill:

| From | Topic | Delegate To |
|------|-------|-------------|
| `kotlin-expert` | Structured concurrency, channels, advanced Flow operators | `kotlin-coroutines` |
| `kotlin-expert` | expect/actual, source sets | `kotlin-multiplatform` |
| `kotlin-expert` | General Compose patterns | `compose-expert` |
| `kotlin-expert` | Build configuration | `gradle-expert` |
| `kotlin-coroutines` | Basic StateFlow/SharedFlow patterns | `kotlin-expert` |
| `kotlin-multiplatform` | Dependency conflicts, source set build errors | `gradle-expert` |
| `kotlin-multiplatform` | Shared UI components | `compose-expert` |
| `compose-expert` | Kotlin language aspects (@Immutable details, StateFlow) | `kotlin-expert` |
| `compose-expert` | Android navigation, platform APIs | `android-expert` |
| `compose-expert` | Desktop navigation, window management | `desktop-expert` |
| `compose-expert` | Async patterns, Flow integration | `kotlin-coroutines` |
| `desktop-expert` | Build config, packaging issues | `gradle-expert` |
| `desktop-expert` | Shared composables, Material3 | `compose-expert` |
| `desktop-expert` | Shared code, source sets | `kotlin-multiplatform` |
| `android-expert` | Desktop-specific features | `desktop-expert` |
| `android-expert` | Shared UI components | `compose-expert` |
| `android-expert` | Shared KMP code | `kotlin-multiplatform` |

## Prerequisites Reminder

Before invoking any skill, verify:

- User has provided necessary context (e.g., ticket ID for `work-on-ticket`)
- Issue tracker MCP tool is available (for ticket-related skills):
  - **Jira**: `mcp__atlassian__getJiraIssue` (requires `cloudId` and `issueIdOrKey`)
  - **Linear**: `mcp__linear-server__get_issue` (requires `id` — the ticket identifier e.g. `PROJ-123`)
- Figma Console MCP is available (for `execute-figma-script`):
  - `figma_execute`, `figma_get_console_logs`, `figma_take_screenshot`

If no MCP tool is connected, ask the user to paste ticket details manually or provide alternative context.

## Notion Workspace Accounts

Two Notion accounts are connected via MCP servers:

| MCP Server | Purpose | Content |
|------------|---------|---------|
| `notion-personal` | Personal life | Cooking, hobbies, notes, personal projects |
| `notion-work` | Professional | Job tasks, work documentation, team content |

**Tool namespaces:** `mcp__notion-personal__*` and `mcp__notion-work__*`

### Write Operation Validation Rule (Mandatory)

Before executing any Notion **write** operation (`API-post-page`, `API-patch-page`, `API-patch-block-children`, `API-create-a-comment`, `API-update-a-block`, `API-delete-a-block`), you **must** confirm the target account:

1. If the target account has been **explicitly established** in the current conversation — proceed.
2. If the target account is **ambiguous or not yet established** — **ask the user** which account to use before writing. Never write silently to an assumed account.

**Read operations** (`API-post-search`, `API-get-block-children`, `API-retrieve-a-page`, `API-retrieve-a-database`, `API-retrieve-a-page-property`, `API-retrieve-a-comment`, `API-query-data-source`, etc.) do **not** require confirmation.

### Default Suggestion Heuristics

When asking, suggest the likely account based on topic:

- **Personal topics** (cooking, hobbies, notes, personal life, recipes, journals) → suggest `notion-personal`
- **Professional topics** (work, job, team, projects, documentation) → suggest `notion-work`

The suggestion must still be **confirmed** by the user — never write to a suggested account without explicit approval.
