#!/bin/bash
# Analyze APK size for optimization opportunities

set -e

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT"

echo "=== APK Size Analysis ==="
echo

# Build release APK
echo "Building release APK..."
./gradlew :app:assembleRelease 2>&1 | tail -3

# Find APK
APK=$(find app/build/outputs/apk -name "*.apk" -type f | sort | tail -1)

if [ -z "$APK" ]; then
    echo "No APK found. Build may have failed."
    exit 1
fi

SIZE=$(du -h "$APK" | cut -f1)
echo
echo "APK: $APK"
echo "Size: $SIZE"

# Check if apkanalyzer is available
if command -v apkanalyzer &> /dev/null; then
    echo
    echo "=== Size Breakdown ==="
    apkanalyzer apk summary "$APK"
    echo
    echo "=== Largest Files ==="
    apkanalyzer files list "$APK" | sort -t$'\t' -k2 -rn | head -20
else
    echo
    echo "Install Android SDK command-line tools for detailed analysis:"
    echo "  apkanalyzer apk summary $APK"
fi

echo
echo "=== Optimization Tips ==="
echo "1. Enable R8: minifyEnabled = true"
echo "2. Enable resource shrinking: shrinkResources = true"
echo "3. Check for unused dependencies"
echo "4. Use WebP instead of PNG for images"
echo "5. Review native libraries (.so files) per ABI"
