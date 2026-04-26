---
name: kotlin-multiplatform
description: Platform abstraction decisions and source set placement for KMP projects — deciding what belongs in commonMain vs per-platform source sets (androidMain, jvmMain, iosMain, jsMain, wasmJsMain), `expect/actual` design, hierarchical source sets with intermediate parents (jvmAndroid, native, apple, mobile), and dependency constraints per target. Invoke proactively whenever touching a KMP module's structure — editing `build.gradle.kts` source set blocks, adding or moving an `expect`/`actual` pair, placing a new file under `commonMain` / `androidMain` / `jvmMain` / `iosMain`, adjusting `kotlin { sourceSets { } }`, or deciding whether a utility should be shared. Load this skill when a diff references `expect fun`, `actual fun`, `expect class`, `actual class`, `sourceSets.commonMain`, `dependsOn(...)` between source sets, or when the user asks "should this be shared?" / "where does this go?". Delegates Gradle configuration specifics to gradle-expert, shared Compose UI to compose-expert, and DI component placement to kotlin-inject.
---

# Kotlin Multiplatform — Platform Abstraction Decisions

Expert guidance for KMP architecture: deciding what to share versus keep platform-specific, placing files in the right source set, and designing clean `expect/actual` boundaries.

## When to consult this skill

Before writing or reviewing a change that touches the shape of a KMP module, consult this skill. Treat these cues as triggers:

| Cue in the diff | Section to check |
|-----------------|------------------|
| New file under `commonMain`, `androidMain`, `jvmMain`, `iosMain` | §Source Set Placement |
| `expect fun`, `actual fun`, `expect class`, `actual class` | §expect/actual Mechanics |
| `kotlin { sourceSets { } }` with `dependsOn(...)` | §Hierarchical Source Sets |
| JVM-only library in `commonMain.dependencies { }` | §Pitfalls — wrong source set |
| "Should this be shared?" / "Where does this go?" | §Decision Tree |

## Abstraction Decision Tree

```
Is the code used by 2+ targets?
├─ No  → keep platform-specific (andriodMain / jvmMain / iosMain)
└─ Yes → continue ↓

Is it pure Kotlin (no platform APIs)?
├─ Yes → commonMain
└─ No  → continue ↓

Does the implementation genuinely vary per target?
├─ Varies per target (Android ≠ iOS ≠ Desktop) → expect/actual in commonMain + per-target actuals
├─ Shared across JVM-based targets (Android ≈ Desktop)  → intermediate source set (e.g. jvmAndroid)
├─ Shared across native targets (iOS/macOS/Linux)        → nativeMain (or appleMain for Apple-only)
└─ Too platform-coupled (UI navigation, permissions)    → keep platform-specific

Maintenance cost of the abstraction < duplication cost?
├─ Yes → abstract
└─ No  → duplicate (often the simpler answer until a third caller arrives)
```

## Source Set Model

```
commonMain (pure Kotlin, kotlinx.* only)
    ├── androidMain          # Android SDK (Context, android.*, Activity lifecycle)
    ├── jvmMain              # Desktop JVM (java.*, AWT, Swing, Compose Desktop)
    ├── iosMain              # iOS + Simulator targets (platform.Foundation, UIKit interop)
    │   ├── iosX64Main
    │   ├── iosArm64Main
    │   └── iosSimulatorArm64Main
    ├── jsMain (optional)    # Browser JS
    └── wasmJsMain (optional) # wasm-js
```

### Hierarchical intermediate source sets

Use these when multiple targets share implementation:

| Intermediate | Parents | Children | When to use |
|--------------|---------|----------|-------------|
| `jvmAndroid` | `commonMain` | `androidMain`, `jvmMain` | Share JVM libraries (OkHttp, Jackson) across Android + Desktop without duplicating |
| `appleMain`  | `commonMain` | `iosMain`, `macosMain`, `tvosMain`, `watchosMain` | Share Apple-only code via `platform.*` |
| `nativeMain` | `commonMain` | all native (incl. iOS, linuxX64) | Share native-only code (POSIX, `kotlinx.cinterop`) |
| `mobileMain` | `commonMain` | `androidMain`, `iosMain` | Share mobile-only UX (push, permissions abstractions) |

```kotlin
// build.gradle.kts — define BEFORE default source sets initialise
kotlin {
    applyDefaultHierarchyTemplate()   // enables appleMain, nativeMain, etc.
    sourceSets {
        val jvmAndroid by creating {
            dependsOn(commonMain.get())
            dependencies { api(libs.okhttp) }
        }
        androidMain { dependsOn(jvmAndroid) }
        jvmMain { dependsOn(jvmAndroid) }
    }
}
```

See `references/source-set-hierarchy.md` for the visual and dependency flow.

