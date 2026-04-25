# Personal Configuration Rules

## Configuration Scope Rule

**All configuration changes are ALWAYS at the user level** (`~/.claude/`). This applies to:
- MCP servers (added to `~/.claude.json`)
- Skills (delivered via plugins from the `zeyden` marketplace)
- Agents (delivered via plugins from the `zeyden` marketplace)
- `settings.json` permissions (allow/deny/ask lists)
- `CLAUDE.md` instructions
- Any references, configs, or allow lists related to the above

Never modify project-level files (`.claude/`, `.mcp.json`, etc.) for these unless explicitly told otherwise.

## GitLab CLI

Use `glab` CLI for all GitLab operations (MRs, issues, pipelines, CI, etc.) instead of API calls or web URLs.

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

**Read operations** do not require confirmation.

### Default Suggestion Heuristics

When asking, suggest the likely account based on topic:

- **Personal topics** (cooking, hobbies, notes, personal life, recipes, journals) → suggest `notion-personal`
- **Professional topics** (work, job, team, projects, documentation) → suggest `notion-work`

The suggestion must still be **confirmed** by the user — never write to a suggested account without explicit approval.

## Tabby Working Directory in Obsidian

All substantial written artefacts produced during Tabby product work sessions — plans, architecture documents, requirement analyses, research notes, etc. — **must** be placed in the Obsidian vault under `Tabby/`.

**Folder distinction**:
- `Tabby/` — Tabby product tasks (features, bugs, backend work)
- `Claude Code/` — Claude Code tool work (skills, agents, plugins, templates)
- `Products/` — Personal pet projects unrelated to Tabby (e.g. `Products/subtitler`)

### Rules

1. **Create a task folder** — When starting work on a task that will produce written artefacts, create a subfolder inside the appropriate root folder (`Tabby/`, `Claude Code/`, or `Products/`) named after the task in natural language (e.g. `Super Button`, `iOS Developer Agent`, `Auth Middleware Rewrite`). Use the task's human-readable name, not a ticket ID.
2. **Place all artefacts inside that folder** — Implementation plans, architecture docs, requirement analyses, design notes, skeleton files, research summaries — everything goes into the task folder as separate Obsidian notes.
3. **Use the `obsidian` skill** for all file creation — create notes via `obsidian create vault=Obsidian path="Tabby/<Folder>/<Note>.md" content='...'`. This ensures the notes appear in Obsidian with proper sync.
4. **Naming** — Use natural language titles with spaces for both folders and files (e.g. `Implementation Plan.md`, `Architecture.md`, `Requirements.md`). Follow vault conventions.
5. **Evolve the folder** — As the conversation progresses and new artefacts are needed (documentation, additional plans, diagrams), add them to the same task folder.
6. **When to create** — Create working directories for: plan-mode outputs, multi-file agent/skill designs, architecture discussions, requirement analyses, research summaries, and any other substantial written work. Do NOT create folders for quick one-off answers or simple vault edits.

### Examples

| Task | Folder | Possible files |
|------|--------|---------------|
| Ticket "Add a super button" → plan mode | `Tabby/Super Button/` | `Implementation Plan.md`, `Architecture.md`, `Requirements.md` |
| Designing an iOS developer agent + skills | `Claude Code/iOS Developer Agent/` | `Agent Skeleton.md`, `SwiftUI Skill.md`, `Swift Skill.md` |
| Researching auth middleware rewrite | `Tabby/Auth Middleware Rewrite/` | `Research.md`, `Migration Plan.md` |
| Personal project subtitler | `Products/subtitler/` | `Architecture.md`, `Research.md` |

## Skill & Agent Delivery

Skills, agents, and the `check-mr.sh` script are delivered via plugins from the **`zeyden`** marketplace (this repo). Auto-invocation is driven by each skill's `SKILL.md` frontmatter description — there is no central trigger table here. Cross-skill delegation is documented inside each skill's own `SKILL.md` (e.g. `compose-expert` documents when it delegates to `kotlin-expert`).

To install or update plugins on a fresh machine, see this repo's `README.md`.
