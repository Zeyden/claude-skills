---
name: compose-expert
description: Advanced Compose Multiplatform UI patterns for shared composables, architecture, and full CMP development lifecycle. Use proactively when working with Jetpack Compose or Compose Multiplatform (KMP/CMP) — visual UI components, state management (remember, derivedStateOf, produceState, StateFlow), MVI/MVVM architecture, recomposition optimisation (@Stable/@Immutable), Material3 theming, animations, accessibility, custom ImageVector icons, lazy lists, paging, image loading (Coil), Ktor networking client, DataStore, Room, or determining whether to share UI in commonMain vs keep platform-specific. Invoke even when the user doesn't explicitly say "Compose" — trigger on @Composable functions, ViewModel onEvent patterns, sealed Event/State/Effect types, LazyColumn, NavHost, collectAsStateWithLifecycle, or any composable UI file. Complements kotlin-expert (Kotlin language aspects), kotlin-coroutines (advanced async/Flow), android-expert (Android-specific navigation and platform APIs), desktop-expert (Desktop window management), gradle-expert (build config), kotlin-inject (DI wiring), and kotlin-multiplatform (source set placement).
---

# Compose Multiplatform Expert

Full Compose / CMP development lifecycle — architecture, state, UI, networking, persistence, performance, accessibility, and cross-platform sharing.

## Existing Project Policy

Do not force migration. If a project already follows MVI, MVVM, or another pattern with its own conventions, respect it. Adapt to the project's existing patterns and base classes. Only suggest structural changes when the user explicitly asks or when the existing code has clear architectural violations (business logic in composables, scattered state mutations, etc.).

## Workflow

