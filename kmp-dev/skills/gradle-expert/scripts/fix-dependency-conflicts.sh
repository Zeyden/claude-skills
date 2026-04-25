#!/bin/bash
# Diagnose common dependency conflicts in KMP projects

set -e

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "=== Dependency Conflict Diagnosis ==="
echo

ISSUES=0

# Check for Kotlin version mismatches
echo "Checking Kotlin version consistency..."
KOTLIN_VERSIONS=$(./gradlew buildEnvironment 2>/dev/null | grep "org.jetbrains.kotlin" | grep -oP '\d+\.\d+\.\d+' | sort -u)
VERSION_COUNT=$(echo "$KOTLIN_VERSIONS" | wc -l)
if [ "$VERSION_COUNT" -gt 1 ]; then
    echo "WARNING: Multiple Kotlin versions detected:"
    echo "$KOTLIN_VERSIONS" | sed 's/^/  /'
    ISSUES=$((ISSUES + 1))
else
    echo "OK: Single Kotlin version"
fi

# Check for duplicate classes hint
echo
echo "Checking for potential duplicates..."
./gradlew dependencies 2>/dev/null | grep -i "FAILED\|conflict" | head -5
if [ $? -eq 0 ]; then
    echo "Found potential conflicts above"
    ISSUES=$((ISSUES + 1))
else
    echo "OK: No obvious conflicts in dependency tree"
fi

# Summary
echo
echo "=== Summary ==="
if [ "$ISSUES" -eq 0 ]; then
    echo "No dependency conflicts detected."
else
    echo "Found $ISSUES potential issue(s)."
    echo "  Run: ./gradlew dependencyInsight --dependency <library> for details"
    echo "  Fix: Align versions in gradle/libs.versions.toml"
fi
