---
name: kotlin-expert
description: Advanced Kotlin patterns for KMP projects. Flow state management (StateFlow/SharedFlow), sealed hierarchies (classes vs interfaces), immutability (@Immutable, data classes), DSL builders (type-safe fluent APIs), inline functions (reified generics, performance). Use when working with: (1) State management patterns (StateFlow/SharedFlow/MutableStateFlow), (2) Sealed classes or sealed interfaces, (3) @Immutable annotations for Compose, (4) DSL builders with lambda receivers, (5) inline/reified functions, (6) Kotlin performance optimization. Complements kotlin-coroutines agent (async patterns) - this skill focuses on Kotlin idioms for KMP projects.
---

# Kotlin Expert

Advanced Kotlin patterns for KMP projects. Covers Flow state management, sealed hierarchies, immutability, DSL builders, and inline functions with practical examples.

## Mental Model

```
State Management (Hot Flows)
    ├── StateFlow<T>           # Single value, always has value, replays to new subscribers
    ├── SharedFlow<T>          # Event stream, configurable replay, multiple subscribers
    └── MutableStateFlow<T>    # Private mutable, public via .asStateFlow()

Type Safety (Sealed Hierarchies)
    ├── sealed class           # State variants with data (AuthState.LoggedIn/LoggedOut)
    └── sealed interface       # Generic result types (OperationResult<T>)

Compose Performance (@Immutable)
    ├── @Immutable             # Prevents recomposition for unchanging data
    └── data class             # Structural equality, copy(), immutable by convention

DSL Patterns
    ├── Builder classes        # Fluent APIs (FilterBuilder)
    ├── Lambda receivers       # inline fun filterArray { ... }
    └── Method chaining        # return this

Performance
    ├── inline fun             # Eliminate lambda overhead
    ├── reified type params    # Runtime type info (JsonMapper)
    └── value class            # Zero-cost wrappers
```

**Delegation:**
- **kotlin-coroutines agent**: Deep async (structured concurrency, channels, operators)
- **kotlin-multiplatform skill**: expect/actual, source sets
- **This skill**: Kotlin idioms, state patterns, type safety

---

## 1. Flow State Management

### StateFlow: State that Changes

**Mental model:** StateFlow is a "hot" observable state holder. Always has a value, new collectors immediately get current state.

```kotlin
class AuthManager {
    private val _authState = MutableStateFlow<AuthState>(AuthState.LoggedOut)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    fun login(credentials: Credentials) {
        _authState.value = AuthState.LoggedIn(...)
    }
}
```

**Key principles:**
1. **Private mutable, public immutable**: `_authState` (MutableStateFlow) private, `authState` (StateFlow) public
2. **Always has value**: Initial value required (`LoggedOut`)
3. **Single value**: Replays ONE most recent value to new subscribers
4. **Hot**: Stays in memory, all collectors share same instance

### SharedFlow: Event Streams

**When to use StateFlow vs SharedFlow:**

| Scenario | Use StateFlow | Use SharedFlow |
|----------|---------------|----------------|
| **UI state** | Current screen data, login status | |
| **One-time events** | | Navigation, snackbars, toasts |
| **Always has value** | Yes | Optional |
| **Replay count** | 1 (latest only) | Configurable (0, 1, n) |
| **Backpressure** | Conflates (drops old) | Configurable buffer |

```kotlin
// State: Use StateFlow
private val _uiState = MutableStateFlow(UiState.Loading)
val uiState: StateFlow<UiState> = _uiState.asStateFlow()

// Events: Use SharedFlow
private val _navigationEvents = MutableSharedFlow<NavEvent>(replay = 0)
val navigationEvents: SharedFlow<NavEvent> = _navigationEvents.asSharedFlow()
```

### Flow Anti-Patterns

**Exposing mutable state:**
```kotlin
val authState: MutableStateFlow<AuthState>  // BAD: Can be mutated externally
```
**Expose immutable:**
```kotlin
val authState: StateFlow<AuthState> = _authState.asStateFlow()  // GOOD
```

**See:** `references/flow-patterns.md` for comprehensive examples.

---

## 2. Sealed Hierarchies

### Sealed Classes: State Variants

```kotlin
sealed class AuthState {
    data object LoggedOut : AuthState()

    data class LoggedIn(
        val userId: String,
        val displayName: String,
        val token: String?,
        val isReadOnly: Boolean
    ) : AuthState()
}

// Usage
when (state) {
    is AuthState.LoggedOut -> showLogin()
    is AuthState.LoggedIn -> showDashboard(state.userId)
}  // Exhaustive - compiler enforces all cases
```

### Sealed Interfaces: Generic Result Types

```kotlin
sealed interface OperationResult<out T> {
    data class Success<T>(val value: T) : OperationResult<T>
    data class Error(val message: String) : OperationResult<Nothing>
    data object Loading : OperationResult<Nothing>
}

fun <T> fetchData(): OperationResult<T> = ...
```

### Sealed Class vs Sealed Interface

| Feature | Sealed Class | Sealed Interface |
|---------|--------------|------------------|
| **Constructor** | Can hold common state | No constructor |
| **Inheritance** | Single parent only | Multiple interfaces |
| **Generics** | No variance | Covariance/contravariance |
| **Use case** | State variants | Result types, contracts |

**Decision tree:**
```
Need common data in base? → sealed class
Need generics with variance? → sealed interface
Need multiple inheritance? → sealed interface
Otherwise → Either works
```

**See:** `references/sealed-class-catalog.md` for sealed type patterns.

