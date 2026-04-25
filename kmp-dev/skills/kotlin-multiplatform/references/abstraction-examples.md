# Abstraction Examples

Real examples of abstraction decisions with rationale for KMP projects.

## Good Abstractions

### PlatformCrypto - Platform Security APIs
**Location:** expect in commonMain, actual per platform
```kotlin
expect object PlatformCrypto {
    fun encrypt(data: ByteArray, key: ByteArray): ByteArray
    fun decrypt(data: ByteArray, key: ByteArray): ByteArray
}
```
**Why:** Security APIs fundamentally differ per platform. Core requirement for all platforms.

### PlatformLogger - Logging
```kotlin
expect object PlatformLogger {
    fun d(tag: String, message: String)
    fun e(tag: String, message: String, throwable: Throwable?)
}
```
**Why:** Logging systems differ (android.util.Log vs println vs NSLog). Simple interface, widely used.

### Platform Utils
```kotlin
expect fun platform(): String
expect fun currentTimeSeconds(): Long
```
**Why:** Simple utilities with clear platform boundaries.

## What NOT to Abstract

### Navigation (Keep Platform-Specific)
```kotlin
// DON'T DO THIS
expect interface Navigator { fun navigate(route: String) }
```
**Why:** Navigation paradigms fundamentally different (Activity back stack vs Window state). Leaky abstraction.

### String Resources (Abstract When Ready)
```kotlin
// Plan when second platform needs it
interface StringProvider { fun get(key: String): String }
```
**Lesson:** Don't abstract prematurely - wait until second platform needs it.

## Migration Examples

### Pure Kotlin Utility → commonMain
```kotlin
// Before: duplicated in app/ and composeApp/
fun String.toDisplayId(): String = "${take(8)}:${takeLast(8)}"

// After: shared/src/commonMain
fun String.toDisplayId(): String = "${take(8)}:${takeLast(8)}"
```

### Platform-Dependent Utility → expect/actual
```kotlin
// commonMain
fun timeAgo(timestamp: Long, stringProvider: StringProvider): String

// androidMain: stringProvider = AndroidStringProvider(context)
// jvmMain: stringProvider = DesktopStringProvider()
```

## Decision Summary

| Pattern | Abstract? | Why |
|---------|-----------|-----|
| Pure Kotlin utilities | Yes | No platform dependency |
| Crypto APIs | Yes (expect/actual) | Platform security APIs differ |
| Simple UI components | Yes | Compose MP works cross-platform |
| Navigation | No | Paradigms too different |
| ViewModels | Partial | Business logic yes, UI state depends |
| String resources | When needed | Needs abstraction layer |
