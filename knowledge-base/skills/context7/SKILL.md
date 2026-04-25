---
name: context7
description: "Fetch up-to-date library, framework, SDK, API, and CLI documentation via Context7 MCP. Use when the user asks about any external library or technology — even well-known ones — to avoid stale or hallucinated APIs."
allowed-tools: mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Context7 — Live Documentation Lookup

## When to Use This Skill

Activate when:
- User asks about any external library, framework, SDK, API, CLI tool, or cloud service
- User needs API syntax, configuration, version migration, setup instructions, or CLI usage
- User is debugging a library-specific issue
- User asks "how do I …" with a named technology (e.g. React, Supabase, Prisma, Tailwind)
- User explicitly says "use context7" or "check the docs"

**Even for well-known libraries** — training data may not reflect recent changes.

Do **not** activate for:
- General programming concepts (algorithms, data structures, design patterns)
- Refactoring or code review of user's own code
- Writing scripts from scratch with no library questions
- Debugging pure business logic

## Workflow

### Step 1 — Resolve the library ID

Call `mcp__context7__resolve-library-id` with:
- `libraryName`: the library/package name (e.g. "next.js", "supabase", "prisma")
- `query`: the user's actual question — this ranks results by relevance

**Skip this step** if the user already provides a Context7 library ID in `/org/project` or `/org/project/version` format.

Selection criteria when multiple results return:
1. Exact name match
2. Description relevance to the query
3. Higher code snippet count (better documentation coverage)
4. Source reputation: High > Medium > Low > Unknown
5. Higher benchmark score

If no good match after 3 attempts, state this clearly and suggest query refinements.

### Step 2 — Query documentation

Call `mcp__context7__query-docs` with:
- `libraryId`: the exact ID from Step 1 (e.g. `/vercel/next.js`)
- `query`: a **specific, detailed** question — not keywords

### Step 3 — Answer using the docs

Use the returned documentation and code examples to answer. Cite Context7 as the source when presenting API details.

## Best Practices

### Write specific queries
- Good: "How to set up authentication with JWT in Express.js"
- Good: "React useEffect cleanup function examples"
- Bad: "auth"
- Bad: "hooks"

### Version-specific lookups
- If the user mentions a specific version, check `resolve-library-id` results for version-specific IDs (format: `/org/project/vX.Y.Z`)
- Use the version-specific ID in `query-docs` for precise results

### Multiple topics
- If the user's question spans several distinct topics (e.g. routing AND authentication), make separate `query-docs` calls for each topic rather than cramming everything into one query

### Call budget
- Max **3 calls** to `resolve-library-id` per question
- Max **3 calls** to `query-docs` per question
- If you can't find what you need within the budget, use the best result available

### When to prefer Context7 over web search
- Always prefer Context7 for library/framework docs — it returns curated, structured content
- Fall back to web search only if Context7 has no coverage for the library
