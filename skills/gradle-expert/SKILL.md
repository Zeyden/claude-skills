---
name: gradle-expert
description: Build optimization, dependency resolution, and multi-module KMP troubleshooting. Use when working with: (1) Gradle build files (build.gradle.kts, settings.gradle), (2) Version catalog (libs.versions.toml), (3) Build errors and dependency conflicts, (4) Module dependencies and source sets, (5) Desktop packaging (DMG/MSI/DEB), (6) Build performance optimization, (7) Proguard/R8 configuration, (8) Common KMP + Android Gradle issues (Compose conflicts, native lib variants, source set problems).
---

# Gradle Expert

Build system expertise for KMP multi-module architecture. Focus: practical troubleshooting, dependency resolution, and project-specific optimizations.

## Build Architecture Mental Model

```
┌─────────────┬─────────────┐
│ :app        │ :composeApp │  ← Platform apps (navigation, layouts)
│ (Android)   │  (Desktop)  │
└──────┬──────┴──────┬──────┘
       └──────┬──────┘
              ▼
      ┌─────────────┐
      │  :shared    │           ← KMP shared module
      │(KMP Library)│
      └─────────────┘
```

**Key insight:** Dependencies flow DOWN. Lower modules never depend on upper modules.

## Version Catalog

All dependencies centralized in `gradle/libs.versions.toml`:

```toml
[versions]
kotlin = "2.3.0"
composeMultiplatform = "1.10.0"

[libraries]
kotlinx-coroutines = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-core", version.ref = "coroutines" }

[plugins]
kotlinMultiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
```

**Critical alignments:**
- All Kotlin plugins MUST share same version
- Compose Multiplatform version must be compatible with Kotlin version

See [references/version-catalog-guide.md](references/version-catalog-guide.md).

## Common Build Tasks

```bash
./gradlew :composeApp:run              # Run desktop app
./gradlew :app:installDebug            # Install Android app
./gradlew :shared:build                # Build shared module
./gradlew :composeApp:packageDmg       # macOS package
./gradlew :composeApp:packageMsi       # Windows package
./gradlew :composeApp:packageDeb       # Linux package
./gradlew test                         # All tests
./gradlew dependencies                 # Dependency tree
./gradlew build --scan                 # Online diagnostics
```

See [references/build-commands.md](references/build-commands.md).

## Desktop Packaging

```kotlin
compose.desktop {
    application {
        mainClass = "com.example.app.desktop.MainKt"
        nativeDistributions {
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
            packageName = "MyApp"
            packageVersion = "1.0.0"
            macOS { bundleID = "com.example.app.desktop" }
        }
    }
}
```

## Build Performance

Add to `gradle.properties`:
```properties
org.gradle.daemon=true
org.gradle.jvmargs=-Xmx4g
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=true
kotlin.incremental=true
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Duplicate class` | Version conflict | Align in libs.versions.toml |
| `Unresolved reference` to JVM lib | Wrong source set | Move to platform-specific source set |
| `Compose version mismatch` | Kotlin/Compose incompatible | Check compatibility matrix |
| `Unsupported class file` | Wrong JVM target | Ensure Java 21 everywhere |
| Main class not found | Wrong mainClass | Verify `...MainKt` (Kotlin adds `Kt`) |

See [references/common-errors.md](references/common-errors.md).

## Delegation

- **Source set architecture** → `kotlin-multiplatform`
- **Compose UI issues** → `compose-expert`
- **Desktop features** → `desktop-expert`

## Scripts & References

- `scripts/analyze-build-time.sh` - Profile build performance
- `scripts/fix-dependency-conflicts.sh` - Diagnose dependency conflicts
- `references/build-commands.md` - Comprehensive command reference
- `references/dependency-graph.md` - Module dependency visualization
- `references/version-catalog-guide.md` - Version catalog patterns
- `references/common-errors.md` - Troubleshooting guide
