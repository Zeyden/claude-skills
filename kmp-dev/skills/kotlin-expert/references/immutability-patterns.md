# Immutability Patterns

@Immutable annotation, data classes, and immutable collections for Compose performance.

## Why Immutability Matters

### Compose Recomposition
```kotlin
// Without @Immutable - Recomposes every time parent recomposes
@Composable
fun ItemCard(item: DataRecord) { Text(item.title) }

// With @Immutable - Only recomposes when item reference changes
@Immutable
data class DataRecord(val id: String, val title: String, val content: String)

@Composable
fun ItemCard(item: DataRecord) { Text(item.title) }  // Smart recomposition
```

## @Immutable Annotation

**Requirements:**
1. All properties must be `val`
2. No mutable collections
3. Nested objects also immutable
4. No public mutable state

### @Immutable vs @Stable
- **@Immutable**: Value never changes after construction
- **@Stable**: Value can change, but changes are tracked via `mutableStateOf`

## Data Classes & copy()

```kotlin
@Immutable
data class ConnectionStatus(val url: String, val connected: Boolean, val error: String? = null)

val status = ConnectionStatus(url = "wss://api.example.com", connected = false)
val updated = status.copy(connected = true)  // Original unchanged
```

**Important:** All properties in constructor for proper `equals()`/`hashCode()`.

## Immutable Collections

```kotlin
import kotlinx.collections.immutable.*

val items: ImmutableList<String> = persistentListOf("a", "b")
val updated = items.add("c")  // items unchanged, updated has 3

// StateFlow with immutable state
@Immutable
data class ListState(
    val items: ImmutableList<Item>,
    val loading: Boolean,
    val error: String?
)
```

**When to use:**
- Compose state in @Immutable classes
- Sharing across coroutines
- Frequent modifications (structural sharing is efficient)

## Anti-Patterns

- **var in @Immutable** → All properties must be `val`
- **MutableList in @Immutable** → Use ImmutableList
- **Mutable nested objects** → Deep immutability required
- **Exposing internal mutable state** → Convert to immutable at boundary

## Checklist

- [ ] All properties are `val`
- [ ] No mutable collections
- [ ] Nested objects also `@Immutable`
- [ ] Use `copy()` for updates
- [ ] LazyColumn uses `key` parameter

## References

- [Compose Performance | Android Developers](https://developer.android.com/jetpack/compose/performance/stability)
- [kotlinx.collections.immutable | GitHub](https://github.com/Kotlin/kotlinx.collections.immutable)
