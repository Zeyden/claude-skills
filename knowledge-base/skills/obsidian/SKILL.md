---
name: obsidian
description: "Obsidian vault operations via the official CLI. Reading, searching, creating/updating notes, tasks, tags, properties, and templates. Default vault: Obsidian. Use when working with Obsidian vaults, notes, daily notes, tasks, tags, properties, templates, or vault structure."
allowed-tools: Bash(obsidian read*), Bash(obsidian search*), Bash(obsidian tags*), Bash(obsidian tag *), Bash(obsidian tasks*), Bash(obsidian properties*), Bash(obsidian property:read*), Bash(obsidian vault*), Bash(obsidian vaults*), Bash(obsidian files*), Bash(obsidian folders*), Bash(obsidian folder *), Bash(obsidian file *), Bash(obsidian backlinks*), Bash(obsidian links*), Bash(obsidian outline*), Bash(obsidian bookmarks*), Bash(obsidian deadends*), Bash(obsidian orphans*), Bash(obsidian wordcount*), Bash(obsidian diff*), Bash(obsidian history*), Bash(obsidian daily:read*), Bash(obsidian daily:path*), Bash(obsidian base:query*), Bash(obsidian base:views*), Bash(obsidian bases*), Bash(obsidian recents*), Bash(obsidian aliases*), Bash(obsidian unresolved*), Bash(obsidian sync:status*), Bash(obsidian sync:history*), Bash(obsidian template:read*), Bash(obsidian templates*), Bash(obsidian random:read*), Bash(obsidian search:context*), Bash(obsidian open*)
---

# Obsidian CLI — Vault Operations

## When to Use This Skill

Activate when:
- User mentions Obsidian, vault, daily note, or note-taking
- User asks to read, search, create, or update notes in a vault
- User references Obsidian CLI commands

## Default Vault

Always use `vault=Obsidian` unless the user explicitly specifies a different vault. If the user says they want to work in a different vault, switch and continue using that vault for the session.

## Vault Structure

```
Obsidian/
├── Attachments/    — Images, PDFs, embedded files
├── Personal/       — Personal notes, journals, reflections
├── Templates/      — Note templates
├── Daily/          — Daily notes
└── Products/       — Product-related notes, specs, documentation
```

If the provided folders are not sufficient for the task, discover additional structure:
```bash
obsidian folders vault=Obsidian
```

See `references/vault-conventions.md` for tag taxonomy, frontmatter properties, template names, and naming conventions.

## CLI Basics

**Targeting:**
- `vault=Obsidian` — target the default vault (always include unless told otherwise)
- `file=<name>` — resolves by name using wikilink resolution (no path or extension needed)
- `path=<path>` — exact path from vault root (e.g., `Personal/my-note.md`)

**Content formatting:**
- Use `\n` for newline and `\t` for tab in content values
- Always use **single quotes** for `content=` values: `content='Hello world'`. Double quotes cause shell expansion issues with backticks, special characters, and markdown.

**Output formats:**
- Many commands support `format=json|tsv|csv` (default: text/tsv)
- Use `format=json` when output needs programmatic parsing

**Stderr noise:**
- The CLI may emit `Loading updated app package...` or installer warnings on stderr
- Append `2>/dev/null` when parsing output programmatically

## Read Operations Reference

### File Content
```bash
obsidian read vault=Obsidian                          # Read active file
obsidian read vault=Obsidian file=<name>              # Read by name
obsidian read vault=Obsidian path=<path>              # Read by exact path
```

### Search
```bash
obsidian search vault=Obsidian query="meeting notes"
obsidian search:context vault=Obsidian query="meeting notes"   # With surrounding context
```

### Vault Structure
```bash
obsidian vault vault=Obsidian                         # Vault info (name, path, files, size)
obsidian vault vault=Obsidian info=files               # File count only
obsidian files vault=Obsidian                          # List all files
obsidian files vault=Obsidian path=Personal            # Files in a folder
obsidian folders vault=Obsidian                        # List all folders
obsidian file vault=Obsidian file=<name>               # File info
```

### Navigation & Links
```bash
obsidian backlinks vault=Obsidian file=<name>          # What links to this file
obsidian links vault=Obsidian file=<name>              # What this file links to
obsidian outline vault=Obsidian file=<name>            # Heading structure
obsidian deadends vault=Obsidian                       # Files with no outgoing links
obsidian orphans vault=Obsidian                        # Files with no incoming links
obsidian unresolved vault=Obsidian                     # Broken/unresolved links
```

### Metadata
```bash
obsidian tags vault=Obsidian                           # All tags
obsidian tags vault=Obsidian counts                    # Tags with counts
obsidian tag vault=Obsidian name=<tag>                 # Tag info
obsidian tag vault=Obsidian name=<tag> verbose         # Tag with file list
obsidian properties vault=Obsidian                     # All properties
obsidian properties vault=Obsidian file=<name>         # Properties for a file
obsidian property:read vault=Obsidian name=<prop>      # Specific property
obsidian aliases vault=Obsidian                        # All aliases
obsidian wordcount vault=Obsidian file=<name>          # Word count
```

### Tasks
```bash
obsidian tasks vault=Obsidian                          # All tasks
obsidian tasks vault=Obsidian todo                     # Incomplete tasks only
obsidian tasks vault=Obsidian done                     # Completed tasks only
obsidian tasks vault=Obsidian daily                    # Tasks from daily note
obsidian tasks vault=Obsidian verbose                  # Grouped by file with line numbers
obsidian tasks vault=Obsidian file=<name>              # Tasks in a specific file
obsidian tasks vault=Obsidian format=json              # JSON output
```

