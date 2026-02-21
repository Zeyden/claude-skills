# Build Commands

Comprehensive command reference for KMP projects.

## Run Commands
```bash
./gradlew :composeApp:run              # Run desktop app
./gradlew :app:installDebug            # Install Android debug APK
./gradlew :shared:build                # Build shared KMP module
```

## Build Commands
```bash
./gradlew build                        # All modules
./gradlew clean build                  # Clean build
./gradlew :shared:build                # Shared module only
./gradlew :composeApp:build            # Desktop app only
./gradlew :app:assembleDebug           # Android debug APK
./gradlew :app:assembleRelease         # Android release APK
```

## Desktop Packaging
```bash
./gradlew :composeApp:packageDmg       # macOS
./gradlew :composeApp:packageMsi       # Windows
./gradlew :composeApp:packageDeb       # Linux
./gradlew :composeApp:packageDistributable  # Current OS
```

Output: `composeApp/build/compose/binaries/main/{dmg,msi,deb}/`

## Testing
```bash
./gradlew test                         # All tests
./gradlew :shared:allTests             # Shared module (all platforms)
./gradlew :shared:jvmTest              # Shared JVM tests only
./gradlew :app:testDebugUnitTest       # Android unit tests
./gradlew :composeApp:test             # Desktop tests
```

## Analysis
```bash
./gradlew dependencies                 # Full dependency tree
./gradlew :shared:dependencies         # Module-specific dependencies
./gradlew dependencyInsight --dependency <name>  # Find specific library
./gradlew build --scan                 # Online diagnostics
./gradlew clean build --profile        # Performance report
./gradlew --stop                       # Stop all daemons
./gradlew --version                    # Gradle version info
```

## Useful Flags
```bash
--info                                 # Detailed logging
--debug                                # Debug logging
--stacktrace                           # Stack traces on error
--no-daemon                            # Don't use daemon
--refresh-dependencies                 # Force re-download
```
