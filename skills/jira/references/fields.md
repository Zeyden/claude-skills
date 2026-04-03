# Jira — CLC Field IDs

Use these field IDs directly when creating/editing issues. No lookups needed.

## Primary Fields (always use)

| Field | Field ID | Type | Notes |
|-------|----------|------|-------|
| Summary | `summary` | string | |
| Description | `description` | ADF/markdown | |
| Issue Type | `issuetype` | `{ id }` | See issue type IDs below |
| Reporter | `reporter` | `{ accountId }` | |
| Assignee | `assignee` | `{ accountId }` | |
| Developer | `customfield_10035` | `{ accountId }` | |
| QA | `customfield_10400` | `{ accountId }` | |
| Priority | `priority` | `{ id }` | See priority IDs below |
| Story Points | `customfield_10026` | number | |
| Labels | `labels` | string[] | |
| Fix Versions | `fixVersions` | `[{ id }]` | |
| Sprint | `customfield_10020` | `{ id }` | |
| Parent | `parent` | `{ key }` | Epic or parent issue |
| Linked Issues | `issuelinks` | link object | |
| QA Notes | `customfield_10213` | string | |
| Status | `status` | read-only | Use transitions to change |

## Fields we never use in CLC

- Subtasks — CLC never uses subtasks

## Rarely used fields (only set when explicitly asked)

| Field | Field ID |
|-------|----------|
| Story Points QA | `customfield_10102` |
| Dev Story point | `customfield_10164` |
| Actual SP QA | `customfield_10163` |
| MR URL | `customfield_10161` |
| Gitlab project name | `customfield_10165` |
| Gitlab project ID | `customfield_10166` |
| Start date | `customfield_10015` |
| Due date | `duedate` |
| Components | `components` |
| Mobile Platform | `customfield_10279` |
| Feature flag | `customfield_10280` |
| Test to develop reason | `customfield_10249` |

Ignore all other fields unless the user explicitly asks to set them.

## Priority IDs

| Priority | ID |
|----------|----|
| Highest | `1` |
| High | `2` |
| Medium | `3` |
| Low | `4` |
| Lowest | `5` |

## Issue Type IDs

**Platform-specific (primary):**

| Type | ID |
|------|----|
| Android Task | `10516` |
| Android Bug | `10517` |
| iOS Task | `10514` |
| iOS Bug | `10515` |
| BE Task | `10510` |
| BE Bug | `10511` |
| Web Task | `10580` |
| Web Bug | `10584` |

**General:**

| Type | ID | Notes |
|------|----|-------|
| Epic | `10000` | Parent for platform tasks. Assignee is typically the feature-lead. |
| Task | `10002` | General-purpose type when no platform type fits (e.g. spikes, research). Prefix summary with `[SPIKE]` for research tasks. |
| Sub-task | `10003` | Never used in CLC. |
| Sprint Goal | `10072` | |
