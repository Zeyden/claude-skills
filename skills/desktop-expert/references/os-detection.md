# OS Detection

Platform detection patterns for desktop apps.

## Basic Detection

```kotlin
val osName = System.getProperty("os.name").lowercase()

val isMacOS = osName.contains("mac")
val isWindows = osName.contains("win")
val isLinux = osName.contains("nux") || osName.contains("nix")
```

## Menu Bar Behavior

| OS | Behavior |
|----|----------|
| **macOS** | System-wide menu bar at top of screen |
| **Windows** | In-window menu bar |
| **Linux** | Varies by desktop environment |

Compose Desktop `MenuBar` adapts automatically.

## System Tray Location

| OS | Location |
|----|----------|
| **macOS** | Top-right menu bar |
| **Windows** | Bottom-right taskbar |
| **Linux** | Top panel (varies) |

## File Paths

```kotlin
val homeDir = System.getProperty("user.home")
val appDataDir = when {
    isMacOS -> "$homeDir/Library/Application Support/MyApp"
    isWindows -> System.getenv("APPDATA") + "/MyApp"
    else -> "$homeDir/.config/myapp"
}
```

## Open External URL

```kotlin
fun openUrl(url: String) {
    if (java.awt.Desktop.isDesktopSupported()) {
        java.awt.Desktop.getDesktop().browse(java.net.URI(url))
    }
}
```
