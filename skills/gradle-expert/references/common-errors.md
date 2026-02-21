# Common Build Errors

Troubleshooting guide for frequent KMP build issues.

## Compose Version Mismatch
**Symptom:** `IllegalStateException: Version mismatch: runtime X but compiler Y`
**Fix:** Update Compose Multiplatform version in libs.versions.toml to match Kotlin. Check compatibility matrix.

## Duplicate Class
**Symptom:** `Duplicate class found in modules`
**Diagnosis:** `./gradlew dependencyInsight --dependency <library>`
**Fix:** Align versions in libs.versions.toml or force resolution:
```kotlin
configurations.all { resolutionStrategy { force(libs.okhttp.get().toString()) } }
```

## Unresolved Reference to JVM Library
**Symptom:** `Unresolved reference` for JVM-only library in shared code
**Fix:** Move dependency to platform-specific source set (androidMain/jvmMain), not commonMain.

## Wrong JVM Target
**Symptom:** `Unsupported class file major version 65`
**Fix:** Ensure Java 21 everywhere:
```bash
java -version  # Should show 21
./gradlew --stop  # Restart daemon after changing JAVA_HOME
```

## Main Class Not Found (Desktop)
**Symptom:** Desktop app can't find main class
**Fix:** Verify `mainClass = "com.example.app.desktop.MainKt"` (Kotlin adds `Kt` suffix)

## Native Library Missing (Desktop)
**Symptom:** `UnsatisfiedLinkError: no <lib> in java.library.path`
**Fix:** Check platform-specific native library dependency is correct variant for jvmMain.

## Proguard Stripping Classes
**Symptom:** `NoClassDefFoundError` in release builds
**Fix:** Add keep rules in proguard-rules.pro:
```proguard
-keep class com.example.shared.model.** { *; }
-keepattributes *Annotation*, Signature
```

## Configuration Cache Issues
**Symptom:** `Configuration cache state could not be cached`
**Fix:** Disable temporarily: `org.gradle.configuration-cache=false`, fix incompatible plugins.

## Source Set Not Found
**Symptom:** `Could not find source set 'jvmAndroid'`
**Fix:** Custom source sets must be defined BEFORE they're referenced by other source sets.
