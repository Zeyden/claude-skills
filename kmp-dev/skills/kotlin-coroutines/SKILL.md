---
name: kotlin-coroutines
description: Advanced Kotlin coroutines patterns for KMP projects. Use when working with: (1) Structured concurrency (supervisorScope, coroutineScope), (2) Advanced Flow operators (flatMapLatest, combine, merge, shareIn, stateIn), (3) Channels and callbackFlow, (4) Dispatcher management and context switching, (5) Exception handling (CoroutineExceptionHandler, SupervisorJob), (6) Testing async code (runTest, Turbine), (7) WebSocket/API connection pools and subscriptions, (8) Backpressure handling in event streams. Delegates to kotlin-expert for basic StateFlow/SharedFlow patterns.
---

# Kotlin Coroutines - Advanced Async Patterns

Expert guidance for complex async operations: data source pools, item streams, structured concurrency, and testing.

## Mental Model

```
DataSourcePool (supervisorScope)
    ├── Source 1 (launch) → callbackFlow → Items
    ├── Source 2 (launch) → callbackFlow → Items
    └── Source 3 (launch) → callbackFlow → Items
            ↓
    merge() → distinctBy(id) → shareIn
            ↓
    Multiple Collectors (ViewModels, Services)
```

**Key principles:**
- **supervisorScope** - Children fail independently
- **callbackFlow** - Bridge callbacks to Flow
- **shareIn/stateIn** - Hot flows from cold
- **Backpressure** - buffer(), conflate(), DROP_OLDEST

## Core Patterns

### Pattern: callbackFlow for WebSocket/API Subscriptions

```kotlin
fun DataSourceClient.observeAsFlow(
    server: String,
    filters: List<QueryFilter>,
): Flow<List<DataItem>> = callbackFlow {
    val subId = UUID.randomUUID().toString()
    var initialLoadComplete = false
    val itemIds = mutableSetOf<String>()
    var currentItems = listOf<DataItem>()

    val listener = object : DataSourceListener {
        override fun onItem(item: DataItem) {
            if (item.id !in itemIds) {
                currentItems = if (initialLoadComplete) {
                    listOf(item) + currentItems  // After initial load: prepend
                } else {
                    currentItems + item  // During initial load: append
                }
                itemIds.add(item.id)
                trySend(currentItems)
            }
        }
        override fun onInitialLoadComplete() { initialLoadComplete = true }
    }

    openSubscription(subId, server, filters, listener)
    awaitClose { closeSubscription(subId) }
}
```

### Pattern: Structured Concurrency for Multiple Sources

```kotlin
suspend fun connectToSources(sources: List<DataSource>) = supervisorScope {
    sources.forEach { source ->
        launch {
            try {
                source.connect()
                source.subscribe(filters).collect { item ->
                    itemChannel.send(item)
                }
            } catch (e: IOException) {
                Log.e("DataSource", "Connection failed: ${source.url}", e)
            }
        }
    }
}
```

### Pattern: Merge Items from Multiple Sources

```kotlin
fun observeFromSources(
    servers: List<String>,
    filters: List<QueryFilter>
): Flow<DataItem> =
    servers.map { server ->
        client.observeAsFlow(server, filters)
            .flatMapConcat { it.asFlow() }
    }.merge()
    .distinctBy { it.id }
```

### Pattern: Network Connectivity as Flow

```kotlin
val status = callbackFlow {
    val networkCallback = object : NetworkCallback() {
        override fun onAvailable(network: Network) {
            trySend(ConnectivityStatus.Active(...))
        }
        override fun onLost(network: Network) {
            trySend(ConnectivityStatus.Off)
        }
    }
    connectivityManager.registerCallback(networkCallback)
    activeNetwork?.let { trySend(ConnectivityStatus.Active(...)) }
    awaitClose { connectivityManager.unregisterCallback(networkCallback) }
}
    .distinctUntilChanged()
    .debounce(200)
    .flowOn(Dispatchers.IO)
```

## Advanced Operators

| Operator | Use Case | Example |
|----------|----------|---------|
| **flatMapLatest** | Cancel previous, switch to new | Search (cancel old query) |
| **combine** | Latest from ALL flows | combine(user, settings, connectivity) |
| **merge** | Single stream from multiple | merge(source1, source2, source3) |
| **shareIn** | Multiple collectors, single upstream | Share expensive computation |
| **stateIn** | StateFlow from Flow | ViewModel state |
| **buffer(DROP_OLDEST)** | High-frequency streams | Real-time item feed |
| **conflate** | Latest only | UI updates |
| **debounce** | Wait for quiet period | Search input |

See [advanced-flow-operators.md](references/advanced-flow-operators.md) for detailed examples.

## Anti-Patterns

**Using GlobalScope** → Use scoped coroutines (`viewModelScope.launch`)
**Forgetting awaitClose** → Always cleanup in callbackFlow
**Blocking in Flow** → Use `delay()` + `flowOn()`, not `Thread.sleep()`
**Ignoring backpressure** → Use `buffer(64, DROP_OLDEST)` for fast producers

## Resources

- **references/advanced-flow-operators.md** - All Flow operators with examples
- **references/data-source-patterns.md** - WebSocket/API async patterns
- **references/testing-coroutines.md** - Complete testing guide

## Quick Decision Tree

```
Need async operation?
    ├─ Simple ViewModel state update → kotlin-expert (StateFlow)
    ├─ Android callback → This skill (callbackFlow)
    ├─ Multiple concurrent operations → This skill (supervisorScope)
    ├─ Complex Flow transformation → references/advanced-flow-operators.md
    ├─ WebSocket/API subscription → references/data-source-patterns.md
    └─ Testing async code → references/testing-coroutines.md
```
