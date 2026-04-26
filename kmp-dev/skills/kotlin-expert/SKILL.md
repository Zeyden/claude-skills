---
name: kotlin-expert
description: Advanced Kotlin language patterns for KMP projects — Flow state (StateFlow/SharedFlow), sealed hierarchies (classes vs interfaces), immutability (@Immutable, data classes, kotlinx.collections.immutable), DSL builders with lambda receivers, inline/reified generics, and value classes. Invoke proactively whenever touching `.kt` or `.kts` files in a KMP module (commonMain, shared/, composeApp/, server/) — reviewing or writing ViewModels, MutableStateFlow exposure, sealed class/interface hierarchies, @Immutable Compose data holders, inline fun with reified types, value class wrappers for IDs, or fluent builder APIs. Load this skill even when the user does not name a pattern explicitly — if the diff contains `sealed`, `StateFlow`, `@Immutable`, `inline fun`, `value class`, `@JvmInline`, or `@Composable`-adjacent state, consult this skill before writing or reviewing the code. Delegates async patterns to kotlin-coroutines and Compose specifics to compose-expert.
---

# Kotlin Expert

Advanced Kotlin patterns for KMP projects. Covers Flow state management, sealed hierarchies, immutability, DSL builders, and inline functions. Targets the Kotlin language layer — for async topology delegate to `kotlin-coroutines`, and for Compose-specific visual patterns delegate to `compose-expert`.

## When to consult this skill

Before you write or review Kotlin code in a KMP project, skim this SKILL.md if the change touches any of the following. Even brief cues in a diff are enough — you do not need the user to name the pattern.

| Cue in the code | Section to check |
|-----------------|------------------|
| `MutableStateFlow`, `MutableSharedFlow`, `.asStateFlow()` | §1 Flow State Management |
| `sealed class`, `sealed interface`, `data object` | §2 Sealed Hierarchies |
| `@Immutable`, `@Stable`, `ImmutableList`, `persistentListOf` | §3 Immutability |
| Builder classes, `.() -> Unit` receivers, fluent API | §4 DSL Builders |
| `inline fun`, `reified`, `@JvmInline value class` | §5–6 Inline & Value |

## Mental Model

```
State Management (Hot Flows)
    ├── StateFlow<T>           # Single value, always has one, replays latest to new collectors
    ├── SharedFlow<T>          # Event stream, configurable replay, multiple subscribers
    └── MutableStateFlow<T>    # Private mutable, expose via .asStateFlow()

Type Safety (Sealed Hierarchies)
    ├── sealed class           # Variants with shared data — state machines
    └── sealed interface       # Variance-safe results, multiple inheritance

Compose Performance
    ├── @Immutable             # Skip recomposition when reference is unchanged
    ├── @Stable                # Tracked mutations via mutableStateOf
    └── data class             # Structural equality, copy(), immutable by convention

DSL Patterns
    ├── Builder classes        # Fluent APIs (return this)
    ├── Lambda receivers       # inline fun builder(block: Builder.() -> Unit)
    └── Type-safe contexts     # @DslMarker to prevent scope pollution

Performance Primitives
    ├── inline fun             # Erase lambda allocation at the call site
    ├── reified type params    # Runtime type access inside inline funs
    └── value class            # Zero-cost type-safe wrappers (IDs, units)
```

**Delegation:**
- `kotlin-coroutines` — structured concurrency, channels, advanced Flow operators
- `kotlin-multiplatform` — `expect/actual`, source set placement
- `compose-expert` — @Composable patterns, recomposition beyond @Immutable
- `gradle-expert` — version catalogue entries, KSP wiring

---

## 1. Flow State Management

### StateFlow — state that changes

StateFlow is a hot observable holder. It always has a value; new collectors immediately get the current one.

```kotlin
class AuthManager {
    private val _authState = MutableStateFlow<AuthState>(AuthState.LoggedOut)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    fun login(credentials: Credentials) {
        _authState.value = AuthState.LoggedIn(...)
    }
}
```