1. **Read the existing code first** — check conventions, base classes, and layout. For small UI or logic asks, read only the immediately relevant files.
2. **Identify the concern** — architecture, state modelling, performance, navigation, animation, cross-platform, testing?
3. **Apply the core rules below** — the heuristics and defaults cover most cases without loading references.
4. **Consult the right reference** — load exactly one file from `references/` only when the task involves advanced concepts. Use [Quick Routing](#quick-routing) to pick it.
5. **Verify dependencies before recommending** — confirm Maven coordinates, target support, and API shape. Use the `context7` skill if available.
6. **Flag anti-patterns for production code** — for prototypes, prioritise answering the specific question.
7. **Write the minimal correct solution** — do not over-engineer.

## Dependency Verification Rule

Before recommending any new dependency or version upgrade:

1. **Coordinates** — confirm the exact `group:artifact:version`
2. **Target support** — confirm the artifact supports the project's targets (Android, iOS, Desktop, `commonMain`). Do not assume a Jetpack library works in `commonMain` without verification.
3. **API shape** — confirm the API exists in that version

Use the `context7` skill (preferred), check official docs, or search Maven Central. If verification is not possible, provide the known snippet with a `// Verify latest version` comment.

## Philosophy: Share by Default

Default to `shared/src/commonMain` unless platform experts indicate otherwise.

| Always Share | Keep Platform-Specific |
|---|---|
| Buttons, cards, lists, dialogs, inputs, state visualisation, icons, theme utilities | Navigation structure, screen layouts, system integrations, platform UX |

## Core Architecture: MVI or MVVM

Both use **unidirectional data flow**: UI renders state → user acts → ViewModel updates state → UI re-renders.

- **MVI**: `sealed interface Event` + single `onEvent()` entry point
- **MVVM**: Named public functions (`onTitleChanged()`, `save()`)

Both use:
- **State** — immutable data class fully describing the screen, owned via `StateFlow`
- **Effect** — one-shot commands (navigate, snackbar, share) via `Channel<Effect>(Channel.BUFFERED)`

**Default:** preserve the project's existing pattern. See [architecture.md](references/architecture.md) for the decision guide, then [mvi.md](references/mvi.md) or [mvvm.md](references/mvvm.md) for implementation.

## UI Rendering Boundary

- **Route**: obtains ViewModel, collects state via `collectAsStateWithLifecycle()`, collects effects via `CollectEffect`, binds navigation/snackbar/platform APIs
- **Screen**: stateless renderer — receives state and `onEvent` (MVI) or named callbacks (MVVM), renders the screen
- **Leaf composables**: render sub-state, emit specific callbacks, keep only tiny visual-local state (focus, scroll, animation)

## Shared Composable Anatomy

```kotlin
@Composable
fun SharedComponent(
    data: DataClass,               // State (read-only)
    onAction: () -> Unit,          // Events (write-only)
    modifier: Modifier = Modifier, // Layout control
    colors: ComponentColors = ComponentDefaults.colors()
) { /* ... */ }
```

State down, events up.

## State Management

### Four-Bucket Model

For complex screens, split state into:

1. **Editable input** — raw text and choice values as the user edits
2. **Derived display/business** — parsed, validated, calculated values
3. **Persisted domain snapshot** — saved entity for dirty tracking or reset
4. **Transient UI-only** — purely visual, not business-significant

| Concern | Where |
|---|---|
| Raw field text | `state` fields |
| Parsed/derived | computed properties or `state` fields |
| Validation | `state.validationErrors` or similar |
| Loading/refresh flags | `state` fields |
| One-off UI commands | `Effect` via Channel |
| Scroll/focus/animation | local Compose state |

### State APIs

```kotlin
// Local UI state across recompositions
var isExpanded by remember { mutableStateOf(false) }

// Reduce downstream recompositions from fast-changing Compose state
val showButton by remember { derivedStateOf { listState.firstVisibleItemIndex > 0 } }

// Bridge async/callback source to Compose state
val user by produceState<User?>(null, userId) { value = repository.fetchUser(userId) }
```

## Recommended Defaults

| Concern | Default |
|---|---|
| ViewModel | One per screen; MVI: `onEvent(Event)` entry; MVVM: named functions |
| State source of truth | `StateFlow<FeatureState>` owned by the ViewModel |
| Side effects | `Channel<Effect>(Channel.BUFFERED)` + `receiveAsFlow()` for UI-consumed one-shots |
| Async loading | Keep previous content, flip loading flag, cancel outdated jobs, update on completion |
| Resources | CMP: `Res.string` / `Res.drawable`. See [resources.md](references/resources.md) |
| Persistence | DataStore Preferences for key-value settings. See [datastore.md](references/datastore.md) |
| Navigation | ViewModel emits semantic navigation effect; route/navigation layer executes it |

## Material3 Theming

```kotlin
val bg = MaterialTheme.colorScheme.background
val typography = MaterialTheme.typography.headlineMedium
val shape = MaterialTheme.shapes.medium
```

See [material-design.md](references/material-design.md) for M3 components, dynamic colour, and adaptive layouts.

## Performance Quick Rules

- Mark parameter data classes `@Immutable`
- Use `key` parameter in `LazyColumn items()` for stable identity
- Use `derivedStateOf` to filter rapid Compose state changes; avoid it for cheap expressions
- Read state as close to its use as possible — move reads from Composition to Layout/Drawing phases
- Use lambda modifiers (`Modifier.offset { }`) to skip Composition for layout/draw changes

See [performance.md](references/performance.md) for the full 16-mistake reference table.

## Custom Icons

```kotlin
fun customIconBuilder(block: ImageVector.Builder.() -> Unit): ImageVector =
    ImageVector.Builder("CustomIcon", 24.dp, 24.dp, 24f, 24f).apply(block).build()
```

See [references/icon-assets.md](references/icon-assets.md) for path patterns.

## Do / Don't

### Do
- Model raw editable text separately from parsed values
- Keep state immutable and equality-friendly (`data class` + immutable collections)
- Emit semantic effects instead of making platform calls from event handlers
- Key list items by stable domain ID
- Guard no-op state emissions (don't update if nothing changed)
- Import all types at the top of the file; use `import ... as ...` for name clashes
- Respect the project's existing MVI/MVVM conventions

### Don't
- Parse numbers or run network requests in composable bodies
- Store `MutableState`, controllers, lambdas, or platform objects in screen state
- Encode snackbar/navigation as "consume once" booleans in state — use effects
- Pass entire state to every child composable
- Keep ephemeral animation flags in global screen state
- Force-migrate a working codebase to a different architecture

## Delegation

| Topic | Skill |
|---|---|
| Kotlin language patterns (@Immutable, sealed classes, StateFlow) | kotlin-expert |
| Advanced async / Flow operators (flatMapLatest, combine, stateIn) | kotlin-coroutines |
| Android navigation, Compose Nav, runtime permissions, lifecycle | android-expert |
| Desktop navigation, Window/Tray/MenuBar, OS-specific behaviour | desktop-expert |
| Gradle build files, version catalog, dependency conflicts | gradle-expert |
| DI setup, kotlin-inject, kotlin-inject-anvil | kotlin-inject |
| Source set placement, expect/actual decisions | kotlin-multiplatform |
| SQLDelight, .sq files, KMP database drivers | sqldelight-kmp |

## Quick Routing

Load exactly one reference file when deeper guidance is needed. Do not load files speculatively.

### Architecture & State
- **Architecture overview, MVI vs MVVM decision, state ownership, domain layer** → [architecture.md](references/architecture.md)
- **MVI pipeline, Event/State/Effect, onEvent pattern, effect delivery** → [mvi.md](references/mvi.md)
- **MVVM pipeline, named functions, direct-callback UI wiring** → [mvvm.md](references/mvvm.md)

### Core Compose
- **Three phases, state primitives, side effects (LaunchedEffect, DisposableEffect), modifiers** → [compose-essentials.md](references/compose-essentials.md)
- **Recomposition too frequent, stability, @Stable/@Immutable, Compose Compiler Metrics** → [performance.md](references/performance.md)
- **M3 theme, dynamic colour, M3 components, adaptive layouts** → [material-design.md](references/material-design.md)
- **Animation API selection (animate\*AsState, Animatable, transitions, AnimatedVisibility)** → [animations.md](references/animations.md)
- **Shared element transitions, gesture-driven animations, Canvas, graphicsLayer** → [animations-advanced.md](references/animations-advanced.md)
- **Accessibility audit, semantics, touch targets, WCAG contrast** → [accessibility.md](references/accessibility.md)
- **Loading states, skeleton/shimmer, inline validation UX** → [ui-ux.md](references/ui-ux.md)
- **LazyColumn, LazyRow, keys, grids, Pager, scroll state** → [lists-grids.md](references/lists-grids.md)
- **Cross-cutting anti-patterns or code smells** → [anti-patterns.md](references/anti-patterns.md)
- **File organisation, naming conventions, disciplined screen architecture** → [clean-code.md](references/clean-code.md)
- **Turbine, ViewModel event→state→effect tests, lean test matrix** → [testing.md](references/testing.md)

### Media & Data
- **AsyncImage, image cache, SVG, Coil 3** → [image-loading.md](references/image-loading.md)
- **Paging 3 setup, PagingSource, filters, LoadState, transformations** → [paging.md](references/paging.md)
- **Offline-first paging with Room + RemoteMediator** → [paging-offline.md](references/paging-offline.md)
- **Paging MVI integration, paging tests, paging anti-patterns** → [paging-mvi-testing.md](references/paging-mvi-testing.md)
- **DataStore Preferences, Typed DataStore, KMP DataStore** → [datastore.md](references/datastore.md)
- **Room entities, DAOs, migrations, relationships, Room + MVI** → [room-database.md](references/room-database.md)
- **CMP Res class, qualifiers, localisation, Android resource interop** → [resources.md](references/resources.md)

### Networking
- **Ktor client setup, plugins, DTOs, API service, repository pattern** → [networking-ktor.md](references/networking-ktor.md)
- **Auth (bearer), WebSockets, SSE** → [networking-ktor-auth.md](references/networking-ktor-auth.md)
- **Network layer architecture, plugin composition, error handling strategy** → [networking-ktor-architecture.md](references/networking-ktor-architecture.md)
- **MockEngine, network testing, DI network setup** → [networking-ktor-testing.md](references/networking-ktor-testing.md)

### Navigation (for architecture context; delegate implementation to android-expert / desktop-expert)
- **Nav 2 vs Nav 3 decision, MVI navigation rules** → [navigation.md](references/navigation.md)
- **Nav 2 NavHost, tabs, deep links, nested graphs, animations** → [navigation-2.md](references/navigation-2.md)
- **Nav 3 routes, tabs, scenes, deep links, back stack** → [navigation-3.md](references/navigation-3.md)
- **Wiring Koin with Nav 2** → [navigation-2-di.md](references/navigation-2-di.md)
- **Wiring Koin with Nav 3** → [navigation-3-di.md](references/navigation-3-di.md)
- **Migrating from Nav 2 to Nav 3** → [navigation-migration.md](references/navigation-migration.md)

### Dependency Injection (for advanced DI patterns; delegate kotlin-inject-anvil to kotlin-inject skill)
- **Choosing Hilt vs Koin** → [dependency-injection.md](references/dependency-injection.md)
- **Koin CMP setup, Nav 3 Koin integration, scoped modules** → [koin.md](references/koin.md)
- **Hilt Android setup, @HiltViewModel, scopes, Hilt testing** → [hilt.md](references/hilt.md)

### Coroutines in Compose (delegate advanced patterns to kotlin-coroutines skill)
- **Channel vs SharedFlow, Flow operators, LaunchedEffect patterns** → [coroutines-flow.md](references/coroutines-flow.md)
- **Backpressure, callbackFlow, Mutex/Semaphore, Turbine** → [coroutines-flow-advanced.md](references/coroutines-flow-advanced.md)
