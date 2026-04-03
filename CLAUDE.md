## Configuration Scope Rule

**All configuration changes are ALWAYS at the user level** (`~/.claude/`). This applies to:
- MCP servers (added to `~/.claude.json`)
- Skills (added to `~/.claude/skills/`)
- Agents (added to `~/.claude/agents/`)
- `settings.json` permissions (allow/deny/ask lists)
- `CLAUDE.md` instructions
- Any references, configs, or allow lists related to the above

Never modify project-level files (`.claude/`, `.mcp.json`, etc.) for these unless explicitly told otherwise.

## GitLab CLI

Use `glab` CLI for all GitLab operations (MRs, issues, pipelines, CI, etc.) instead of API calls or web URLs.

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
| "obsidian", "vault", "daily note", Obsidian CLI operations, note-taking vault context | `obsidian` |
| "jira", "jira issue", JQL query, `atlassian.net` link, Jira project management | `jira` |
| "notion", "notion page", "notion database", "workspace", Notion content operations | `notion` |
| "linear", "linear issue", `linear.app` link, Linear project management | `linear` |
| "lokalise", "translation keys", "localisation", "i18n", `lokalise.com` link, translation management | `lokalise` |

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
| Kotlin Notebook (.ipynb), notebook cells, %use directives, @file:DependsOn, USE {} blocks, DataFrame operations, rich output rendering (tables, HTML, images, SVG, LaTeX, Kandy charts), Compose UI rendering (ImageComposeScene), interactive Kotlin documentation, component catalogues in notebooks, design token documentation, prototyping Kotlin code in notebooks | `kotlin-notebook` |
| kotlin-inject, DI setup in Kotlin, Dagger alternatives for KMP, compile-time injection, @Component/@Inject/@Provides, kotlin-inject-anvil, assisted injection, scoping, qualifiers, multi-bindings, KmpComponentCreate, DI framework choice for KMP | `kotlin-inject` |
| SQLDelight setup, .sq files, database drivers (Android/iOS/JVM/JS), migrations (.sqm), ColumnAdapter, custom column types, coroutines-extensions (asFlow, mapToList), reactive queries, SQLite performance, WAL mode, generateAsync | `sqldelight-kmp` |
| BDUI Sanity pages, BDUI widget configuration, BDUI styling (BDUIStyleV1Output), Sanity CMS BDUI pages, widget catalog, enrichment backends, Lokalize keys, BDUI landing pages, JavaScript actions, BDUI widget fields, BDUISupercell, BDUIInformer, BDUIAccordion, BDUIButton, BDUI OpenAPI contracts, Input/Output pattern | `bdui-sanity` |
| Go backend, pkg/log, postgreskit, pubsub/v2, Google pub/sub, AsyncAPI SDK, outbox pattern, otelkit, metrics.yaml, DataDog tracing, tabbycli, Caddy API gateway, ffkit, OpenFeature, auth/casbin, l10nkit, Temporal, pgbouncer, migrations, Tabby Go service, project-template | `tabby-go` |

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
| `kotlin-notebook` | Composable patterns, @Preview, Material3 | `compose-expert` |
| `kotlin-notebook` | Kotlin language patterns in cells | `kotlin-expert` |
| `kotlin-notebook` | Async code, Flow collection in cells | `kotlin-coroutines` |
| `kotlin-notebook` | Dependency coordinates, publishing | `gradle-expert` |
| `kotlin-notebook` | Source set context for imports | `kotlin-multiplatform` |
| `kotlin-notebook` | Desktop-specific component previews | `desktop-expert` |
| `kotlin-notebook` | DI setup for notebook-tested code | `kotlin-inject` |
| `kotlin-notebook` | SQLDelight queries in notebooks | `sqldelight-kmp` |
| `compose-expert` | Component catalogues in notebooks | `kotlin-notebook` |
| `kotlin-expert` | Interactive documentation, prototyping | `kotlin-notebook` |
| `kotlin-inject` | Gradle/KSP build issues, version catalogue | `gradle-expert` |
| `kotlin-inject` | expect/actual source set placement | `kotlin-multiplatform` |
| `kotlin-inject` | Compose function injection UI patterns | `compose-expert` |
| `kotlin-inject` | Android Activity/Fragment/ViewModel lifecycle | `android-expert` |
| `kotlin-multiplatform` | DI setup, component creation for KMP | `kotlin-inject` |
| `kotlin-multiplatform` | SQLDelight setup, .sq files, database layer | `sqldelight-kmp` |
| `gradle-expert` | kotlin-inject KSP configuration | `kotlin-inject` |
| `gradle-expert` | SQLDelight plugin config, dialect dependencies | `sqldelight-kmp` |
| `sqldelight-kmp` | Gradle build errors, version catalogue, dialect deps | `gradle-expert` |
| `sqldelight-kmp` | expect/actual driver factory, source set placement | `kotlin-multiplatform` |
| `sqldelight-kmp` | StateFlow/SharedFlow patterns for ViewModel layer | `kotlin-expert` |
| `sqldelight-kmp` | Advanced Flow operators (flatMapLatest, combine, stateIn) | `kotlin-coroutines` |
| `sqldelight-kmp` | kotlin-inject DI setup for driver factories | `kotlin-inject` |
| `sqldelight-kmp` | Compose UI collecting StateFlow from queries | `compose-expert` |
| `sqldelight-kmp` | Desktop file paths, app data directories | `desktop-expert` |
| `sqldelight-kmp` | Android Context, ViewModel lifecycle | `android-expert` |
| `bdui-sanity` | Go backend handlers, pipeline, preprocessors, postprocessors | `tabby-go` |
| `bdui-sanity` | Compose UI rendering of BDUI widgets | `compose-expert` |
| `tabby-go` | BDUI widget configuration, Sanity CMS | `bdui-sanity` |
| `tabby-go` | Compose UI rendering of BDUI widgets | `compose-expert` |
| `obsidian` | Jira issue context for notes | `jira` |
| `obsidian` | Linear issue context for notes | `linear` |
| `obsidian` | Notion page content for notes | `notion` |
| `jira` | Obsidian vault notes for ticket context | `obsidian` |
| `jira` | Notion documentation for ticket context | `notion` |
| `jira` | Linear issue cross-references | `linear` |
| `linear` | Obsidian vault notes for issue context | `obsidian` |
| `linear` | Notion documentation for issue context | `notion` |
| `linear` | Jira issue cross-references | `jira` |
| `notion` | Jira ticket references in pages | `jira` |
| `notion` | Linear issue references in pages | `linear` |
| `notion` | Obsidian vault content for pages | `obsidian` |
| `lokalise` | Committing downloaded translation files | `git-commit` |
| `lokalise` | Tracking localisation tasks in Jira | `jira` |
| `lokalise` | Tracking localisation tasks in Linear | `linear` |
| `lokalise` | Documenting localisation conventions | `notion` |
| `lokalise` | Noting localisation decisions | `obsidian` |
| `bdui-sanity` | Lokalize key management | `lokalise` |

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

## Content Authoring Agent

The `writer` agent writes and updates content across Obsidian, Jira, Notion, and Linear. It receives context from a planner or researcher, reads freely from all platforms, and asks before any write operation. Related skills: `obsidian`, `jira`, `notion`, `linear`.
