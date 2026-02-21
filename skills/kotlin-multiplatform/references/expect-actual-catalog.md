# expect/actual Catalog

Common expect/actual patterns for KMP projects.

## Common Patterns

| # | Name | Type | Purpose | Why Abstracted |
|---|------|------|---------|----------------|
| 1 | PlatformLogger | object | Logging | Platform logging systems differ |
| 2 | PlatformPreferences | class | Key-value storage | SharedPreferences vs UserDefaults vs Properties |
| 3 | PlatformFileSystem | object | File I/O | Platform file APIs differ |
| 4 | PlatformCrypto | object | Encryption/signing | Platform security APIs differ |
| 5 | HttpEngineFactory | object | HTTP client engine | Ktor engines differ per platform |
| 6 | PlatformContext | class | App context wrapper | Android Context vs no-op |
| 7 | UuidGenerator | object | UUID generation | java.util.UUID vs platform.Foundation |
| 8 | DateTimeFormatter | object | Date/time formatting | Platform formatting APIs differ |
| 9 | ImageLoader | object | Image loading | Platform image libraries differ |
| 10 | BiometricAuth | object | Biometric auth | Platform biometric APIs differ |

## Implementation Examples

### Object Pattern (Singletons)

```kotlin
// commonMain
expect object PlatformLogger {
    fun d(tag: String, message: String)
    fun e(tag: String, message: String, throwable: Throwable?)
}

// androidMain
actual object PlatformLogger {
    actual fun d(tag: String, message: String) { android.util.Log.d(tag, message) }
    actual fun e(tag: String, message: String, throwable: Throwable?) { android.util.Log.e(tag, message, throwable) }
}

// jvmMain
actual object PlatformLogger {
    actual fun d(tag: String, message: String) { println("[$tag] $message") }
    actual fun e(tag: String, message: String, throwable: Throwable?) { System.err.println("[$tag] $message: $throwable") }
}
```

### Class Pattern (Stateful)

```kotlin
// commonMain
expect class PlatformPreferences {
    fun getString(key: String, default: String): String
    fun putString(key: String, value: String)
    fun getInt(key: String, default: Int): Int
    fun putInt(key: String, value: Int)
}

// androidMain
actual class PlatformPreferences(private val prefs: SharedPreferences) {
    actual fun getString(key: String, default: String) = prefs.getString(key, default) ?: default
    actual fun putString(key: String, value: String) { prefs.edit().putString(key, value).apply() }
    actual fun getInt(key: String, default: Int) = prefs.getInt(key, default)
    actual fun putInt(key: String, value: Int) { prefs.edit().putInt(key, value).apply() }
}

// jvmMain
actual class PlatformPreferences(private val prefs: java.util.prefs.Preferences) {
    actual fun getString(key: String, default: String) = prefs.get(key, default)
    actual fun putString(key: String, value: String) { prefs.put(key, value) }
    actual fun getInt(key: String, default: Int) = prefs.getInt(key, default)
    actual fun putInt(key: String, value: Int) { prefs.putInt(key, value) }
}
```

### Function Pattern (Utilities)

```kotlin
// commonMain
expect fun platform(): String
expect fun currentTimeMillis(): Long

// androidMain
actual fun platform(): String = "Android ${Build.VERSION.SDK_INT}"
actual fun currentTimeMillis(): Long = System.currentTimeMillis()

// jvmMain
actual fun platform(): String = "Desktop JVM"
actual fun currentTimeMillis(): Long = System.currentTimeMillis()

// iosMain
actual fun platform(): String = "iOS"
actual fun currentTimeMillis(): Long = (NSDate().timeIntervalSince1970 * 1000).toLong()
```

### Type Alias Pattern

```kotlin
// commonMain
expect class BigDecimal { constructor(value: String); fun add(other: BigDecimal): BigDecimal }

// jvmMain (Android + Desktop)
actual typealias BigDecimal = java.math.BigDecimal

// iosMain
actual class BigDecimal actual constructor(value: String) {
    private val nsValue = NSDecimalNumber(value)
    actual fun add(other: BigDecimal): BigDecimal = ...
}
```

## Decision Patterns

1. **Used by 2+ platforms?** → YES (otherwise keep platform-specific)
2. **Pure Kotlin possible?** → Put in commonMain directly (no expect/actual)
3. **Varies by platform?** → expect/actual
4. **JVM-only library?** → jvmAndroid or platform-specific (not commonMain)
