#!/bin/bash
# Silent MR monitor — outputs only when something changes
# Usage: check-mr.sh <MR_NUMBER> <REPO>
# Example: check-mr.sh 158 gitlab.com/tabby.ai/services/clc-widgets

VERBOSE=false
while [[ "$1" == --* ]]; do
  case "$1" in
    --verbose|-v) VERBOSE=true; shift ;;
    *) shift ;;
  esac
done

MR="${1:?Usage: check-mr.sh [--verbose] <MR_NUMBER> <REPO>}"
REPO="${2:?Usage: check-mr.sh [--verbose] <MR_NUMBER> <REPO>}"

STATE_FILE="/tmp/mr_${MR}_state"

# Fetch current state
CURRENT=$(glab mr view "$MR" --repo "$REPO" --output json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
p = d.get('head_pipeline', {})
print(d.get('state'), p.get('id'), p.get('status'))
" 2>/dev/null)

# Count unresolved discussion threads via API
PROJECT_PATH=$(echo "$REPO" | sed 's|gitlab.com/||;s|/|%2F|g')
UNRESOLVED=$(glab api "projects/${PROJECT_PATH}/merge_requests/${MR}/discussions" 2>/dev/null | python3 -c "
import sys,json
discussions=json.load(sys.stdin)
print(sum(1 for d in discussions if any(n.get('resolvable') and not n.get('resolved') for n in d.get('notes',[]))))
" 2>/dev/null)

NOW="${CURRENT} ${UNRESOLVED}"

# Compare with last known state
if [ -f "$STATE_FILE" ]; then
  PREV=$(cat "$STATE_FILE")
else
  PREV=""
fi

echo "$NOW" > "$STATE_FILE"

if [ "$NOW" = "$PREV" ]; then
  if [ "$VERBOSE" = true ]; then
    MR_STATE=$(echo "$CURRENT" | awk '{print $1}')
    PIPELINE_ID=$(echo "$CURRENT" | awk '{print $2}')
    PIPELINE_STATUS=$(echo "$CURRENT" | awk '{print $3}')
    echo "MR !${MR} — no change | state: $MR_STATE | pipeline: $PIPELINE_ID ($PIPELINE_STATUS) | unresolved threads: $UNRESOLVED"
  fi
  exit 0
fi

# Something changed — output details
MR_STATE=$(echo "$CURRENT" | awk '{print $1}')
PIPELINE_ID=$(echo "$CURRENT" | awk '{print $2}')
PIPELINE_STATUS=$(echo "$CURRENT" | awk '{print $3}')

# Extract project ID from repo for API calls
PROJECT_ID=$(glab api "projects/${PROJECT_PATH}" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

echo "MR !${MR} changed → state: $MR_STATE | pipeline: $PIPELINE_ID ($PIPELINE_STATUS) | unresolved threads: $UNRESOLVED"

if [ "$MR_STATE" = "merged" ] || [ "$MR_STATE" = "closed" ]; then
  echo "STOP: MR is $MR_STATE — delete the cron job"
  exit 0
fi

if [ "$PIPELINE_STATUS" = "failed" ] && [ -n "$PROJECT_ID" ]; then
  echo "--- Failed jobs ---"
  glab api "projects/${PROJECT_ID}/pipelines/${PIPELINE_ID}/jobs" 2>/dev/null | python3 -c "
import sys,json
jobs=json.load(sys.stdin)
for j in jobs:
    if j['status'] == 'failed':
        print(f\"  {j['name']} — {j.get('failure_reason','unknown')}\")
" 2>/dev/null
fi

if [ "$PIPELINE_STATUS" = "success" ]; then
  echo "Pipeline green! Check approvals on the MR web UI."
fi
