#!/bin/bash
# Find all @Composable functions in the codebase

set -e

PROJECT_ROOT="${1:-.}"

echo "=== @Composable Functions ==="
echo

# Search in shared module
echo "--- shared/src/commonMain ---"
find "$PROJECT_ROOT"/shared/src/commonMain -name "*.kt" 2>/dev/null | xargs grep -h "@Composable" 2>/dev/null | grep "fun " | sed 's/.*fun //' | sed 's/(.*$//' | sort -u || echo "(none found)"

echo
echo "--- app/src/main ---"
find "$PROJECT_ROOT"/app/src/main -name "*.kt" 2>/dev/null | xargs grep -h "@Composable" 2>/dev/null | grep "fun " | sed 's/.*fun //' | sed 's/(.*$//' | sort -u || echo "(none found)"

echo
echo "--- composeApp/src/jvmMain ---"
find "$PROJECT_ROOT"/composeApp/src/jvmMain -name "*.kt" 2>/dev/null | xargs grep -h "@Composable" 2>/dev/null | grep "fun " | sed 's/.*fun //' | sed 's/(.*$//' | sort -u || echo "(none found)"

echo
TOTAL=$(find "$PROJECT_ROOT" -name "*.kt" 2>/dev/null | xargs grep -l "@Composable" 2>/dev/null | wc -l)
echo "Total files with @Composable: $TOTAL"
