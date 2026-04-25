# Keyboard Shortcuts

Standard keyboard shortcuts by OS for desktop apps.

## OS-Aware Shortcut Helper

```kotlin
object DesktopShortcuts {
    private val isMacOS = System.getProperty("os.name").lowercase().contains("mac")

    fun primary(key: Key) = if (isMacOS) KeyShortcut(key, meta = true) else KeyShortcut(key, ctrl = true)
    fun primaryShift(key: Key) = if (isMacOS) KeyShortcut(key, meta = true, shift = true) else KeyShortcut(key, ctrl = true, shift = true)

    val modifierName = if (isMacOS) "Cmd" else "Ctrl"
}
```

## Standard Shortcuts

| Action | macOS | Windows/Linux |
|--------|-------|---------------|
| New | Cmd+N | Ctrl+N |
| Open | Cmd+O | Ctrl+O |
| Save | Cmd+S | Ctrl+S |
| Close | Cmd+W | Ctrl+W |
| Quit | Cmd+Q | Ctrl+Q (Alt+F4) |
| Settings | Cmd+, | Ctrl+, |
| Copy | Cmd+C | Ctrl+C |
| Paste | Cmd+V | Ctrl+V |
| Cut | Cmd+X | Ctrl+X |
| Undo | Cmd+Z | Ctrl+Z |
| Redo | Cmd+Shift+Z | Ctrl+Shift+Z |
| Find | Cmd+F | Ctrl+F |
| Select All | Cmd+A | Ctrl+A |
| Refresh | Cmd+R | Ctrl+R |

## Modifier Keys

| Modifier | macOS | Windows/Linux |
|----------|-------|---------------|
| Primary | `meta = true` (Cmd) | `ctrl = true` |
| Secondary | `ctrl = true` | `alt = true` |
| Shift | `shift = true` | `shift = true` |

## Tooltip Format

Show keyboard shortcut in tooltip:
```kotlin
TooltipButton(tooltip = "Refresh (${DesktopShortcuts.modifierName}+R)", onClick = { refresh() }) {
    Icon(Icons.Default.Refresh, "Refresh")
}
```
