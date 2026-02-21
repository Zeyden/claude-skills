# Custom Icon Patterns

ImageVector patterns for multiplatform icon assets.

## Why ImageVector?
- Pure Kotlin, no XML resources
- Works on Android, Desktop, iOS
- GPU-accelerated rendering
- Type-safe

## Building Custom Icons

```kotlin
fun customIconBuilder(
    name: String = "CustomIcon",
    width: Dp = 24.dp,
    height: Dp = 24.dp,
    viewportWidth: Float = 24f,
    viewportHeight: Float = 24f,
    block: ImageVector.Builder.() -> Unit
): ImageVector {
    return ImageVector.Builder(
        name = name,
        defaultWidth = width, defaultHeight = height,
        viewportWidth = viewportWidth, viewportHeight = viewportHeight
    ).apply(block).build()
}
```

## Path Data

```kotlin
private val checkPath = PathData {
    moveTo(9f, 16.17f)
    lineToRelative(-4.17f, -4.17f)
    lineToRelative(-1.42f, 1.41f)
    lineToRelative(5.59f, 5.59f)
    lineToRelative(12f, -12f)
    lineToRelative(-1.41f, -1.41f)
    close()
}

fun buildCheckIcon(color: SolidColor, builder: ImageVector.Builder) {
    builder.addPath(pathData = checkPath, fill = color)
}
```

## Usage in Composables

```kotlin
@Composable
fun CustomCheckIcon(tint: Color = MaterialTheme.colorScheme.primary) {
    Image(
        painter = rememberVectorPainter(
            customIconBuilder {
                buildCheckIcon(SolidColor(tint), this)
            }
        ),
        contentDescription = "Check"
    )
}
```

## Caching Pattern

```kotlin
object AppIcons {
    private val cache = mutableMapOf<String, ImageVector>()
    fun get(key: String): ImageVector = cache.getOrPut(key) { buildIcon(key) }
}
```

## Converting SVG to ImageVector
1. Export SVG from design tool
2. Convert to PathData using Android Studio or svg-to-compose tools
3. Create icon function with customIconBuilder
4. Add caching if generated dynamically
