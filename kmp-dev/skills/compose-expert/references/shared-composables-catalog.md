# Shared Composables Catalog

Common UI components for `shared/src/commonMain` in KMP projects.

## Buttons
```kotlin
@Composable
fun ActionButton(onClick: () -> Unit, text: String = "Action", modifier: Modifier = Modifier, enabled: Boolean = true) {
    OutlinedButton(modifier = modifier, enabled = enabled, onClick = onClick, shape = RoundedCornerShape(20.dp)) {
        Text(text = text, textAlign = TextAlign.Center)
    }
}
```

## Cards
```kotlin
@Composable
fun ItemCard(item: ItemDisplayData, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Card(modifier = modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Column(Modifier.padding(16.dp)) {
            Text(item.title, style = MaterialTheme.typography.titleMedium)
            Text(item.subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
```

## State Visualization
```kotlin
@Composable
fun LoadingState(message: String = "Loading...") {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator()
            Spacer(Modifier.height(16.dp))
            Text(message)
        }
    }
}

@Composable
fun EmptyState(title: String, onRefresh: (() -> Unit)? = null) { /* ... */ }

@Composable
fun ErrorState(message: String, onRetry: (() -> Unit)? = null) { /* ... */ }
```

## Connection Status
```kotlin
@Composable
fun ConnectionStatusIndicator(connectedCount: Int) {
    val color = when { connectedCount == 0 -> Color.Red; connectedCount < 3 -> Color.Yellow; else -> Color.Green }
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(if (connectedCount > 0) Icons.Default.Check else Icons.Default.Close, null, tint = color, modifier = Modifier.size(16.dp))
        Text("$connectedCount source${if (connectedCount != 1) "s" else ""}")
    }
}
```

## Placeholders
```kotlin
@Composable
fun PlaceholderScreen(title: String, description: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier) {
        Text(title, style = MaterialTheme.typography.headlineMedium)
        Spacer(Modifier.height(16.dp))
        Text(description, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
```

## Sharing Principle

All components here use only Material3 primitives - no platform APIs. They work on Android, Desktop, and iOS.
