# Jira — Team

## Team Members

| Name | Nicknames | Role | Jira Account ID |
|------|-----------|------|-----------------|
| Azat Shamsullin | me, I, Azat | Backend developer | `626676bf52310b0068fece40` |
| Aleksandr Tverdovskiy | Sasha | QA | `712020:43d7db9f-7407-4c79-8953-04b8d0a0bc80` |
| Arsenii Meshcherinov | Ars, Arse, Arsenii | QA | `712020:5a4e10a5-e4e6-4f3a-8b9e-f73335553535` |
| Daniil Matsyutsya | Danya, Daniil | Backend tech lead | `622e46e350cceb007078a0f2` |
| Danila Kostyuk | Danila | Android developer | `62752ac976b8d300687537e8` |
| Evgenii Riadovoi | Jenya, Evgenii | iOS developer | `712020:bf70ae60-906b-4172-9bb7-c323fbc5d6a7` |
| Igor Safiyulin | Igor | Backend developer | `712020:e872fdc4-32b5-48fe-8153-90417af667ef` |

When the user mentions a nickname, resolve to the account ID directly — no lookups needed.

## Field Assignment Rules

**Reporter:** anyone can be reporter on any issue type.

**Assignee (`assignee`) / Developer (`customfield_10035`):**

| Person | Allowed issue types |
|--------|---------------------|
| Azat | Any (BE, Android, iOS, Web, Epic, Task) |
| Daniil, Igor | BE Task, BE Bug, Epic, Task |
| Danila | Android Task, Android Bug, Epic, Task |
| Evgenii | iOS Task, iOS Bug, Epic, Task |
| Sasha, Ars | Not assignee/developer — QA only |

**QA (`customfield_10400`):**

| Person | Can be QA? |
|--------|------------|
| Sasha, Ars | Yes |
| Everyone else | No |

**Epic assignee:** typically the feature-lead who creates the epic.
