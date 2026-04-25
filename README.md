# Zeyden's Claude Code Marketplace

Private Claude Code plugin marketplace. Five themed plugins covering Kotlin Multiplatform development, code-lifecycle workflow, issue trackers, knowledge tools, and Tabby backend.

## Plugins

| Plugin | Contents |
|---|---|
| **kmp-dev** | KMP experts: `kotlin-expert`, `kotlin-coroutines`, `kotlin-multiplatform`, `kotlin-inject`, `kotlin-notebook`, `gradle-expert`, `compose-expert`, `desktop-expert`, `android-expert`, `sqldelight-kmp` |
| **workflow** | Skills: `git-commit`, `code-review`, `work-on-ticket`, `resolve`, `execute-figma-script`. Agents: `developer`, `code-reviewer`, `test-runner`. Script: `check-mr.sh` |
| **issue-tracking** | Skills: `jira`, `linear`, `lokalise`, `bamboohr`. Agent: `writer` |
| **knowledge-base** | Skills: `obsidian`, `notion`, `mermaid`, `context7` |
| **tabby-backend** | Skills: `tabby-go`, `bdui-sanity`. Work-Mac only |

## Bootstrap a fresh Mac

```bash
# 1. Register this marketplace (once)
/plugin marketplace add git@github.com:Zeyden/claude-skills.git

# 2. Install the plugins you want
/plugin install workflow@zeyden
/plugin install knowledge-base@zeyden
/plugin install issue-tracking@zeyden
/plugin install kmp-dev@zeyden
/plugin install tabby-backend@zeyden     # work Mac only
```

## Update

```bash
/plugin update                # all installed plugins
/plugin update kmp-dev@zeyden # one specific plugin
```

## Uninstall

```bash
/plugin uninstall tabby-backend@zeyden
```

## What this repo does NOT install

These remain per-machine and must be set up manually on each Mac:

- **`~/.claude/settings.json`** — env vars, model, permissions, statusline. The `settings.json` at the root of this repo can be copied as a starting point.
- **`~/.claude.json`** — MCP server credentials (Atlassian, Linear, Notion, BambooHR, Lokalise, Context7, etc.). Each Mac authenticates locally.
- **`~/.claude/agent-memory/`** — per-machine agent memory.
- **`~/.claude/keybindings.json`** — per-machine keyboard shortcuts (optional).
- **`~/.claude/CLAUDE.md`** — personal rules. The `CLAUDE.md` at the root of this repo is the synced version; copy or symlink as desired.

## Required MCP servers per plugin

| Plugin | MCP servers expected in `~/.claude.json` |
|---|---|
| kmp-dev | none |
| workflow | atlassian (for `work-on-ticket` / `resolve`) |
| issue-tracking | atlassian, linear, lokalise, bamboohr |
| knowledge-base | notion-personal, notion-work, context7 (obsidian and mermaid use local CLI / no MCP) |
| tabby-backend | none |

## Repo layout

```
.
├── .claude-plugin/marketplace.json    # marketplace catalog
├── kmp-dev/.claude-plugin/plugin.json
├── kmp-dev/skills/...
├── workflow/.claude-plugin/plugin.json
├── workflow/skills/...
├── workflow/agents/...
├── workflow/scripts/check-mr.sh
├── issue-tracking/.claude-plugin/plugin.json
├── issue-tracking/skills/...
├── issue-tracking/agents/writer.md
├── knowledge-base/.claude-plugin/plugin.json
├── knowledge-base/skills/...
├── tabby-backend/.claude-plugin/plugin.json
├── tabby-backend/skills/...
├── settings.json                       # personal sync (not auto-installed)
└── CLAUDE.md                           # personal rules (not auto-installed)
```