---

## 3. Immutability & Compose Performance

### @Immutable Annotation

```kotlin
@Immutable
data class DataRecord(
    val id: String,
    val title: String,
    val content: String,
    val createdAt: Long
) {
    // All properties immutable (val), no mutable state
}
```

**Key principles:**
1. All properties must be `val`
2. No mutable collections
3. Deep immutability - nested objects also immutable
4. Compose optimization - skips recomposition if reference equals

### kotlinx.collections.immutable

```kotlin
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

val items: ImmutableList<String> = persistentListOf("item1", "item2")
val updated = items.add("item3")  // items unchanged, updated has 3
```

**See:** `references/immutability-patterns.md`

---

## 4. DSL Builders

### Type-Safe Fluent APIs

```kotlin
class FilterBuilder<T> {
    private val entries = mutableMapOf<String, MutableList<Array<String>>>()

    fun add(entry: Array<String>): FilterBuilder<T> {
        if (entry.isEmpty() || entry[0].isEmpty()) return this
        entries.getOrPut(entry[0], ::mutableListOf).add(entry)
        return this  // Method chaining
    }

    fun remove(key: String): FilterBuilder<T> {
        entries.remove(key)
        return this
    }

    fun build() = entries.flatMap { it.value }.toTypedArray()
}

inline fun <T> filterArray(initializer: FilterBuilder<T>.() -> Unit = {}): Array<Array<String>> =
    FilterBuilder<T>().apply(initializer).build()
```

**Usage:**
```kotlin
val filters = filterArray<DataRecord> {
    add(arrayOf("type", "note"))
    add(arrayOf("author", userId))
    remove("draft")
}
```

**See:** `references/dsl-builder-examples.md` for more patterns.

---

## 5. Inline Functions & reified

### inline fun: Eliminate Overhead

```kotlin
inline fun <T> measureTime(block: () -> T): T {
    val start = System.currentTimeMillis()
    val result = block()  // No allocation, code inlined
    println("Time: ${System.currentTimeMillis() - start}ms")
    return result
}
```

### reified: Runtime Type Access

```kotlin
inline fun <reified T> fromJson(json: String): T {
    return when (T::class) {
        DataRecord::class -> parseRecord(json) as T
        // ...
    }
}

val record = fromJson<DataRecord>(json)  // Clean, type-safe
```

---

## 6. Value Classes

```kotlin
@JvmInline
value class UserId(val value: String)

@JvmInline
value class RecordId(val value: String)

fun fetchRecord(id: RecordId): Record  // Type safe, zero cost
// fetchRecord(UserId("xyz"))  // Compile error!
```

---

## Common Patterns

### Pattern: StateFlow State Management

```kotlin
class MyViewModel {
    private val _state = MutableStateFlow(State.Initial)
    val state: StateFlow<State> = _state.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _state.value = State.Loading
            val result = repository.getData()
            _state.value = when (result) {
                is Success -> State.Success(result.data)
                is Error -> State.Error(result.message)
            }
        }
    }
}

sealed class State {
    data object Initial : State()
    data object Loading : State()
    data class Success(val data: List<Item>) : State()
    data class Error(val message: String) : State()
}
```

---

## Delegation Guide

| Topic | Delegate To | This Skill Covers |
|-------|-------------|-------------------|
| Structured concurrency, channels | kotlin-coroutines agent | Flow state patterns only |
| expect/actual, source sets | kotlin-multiplatform skill | Platform-agnostic Kotlin |
| General Compose patterns | compose-expert skill | @Immutable for performance |
| Build configuration | gradle-expert skill | - |

---

## Anti-Patterns

**Mutable public state:**
```kotlin
val state: MutableStateFlow<State>  // BAD
```
**Immutable public interface:**
```kotlin
val state: StateFlow<State> = _state.asStateFlow()  // GOOD
```

**Sealed class for generic results:**
```kotlin
sealed class Result<T> { ... }  // BAD: Can't use variance
```
**Sealed interface for generics:**
```kotlin
sealed interface Result<out T> { ... }  // GOOD: Covariance
```

**Passing class explicitly when reified available:**
```kotlin
inline fun <T> parse(json: String, clazz: KClass<T>): T  // BAD
```
**Use reified:**
```kotlin
inline fun <reified T> parse(json: String): T  // GOOD
```

---

## Quick Reference

### Flow Decision Tree
```
Need to expose state? → StateFlow
Need events? → SharedFlow
Need to mutate internally only? → MutableStateFlow (private) + .asStateFlow() (public)
```

### Sealed Decision Tree
```
Need common data in base? → sealed class
Need generics with variance? → sealed interface
Need multiple inheritance? → sealed interface
```

### Inline Decision Tree
```
Passing lambda frequently? → inline
Need reified? → inline (required)
Need to store/pass lambda? → regular fun
```

---

## Resources

### Official Docs
- [StateFlow and SharedFlow | Android Developers](https://developer.android.com/kotlin/flow/stateflow-and-sharedflow)
- [Sealed Classes | Kotlin Docs](https://kotlinlang.org/docs/sealed-classes.html)
- [Inline Functions | Kotlin Docs](https://kotlinlang.org/docs/inline-functions.html)

### Bundled References
- `references/flow-patterns.md` - StateFlow/SharedFlow examples
- `references/sealed-class-catalog.md` - Sealed type patterns
- `references/dsl-builder-examples.md` - Builder and DSL patterns
- `references/immutability-patterns.md` - @Immutable usage, data classes, collections
