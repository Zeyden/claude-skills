#!/bin/bash
# Validates KMP source set structure and detects common issues

set -e

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "=== Validating KMP Structure ==="
echo

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ISSUES_FOUND=0

# Check 1: Platform code in commonMain (Android imports)
echo "Checking for platform code in commonMain..."
android_imports_in_common=$(find */src/commonMain -name "*.kt" 2>/dev/null | xargs grep -l "^import android\." 2>/dev/null || true)
if [ -n "$android_imports_in_common" ]; then
    echo -e "${RED}!${NC} Found Android imports in commonMain:"
    echo "$android_imports_in_common" | sed 's/^/  /'
    echo "  Fix: Move to androidMain or create expect/actual"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}OK${NC} No Android imports in commonMain"
fi

# Check 2: JVM libraries in commonMain
echo
echo "Checking for JVM libraries in commonMain..."
jvm_imports_in_common=$(find */src/commonMain -name "*.kt" 2>/dev/null | xargs grep -l "^import com.fasterxml.jackson\|^import okhttp3\." 2>/dev/null || true)
if [ -n "$jvm_imports_in_common" ]; then
    echo -e "${RED}!${NC} Found JVM library imports in commonMain:"
    echo "$jvm_imports_in_common" | sed 's/^/  /'
    echo "  Fix: Move to jvmAndroid source set or migrate to kotlinx.serialization/ktor"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}OK${NC} No JVM library imports in commonMain"
fi

# Check 3: Unmatched expect/actual declarations
echo
echo "Checking expect/actual pairs..."
expect_files=$(find */src/commonMain -name "*.kt" 2>/dev/null | xargs grep -l "^expect " 2>/dev/null || true)
if [ -n "$expect_files" ]; then
    for file in $expect_files; do
        expects=$(grep "^expect \(class\|object\|fun\|interface\)" "$file" 2>/dev/null | sed 's/expect //' | awk '{print $2}' | sed 's/[({].*$//')
        for expect_name in $expects; do
            actual_count=0
            for platform in androidMain jvmMain iosMain; do
                platform_dir=$(dirname "$file" | sed "s/commonMain/$platform/")
                if [ -d "$platform_dir" ]; then
                    if find "$platform_dir" -name "*.kt" -exec grep -l "actual.*$expect_name" {} \; 2>/dev/null | grep -q .; then
                        actual_count=$((actual_count + 1))
                    fi
                fi
            done
            if [ "$actual_count" -eq 0 ]; then
                echo -e "${YELLOW}?${NC} No actual implementations found for: $expect_name in $file"
                ISSUES_FOUND=$((ISSUES_FOUND + 1))
            fi
        done
    done
else
    echo -e "${GREEN}OK${NC} No expect declarations to validate"
fi

# Summary
echo
echo "=== Summary ==="
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
else
    echo -e "${RED}Found $ISSUES_FOUND issue(s)${NC}"
    echo "  1. Platform code in commonMain -> Move to platform source set or create expect/actual"
    echo "  2. JVM libraries in commonMain -> Move to jvmAndroid or migrate to kotlinx.*"
    echo "  3. Missing actual implementations -> Implement in all target platforms"
    exit 1
fi
