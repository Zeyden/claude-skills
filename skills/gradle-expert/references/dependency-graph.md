# Dependency Graph

Module dependencies and source set hierarchy for KMP projects.

## Standard Module Structure

```
:app (Android) ──────┐
                     ├──→ :shared (KMP)
:composeApp (Desktop)┘
```

**Dependency flow:** Platform apps → Shared module. Never the reverse.

## Source Set Hierarchy (shared module)

```
commonMain
    ├── androidMain
    ├── jvmMain
    └── iosMain
```

## Dependency Config Types

| Config | When to Use | Example |
|--------|------------|---------|
| `api` | Types appear in public API | Exposed domain models |
| `implementation` | Internal details only | HTTP client, JSON parser |
| `compileOnly` | Compile-time annotations | @Immutable |
| `runtimeOnly` | Runtime-only | JDBC drivers |

## Example Configuration

```kotlin
// shared/build.gradle.kts
sourceSets {
    commonMain {
        dependencies {
            implementation(libs.kotlinx.coroutines)
            implementation(libs.kotlinx.serialization)
            api(libs.kotlinx.datetime)  // Exposed in public API
        }
    }
    androidMain {
        dependencies {
            implementation(libs.ktor.client.android)
        }
    }
    jvmMain {
        dependencies {
            implementation(libs.ktor.client.cio)
            implementation(compose.desktop.currentOs)
        }
    }
}
```

## Transitive Dependencies

Dependencies in `:shared` are transitively available to `:app` and `:composeApp` when using `api`.

```
:app → :shared(api: kotlinx-datetime) → kotlinx-datetime available in :app
:app → :shared(impl: ktor) → ktor NOT available in :app
```
