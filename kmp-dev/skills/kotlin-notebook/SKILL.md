---
name: kotlin-notebook
description: Kotlin Notebook (.ipynb) development for KMP projects. Creating and editing notebooks, cell structure, dependency management (@file:DependsOn, %use, USE {}), rich output rendering (tables, HTML, images, SVG, LaTeX, Kandy charts), DataFrame data analysis, design token documentation, component catalogues, and Compose UI rendering (ImageComposeScene workaround / future KTNB-650). Use when working with .ipynb files, notebook cells, %use directives, @file:DependsOn annotations, interactive Kotlin documentation, component catalogues in notebooks, Kandy charts, DataFrame operations, or prototyping Kotlin code in notebooks. Complements compose-expert (UI patterns), kotlin-expert (language patterns), kotlin-coroutines (async), and gradle-expert (dependency coordinates).
---

# Kotlin Notebook Expert

Interactive Kotlin notebooks for data analysis, documentation, prototyping, and component catalogues in KMP projects.

## Mental Model

```
Kotlin Notebook (.ipynb)
    |-- Kernel
    |   |-- Kotlin Jupyter kernel (JVM-based, compiles per cell)
    |   |-- State persists across cells (top-to-bottom execution order)
    |   +-- IntelliJ IDEA 2025.1+ (bundled, Community & Ultimate)
    |
    |-- Cells
    |   |-- Code cells         # Executable Kotlin, last expression = output
    |   +-- Markdown cells     # Documentation, headings, tables, LaTeX, HTML
    |
    |-- Dependencies
    |   |-- %use               # Pre-built library integrations (kandy, dataframe, etc.)
    |   |-- @file:DependsOn    # Arbitrary Maven/local dependencies
    |   |-- @file:Repository   # Custom Maven/Ivy repositories
    |   +-- USE {}             # Gradle-like DSL (repos + deps, credentials)
    |
    |-- Rich Output
    |   |-- Tables             # Data classes & collections render as tables
    |   |-- HTML               # HTML() -- raw HTML with CSS/JS (Trusted mode)
    |   |-- Images             # BufferedImage renders as image/png
    |   |-- SVG                # DISPLAY(MimeTypedResult(mapOf("image/svg+xml" to ...)))
    |   |-- Charts             # Kandy (type-safe DSL) or lets-plot (ggplot2-style)
    |   |-- LaTeX              # LATEX() via %use lib-ext
    |   +-- DataFrame          # Rich interactive HTML tables (auto-rendered)
    |
    |-- Data Analysis
    |   |-- DataFrame          # Read CSV/JSON/Excel/Arrow, filter, group, aggregate
    |   |-- Kandy              # Type-safe plotting DSL (bars, lines, points, area, pie)
    |   +-- lets-plot           # Lower-level ggplot2-style API
    |
    +-- Compose UI (future)
        |-- KTNB-650           # Native Compose Desktop rendering (in development)
        +-- ImageComposeScene  # Current workaround: render to BufferedImage
```

**Delegation:**
- **compose-expert**: Composable patterns, Material3 theming, @Preview annotations
- **kotlin-expert**: Kotlin language patterns used in notebook code cells
- **kotlin-coroutines**: Async patterns (runBlocking in cells, Flow collection)
- **gradle-expert**: Dependency coordinates for @file:DependsOn, publishToMavenLocal
- **kotlin-multiplatform**: Source set context when referencing project modules
- **desktop-expert**: Desktop-specific component previews, Skiko platform artifacts

---

## Context

| Property | Value |
|----------|-------|
| IDE | IntelliJ IDEA 2025.1+ (bundled), Datalore, Jupyter Notebook/Lab |
| File type | `.ipynb` (standard Jupyter format) |
| Kernel | Kotlin Jupyter kernel (`pip install kotlin-jupyter-kernel`) |
| JDK | Eclipse Temurin (AdoptOpenJDK HotSpot) recommended; match project `jvmToolchain` |
| Plugin ID | `16340` (auto-enabled in IDEA 2025.1+) |

---

## Library Reference

