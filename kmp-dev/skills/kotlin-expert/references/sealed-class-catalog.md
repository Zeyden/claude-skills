# Sealed Class Catalog

Comprehensive sealed type patterns for KMP projects.

## State Management

### AuthState (Sealed Class)
```kotlin
sealed class AuthState {
    data object LoggedOut : AuthState()
    data class LoggedIn(val userId: String, val displayName: String, val token: String?, val isReadOnly: Boolean) : AuthState()
}
```
**Why sealed class:** Two distinct states with different data. `LoggedIn` holds data, `LoggedOut` doesn't.

### VerificationState (Sealed Class)
```kotlin
sealed class VerificationState {
    data object NotStarted : VerificationState()
    data object Started : VerificationState()
    data class Failed(val reason: String) : VerificationState()
    data object Verified : VerificationState()
}
```
**Pattern:** State machine (NotStarted → Started → Failed/Verified).

## Result Types

### OperationResult (Sealed Interface with Generics)
```kotlin
sealed interface OperationResult<out T> {
    data class Success<T>(val value: T) : OperationResult<T>
    data class Error(val message: String) : OperationResult<Nothing>
    data object Loading : OperationResult<Nothing>
}

fun <T> OperationResult<T>.getOrNull(): T? = when (this) {
    is OperationResult.Success -> value
    else -> null
}
```
**Why sealed interface:** Generic result type with covariance (`out T`).

### CacheResults (Sealed Class with Generics)
```kotlin
sealed class CacheResults<T> {
    data class Found<T>(val value: T) : CacheResults<T>()
    class NotFound<T> : CacheResults<T>()
}
```

## Exception Hierarchies

```kotlin
sealed class ServiceExceptions(message: String) : Exception(message) {
    class UnableToProcess(message: String) : ServiceExceptions(message)
    class UnableToDecrypt(message: String) : ServiceExceptions(message)
    class UnableToEncrypt(message: String) : ServiceExceptions(message)
    class UnableToAuthenticate(message: String) : ServiceExceptions(message)
}
```

## Patterns

### State Machine
```kotlin
sealed class ConnectionState {
    data object Disconnected : ConnectionState()
    data object Connecting : ConnectionState()
    data class Connected(val server: String) : ConnectionState()
    data class Failed(val error: String) : ConnectionState()
}
```

### Nested Sealed Hierarchies
```kotlin
sealed interface UiState {
    sealed interface Loading : UiState {
        data object Initial : Loading
        data class Refreshing(val currentData: List<Item>) : Loading
    }
    sealed interface Content : UiState {
        data class Success(val data: List<Item>) : Content
        data object Empty : Content
    }
    sealed interface Error : UiState {
        data class Network(val message: String) : Error
        data class Server(val code: Int, val message: String) : Error
    }
}
```

## Decision Tree

```
Need variants of a concept? → sealed type (else regular class)
Variants have different data? → sealed (else enum)
Need generics with variance? → sealed interface
Need common constructor? → sealed class
Need multiple inheritance? → sealed interface
State machine? → sealed class
Result/error types? → sealed interface (if generic)
```

## References

- [Sealed Classes | Kotlin Docs](https://kotlinlang.org/docs/sealed-classes.html)
- [Effective Kotlin: Sealed Classes](https://kt.academy/article/ek-sealed-classes)
