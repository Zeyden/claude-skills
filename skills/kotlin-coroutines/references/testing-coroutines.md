# Testing Coroutines

Comprehensive guide for testing async code with runTest, Turbine, and best practices.

## runTest - Standard Testing

```kotlin
@Test
fun `test suspend function`() = runTest {
    val result = repository.fetchData()
    assertEquals(expected, result)
}

@Test
fun `stateflow updates correctly`() = runTest {
    val viewModel = MyViewModel()
    assertEquals(UiState.Loading, viewModel.state.value)
    viewModel.loadData()
    advanceUntilIdle()
    assertEquals(UiState.Success(data), viewModel.state.value)
}
```

**Time control:** `advanceTimeBy(millis)`, `advanceUntilIdle()`, `runCurrent()`

## Turbine - Flow Testing

```kotlin
@Test
fun `flow emits expected values`() = runTest {
    repository.observeData().test {
        assertEquals(Item1, awaitItem())
        assertEquals(Item2, awaitItem())
        awaitComplete()
    }
}

@Test
fun `data source subscription receives items`() = runTest {
    val client = FakeDataClient()
    client.observeAsFlow(server, filters).test {
        assertEquals(emptyList(), awaitItem())
        client.sendItem(item1)
        assertEquals(listOf(item1), awaitItem())
        cancelAndIgnoreRemainingEvents()
    }
}
```

**Assertions:** `awaitItem()`, `awaitComplete()`, `awaitError()`, `expectNoEvents()`, `cancelAndIgnoreRemainingEvents()`

## Testing Patterns

### Reconnection Test
```kotlin
@Test
fun `reconnects on connectivity change`() = runTest {
    val connectivity = MutableStateFlow(ConnectivityStatus.Off)
    val pool = FakeConnectionPool()
    connectivity.flatMapLatest { status ->
        when (status) { is Active -> pool.connectAll(); else -> emptyFlow() }
    }.test {
        expectNoEvents()
        connectivity.value = ConnectivityStatus.Active(1L, false)
        assertTrue(pool.connected)
        cancelAndIgnoreRemainingEvents()
    }
}
```

### Deduplication Test
```kotlin
@Test
fun `deduplicates items across sources`() = runTest {
    val source1 = FakeDataSource()
    val source2 = FakeDataSource()
    merge(source1.items, source2.items).distinctBy { it.id }.test {
        source1.send(item1)
        source2.send(item1)  // Same item
        assertEquals(item1, awaitItem())
        expectNoEvents()  // Only one emission
        cancelAndIgnoreRemainingEvents()
    }
}
```

### Retry Test
```kotlin
@Test
fun `retries failed connections`() = runTest {
    var attempts = 0
    flow { attempts++; if (attempts < 3) throw IOException(); emit("Success") }
        .retry(3).test {
            assertEquals("Success", awaitItem())
            awaitComplete()
            assertEquals(3, attempts)
        }
}
```

## Fakes over Mocks

```kotlin
class FakeDataClient {
    private val subscriptions = mutableMapOf<String, MutableSharedFlow<DataItem>>()

    fun observeAsFlow(server: String, filters: List<QueryFilter>): Flow<List<DataItem>> = callbackFlow {
        val flow = MutableSharedFlow<DataItem>()
        subscriptions[server] = flow
        val items = mutableListOf<DataItem>()
        flow.collect { item -> items.add(item); send(items.toList()) }
        awaitClose { subscriptions.remove(server) }
    }

    fun sendItem(item: DataItem) { subscriptions.values.forEach { it.tryEmit(item) } }
}
```

## Best Practices

1. Use `runTest` for all coroutine tests
2. Use Turbine for Flow testing
3. Test both success and error paths
4. Control virtual time explicitly
5. Create fakes, not mocks
6. Test cancellation behavior