Principles:
1. **Private mutable, public read-only.** `_state: MutableStateFlow` private; `state: StateFlow` public via `.asStateFlow()`.
2. **Always has a value.** Initial value required.
3. **Conflates.** Only the latest value replays to new subscribers.
4. **Hot.** Stays active while the scope is alive; collectors share one instance.

### SharedFlow — event streams

| Scenario | Use StateFlow | Use SharedFlow |
|----------|---------------|----------------|
| UI state (current screen, auth status) | Yes | |
| One-shot events (navigation, snackbars) | | Yes |
| Must always have a value | Yes | Optional |
| Replay count | 1 (conflated) | Configurable (0, 1, N) |
| Backpressure behaviour | Conflates (drops old) | Configurable buffer |

```kotlin
// State
private val _uiState = MutableStateFlow(UiState.Loading)
val uiState: StateFlow<UiState> = _uiState.asStateFlow()

// Events
private val _navigation = MutableSharedFlow<NavEvent>(replay = 0)
val navigation: SharedFlow<NavEvent> = _navigation.asSharedFlow()
```

### Anti-patterns

```kotlin
val authState: MutableStateFlow<AuthState>        // Bad — caller can mutate
val authState: StateFlow<AuthState> = _authState.asStateFlow()  // Good
```

See `references/flow-patterns.md` for extended examples including derived state, immutable updates, and Compose integration.

---

## 2. Sealed Hierarchies

### Sealed classes — state variants with data

```kotlin
sealed class AuthState {
    data object LoggedOut : AuthState()
    data class LoggedIn(
        val userId: String,
        val displayName: String,
        val token: String?,
    ) : AuthState()
}

when (state) {
    is AuthState.LoggedOut -> showLogin()
    is AuthState.LoggedIn -> showDashboard(state.userId)
}  // Exhaustive — the compiler enforces every branch.
```

### Sealed interfaces — generic result types

```kotlin
sealed interface OperationResult<out T> {
    data class Success<T>(val value: T) : OperationResult<T>
    data class Error(val message: String) : OperationResult<Nothing>
    data object Loading : OperationResult<Nothing>
}
```

### Decision tree

```
Need shared data in the base?           → sealed class
Need generics with variance (out/in)?   → sealed interface
Need multiple inheritance?              → sealed interface
Otherwise                               → either works; pick sealed class for state machines
```

See `references/sealed-class-catalog.md` for state-machine, nested, and error-type patterns.

---

## 3. Immutability & Compose Performance

```kotlin
@Immutable
data class DataRecord(
    val id: String,
    val title: String,
    val content: String,
    val createdAt: Long,
)
```

Requirements for `@Immutable`:
1. All properties `val`.
2. No mutable collections (`List`, `MutableMap`, etc. are read-only *views* — use `ImmutableList`/`persistentListOf` for true guarantees).
3. Nested objects must also be `@Immutable`.
4. The compiler skips recomposition when the reference is unchanged.

`@Immutable` vs `@Stable`:
- `@Immutable` — value never changes after construction.
- `@Stable` — value can change, but changes flow through `mutableStateOf`/`SnapshotStateList`.

```kotlin
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

val items: ImmutableList<String> = persistentListOf("a", "b")
val added = items.add("c")   // items unchanged; added has three
```

See `references/immutability-patterns.md` for Compose-focused rules, state holders, and anti-patterns.

---

## 4. DSL Builders

```kotlin
class FilterBuilder<T> {
    private val entries = mutableMapOf<String, MutableList<Array<String>>>()

    fun add(entry: Array<String>): FilterBuilder<T> = apply {
        if (entry.isEmpty() || entry[0].isEmpty()) return@apply
        entries.getOrPut(entry[0], ::mutableListOf).add(entry)
    }

    fun build(): Array<Array<String>> = entries.flatMap { it.value }.toTypedArray()
}

inline fun <T> filterArray(init: FilterBuilder<T>.() -> Unit = {}): Array<Array<String>> =
    FilterBuilder<T>().apply(init).build()
```

