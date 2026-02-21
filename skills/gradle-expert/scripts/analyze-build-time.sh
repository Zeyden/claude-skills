#!/bin/bash
# Profile Gradle build performance and generate optimization report

set -e

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "=== Build Time Analysis ==="
echo

echo "Running profiled build..."
./gradlew clean build --profile 2>&1 | tail -5

REPORT=$(find build/reports/profile -name "profile-*.html" -type f | sort | tail -1)

if [ -n "$REPORT" ]; then
    echo
    echo "Profile report: $REPORT"
    echo "Open in browser: file://$(pwd)/$REPORT"
else
    echo "No profile report found. Run: ./gradlew clean build --profile"
fi

echo
echo "=== Quick Optimization Checklist ==="
echo

# Check gradle.properties
if [ -f "gradle.properties" ]; then
    echo "Checking gradle.properties..."
    for prop in "org.gradle.daemon=true" "org.gradle.parallel=true" "org.gradle.caching=true" "kotlin.incremental=true"; do
        key=$(echo "$prop" | cut -d= -f1)
        if grep -q "$key" gradle.properties 2>/dev/null; then
            echo "  OK: $key is set"
        else
            echo "  MISSING: Add $prop to gradle.properties"
        fi
    done
else
    echo "WARNING: No gradle.properties found. Create one with optimization settings."
fi

echo
echo "Done. Review the HTML profile report for detailed analysis."
