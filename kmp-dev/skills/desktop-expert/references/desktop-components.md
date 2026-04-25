# Desktop Components

Desktop-specific UI components and patterns (merged from compose-desktop quick reference).

## File Dialog

```kotlin
class FileDialogState {
    var isOpen by mutableStateOf(false)
    var result by mutableStateOf<File?>(null)

    fun open() { isOpen = true }

    @Composable
    fun Dialog(title: String = "Select File", allowedExtensions: List<String> = emptyList()) {
        if (isOpen) {
            DisposableEffect(Unit) {
                val dialog = java.awt.FileDialog(null as java.awt.Frame?, title)
                if (allowedExtensions.isNotEmpty()) {
                    dialog.setFilenameFilter { _, name -> allowedExtensions.any { name.endsWith(it) } }
                }
                dialog.isVisible = true
                result = dialog.file?.let { File(dialog.directory, it) }
                isOpen = false
                onDispose { }
            }
        }
    }
}
```

## Scrollbar Support

```kotlin
@Composable
fun ScrollableColumn(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    val scrollState = rememberScrollState()
    Box(modifier) {
        Column(Modifier.verticalScroll(scrollState).fillMaxSize()) { content() }
        VerticalScrollbar(modifier = Modifier.align(Alignment.CenterEnd), adapter = rememberScrollbarAdapter(scrollState))
    }
}
```

## Keyboard Navigation

```kotlin
@Composable
fun KeyboardNavigableList(items: List<Item>, selectedIndex: Int, onSelect: (Int) -> Unit, onActivate: (Item) -> Unit) {
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) { focusRequester.requestFocus() }

    LazyColumn(modifier = Modifier.focusRequester(focusRequester).focusable().onKeyEvent { event ->
        when {
            event.key == Key.DirectionDown && event.type == KeyEventType.KeyDown -> { onSelect((selectedIndex + 1).coerceAtMost(items.lastIndex)); true }
            event.key == Key.DirectionUp && event.type == KeyEventType.KeyDown -> { onSelect((selectedIndex - 1).coerceAtLeast(0)); true }
            event.key == Key.Enter && event.type == KeyEventType.KeyDown -> { items.getOrNull(selectedIndex)?.let { onActivate(it) }; true }
            else -> false
        }
    }) {
        itemsIndexed(items) { index, item -> ItemCard(item = item, isSelected = index == selectedIndex, modifier = Modifier.clickable { onSelect(index) }) }
    }
}
```

## Multi-Window Support

```kotlin
@Composable
fun ApplicationScope.ItemDetailWindow(item: Item, onClose: () -> Unit) {
    Window(onCloseRequest = onClose, title = "Detail: ${item.title}", state = rememberWindowState(width = 600.dp, height = 400.dp)) {
        ItemDetailScreen(item)
    }
}
```

## Tooltips

```kotlin
@Composable
fun TooltipButton(tooltip: String, onClick: () -> Unit, content: @Composable () -> Unit) {
    TooltipArea(tooltip = {
        Surface(shape = RoundedCornerShape(4.dp), color = MaterialTheme.colorScheme.inverseSurface) {
            Text(text = tooltip, modifier = Modifier.padding(8.dp), color = MaterialTheme.colorScheme.inverseOnSurface)
        }
    }) { IconButton(onClick = onClick) { content() } }
}
```

## Desktop Layout Pattern

```kotlin
@Composable
fun DesktopAppLayout(currentScreen: Screen, onNavigate: (Screen) -> Unit, content: @Composable () -> Unit) {
    Row(Modifier.fillMaxSize()) {
        NavigationRail(modifier = Modifier.width(72.dp), containerColor = MaterialTheme.colorScheme.surfaceVariant) {
            Spacer(Modifier.height(16.dp))
            NavigationRailItem(icon = { Icon(Icons.Default.Home, "Home") }, label = { Text("Home") }, selected = currentScreen == Screen.Home, onClick = { onNavigate(Screen.Home) })
            // More items...
            Spacer(Modifier.weight(1f))
            NavigationRailItem(icon = { Icon(Icons.Default.Settings, "Settings") }, label = { Text("Settings") }, selected = currentScreen == Screen.Settings, onClick = { onNavigate(Screen.Settings) })
        }
        VerticalDivider()
        Box(Modifier.weight(1f).fillMaxHeight()) { content() }
    }
}
```