Call site:
```kotlin
val filters = filterArray<DataRecord> {
    add(arrayOf("type", "note"))
    add(arrayOf("author", userId))
}
```

Principles: lambda-with-receiver, method chaining via `apply` or `this`, `inline` to elide lambda allocation, and `@DslMarker` annotations when nesting builders to prevent scope leaks. See `references/dsl-builder-examples.md`.

---

## 5. Inline Functions & reified

```kotlin
inline fun <T> measureTime(block: () -> T): T {
    val start = System.currentTimeMillis()
    val result = block()
    println("Time: ${System.currentTimeMillis() - start}ms")
    return result
}

inline fun <reified T> fromJson(json: String, parser: JsonParser): T =
    parser.decodeFromString(serializersModule.serializer(typeOf<T>()), json) as T
```

Rules:
- `inline` eliminates lambda allocation and may enable non-local returns — avoid when you need to store or pass the lambda.
- `reified` is only available inside `inline` functions; use it to read the type at runtime without passing `KClass<T>`.
- Prefer `reified` over `KClass<T>` parameters when both can express the API cleanly.

---

## 6. Value Classes

```kotlin
@JvmInline value class UserId(val value: String)
@JvmInline value class Timecode(val millis: Long)

fun format(time: Timecode): String = ...
// format(UserId("abc"))  // compile error
```

Use value classes for IDs, units, and typed identifiers to get type safety without the overhead of a regular wrapper class. They cannot have mutable state, `init` blocks with side effects, or extend other classes.

---

## Common end-to-end pattern

```kotlin
sealed class State {
    data object Initial : State()
    data object Loading : State()
    data class Success(val data: ImmutableList<Item>) : State()
    data class Error(val message: String) : State()
}

class FeedViewModel(private val repo: Repository) {
    private val _state = MutableStateFlow<State>(State.Initial)
    val state: StateFlow<State> = _state.asStateFlow()

    fun load(scope: CoroutineScope) = scope.launch {
        _state.value = State.Loading
        _state.value = runCatching { repo.fetch() }.fold(
            onSuccess = { State.Success(it.toPersistentList()) },
            onFailure = { State.Error(it.message.orEmpty()) },
        )
    }
}
```

Delegates: the `scope.launch` pattern and its cancellation semantics live in `kotlin-coroutines`; the `@Composable fun Feed(viewModel: FeedViewModel)` rendering belongs to `compose-expert`.

---

## Anti-patterns

| Anti-pattern | Correct approach |
|--------------|------------------|
| `val state: MutableStateFlow<T>` exposed publicly | `val state: StateFlow<T> = _state.asStateFlow()` |
| `sealed class Result<T>` needing covariance | `sealed interface Result<out T>` |
| `KClass<T>` parameter when `reified` fits | `inline fun <reified T> ...` |
| `List<T>` inside an `@Immutable` data class | `ImmutableList<T>` from `kotlinx.collections.immutable` |
| `data class Id(val value: String)` for typed IDs | `@JvmInline value class Id(val value: String)` |

---

## Quick reference

```
StateFlow vs SharedFlow?
  Need current value → StateFlow        Events → SharedFlow
Sealed class vs interface?
  Shared data in base → sealed class    Variance → sealed interface
Inline or not?
  Lambda passed, not stored → inline    reified generics → inline (required)
```

## Bundled references

- `references/flow-patterns.md` — StateFlow/SharedFlow in depth, Compose integration, derived state.
- `references/sealed-class-catalog.md` — state machines, nested hierarchies, error types.
- `references/dsl-builder-examples.md` — builder classes, `@DslMarker`, nested DSLs.
- `references/immutability-patterns.md` — `@Immutable`/`@Stable`, immutable collections, anti-patterns.

## Official docs

- [StateFlow and SharedFlow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-state-flow/)
- [Sealed classes and interfaces](https://kotlinlang.org/docs/sealed-classes.html)
- [Inline functions](https://kotlinlang.org/docs/inline-functions.html)
- [Value classes](https://kotlinlang.org/docs/inline-classes.html)
