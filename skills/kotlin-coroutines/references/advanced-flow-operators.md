# Advanced Flow Operators

Comprehensive guide to Flow operators for complex async patterns.

## Transformation Operators

### flatMapLatest - Cancel Previous, Switch to New
```kotlin
searchQuery.flatMapLatest { query -> repository.search(query) }.collect { results -> updateUI(results) }
```

### flatMapConcat - Sequential Processing
```kotlin
itemIds.flatMapConcat { id -> repository.fetchItem(id) }.collect { item -> process(item) }
```

### flatMapMerge - Concurrent Processing
```kotlin
sources.flatMapMerge(concurrency = 10) { source -> source.subscribe(filters) }.collect { item -> handle(item) }
```

## Combination Operators

### combine - Latest from Multiple Flows
```kotlin
combine(userFlow, settingsFlow, connectivityFlow) { user, settings, connectivity ->
    AppState(user, settings, connectivity)
}.collect { state -> render(state) }
```

### merge - Combine Multiple Flows
```kotlin
merge(source1.items, source2.items, source3.items).collect { item -> handle(item) }
```

## Backpressure & Buffering

### shareIn - Hot Flow from Cold
```kotlin
val shared = repository.observeItems()
    .shareIn(scope = viewModelScope, started = SharingStarted.WhileSubscribed(5000), replay = 0)
```

### stateIn - StateFlow from Cold Flow
```kotlin
val uiState: StateFlow<UiState> = repository.observeData()
    .map { UiState.Success(it) }
    .stateIn(scope = viewModelScope, started = SharingStarted.WhileSubscribed(5000), initialValue = UiState.Loading)
```

### buffer - Control Backpressure
```kotlin
itemFlow.buffer(capacity = 64, onBufferOverflow = BufferOverflow.DROP_OLDEST).collect { slowProcessor(it) }
```

## Debouncing & Throttling

```kotlin
searchQuery.debounce(300).flatMapLatest { query -> search(query) }  // Wait for typing pause
sensorData.sample(1000).collect { data -> process(data) }  // Sample every 1s
```

## Error Handling

```kotlin
repository.fetchData()
    .catch { e -> emit(emptyList()) }  // Only catches UPSTREAM errors
    .collect { data -> updateUI(data) }

connection.retry(3) { cause -> cause is IOException }  // Retry on network errors
```

## Context Switching

```kotlin
repository.fetchData()
    .map { heavyProcessing(it) }
    .flowOn(Dispatchers.Default)  // Heavy work offloaded; only affects UPSTREAM
    .collect { updateUI(it) }
```

## Common Patterns

### Retry with Exponential Backoff
```kotlin
fun <T> Flow<T>.retryWithBackoff(maxRetries: Int = 3, initialDelay: Long = 1000): Flow<T> =
    retryWhen { cause, attempt ->
        if (attempt >= maxRetries || cause !is IOException) false
        else { delay(initialDelay * (1L shl attempt.toInt())); true }
    }
```

### Load + Cache + Observe
```kotlin
fun observeWithCache(id: String): Flow<Data> = flow {
    cache[id]?.let { emit(it) }
    emitAll(repository.observe(id))
}.distinctUntilChanged()
```

## Performance Tips

1. **shareIn** for expensive operations shared by multiple collectors
2. **conflate()** or **DROP_OLDEST** for UI updates
3. **distinctUntilChanged()** to skip redundant emissions
4. **flowOn placement** after expensive operators