| Library | `%use` Alias | Maven Coordinates | Version | Purpose |
|---------|-------------|-------------------|---------|---------|
| Kotlin DataFrame | `dataframe` | `org.jetbrains.kotlinx:dataframe` | 1.0.0-Beta4 | Structured data processing (CSV, JSON, Excel, Arrow) |
| Kandy | `kandy` | `org.jetbrains.kotlinx:kandy-lets-plot` | 0.8.3 | Type-safe Kotlin plotting DSL |
| lets-plot | `lets-plot` | `org.jetbrains.lets-plot:lets-plot-kotlin-jvm` | 4.12.1 | ggplot2-style plotting API |
| Multik | `multik` | `org.jetbrains.kotlinx:multik-core` | 0.2.3 | N-dimensional arrays, linear algebra |
| Ktor Client | `ktor-client` | `io.ktor:ktor-client-core-jvm` | 3.4.0 | HTTP client + JSON deserialization |
| Serialization | `serialization` | `org.jetbrains.kotlinx:kotlinx-serialization-json` | 1.7.3 | JSON serialization/deserialization |
| Coroutines | `coroutines` | `org.jetbrains.kotlinx:kotlinx-coroutines-core` | 1.10.2 | Async programming, Flow |
| DateTime | `datetime` | `org.jetbrains.kotlinx:kotlinx-datetime` | 0.7.1 | Date/time types and operations |
| Library Extensions | `lib-ext` | (bundled) | 0.11.0-398 | `Image()`, `LATEX()`, `HTML()` helpers |

**Version override syntax:** `%use dataframe(v=1.0.0-Beta4)` or `%use kandy(0.8.3)`.

