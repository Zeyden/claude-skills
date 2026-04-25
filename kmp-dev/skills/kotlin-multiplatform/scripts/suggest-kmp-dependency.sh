#!/bin/bash
# Suggests KMP library alternatives for JVM-specific dependencies

set -e

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "=== KMP Dependency Suggestions ==="
echo

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

SUGGESTIONS_FOUND=0

# Check for Jackson
echo "Checking for Jackson JSON..."
if grep -r "jackson" */build.gradle.kts 2>/dev/null | grep -q "implementation\|api"; then
    echo -e "${YELLOW}!${NC} Found Jackson dependency (JVM-only)"
    echo "  Suggest: kotlinx.serialization (works on all platforms)"
    SUGGESTIONS_FOUND=$((SUGGESTIONS_FOUND + 1))
else
    echo -e "${GREEN}OK${NC} Not using Jackson"
fi

# Check for OkHttp
echo
echo "Checking for OkHttp..."
if grep -r "okhttp" */build.gradle.kts 2>/dev/null | grep -q "implementation\|api"; then
    echo -e "${YELLOW}!${NC} Found OkHttp dependency (JVM-only)"
    echo "  Suggest: ktor-client (works on all platforms)"
    SUGGESTIONS_FOUND=$((SUGGESTIONS_FOUND + 1))
else
    echo -e "${GREEN}OK${NC} Not using OkHttp"
fi

# Check for java.time
echo
echo "Checking for java.time usage..."
if find */src -name "*.kt" 2>/dev/null | xargs grep -l "import java.time\." >/dev/null 2>&1; then
    echo -e "${YELLOW}!${NC} Found java.time imports (JVM-only)"
    echo "  Suggest: kotlinx.datetime (works on all platforms)"
    SUGGESTIONS_FOUND=$((SUGGESTIONS_FOUND + 1))
else
    echo -e "${GREEN}OK${NC} Not using java.time"
fi

# Summary
echo
echo "=== Summary ==="
if [ "$SUGGESTIONS_FOUND" -eq 0 ]; then
    echo -e "${GREEN}No JVM-specific dependencies found! Ready for all targets.${NC}"
else
    echo -e "${YELLOW}Found $SUGGESTIONS_FOUND suggestion(s) for KMP alternatives${NC}"
    echo "  Priority: Jackson -> kotlinx.serialization, OkHttp -> ktor-client, java.time -> kotlinx.datetime"
fi

exit 0
