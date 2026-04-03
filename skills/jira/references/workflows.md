# Jira — Workflows & Conventions

## Issue Statuses

| Status | Category |
|--------|----------|
| To Do | To Do |
| Developing | In Progress |
| Review | In Progress |
| Need testing | In Progress |
| Testing | In Progress |
| Ready for release | In Progress |
| Infosec Approval | In Progress |
| CAB Approval | In Progress |
| Blocked | In Progress |
| Cancelled | Done |
| Done | Done |

## Workflow (main flow)

```
To Do → Developing → Review → Need testing → Testing → Ready for release → Done
```

## Transitions

| From | To |
|------|----|
| To Do | Developing |
| Developing | Review, Need testing |
| Review | Need testing, To Do |
| Need testing | Testing, To Do |
| Testing | Ready for release, Need testing, To Do |
| Ready for release | Infosec Approval, To Do |
| Infosec Approval | CAB Approval, Ready for release |
| CAB Approval | Done |

**Note:** After Ready for release, all tasks go to Infosec Approval. From there, automation moves tasks through CAB Approval → Done automatically.
| Blocked | Any (global, from any status) |
| Cancelled | Any (global, from any status) |

## Issue Types

**Hierarchy:** Initiative → Epic → platform-specific types

**Platform-specific types (primary):**
- Android Task, Android Bug
- iOS Task, iOS Bug
- BE Task, BE Bug
- Web Task, Web Bug

**Other:** Sprint Goal, Security Issues, Sub-task, QA Task (Manual test cases), QA Task (Meeting review test-model)
