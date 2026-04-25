---
name: compose-expert
description: Advanced Compose Multiplatform UI patterns for shared composables. Use when working with visual UI components, state management patterns (remember, derivedStateOf, produceState), recomposition optimization (@Stable/@Immutable visual usage), Material3 theming, custom ImageVector icons, or determining whether to share UI in commonMain vs keep platform-specific. Delegates navigation to android-expert/desktop-expert. Complements kotlin-expert (handles Kotlin language aspects of state/annotations).
---

# Compose Multiplatform Expert

Visual UI patterns for sharing composables across Android and Desktop.

## Philosophy: Share by Default

Default to `shared/src/commonMain` unless platform experts indicate otherwise.

**Always Share:** Buttons, cards, lists, dialogs, inputs, state visualization, icons, theme utilities
**Keep Platform-Specific:** Navigation structure, screen layouts, system integrations, platform UX

## Shared Composable Anatomy

```kotlin
@Composable
fun SharedComponent(
    data: DataClass,              // State (read-only)
    onAction: () -> Unit,         // Events (write-only)
    modifier: Modifier = Modifier, // Layout control
    colors: ComponentColors = ComponentDefaults.colors()  // Optional
) { /* ... */ }
```

**Pattern**: State down, events up.

## State Management

### remember - Cache Across Recompositions
```kotlin
var isExpanded by remember { mutableStateOf(false) }
```

### derivedStateOf - Optimize Frequent Changes
```kotlin
val showButton by remember { derivedStateOf { listState.firstVisibleItemIndex > 0 } }
```

### produceState - Async to Compose State
```kotlin
val user by produceState<User?>(initialValue = null, userId) {
    value = repository.fetchUser(userId)
}
```

## State Hoisting

```kotlin
// Stateless - reusable, testable
@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) { /* ... */ }
```

## Material3 Theming

```kotlin
val bg = MaterialTheme.colorScheme.background
val typography = MaterialTheme.typography.headlineMedium
val shape = MaterialTheme.shapes.medium
```

## Custom Icons: ImageVector Pattern

```kotlin
fun customIconBuilder(block: ImageVector.Builder.() -> Unit): ImageVector {
    return ImageVector.Builder(
        name = "CustomIcon",
        defaultWidth = 24.dp, defaultHeight = 24.dp,
        viewportWidth = 24f, viewportHeight = 24f
    ).apply(block).build()
}
```

## Connection Status Indicator (Example Pattern)

```kotlin
@Composable
fun ConnectionStatusIndicator(connectedCount: Int) {
    val statusColor = when {
        connectedCount == 0 -> ConnectionColors.Disconnected
        connectedCount < 3 -> ConnectionColors.Connecting
        else -> ConnectionColors.Connected
    }
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(
            imageVector = if (connectedCount > 0) Icons.Default.Check else Icons.Default.Close,
            tint = statusColor,
            modifier = Modifier.size(16.dp)
        )
        Text("$connectedCount source${if (connectedCount != 1) "s" else ""}")
    }
}
```

## Performance

- Use `key` parameter in LazyColumn `items()` for stable identity
- Use `derivedStateOf` to avoid recomposing on every scroll pixel
- Mark parameter data classes as `@Immutable`

## Delegation

- **kotlin-expert**: Kotlin language aspects (@Immutable details, StateFlow)
- **android-expert**: Android navigation, platform APIs
- **desktop-expert**: Desktop navigation, window management
- **kotlin-coroutines**: Async patterns, Flow integration

## Resources

- `references/shared-composables-catalog.md` - Shared UI component catalog
- `references/state-patterns.md` - State management patterns
- `references/icon-assets.md` - Custom ImageVector icon patterns
- `scripts/find-composables.sh` - Find all @Composable functions
