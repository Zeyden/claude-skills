# Jira — JQL Templates

## My Work

```
# My open issues
project = CLC AND assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC

# My in-progress work
project = CLC AND assignee = currentUser() AND status = Developing

# My issues needing testing
project = CLC AND assignee = currentUser() AND status = "Need testing"
```

## Sprint Queries

```
# Current sprint issues
project = CLC AND sprint in openSprints()

# Current sprint — my issues
project = CLC AND sprint in openSprints() AND assignee = currentUser()

# Unfinished from last sprint
project = CLC AND sprint in closedSprints() AND resolution = Unresolved
```

## Review & QA

```
# Awaiting review
project = CLC AND status = Review

# In testing
project = CLC AND status = Testing

# Ready for release
project = CLC AND status = "Ready for release"

# Blocked issues
project = CLC AND status = Blocked
```

## By Platform

```
# Android issues in current sprint
project = CLC AND sprint in openSprints() AND issuetype in ("Android Task", "Android Bug")

# iOS issues in current sprint
project = CLC AND sprint in openSprints() AND issuetype in ("iOS Task", "iOS Bug")

# Backend issues in current sprint
project = CLC AND sprint in openSprints() AND issuetype in ("BE Task", "BE Bug")

# Web issues in current sprint
project = CLC AND sprint in openSprints() AND issuetype in ("Web Task", "Web Bug")
```
