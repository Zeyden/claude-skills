# Flow Patterns

StateFlow and SharedFlow usage patterns for KMP projects.

## StateFlow for State Management

### AuthManager Pattern

```kotlin
sealed class AuthState {
    data object LoggedOut : AuthState()
    data class LoggedIn(
        val userId: String,
        val displayName: String,
        val token: String?,
        val isReadOnly: Boolean,
    ) : AuthState()
}

class AuthManager {
    private val _authState = MutableStateFlow<AuthState>(AuthState.LoggedOut)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    fun login(credentials: Credentials): Result<AuthState.LoggedIn> {
        val state = AuthState.LoggedIn(...)
        _authState.value = state
        return Result.success(state)
    }

    fun logout() {
        _authState.value = AuthState.LoggedOut
    }
}
```

### ConnectionManager Pattern

```kotlin
data class ConnectionStatus(
    val url: String,
    val connected: Boolean,
    val error: String? = null,
    val messageCount: Int = 0
)

class ConnectionManager {
    private val _statuses = MutableStateFlow<Map<String, ConnectionStatus>>(emptyMap())
    val statuses: StateFlow<Map<String, ConnectionStatus>> = _statuses.asStateFlow()

    fun addServer(url: String) {
        updateStatus(url) { it.copy(connected = false, error = null) }
    }

    fun removeServer(url: String) {
        _statuses.value = _statuses.value - url
    }

    private fun updateStatus(url: String, update: (ConnectionStatus) -> ConnectionStatus) {
        _statuses.value = _statuses.value.toMutableMap().apply {
            val current = get(url) ?: ConnectionStatus(url, false)
            put(url, update(current))
        }
    }
}
```

## Flow Composition in Compose

```kotlin
@Composable
fun LoginScreen(authManager: AuthManager) {
    val authState by authManager.authState.collectAsState()
    when (authState) {
        is AuthState.LoggedOut -> LoginForm(onLogin = { authManager.login(it) })
        is AuthState.LoggedIn -> MainApp(account = authState as AuthState.LoggedIn)
    }
}
```

## Common Patterns

### Immutable State Updates
```kotlin
_statuses.value = _statuses.value + (url to newStatus)  // Add
_statuses.value = _statuses.value - url  // Remove
_items.value = _items.value + newItem  // Append
_items.value = _items.value.filter { it.id != removedId }  // Remove
_user.value = _user.value.copy(name = newName)  // Update field
```

### Derived State
```kotlin
val itemCount: StateFlow<Int> = items.map { it.size }
    .stateIn(viewModelScope, SharingStarted.Lazily, 0)
```

### State with Loading/Error
```kotlin
sealed class UiState<out T> {
    data object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}
```

## Anti-Patterns

- **Exposing MutableStateFlow publicly** → Use `.asStateFlow()`
- **Mutating collection in-place** → Create new instance (`+ newItem`)
- **StateFlow for one-time events** → Use SharedFlow with replay = 0
- **Blocking operations in state update** → Use coroutines with `withContext(Dispatchers.IO)`

## References

- [StateFlow and SharedFlow | Android Developers](https://developer.android.com/kotlin/flow/stateflow-and-sharedflow)
- [Hot vs Cold Flows](https://carrion.dev/en/posts/kotlin-flows-hot-cold/)
