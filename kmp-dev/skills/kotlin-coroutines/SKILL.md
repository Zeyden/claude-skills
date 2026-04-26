---
name: kotlin-coroutines
description: Advanced Kotlin coroutines and Flow patterns for KMP projects — structured concurrency (supervisorScope, coroutineScope, SupervisorJob), advanced Flow operators (flatMapLatest, combine, merge, shareIn, stateIn, debounce), callbackFlow and channels, dispatcher management and context switching with flowOn, exception handling (CoroutineExceptionHandler), testing with runTest and Turbine, WebSocket/API subscriptions, and backpressure handling. Invoke proactively whenever touching `.kt` files that launch coroutines, expose a Flow, use `suspend` functions beyond trivial sequencing, or run `runTest`/`runBlocking`. Load this skill without waiting for the user to name an operator — if the diff contains `launch`, `async`, `supervisorScope`, `callbackFlow`, `flowOn`, `shareIn`, `stateIn`, `flatMapLatest`, `Channel`, `SupervisorJob`, `runTest`, or `.test {` (Turbine), consult this skill before writing or reviewing the code. Delegates basic StateFlow/SharedFlow holding patterns to kotlin-expert.
---

# Kotlin Coroutines — Advanced Async Patterns

Expert guidance for complex async topologies: connection pools, event streams, structured concurrency, and testing. For bare `MutableStateFlow` state holders delegate to `kotlin-expert`; this skill picks up once you need operators, scopes, or lifecycle control.

## When to consult this skill

Before writing or reviewing coroutine-heavy Kotlin code, skim this SKILL.md. Treat these cues as triggers even when the user does not ask explicitly:

| Cue in the code | Section to check |
|-----------------|------------------|
| `launch`, `async`, `supervisorScope`, `coroutineScope` | §Structured Concurrency |
| `callbackFlow`, `awaitClose`, bridging a listener/callback | §callbackFlow |
| `flatMapLatest`, `combine`, `merge`, `shareIn`, `stateIn`, `debounce`, `conflate` | §Advanced Operators |
| `CoroutineExceptionHandler`, `SupervisorJob`, try/catch in a coroutine | §Exception Handling |
| `flowOn`, `Dispatchers.IO`, switching dispatchers mid-Flow | §Context Switching |
| `runTest`, `.test {`, `advanceUntilIdle`, Turbine | §Testing |

## Mental Model

```
DataSourcePool (supervisorScope)
    ├── Source 1 (launch) → callbackFlow → items
    ├── Source 2 (launch) → callbackFlow → items
    └── Source 3 (launch) → callbackFlow → items
            ↓
    merge() → distinctBy { id } → shareIn(scope, WhileSubscribed(5000))
            ↓
    StateFlow/UI consumers
```

Key principles:
- **supervisorScope** — children fail independently; sibling failures do not cancel each other.
- **callbackFlow** — bridges listener/callback APIs to cold Flow with cancellation.
- **shareIn / stateIn** — hot sharing of cold upstreams with lifecycle control.
- **Backpressure** — `buffer(capacity, onBufferOverflow)`, `conflate`, `sample`, `debounce`.

**Delegation:**
- `kotlin-expert` — basic `MutableStateFlow` / `SharedFlow` exposure idioms.
- `kotlin-multiplatform` — picking the right Dispatcher per target, `expect/actual` dispatcher setup.
- `compose-expert` — collecting Flows into Compose with `collectAsStateWithLifecycle`.

---

## Core Patterns

### callbackFlow — bridge a listener into a Flow

```kotlin
fun DataSourceClient.observeAsFlow(
    server: String,
    filters: List<QueryFilter>,
): Flow<List<DataItem>> = callbackFlow {
    val subId = Uuid.random().toString()
    var initialLoadComplete = false
    val ids = mutableSetOf<String>()
    var current = listOf<DataItem>()

    val listener = object : DataSourceListener {
        override fun onItem(item: DataItem) {
            if (item.id in ids) return
            ids += item.id
            current = if (initialLoadComplete) listOf(item) + current else current + item
            trySend(current)
        }
        override fun onInitialLoadComplete() { initialLoadComplete = true }
    }

    openSubscription(subId, server, filters, listener)
    awaitClose { closeSubscription(subId) }
}
```

Rules: always call `awaitClose` to release resources; return early in callbacks that are not idempotent; prefer `trySend` over `send` inside non-suspending callbacks.

### Structured concurrency across multiple sources

```kotlin
suspend fun connectToSources(sources: List<DataSource>) = supervisorScope {
    sources.forEach { source ->
        launch {
            runCatching {
                source.connect()
                source.subscribe(filters).collect { itemChannel.send(it) }
            }.onFailure { Log.e("DataSource", "Connection failed: ${source.url}", it) }
        }
    }
}
```

`supervisorScope` ensures one connection failure does not cancel siblings. Reach for `coroutineScope` when you *do* want a single failure to abort everything.

### Merge items from multiple streams

```kotlin
fun observeFromSources(
    servers: List<String>,
    filters: List<QueryFilter>,
): Flow<DataItem> =
    servers
        .map { server -> client.observeAsFlow(server, filters).flatMapConcat { it.asFlow() } }
        .merge()
        .distinctBy { it.id }
```

### Connectivity as Flow

```kotlin
val connectivity: Flow<ConnectivityStatus> = callbackFlow {
    val callback = object : NetworkCallback() {
        override fun onAvailable(network: Network) { trySend(ConnectivityStatus.Active(network)) }
        override fun onLost(network: Network) { trySend(ConnectivityStatus.Off) }
    }
    connectivityManager.registerCallback(callback)
    activeNetwork?.let { trySend(ConnectivityStatus.Active(it)) }
    awaitClose { connectivityManager.unregisterCallback(callback) }
}
    .distinctUntilChanged()
    .debounce(200)
    .flowOn(Dispatchers.IO)
```

