# State Patterns

State management patterns for Compose Multiplatform.

## remember - Simple UI State
```kotlin
var isExpanded by remember { mutableStateOf(false) }
var searchQuery by remember { mutableStateOf("") }
```

## derivedStateOf - Optimize Frequent Changes
```kotlin
val showScrollToTop by remember { derivedStateOf { listState.firstVisibleItemIndex > 0 } }
```
**Use when:** Input changes frequently, derived result changes rarely.

## produceState - Async to Compose State
```kotlin
val user by produceState<User?>(initialValue = null, userId) {
    value = repository.fetchUser(userId)
}
```

## State Hoisting Pattern
```kotlin
// Stateless (reusable, testable)
@Composable
fun SearchBar(query: String, onQueryChange: (String) -> Unit, modifier: Modifier = Modifier) {
    TextField(value = query, onValueChange = onQueryChange, modifier = modifier)
}

// Stateful wrapper
@Composable
fun SearchScreen() {
    var query by remember { mutableStateOf("") }
    SearchBar(query = query, onQueryChange = { query = it })
}
```

## StateFlow Collection
```kotlin
// Android
val state by viewModel.state.collectAsStateWithLifecycle()

// Compose Multiplatform (shared)
val state by viewModel.state.collectAsState()
```

## UiState Pattern
```kotlin
sealed class UiState<out T> {
    data object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}

@Composable
fun DataScreen(state: UiState<List<Item>>) {
    when (state) {
        is UiState.Loading -> LoadingState()
        is UiState.Success -> ItemList(state.data)
        is UiState.Error -> ErrorState(state.message)
    }
}
```

## Anti-Patterns
- **Stateful shared components** → Hoist state up
- **derivedStateOf without remember** → Must wrap in `remember {}`
- **Direct Flow collection in composable** → Use collectAsState()
