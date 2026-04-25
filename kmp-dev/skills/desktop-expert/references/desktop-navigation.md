# Desktop Navigation Patterns

NavigationRail and multi-pane layouts for desktop apps.

## NavigationRail (Primary Pattern)

Desktop uses vertical sidebar instead of Android's bottom navigation.

```kotlin
Row(Modifier.fillMaxSize()) {
    NavigationRail(modifier = Modifier.width(80.dp).fillMaxHeight()) {
        NavigationRailItem(icon = { Icon(Icons.Default.Home, "Home") }, label = { Text("Home") }, selected = currentScreen == Screen.Home, onClick = { currentScreen = Screen.Home })
        NavigationRailItem(icon = { Icon(Icons.Default.Email, "Messages") }, label = { Text("Messages") }, selected = currentScreen == Screen.Messages, onClick = { currentScreen = Screen.Messages })
    }
    VerticalDivider()
    Box(Modifier.weight(1f).fillMaxHeight()) {
        when (currentScreen) { Screen.Home -> HomeScreen(); Screen.Messages -> MessagesScreen() }
    }
}
```

## Multi-Pane Layout

Desktop can leverage wide screens:
```kotlin
Row {
    NavigationRail { /* ... */ }
    Box(Modifier.weight(0.6f)) { ContentList() }
    if (selectedItem != null) {
        VerticalDivider()
        Box(Modifier.weight(0.4f)) { ItemDetailPane(selectedItem) }
    }
}
```

## Why NavigationRail?
- Desktop has horizontal space (1200+ dp width)
- Vertical sidebar is standard desktop pattern
- Always visible (no hidden tabs)
- Icon + label both visible

## Android Comparison
- Android: `NavigationBar` (horizontal, bottom)
- Desktop: `NavigationRail` (vertical, left)
