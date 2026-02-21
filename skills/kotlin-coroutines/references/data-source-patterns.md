# Data Source Patterns

Proven coroutine patterns for WebSocket/API connections, subscriptions, and data streaming.

## WebSocket Connection as Flow

```kotlin
fun WebSocketClient.observeAsFlow(url: String): Flow<DataItem> = callbackFlow {
    val connection = connect(url, object : WebSocketListener {
        override fun onMessage(text: String) {
            val item = parseItem(text)
            trySend(item)
        }
        override fun onOpen() { trySend(DataItem.ConnectionOpened) }
        override fun onClose(code: Int, reason: String) { close() }
        override fun onError(error: Throwable) { close(error) }
    })
    awaitClose { connection.close() }
}
```

## Multiple Data Source Merge

```kotlin
fun observeFromSources(servers: List<String>, filters: List<QueryFilter>): Flow<DataItem> =
    servers.map { server ->
        client.observeAsFlow(server, filters).flatMapConcat { it.asFlow() }
    }.merge()
    .distinctBy { it.id }
```

## Structured Concurrency for Connections

```kotlin
suspend fun subscribeToAll(sources: List<DataSource>) = supervisorScope {
    sources.forEach { source ->
        launch {
            source.subscribe(filters).collect { item -> itemChannel.send(item) }
        }
    }
}
```
**supervisorScope:** One failure doesn't cancel others.

## Backpressure Handling

```kotlin
// High-frequency streams: drop oldest
dataFlow.buffer(64, BufferOverflow.DROP_OLDEST).collect { process(it) }

// UI updates: keep only latest
dataFlow.map { toUiItem(it) }.conflate().flowOn(Dispatchers.Default)
```

## Reconnect on Connectivity Change

```kotlin
connectivityFlow.flatMapLatest { status ->
    when (status) {
        is ConnectivityStatus.Active -> dataPool.observeItems()
        else -> emptyFlow()
    }
}.collect { item -> handleItem(item) }
```

## Retry with Exponential Backoff

```kotlin
fun connectWithRetry(source: DataSource): Flow<ConnectionStatus> = flow {
    var attempt = 0
    while (attempt < 5) {
        try {
            emit(ConnectionStatus.Connecting)
            source.connect()
            emit(ConnectionStatus.Connected)
            return@flow
        } catch (e: Exception) {
            attempt++
            emit(ConnectionStatus.Error(e, attempt))
            if (attempt < 5) delay(1000L * (1L shl attempt))
        }
    }
    emit(ConnectionStatus.Failed)
}
```

## Shared Upstream for Multiple Collectors

```kotlin
val items: SharedFlow<DataItem> = client.observeAsFlow(server, filters)
    .flatMapConcat { it.asFlow() }
    .shareIn(scope = viewModelScope, started = SharingStarted.WhileSubscribed(5000), replay = 0)
```

## Deduplication Cache

```kotlin
class ItemCache {
    private val seen = mutableSetOf<String>()
    fun filterNew(items: List<DataItem>): List<DataItem> =
        items.filter { it.id !in seen }.also { new -> seen.addAll(new.map { it.id }) }
}
```

## Subscription Lifecycle in Compose

```kotlin
@Composable
fun ObserveItems(filters: List<QueryFilter>, onItem: (DataItem) -> Unit) {
    val scope = rememberCoroutineScope()
    DisposableEffect(filters) {
        val job = scope.launch {
            dataClient.observeAsFlow(filters).collect { items -> items.forEach { onItem(it) } }
        }
        onDispose { job.cancel() }
    }
}
```

## Exception Handling Pattern

```kotlin
class DataService {
    val exceptionHandler = CoroutineExceptionHandler { _, throwable ->
        Log.e("DataService", "Caught: ${throwable.message}", throwable)
    }
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob() + exceptionHandler)

    fun destroy() { scope.cancel() }
}
```
