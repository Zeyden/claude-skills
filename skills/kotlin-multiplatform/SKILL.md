---
name: kotlin-multiplatform
description: Platform abstraction decision-making for KMP projects. Guides when to abstract vs keep platform-specific, source set placement (commonMain, platform-specific), expect/actual patterns. Covers primary targets (Android, JVM/Desktop, iOS) with web/wasm future considerations. Integrates with gradle-expert for dependency issues. Triggers on abstraction decisions, source set placement questions, expect/actual creation, build.gradle.kts work, incorrect placement detection, KMP dependency suggestions.
---

# Kotlin Multiplatform: Platform Abstraction Decisions

Expert guidance for KMP architecture - deciding what to share vs keep platform-specific.

## Abstraction Decision Tree

```
Q: Is it used by 2+ platforms?
├─ NO  → Keep platform-specific
└─ YES → Continue ↓

Q: Is it pure Kotlin (no platform APIs)?
├─ YES → commonMain
└─ NO  → Continue ↓

Q: Does it vary by platform?
├─ By platform (Android ≠ iOS ≠ Desktop) → expect/actual
├─ JVM-only library (Android = Desktop) → optional jvmAndroid intermediate source set
└─ Complex/UI-related → Keep platform-specific

Final check: Maintenance cost of abstraction < duplication cost?
├─ YES → Proceed with abstraction
└─ NO  → Duplicate (simpler)
```

## Source Set Mental Model

```
commonMain (Pure Kotlin)
    ├── androidMain      (Android-specific)
    ├── jvmMain          (Desktop JVM-specific)
    └── iosMain          (iOS-specific)
```

**Advanced pattern:** An optional `jvmAndroid` intermediate source set can share JVM libraries between Android and Desktop when both use JVM-only libraries like Jackson or OkHttp.

## What to Abstract vs Keep Platform-Specific

| Code Type | Location | Reason |
|-----------|----------|--------|
| Pure Kotlin business logic | commonMain | Works everywhere |
| Data models, domain rules | commonMain | Core logic, no platform APIs |
| Platform crypto/security | expect/actual | Security APIs differ per platform |
| Logging | expect/actual | Platform logging systems differ |
| ViewModels (state + logic) | commonMain | StateFlow/SharedFlow are platform-agnostic |
| UI components (simple) | commonMain | Compose Multiplatform works cross-platform |
| Screen layouts | Platform-specific | Window vs Activity paradigms differ |
| Navigation | Platform-specific | Activity vs Window too different |
| Permissions | Platform-specific | APIs incompatible |

## expect/actual Mechanics

```kotlin
// commonMain - declare the contract
expect object PlatformLogger {
    fun d(tag: String, message: String)
    fun e(tag: String, message: String, throwable: Throwable?)
}

// androidMain - Android implementation
actual object PlatformLogger {
    actual fun d(tag: String, message: String) { android.util.Log.d(tag, message) }
    actual fun e(tag: String, message: String, throwable: Throwable?) { android.util.Log.e(tag, message, throwable) }
}

// jvmMain - Desktop implementation
actual object PlatformLogger {
    actual fun d(tag: String, message: String) { println("[$tag] $message") }
    actual fun e(tag: String, message: String, throwable: Throwable?) { System.err.println("[$tag] $message") }
}
```

See [references/expect-actual-catalog.md](references/expect-actual-catalog.md) for complete catalog.

## Common Pitfalls

1. **Over-abstraction**: Don't create expect/actual for navigation - paradigms too different
2. **Under-sharing**: Don't duplicate business logic across platforms
3. **Leaky abstractions**: No `import android.*` in commonMain
4. **Premature abstraction**: Wait until second platform needs it
5. **Wrong source set**: JVM-only libraries can't go in commonMain

## Integration with Other Skills

- **gradle-expert**: Dependency conflicts, source set build errors
- **compose-expert**: Shared UI components
- **kotlin-expert**: Kotlin language patterns

## Scripts

- `scripts/validate-kmp-structure.sh` - Detect incorrect placements
- `scripts/suggest-kmp-dependency.sh` - Suggest KMP library alternatives

## See Also

- [references/abstraction-examples.md](references/abstraction-examples.md) - Good/bad abstraction examples
- [references/source-set-hierarchy.md](references/source-set-hierarchy.md) - Visual source set hierarchy
- [references/expect-actual-catalog.md](references/expect-actual-catalog.md) - expect/actual patterns
- [references/target-compatibility.md](references/target-compatibility.md) - Platform constraints