## What to Abstract vs Keep Platform-Specific

| Code type | Location | Reason |
|-----------|----------|--------|
| Pure Kotlin business logic, models, validation | `commonMain` | Works everywhere |
| Repository interfaces, use cases | `commonMain` | Contracts are platform-agnostic |
| ViewModels (state + logic) | `commonMain` | StateFlow/SharedFlow are KMP-ready |
| Compose UI (cross-platform) | `commonMain` (composeApp shared module) | Compose Multiplatform supports Android + Desktop + iOS |
| Secure storage / keychain / keystore | `expect/actual` | Platform security APIs differ fundamentally |
| Logging | `expect/actual` | `android.util.Log` vs `println` vs `NSLog` |
| HTTP engine factory | `expect/actual` | Ktor engine differs per target |
| SQLDelight driver factory | `expect/actual` | AndroidSqliteDriver vs NativeSqliteDriver vs JdbcSqliteDriver |
| File system paths (data dir, cache dir) | `expect/actual` | No cross-platform concept in commonMain |
| Navigation | Platform-specific | Window vs Activity vs UIViewController paradigms differ |
| Permissions | Platform-specific | APIs are incompatible |

## expect/actual Mechanics

```kotlin
// commonMain — declare the contract
expect object PlatformLogger {
    fun d(tag: String, message: String)
    fun e(tag: String, message: String, throwable: Throwable?)
}

// androidMain
actual object PlatformLogger {
    actual fun d(tag: String, message: String) = android.util.Log.d(tag, message).let { }
    actual fun e(tag: String, message: String, throwable: Throwable?) =
        android.util.Log.e(tag, message, throwable).let { }
}

// jvmMain
actual object PlatformLogger {
    actual fun d(tag: String, message: String) = println("[$tag] $message")
    actual fun e(tag: String, message: String, throwable: Throwable?) {
        System.err.println("[$tag] $message")
        throwable?.printStackTrace(System.err)
    }
}

// iosMain
actual object PlatformLogger {
    actual fun d(tag: String, message: String) = NSLog("[$tag] $message")
    actual fun e(tag: String, message: String, throwable: Throwable?) =
        NSLog("[ERROR][$tag] $message: ${throwable?.stackTraceToString()}")
}
```

Rules:
- Declaration and actuals must match — same name, parameters, nullability, visibility.
- Prefer objects/interfaces/functions over classes where possible — they survive refactors better.
- `typealias` is the cheapest actual when the platform type already matches (e.g. `actual typealias BigDecimal = java.math.BigDecimal` in jvmMain).
- Keep `expect` surfaces minimal; avoid leaking platform types into their signatures.

See `references/expect-actual-catalog.md` for object, class, function and typealias patterns.

## Pitfalls

| Pitfall | Fix |
|---------|-----|
| JVM-only library in `commonMain.dependencies { }` | Move to `jvmMain` (or `jvmAndroid` if shared) |
| `import android.*` in `commonMain` | Move the file or abstract via `expect/actual` |
| `expect` surface leaking platform types (e.g. `Context`) | Wrap the platform type or invert the dependency |
| Forcing navigation into `expect/actual` | Don't — keep per-platform; share only the screen graph data |
| Abstracting "in case a second platform needs it" | Wait for the second call site; duplication is cheap until then |

## Integration with Other Skills

- `gradle-expert` — dependency conflicts, source set wiring errors, KSP placement.
- `compose-expert` — shared UI components in `commonMain` and sharing strategy.
- `kotlin-inject` — component placement across KMP targets (`@KmpComponentCreate`, `@MergeComponent.CreateComponent`).
- `sqldelight-kmp` — driver factory `expect/actual`, migration placement.
- `kotlin-expert` — language-level patterns used by shared code (StateFlow, sealed hierarchies).

## Scripts

- `scripts/validate-kmp-structure.sh` — detect wrong placements (JVM imports in common, etc.).
- `scripts/suggest-kmp-dependency.sh` — suggest KMP-native alternatives for JVM libraries.

## Bundled references

- `references/abstraction-examples.md` — good vs bad abstractions, with rationale.
- `references/source-set-hierarchy.md` — source set visual and dependency flow.
- `references/expect-actual-catalog.md` — object / class / function / typealias patterns across targets.
- `references/target-compatibility.md` — what works on which target; common KMP libraries.

## Official docs

- [Kotlin Multiplatform overview](https://kotlinlang.org/docs/multiplatform.html)
- [Source set hierarchy & default template](https://kotlinlang.org/docs/multiplatform-hierarchy.html)
- [expect / actual declarations](https://kotlinlang.org/docs/multiplatform-expect-actual.html)
- [KMP compatibility guide](https://kotlinlang.org/docs/multiplatform-compatibility-guide.html)