---

## Advanced Operators

| Operator | Use case | One-line example |
|----------|----------|------------------|
| `flatMapLatest` | Cancel in-flight, switch to new upstream (search input) | `query.flatMapLatest { repo.search(it) }` |
| `flatMapConcat` | Sequential, preserve order | `ids.flatMapConcat { repo.fetch(it) }` |
| `flatMapMerge` | Concurrent fan-out with bound | `sources.flatMapMerge(concurrency = 8) { it.stream() }` |
| `combine` | Latest from N sources | `combine(user, settings) { u, s -> u to s }` |
| `merge` | Union of N streams | `merge(a, b, c)` |
| `shareIn` | One upstream, many collectors | `.shareIn(scope, SharingStarted.WhileSubscribed(5_000))` |
| `stateIn` | Cold → StateFlow for UI | `.stateIn(scope, started, initialValue)` |
| `buffer` | Decouple producer/consumer speed | `.buffer(64, DROP_OLDEST)` |
| `conflate` | Keep only latest | `.conflate()` |
| `debounce` | Wait for quiet period | `.debounce(300)` |
| `sample` | Emit on tick | `.sample(1_000)` |

See `references/advanced-flow-operators.md` for full operator catalogue including error handling, `retryWhen`, and cache-then-observe patterns.

---

## Exception Handling

```kotlin
class DataService(private val parent: CoroutineScope) {
    private val handler = CoroutineExceptionHandler { _, t ->
        log.e("DataService", "Uncaught: ${t.message}", t)
    }
    private val scope = CoroutineScope(parent.coroutineContext + SupervisorJob() + handler)

    fun start() = scope.launch { ... }
    fun shutdown() = scope.cancel()
}
```

Rules:
- `CoroutineExceptionHandler` catches uncaught failures — it does **not** replace try/catch inside coroutines.
- `SupervisorJob()` plus `supervisorScope { }` keeps sibling coroutines alive when one fails.
- `Flow.catch { }` catches **upstream** errors only; put `catch` at the point where you want to convert error to state.

---

## Context Switching

```kotlin
repository.fetchData()
    .map { heavyProcessing(it) }
    .flowOn(Dispatchers.Default)   // affects UPSTREAM only
    .collect { updateUI(it) }
```

Defaults:
- `Dispatchers.Main` for UI (provided by the platform-specific Compose dispatcher).
- `Dispatchers.IO` for blocking I/O.
- `Dispatchers.Default` for CPU-bound work.
- `Dispatchers.Unconfined` only for tests or re-dispatching.

For KMP Dispatcher abstractions across targets, delegate to `kotlin-multiplatform`.

---

## Testing

```kotlin
@Test fun `state flow updates`() = runTest {
    val vm = MyViewModel()
    assertEquals(UiState.Loading, vm.state.value)
    vm.loadData()
    advanceUntilIdle()
    assertEquals(UiState.Success(data), vm.state.value)
}

@Test fun `flow emits expected values`() = runTest {
    repository.observeData().test {
        assertEquals(Item1, awaitItem())
        assertEquals(Item2, awaitItem())
        awaitComplete()
    }
}
```

Rules:
- Use `runTest { }` — it creates a `TestScope` with a `StandardTestDispatcher`.
- Drive virtual time with `advanceTimeBy`, `advanceUntilIdle`, `runCurrent`.
- Use Turbine (`.test { }`) for Flow assertions; it handles cancellation and timeout cleanly.
- Prefer **fakes** over mocks for collaborators; mock only process boundaries (network, clock, I/O).

See `references/testing-coroutines.md` for fake `DataClient` scaffolding, reconnection tests, and deduplication assertions.

---

## Anti-Patterns

| Anti-pattern | Correct approach |
|--------------|------------------|
| `GlobalScope.launch { }` | Scope the coroutine (e.g. `viewModelScope`, passed-in `CoroutineScope`) |
| Missing `awaitClose` in `callbackFlow` | Always register cleanup |
| Blocking with `Thread.sleep` inside a coroutine | `delay(...)` |
| Ignoring backpressure on fast producers | `buffer(64, DROP_OLDEST)` or `conflate` |
| `flowOn(Dispatchers.Main)` at the end of the chain | `flowOn` only affects upstream; UI dispatch happens at the collector |
| `Flow.catch { }` after the collector | Place `catch` before `collect` |

---

## Quick decision tree

```
Need async work?
    ├─ Simple holder updated synchronously      → kotlin-expert (StateFlow patterns)
    ├─ Listener/callback → Flow                  → callbackFlow (§Core Patterns)
    ├─ Multiple concurrent children              → supervisorScope / coroutineScope
    ├─ Transform/compose Flows                   → §Advanced Operators
    ├─ Hot sharing of cold upstream              → shareIn / stateIn
    ├─ Timing-sensitive input                    → debounce / sample / conflate
    └─ Test async code                           → runTest + Turbine
```

## Bundled references

- `references/advanced-flow-operators.md` — operator catalogue with retry, cache-then-observe, dispatcher placement.
- `references/data-source-patterns.md` — WebSocket/API subscription lifecycles, reconnect-on-connectivity, deduplication cache.
- `references/testing-coroutines.md` — fakes, Turbine patterns, time control, cancellation testing.

## Official docs

- [Coroutines guide](https://kotlinlang.org/docs/coroutines-guide.html)
- [Flow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/)
- [Testing coroutines](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-test/)
- [Turbine](https://github.com/cashapp/turbine)