**Full list of `%use` descriptors:** [Kotlin/kotlin-jupyter-libraries](https://github.com/Kotlin/kotlin-jupyter-libraries). Run `%use` without arguments to list all available.

---

## Core Rules & Standards

### Cell Organisation

```
Cell 1 (Code):    %useLatestDescriptors (optional), %use directives
Cell 2 (Code):    @file:DependsOn / @file:Repository / USE {} (if needed)
Cell 3 (Markdown): # Notebook Title
Cell 4 (Code):    Data models, shared types
Cell 5 (Markdown): ## Section Heading
Cell 6 (Code):    Data loading / transformation
Cell 7 (Code):    Visualisation / output
...
```

### Mandatory Rules

1. **Dependencies in the first code cell.** `%use`, `@file:DependsOn`, `@file:Repository`, and `USE {}` must appear in the first code cell. They are not reliably picked up from later cells.
2. **`%useLatestDescriptors` before `%use`.** If used, place it before any `%use` statements.
3. **One concept per code cell.** Keep cells focused. Use markdown cells for headings and explanations.
4. **Last expression = output.** The last expression in a code cell is rendered as output. Use `DISPLAY()` for multiple outputs per cell.
5. **Use `-jvm` suffixes for KMP artifacts.** Gradle metadata is NOT resolved. `io.ktor:ktor-client-core-jvm:3.4.0` not `io.ktor:ktor-client-core:3.4.0`.
6. **Trust the notebook for HTML/JS.** Toggle "Trusted" at the top of the notebook to enable JavaScript execution in HTML output.
7. **Pin versions for reproducibility.** Use `%use lib(v=X.Y.Z)` instead of bare `%use lib` for shared notebooks.

### Cell Execution Model

- State persists top-to-bottom across code cells within a session.
- **Execution order matters, not cell position.** Only cells that have been run contribute state.
- Re-running a cell updates its state; downstream cells may need re-running.
- Kernel restart clears all state. Re-run dependency cells first.
- DataFrame column extension properties are generated **between cell executions** -- available in cells after the one declaring the DataFrame.

---

## Dependency Management

### %use -- Pre-Built Library Integrations

```kotlin
%use dataframe                    // Single library
%use dataframe, kandy             // Multiple libraries
%use dataframe(v=1.0.0-Beta4)    // Pinned version
%use lets-plot@0.8.2.5            // Git tag version
```

What `%use` does automatically:
1. Resolves and downloads artifact JARs
2. Adds default imports
3. Runs initialisation code
4. Registers type renderers (e.g., DataFrame -> HTML table, Kandy plot -> Swing)

### @file:DependsOn -- Maven Dependencies

```kotlin
@file:DependsOn("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
@file:DependsOn("io.ktor:ktor-client-cio-jvm:3.4.0")
```

Must appear in the first code cell. Requires manual imports. No renderers registered.

### @file:Repository -- Custom Repositories

```kotlin
@file:Repository("https://maven.pkg.jetbrains.space/public/p/compose/dev")
@file:Repository("*mavenLocal")  // ~/.m2/repository
@file:Repository("https://private.repo.com/maven", "username", "password")
```

### USE {} -- Gradle-Like DSL

```kotlin
USE {
    repositories {
        maven("https://custom.repo.com/releases")
        mavenLocal()
    }
    dependencies {
        val ktorVersion = "3.4.0"
        implementation("io.ktor:ktor-client-cio-jvm:$ktorVersion")
    }
}
```

**Caveat:** Gradle is NOT running under the hood. Gradle metadata, BOMs, platform dependencies, and resolution strategies are not supported.

### Referencing Project Modules

```kotlin
// Option 1: After ./gradlew :shared:publishToMavenLocal
@file:Repository("*mavenLocal")
@file:DependsOn("com.example:shared-jvm:1.0.0")

// Option 2: Direct JAR reference
@file:DependsOn("/path/to/project/shared/build/libs/shared-jvm-1.0.0.jar")

// Option 3: Module classpath selection (IDEA 2025.1+)
// Use the combobox in the notebook toolbar to attach a module's classpath
```

**Delegate to gradle-expert** for `publishToMavenLocal` setup.

### %use vs @file:DependsOn

| Feature | `%use` | `@file:DependsOn` |
|---------|--------|-------------------|
| Scope | Pre-integrated libraries only | Any Maven artifact |
| Imports | Automatically added | Must add manually |
| Renderers | Automatically registered | Not included |
| Init code | Runs automatically | Not included |
| Autocomplete | IDE autocomplete for names | No autocomplete |
| Custom repos | Not supported | Use with `@file:Repository` |
| Use case | Well-known Kotlin/data science libs | Custom/private/niche libraries |

---

## Rich Output Rendering

### Automatic Table Rendering

Data classes and collections render as formatted tables:

```kotlin
data class Token(val name: String, val value: String, val usage: String)

listOf(
    Token("Primary", "#6750A4", "Main interactive elements"),
    Token("Surface", "#FFFBFE", "Background surfaces"),
)
// Last expression -> renders as an HTML table
```

### HTML -- Custom Rich Output

```kotlin
HTML("""
<div style="display: flex; gap: 12px; align-items: center;">
    <div style="width: 48px; height: 48px; border-radius: 8px; background: #6750A4;"></div>
    <div>
        <strong>Primary</strong><br/>
        <code>#6750A4</code>
    </div>
</div>
""")
```

Supports full CSS and JavaScript. **Notebook must be Trusted** for JS execution.

### DISPLAY -- Multiple Outputs Per Cell

```kotlin
DISPLAY(HTML("<h2>Section Title</h2>"))
DISPLAY(myDataFrame)
DISPLAY(myPlot)
```

Without `DISPLAY()`, only the last expression renders.

### Images

```kotlin
// BufferedImage (renders as image/png)
import java.awt.image.BufferedImage
import java.awt.Color

val img = BufferedImage(200, 100, BufferedImage.TYPE_INT_RGB).apply {
    val g = createGraphics()
    g.color = Color(0x67, 0x50, 0xA4)
    g.fillRect(0, 0, 200, 100)
    g.dispose()
}
img  // Renders inline

// URL-based image (requires %use lib-ext)
%use lib-ext(0.11.0-398)
Image("https://kotlinlang.org/docs/images/kotlin-logo.png", embed = true).withWidth(300)
```

### SVG

```kotlin
DISPLAY(MimeTypedResult(mapOf("image/svg+xml" to """
<svg width="200" height="100" xmlns="http://www.w3.org/2000/svg">
    <rect width="200" height="100" rx="8" fill="#6750A4"/>
</svg>
""")))
```

### LaTeX

```kotlin
%use lib-ext(0.11.0-398)
LATEX("c^2 = a^2 + b^2 - 2ab\\cos\\alpha")
```

### MimeTypedResult -- Manual MIME Control

```kotlin
MimeTypedResult(mapOf(
    "text/plain" to "Fallback text",
    "text/html" to "<h1>Rich Content</h1>",
))
```

---

## Step-by-Step Workflows

### 1. New Notebook Setup

1. **Create:** File > New > Kotlin Notebook (project) or Cmd+Shift+N > Kotlin Notebook (scratch)
2. **First cell -- dependencies:**
   ```kotlin
   %use dataframe, kandy
   ```
3. **Second cell -- markdown title:**
   ```markdown
   # My Analysis Notebook
   ```
4. **Run the dependency cell** before writing any code that uses those libraries.
5. **Module classpath** (optional): Use the toolbar combobox to attach project module dependencies.

### 2. Data Loading & Transformation (DataFrame)

**Setup:**
```kotlin
%use dataframe
```

**Loading data:**
```kotlin
// Auto-detect format from extension
val df = DataFrame.read("data.csv")

// Specific readers
val csv = DataFrame.readCsv("https://example.com/data.csv")
val json = DataFrame.readJson("data.json")
val excel = DataFrame.readExcel("report.xlsx")
```

**Inspection:**
```kotlin
df            // Renders as interactive HTML table
df.describe() // Column types, null counts, basic statistics
df.schema()   // Hierarchical schema view
df.head(5)    // First 5 rows
df.rowsCount()
df.columnsCount()
```

**Column access:** Extension properties are auto-generated between cells:
```kotlin
// Cell 1:
val df = DataFrame.readCsv("people.csv")

// Cell 2 (extension properties available):
df.filter { age > 25 }
df.sortBy { name }
```

**Transformation pipeline:**
```kotlin
val result = df
    .filter { age > 18 && city != "Berlin" }
    .add("fullName") { "$firstName $lastName" }
    .convert { age }.to<Double>()
    .rename { stargazersCount }.into("stars")
    .sortByDesc { age }
    .groupBy { city }.aggregate {
        count() into "total"
        mean { age } into "avgAge"
        max { age } into "maxAge"
    }
result
```

**Export:**
```kotlin
df.writeCsv("output.csv")
df.writeJson("output.json")
df.writeExcel("output.xlsx")
df.toStandaloneHTML()  // Opens in browser
```

### 3. Visualisation (Kandy / lets-plot)

**Kandy (recommended -- type-safe DSL):**

```kotlin
%use dataframe, kandy
```

**Bar chart:**
```kotlin
plot {
    bars {
        x(listOf("Alpha", "Beta", "Gamma"))
        y(listOf(42, 28, 15))
    }
    layout.title = "Component Distribution"
}
```

**Line chart from DataFrame:**
```kotlin
df.plot {
    line {
        x(month) { axis.name = "Month" }
        y(temperature) { axis.name = "Temperature" }
        color(city) {
            scale = categorical(
                "Berlin" to Color.LIGHT_GREEN,
                "Madrid" to Color.BLACK,
            )
        }
        width = 1.5
    }
    layout {
        title = "Temperature per Month"
        size = 800 to 400
    }
}
```

**Combined bar + line:**
```kotlin
data.plot {
    x(time)
    y(temperature) { scale = continuous(0.0..25.5) }
    bars {
        fillColor(humidity) {
            scale = continuous(range = Color.YELLOW..Color.RED)
        }
        borderLine.width = 0.0
    }
    line {
        width = 3.0
        color = Color.hex("#6e5596")
    }
}
```

**Export plots:**
```kotlin
val p = plot { bars { x(listOf("A", "B")); y(listOf(1, 2)) } }
p.save("chart.png")                          // PNG
p.save("chart.svg")                          // SVG
p.save("chart.html")                         // HTML
p.save("chart.png", scale = 2.5, dpi = 300)  // High-res
val img: BufferedImage = p.toBufferedImage()  // In-memory
```

**lets-plot (lower-level, ggplot2-style):**
```kotlin
%use lets-plot

val data = mapOf("x" to listOf(1, 2, 3), "y" to listOf(10, 20, 15))
letsPlot(data) { x = "x"; y = "y" } + geomPoint() + geomLine() + ggsize(600, 400)
```

**Kandy vs lets-plot:**

| Aspect | Kandy | lets-plot |
|--------|-------|----------|
| API style | Kotlin-idiomatic DSL | ggplot2-like (R port) |
| Type safety | Column references | String-based aesthetics |
| Abstraction | Higher-level | Lower-level, finer control |
| Data format | Collections + DataFrame | `Map<String, List<*>>` |
| Recommendation | **Prefer for new work** | When ggplot2 familiarity needed |

### 4. Composable Preview Rendering

#### Status: KTNB-650 (In Development)

Native Compose rendering in notebook cells is tracked as [KTNB-650](https://youtrack.jetbrains.com/issues/KTNB-650). Blocked by K2 REPL support (KTNB-891). No public release date. Demonstrated at KotlinConf 2025 ([demo repo](https://github.com/cmelchior/notebook-compose-kotlinconf2025) -- requires custom kernel, not reproducible).

#### Current Workaround: ImageComposeScene to BufferedImage

Render composables offscreen and display as static images:

```kotlin
// Cell 1: Dependencies
@file:Repository("https://repo.maven.apache.org/maven2/")
@file:Repository("https://maven.google.com/")
@file:DependsOn("org.jetbrains.compose:compose-full:1.6.1")
@file:DependsOn("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.8.0")
@file:DependsOn("androidx.collection:collection-jvm:1.4.0")
@file:DependsOn("org.jetbrains.skiko:skiko-awt:0.7.93")
// Platform-specific: choose ONE matching your OS
@file:DependsOn("org.jetbrains.skiko:skiko-awt-runtime-macos-arm64:0.7.93")
// @file:DependsOn("org.jetbrains.skiko:skiko-awt-runtime-macos-x64:0.7.93")
// @file:DependsOn("org.jetbrains.skiko:skiko-awt-runtime-linux-x64:0.7.93")
// @file:DependsOn("org.jetbrains.skiko:skiko-awt-runtime-windows-x64:0.7.93")
```

```kotlin
// Cell 2: Render helper
import androidx.compose.ui.ImageComposeScene
import androidx.compose.ui.unit.Density
import androidx.compose.runtime.Composable
import org.jetbrains.skia.EncodedImageFormat
import java.awt.image.BufferedImage

System.setProperty("java.awt.headless", "true")

fun renderComposable(
    width: Int = 800,
    height: Int = 600,
    density: Float = 2f,
    content: @Composable () -> Unit
): BufferedImage {
    val scene = ImageComposeScene(width, height, Density(density), content = content)
    scene.render()  // Warm-up (triggers initial composition)
    val skiaImage = scene.render()  // Actual render
    val pngBytes = skiaImage.encodeToData(EncodedImageFormat.PNG)!!.bytes
    scene.close()
    return javax.imageio.ImageIO.read(pngBytes.inputStream())
}
```

```kotlin
// Cell 3: Render a composable
import androidx.compose.material3.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier

renderComposable(width = 300, height = 80) {
    MaterialTheme {
        Button(onClick = {}) {
            Text("Primary Button")
        }
    }
}
```

**Limitations:**
- Static images only (not interactive).
- Must call `render()` twice (first call is warm-up).
- `compose-full` is a large dependency (~100 MB).
- Requires platform-specific `skiko-awt-runtime-*` artifact.
- Dialogs render incorrectly (positioned at top-left).

#### Preparing for Future Native Compose Support

Structure notebooks so Compose rendering can be enabled when KTNB-650 ships:

```kotlin
// Markdown cell:
// ## Button -- Primary Variant
// [Visual preview pending KTNB-650]

// Code cell (uncomment when Compose rendering ships):
// @Composable
// fun PrimaryButtonPreview() {
//     AppTheme {
//         PrimaryButton(text = "Save", onClick = {})
//     }
// }
```

### 5. Export & Sharing

| Method | How | Best for |
|--------|-----|----------|
| GitHub | Commit `.ipynb` file | Version-controlled documentation |
| GitHub Gist | Toolbar > "Create Gist" button | Quick sharing |
| Datalore | Upload `.ipynb` | Collaborative editing, scheduled runs |
| HTML | `jupyter nbconvert --to html notebook.ipynb` | Static reports |
| Jupyter | Open in Jupyter Notebook/Lab (kernel must be installed) | Cross-platform |

**For reproducibility:** Pin all library versions and include all dependencies in the first cell.

---

## Component Documentation Patterns

### Design Token Catalogue

```kotlin
// Cell 1: Dependencies
%use dataframe

// Cell 2: Token data model
data class ColorToken(
    val name: String,
    val lightHex: String,
    val darkHex: String,
    val usage: String,
    val category: String
)

// Cell 3: Tokens (renders as table)
val surfaceTokens = listOf(
    ColorToken("Surface/Primary", "#FFFFFF", "#1A1A2E", "Main background", "Surface"),
    ColorToken("Surface/Secondary", "#F5F5F7", "#252540", "Card backgrounds", "Surface"),
    ColorToken("Surface/Tertiary", "#EEEEF0", "#2D2D4A", "Nested containers", "Surface"),
)
surfaceTokens
```

### Colour Swatch Rendering (HTML)

```kotlin
fun colorSwatchHtml(tokens: List<ColorToken>): String = buildString {
    append("<div style='display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px;'>")
    for (token in tokens) {
        append("""
        <div style="border: 1px solid #ddd; border-radius: 8px; overflow: hidden;">
            <div style="height: 48px; background: ${token.lightHex};"></div>
            <div style="padding: 8px; font-family: monospace; font-size: 12px;">
                <strong>${token.name}</strong><br/>
                Light: ${token.lightHex}<br/>
                Dark: ${token.darkHex}<br/>
                <em>${token.usage}</em>
            </div>
        </div>
        """.trimIndent())
    }
    append("</div>")
}

HTML(colorSwatchHtml(surfaceTokens))
```

### Typography Scale

```kotlin
data class TypeToken(
    val name: String,
    val fontFamily: String,
    val weight: String,
    val size: String,
    val lineHeight: String,
    val usage: String
)

val typeScale = listOf(
    TypeToken("Display/Large", "Inter", "Regular", "57sp", "64sp", "Hero headlines"),
    TypeToken("Headline/Medium", "Inter", "Semi Bold", "28sp", "36sp", "Section titles"),
    TypeToken("Body/Large", "Inter", "Regular", "16sp", "24sp", "Primary body text"),
    TypeToken("Label/Medium", "Inter", "Medium", "12sp", "16sp", "Button labels, tabs"),
)
typeScale  // Renders as table

// Visual rendering via HTML
HTML(typeScale.joinToString("") { t ->
    """<p style="font-size:${t.size.replace("sp","px")}; line-height:${t.lineHeight.replace("sp","px")}; font-weight:${
        when(t.weight) { "Semi Bold" -> "600"; "Medium" -> "500"; else -> "400" }
    };">${t.name} -- ${t.usage}</p>"""
})
```

### Component Inventory

```kotlin
data class ComponentSpec(
    val name: String,
    val category: String,
    val variants: List<String>,
    val states: List<String>,
    val composableName: String,
    val sourceModule: String
)

val components = listOf(
    ComponentSpec(
        name = "Subtitle Cue Card",
        category = "Organism",
        variants = listOf("Default", "Selected", "Error"),
        states = listOf("Idle", "Editing", "Saving", "Locked"),
        composableName = "SubtitleCueCard",
        sourceModule = "composeApp"
    ),
)
components  // Renders as table
```

---

## Async Code in Notebooks

The Kotlin Notebook kernel runs on a coroutine-aware event loop. `runBlocking` is available:

```kotlin
import kotlinx.coroutines.*

val result = runBlocking {
    delay(100)
    "Loaded data"
}
result
```

For Flow collection:
```kotlin
import kotlinx.coroutines.flow.*

val items = flow {
    emit("Item 1")
    emit("Item 2")
}.toList()
items
```

**Ktor Client** handles `runBlocking` automatically via `%use ktor-client`:
```kotlin
%use ktor-client

val response = http.get("https://api.example.com/data")
response.bodyAsText()
```

**Delegate to kotlin-coroutines** for advanced async patterns.

---

## Line Magics & REPL Commands

### Line Magics

| Magic | Syntax | Purpose |
|-------|--------|---------|
| `%use` | `%use lib1, lib2` | Import integrated libraries |
| `%useLatestDescriptors` | `%useLatestDescriptors [on\|off]` | Fetch latest descriptors from GitHub (default: off) |
| `%trackClasspath` | `%trackClasspath [on\|off]` | Log classpath changes (debugging) |
| `%trackExecution` | `%trackExecution [all\|generated\|off]` | Log executed code (debugging) |
| `%output` | `%output --max-cell-size=N --no-stdout` | Configure output capturing |
| `%logLevel` | `%logLevel [off\|error\|warn\|info\|debug]` | Set kernel log level |

### `%output` Options

```kotlin
%output --max-cell-size=1000 --no-stdout --max-time=100 --max-buffer=400
%output --reset-to-defaults
```

### REPL Commands

| Command | Purpose |
|---------|---------|
| `:help` | Kernel version, magics, supported libraries |
| `:classpath` | Display current classpath |
| `:vars` | Display declared variables and values |

---

## Error Handling

### Kernel Not Found / Connection Issues

| Symptom | Fix |
|---------|-----|
| Kernel not visible in Jupyter | `pip install kotlin-jupyter-kernel` or `conda install kotlin-jupyter-kernel -c jetbrains` |
| Dead kernel loop | Update kernel to 0.10.0.84+ |
| IntelliJ can't run cells | Settings > Plugins > Installed > ensure "Kotlin Notebook" checkbox is enabled |
| Verify installation | `jupyter kernelspec list` -- check `kotlin` entry |

### Dependency Resolution Failures

| Symptom | Fix |
|---------|-----|
| Artifact not found | Use `-jvm` suffix for KMP artifacts: `ktor-client-core-jvm` not `ktor-client-core` |
| Download errors | Clear `~/.m2/repository` cache, restart kernel |
| Wrong version loaded | Pin version: `%use dataframe(v=1.0.0-Beta4)` |
| `%useLatestDescriptors` incompatibility | Remove `%useLatestDescriptors` or use bundled descriptors |
| Debug resolution | Run `%trackClasspath on` before `%use`, then inspect logs |

### DataFrame Column Extension Errors

| Symptom | Fix |
|---------|-----|
| "Unresolved reference" for column names | Extension properties generate between cells -- use column in a **later** cell than the DataFrame declaration |
| Extensions unresolved but code runs | Known IDE bug -- the code is correct |
| Fallback access | Use string API: `df["columnName"]` or Column Accessor API: `val col by column<Type>()` |

### Compose Rendering Errors

| Symptom | Fix |
|---------|-----|
| `UnsatisfiedLinkError` for Skiko | Wrong `skiko-awt-runtime-*` platform artifact. Match your OS (macos-arm64, linux-x64, etc.) |
| Blank image from `render()` | Call `render()` twice -- first is warm-up |
| Dialogs at wrong position | Known issue (#4875) -- avoid dialogs in ImageComposeScene |
| `NoClassDefFoundError` for Compose | Ensure `compose-full` dependency and `androidx.collection:collection-jvm` are included |

### General Issues

| Symptom | Fix |
|---------|-----|
| Cell hangs / infinite loop | Interrupt (stop button), then restart kernel if needed |
| Project code changes not reflected | Kernel restart required -- classpath compiled on session start |
| HTML/JS not rendering | Toggle "Trusted" at top of notebook |
| Large output truncated | `%output --max-cell-size=500000` |

---

## Anti-Patterns

**Dependencies outside first cell:**
```kotlin
// Cell 3
@file:DependsOn("some:library:1.0")  // BAD: May not be picked up
```
**Always declare in cell 1:**
```kotlin
// Cell 1
@file:DependsOn("some:library:1.0")  // GOOD
```

**KMP artifact without -jvm suffix:**
```kotlin
@file:DependsOn("io.ktor:ktor-client-core:3.4.0")  // BAD: Gradle metadata not resolved
```
**Use JVM variant:**
```kotlin
@file:DependsOn("io.ktor:ktor-client-core-jvm:3.4.0")  // GOOD
```

**Monolithic cells:**
```kotlin
// Single cell with 200 lines of tokens, components, and rendering  // BAD
```
**Split by concept:**
```kotlin
// Cell: Color tokens (20 lines)
// Cell: Typography tokens (15 lines)
// Cell: Component specs (25 lines)   // GOOD
```

**Hardcoded absolute paths:**
```kotlin
@file:DependsOn("/Users/specific-user/project/build/libs/shared.jar")  // BAD
```
**Use mavenLocal:**
```kotlin
@file:Repository("*mavenLocal")
@file:DependsOn("com.example:shared-jvm:1.0.0")  // GOOD: Portable
```

**Using %useLatestDescriptors in shared notebooks:**
```kotlin
%useLatestDescriptors  // BAD: Different results on different machines/dates
%use dataframe
```
**Pin versions explicitly:**
```kotlin
%use dataframe(v=1.0.0-Beta4)  // GOOD: Reproducible
```

---

## Quality Checks

Before finishing any notebook task, verify:

- [ ] Dependencies declared in the **first code cell**
- [ ] `%use` directives execute without errors
- [ ] All code cells execute top-to-bottom without errors (Run All)
- [ ] DataFrame column extensions resolve in cells **after** the declaration cell
- [ ] Kandy plots render visually (not just code output)
- [ ] HTML output renders correctly (notebook is Trusted if using JS)
- [ ] For Compose workaround: correct platform-specific Skiko artifact, `render()` called twice
- [ ] Library versions pinned for shared/committed notebooks
- [ ] Markdown cells provide context between code sections
- [ ] No monolithic cells -- one concept per cell
- [ ] KMP artifacts use `-jvm` suffix in `@file:DependsOn`
- [ ] No hardcoded user-specific paths

---

## Delegation Guide

| Topic | Delegate To | This Skill Covers |
|-------|-------------|-------------------|
| Composable patterns, @Preview, Material3 | compose-expert | Notebook cell structure, HTML-based token docs, ImageComposeScene workaround |
| Kotlin language patterns in cells | kotlin-expert | Notebook-specific patterns (dependencies, output rendering) |
| Async code, Flow collection in cells | kotlin-coroutines | Basic runBlocking / toList() in notebooks |
| Dependency coordinates, publishing | gradle-expert | @file:DependsOn usage, %use directives, USE {} block |
| Source set context for imports | kotlin-multiplatform | Referencing project modules from notebooks |
| Desktop-specific component previews | desktop-expert | General component documentation, Skiko platform artifacts |
| DI setup for notebook-tested code | kotlin-inject | Notebook dependency management only |
| SQLDelight queries in notebooks | sqldelight-kmp | Notebook data loading via DataFrame instead |

---

## Quick Reference

### Dependency Syntax
```
%use <library>                                    # Pre-built integration
%use <library>(v=X.Y.Z)                          # Pinned version
@file:DependsOn("group:artifact:version")         # Maven dependency (use -jvm for KMP)
@file:Repository("https://repo.example.com")      # Custom repository
@file:Repository("*mavenLocal")                   # Local Maven (~/.m2)
USE { dependencies { implementation("...") } }    # Gradle-like DSL
```

### Output Types
```
collection / data class  -> Table (automatic)
DataFrame                -> Interactive HTML table (via %use dataframe)
HTML("...")               -> Rendered HTML
BufferedImage             -> Inline image (image/png)
DISPLAY(value)            -> Multiple outputs per cell
MimeTypedResult(mapOf("image/svg+xml" to "...")) -> SVG
%use kandy + plot {}      -> Inline chart
LATEX("...")               -> LaTeX (requires %use lib-ext)
Image("url")              -> URL image (requires %use lib-ext)
```

### Compose Readiness Checklist
```
KTNB-650 shipped?
|-- Yes -> Add @Composable cells, import theme, render live previews
+-- No  -> Use ImageComposeScene workaround, HTML swatches, data tables, @Preview in source
```

### DataFrame Pipeline Cheatsheet
```
DataFrame.read("file.csv")          # Load (auto-detect format)
df.filter { col > value }           # Filter rows
df.sortBy { col }                   # Sort
df.groupBy { col }.count()          # Group + aggregate
df.add("new") { expression }        # Add column
df.convert { col }.to<Type>()       # Convert column type
df.rename { old }.into("new")       # Rename column
df.describe()                       # Summary statistics
df.writeCsv("out.csv")             # Export
```

---

## Resources

### Official Docs
- [Kotlin Notebook overview -- kotlinlang.org](https://kotlinlang.org/docs/kotlin-notebook-overview.html)
- [Add dependencies -- kotlinlang.org](https://kotlinlang.org/docs/kotlin-notebook-add-dependencies.html)
- [Output formats -- kotlinlang.org](https://kotlinlang.org/docs/data-analysis-notebooks-output-formats.html)
- [Kotlin Jupyter kernel -- GitHub](https://github.com/Kotlin/kotlin-jupyter)
- [Kotlin Jupyter libraries (all %use descriptors)](https://github.com/Kotlin/kotlin-jupyter-libraries)
- [Kotlin DataFrame docs](https://kotlin.github.io/dataframe/)
- [Kandy plotting docs](https://kotlin.github.io/kandy/welcome.html)
- [lets-plot Kotlin docs](https://lets-plot.org/kotlin/get-started.html)

### Tracking
- [KTNB-650: Compose Support -- YouTrack](https://youtrack.jetbrains.com/issues/KTNB-650)
- [KotlinConf 2025 demo repo](https://github.com/cmelchior/notebook-compose-kotlinconf2025)
