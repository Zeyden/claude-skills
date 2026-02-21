# Version Catalog Guide

Patterns for `gradle/libs.versions.toml`.

## Structure

```toml
[versions]
kotlin = "2.3.0"
composeMultiplatform = "1.10.0"
ktor = "3.3.3"
coroutines = "1.10.2"
serialization = "1.8.1"

[libraries]
kotlinx-coroutines = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-core", version.ref = "coroutines" }
kotlinx-serialization-json = { group = "org.jetbrains.kotlinx", name = "kotlinx-serialization-json", version.ref = "serialization" }
ktor-client-core = { group = "io.ktor", name = "ktor-client-core", version.ref = "ktor" }
ktor-client-android = { group = "io.ktor", name = "ktor-client-android", version.ref = "ktor" }
ktor-client-cio = { group = "io.ktor", name = "ktor-client-cio", version.ref = "ktor" }
ktor-client-darwin = { group = "io.ktor", name = "ktor-client-darwin", version.ref = "ktor" }

[plugins]
kotlinMultiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
composeMultiplatform = { id = "org.jetbrains.compose", version.ref = "composeMultiplatform" }
composeCompiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
```

## Usage in build.gradle.kts

```kotlin
dependencies {
    implementation(libs.kotlinx.coroutines)  // Type-safe, IDE-autocompleted
    implementation(libs.ktor.client.core)
}
```

## Critical Alignments

1. **Kotlin ecosystem:** All Kotlin plugins MUST share same version
2. **Compose:** Check [compatibility matrix](https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-compatibility-and-versioning.html)
3. **Platform variants:** Same version across all platform-specific artifacts

## Best Practices

- Never hardcode versions in build.gradle.kts
- Group related libraries under same version ref
- Use version ranges sparingly (prefer pinned versions)
- Check compatibility matrix when updating Kotlin or Compose