### Daily Notes
```bash
obsidian daily:read vault=Obsidian                     # Read today's daily note
obsidian daily:path vault=Obsidian                     # Path to today's daily note
```

### History & Versions
```bash
obsidian diff vault=Obsidian file=<name> from=1 to=3   # Compare versions
obsidian history vault=Obsidian file=<name>             # File history
obsidian history:list vault=Obsidian file=<name>        # List history entries
obsidian history:read vault=Obsidian file=<name>        # Read historical version
```

### Templates
```bash
obsidian templates vault=Obsidian                      # List available templates
obsidian template:read vault=Obsidian name=<template>  # Read a template
```

### Bases (Databases)
```bash
obsidian bases vault=Obsidian                          # List bases
obsidian base:views vault=Obsidian                     # List base views
obsidian base:query vault=Obsidian                     # Query a base
```

### Other
```bash
obsidian bookmarks vault=Obsidian                      # Bookmarked files
obsidian recents vault=Obsidian                        # Recently opened files
obsidian sync:status vault=Obsidian                    # Sync status
obsidian sync:history vault=Obsidian                   # Sync history
obsidian random:read vault=Obsidian                    # Read a random note
```

## Note Title Rule: Never Duplicate the Filename as H1

Never start a note with `# <note-name>` or `# <date>` — Obsidian already shows the filename as the title. Start content directly with the first meaningful heading or body text. H1 headings are fine for top-level content sections within the note.

## Post-Write Rule: Always Open the Modified File

After any write operation (create, overwrite, append, prepend, property change, task toggle, delete), always open the modified file in Obsidian immediately afterwards — unless it was a deletion:

```bash
obsidian open vault=Obsidian path="<path-to-modified-file>"
```

Do this even if the user did not explicitly ask. The file should be visible in Obsidian as soon as the change is made.

## Write Operations Reference

**All write operations require user approval before execution.**

### Create Notes
```bash
obsidian create vault=Obsidian name="Note Title" content='# Title\n\nBody text'
obsidian create vault=Obsidian name="Trip to Paris" template=Travel
obsidian create vault=Obsidian name="Note" content='Hello' open         # Create and open
obsidian create vault=Obsidian name="Note" content='Hello' overwrite    # Overwrite if exists
```

### Append / Prepend
```bash
obsidian append vault=Obsidian file=<name> content='New content at the end'
obsidian prepend vault=Obsidian file=<name> content='New content at the start'
```

### Daily Note Operations
```bash
obsidian daily:append vault=Obsidian content='- [ ] Buy groceries'
obsidian daily:prepend vault=Obsidian content='## Morning\n\nToday''s priorities:'
```

### Task Management
```bash
obsidian task vault=Obsidian file=<name> line=<n> toggle    # Toggle task status
obsidian task vault=Obsidian file=<name> line=<n> done      # Mark as done
obsidian task vault=Obsidian file=<name> line=<n> todo      # Mark as todo
obsidian task vault=Obsidian file=<name> line=<n> status="x"  # Set custom status
obsidian task vault=Obsidian ref=<path:line> toggle         # Toggle by reference
obsidian task vault=Obsidian daily done                     # Mark daily task as done
```

### Properties
```bash
obsidian property:set vault=Obsidian file=<name> name=<prop> value=<val>
obsidian property:remove vault=Obsidian file=<name> name=<prop>
```

### File Management
```bash
obsidian move vault=Obsidian file=<name> to=<path>
obsidian rename vault=Obsidian file=<name> name=<newname>
obsidian delete vault=Obsidian file=<name>
```

### Bookmarks & Bases
```bash
obsidian bookmark vault=Obsidian file=<path>
obsidian base:create vault=Obsidian
```

## Common Workflows

### Read a note and its context
```bash
obsidian read vault=Obsidian file="Project Spec"
obsidian backlinks vault=Obsidian file="Project Spec"
obsidian properties vault=Obsidian file="Project Spec"
```

### Search and explore
```bash
obsidian search vault=Obsidian query="authentication"
obsidian search:context vault=Obsidian query="authentication"
obsidian tags vault=Obsidian counts
```

### Append to daily note
```bash
obsidian daily:read vault=Obsidian                    # See current content first
obsidian daily:append vault=Obsidian content="- [ ] Review PR #42"
```

### Create note from template
```bash
obsidian templates vault=Obsidian                     # List templates
obsidian template:read vault=Obsidian name=Meeting    # Preview template
obsidian create vault=Obsidian name="Sprint Planning 2026-04-01" template=Meeting
```

## Related Skills

- **`mermaid`** — Comprehensive Mermaid diagram syntax for creating diagrams in Obsidian notes. Delegate to this skill when the user asks to create, edit, or fix Mermaid diagrams, or wants to visualise information as a diagram. Covers all diagram types (flowchart, sequence, class, state, ER, gantt, mindmap, etc.), styling, theming, and Obsidian-specific integration.

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Vault not found | Obsidian app not running or vault not registered | Check `obsidian vaults verbose` |
| File not found | Name doesn't match any file | Try `obsidian search vault=Obsidian query="<partial name>"` |
| No active file | No file open in Obsidian | Specify `file=` or `path=` explicitly |
| Stderr warnings | Outdated installer | Append `2>/dev/null` to suppress |
