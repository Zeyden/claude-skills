---
name: desktop-expert
description: Compose Multiplatform Desktop development expertise. Desktop-specific APIs (Window, Tray, MenuBar, Dialog), OS conventions, navigation patterns (NavigationRail, multi-window), keyboard shortcuts, file system integration, and UX principles. Use when working with composeApp/ module files, Desktop-only APIs, keyboard shortcuts, menu systems, file pickers, or OS-specific behavior.
---

# Desktop Expert

Expert in Compose Multiplatform Desktop development. Covers Desktop-specific APIs, OS conventions, navigation patterns, and UX principles.

## Desktop Entry Point

```kotlin
fun main() = application {
    val windowState = rememberWindowState(width = 1200.dp, height = 800.dp)
    Window(
        onCloseRequest = ::exitApplication,
        state = windowState,
        title = "My App"
    ) {
        MenuBar { /* ... */ }
        App()
    }
}
```

## MenuBar + OS-Aware Shortcuts

```kotlin
val isMacOS = System.getProperty("os.name").lowercase().contains("mac")

MenuBar {
    Menu("File") {
        Item("New Item",
            shortcut = if (isMacOS) KeyShortcut(Key.N, meta = true) else KeyShortcut(Key.N, ctrl = true),
            onClick = { /* ... */ })
        Separator()
        Item("Quit", onClick = ::exitApplication)
    }
}
```

| Action | macOS | Windows/Linux |
|--------|-------|---------------|
| New | Cmd+N | Ctrl+N |
| Save | Cmd+S | Ctrl+S |
| Quit | Cmd+Q | Ctrl+Q |
| Settings | Cmd+, | Ctrl+, |

## Navigation: NavigationRail

```kotlin
Row(Modifier.fillMaxSize()) {
    NavigationRail(modifier = Modifier.width(80.dp).fillMaxHeight()) {
        NavigationRailItem(
            icon = { Icon(Icons.Default.Home, "Home") },
            label = { Text("Home") },
            selected = currentScreen == Screen.Home,
            onClick = { currentScreen = Screen.Home }
        )
    }
    VerticalDivider()
    Box(Modifier.weight(1f).fillMaxHeight()) {
        when (currentScreen) {
            Screen.Home -> HomeScreen()
            // ...
        }
    }
}
```

## System Tray

```kotlin
Tray(
    icon = painterResource("icon.png"),
    onAction = { isVisible = true },
    menu = {
        Item("Show", onClick = { isVisible = true })
        Item("Quit", onClick = ::exitApplication)
    }
)
```

## Packaging

```kotlin
nativeDistributions {
    targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
    packageName = "MyApp"
    macOS { bundleID = "com.example.app.desktop" }
}
```

## Delegation

- **gradle-expert**: Build config, packaging issues
- **compose-expert**: Shared composables, Material3
- **kotlin-multiplatform**: Shared code, source sets

## References

- `references/desktop-compose-apis.md` - Desktop API catalog
- `references/desktop-components.md` - Desktop-specific components (file dialog, scrollbar, tooltips)
- `references/desktop-navigation.md` - NavigationRail patterns
- `references/keyboard-shortcuts.md` - Standard shortcuts by OS
- `references/os-detection.md` - Platform detection patterns
