# Desktop Compose APIs

Complete catalog of Desktop-only Compose APIs.

## Window Management
- `application {}` - Root composable for desktop apps
- `Window()` - Creates a window with title, state, close handler
- `rememberWindowState()` - Manages window size/position
- `WindowPosition.Aligned()` - Position window on screen

## MenuBar
- `MenuBar {}` - Window-level menu bar
- `Menu()` - Menu category (File, Edit, View)
- `Item()` - Menu item with onClick and optional shortcut
- `Separator()` - Visual separator between items
- `CheckboxItem()` - Toggleable menu item

## System Tray
- `Tray()` - System tray icon with menu
- `onAction` - Double-click handler
- `menu {}` - Tray context menu

## Keyboard Shortcuts
- `KeyShortcut(Key.N, ctrl = true)` - Windows/Linux
- `KeyShortcut(Key.N, meta = true)` - macOS (Cmd)
- `KeyShortcut(Key.S, ctrl = true, shift = true)` - Ctrl+Shift+S

## Navigation Components
- `NavigationRail` - Vertical sidebar navigation
- `NavigationRailItem` - Individual nav item with icon + label
- `VerticalDivider()` - Divider between rail and content

## Scrollbars
- `VerticalScrollbar()` - Vertical scrollbar overlay
- `HorizontalScrollbar()` - Horizontal scrollbar overlay
- `rememberScrollbarAdapter()` - Adapter for scroll state

## Dialogs
- `Dialog()` - Modal dialog window
- `FileDialog` (AWT) - Native file open/save dialog

## Desktop.getDesktop()
- `browse(URI)` - Open URL in default browser
- `open(File)` - Open file with default app
- `mail(URI)` - Open default email client
