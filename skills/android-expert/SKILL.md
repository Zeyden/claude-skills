---
name: android-expert
description: Android platform expertise for KMP projects. Use when your KMP project targets Android. Covers Compose Navigation, Material3, permissions, lifecycle, and Android-specific patterns. Use when working with: (1) Android navigation (Navigation Compose, routes, bottom nav), (2) Runtime permissions (camera, notifications), (3) Platform APIs (Intent, Context, Activity), (4) Material3 theming and edge-to-edge UI, (5) Android build configuration (Proguard, APK optimization), (6) Android lifecycle (ViewModel, collectAsStateWithLifecycle).
---

# Android Expert

Android platform expertise for KMP projects. Covers Compose Navigation, Material3, permissions, lifecycle, and Android-specific patterns.

## Core Mental Model

**Single Activity Architecture + Compose Navigation**

```
MainActivity (Single Entry Point)
    ├── enableEdgeToEdge()
    ├── AppTheme { }
    └── NavHost
        ├── Route.Home → HomeScreen
        ├── Route.Detail(id) → DetailScreen
        └── Route.Settings → SettingsScreen
```

## Type-Safe Navigation

```kotlin
@Serializable
sealed class Route {
    @Serializable object Home : Route()
    @Serializable object Search : Route()
    @Serializable data class Detail(val itemId: String) : Route()
    @Serializable data class Profile(val userId: String) : Route()
    @Serializable object Settings : Route()
}

NavHost(navController = navController, startDestination = Route.Home) {
    composable<Route.Home> { HomeScreen(navController) }
    composable<Route.Detail> { backStackEntry ->
        val detail = backStackEntry.toRoute<Route.Detail>()
        DetailScreen(detail.itemId, navController)
    }
}
```

## Permissions (Accompanist)

```kotlin
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraFeature() {
    val cameraPermission = rememberPermissionState(Manifest.permission.CAMERA)
    when {
        cameraPermission.status.isGranted -> CameraPreview()
        cameraPermission.status.shouldShowRationale -> RationaleDialog(...)
        else -> Button(onClick = { cameraPermission.launchPermissionRequest() }) { Text("Enable Camera") }
    }
}
```

## ViewModel + Lifecycle

```kotlin
@Composable
fun ListScreen(viewModel: ListViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    when (state) {
        is UiState.Loading -> LoadingIndicator()
        is UiState.Success -> ItemList(state.data)
        is UiState.Error -> ErrorScreen(state.message)
    }
}
```

## Deep Links

```kotlin
LaunchedEffect(activity?.intent) {
    activity?.intent?.data?.let { uri ->
        when (uri.scheme) {
            "myapp" -> handleDeepLink(uri, navController)
            "https" -> handleWebLink(uri, navController)
        }
    }
}
```

## Edge-to-Edge + Material3

```kotlin
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent { AppTheme { MainScreen() } }
    }
}
```

## Delegation

- **desktop-expert**: Desktop-specific features
- **compose-expert**: Shared UI components
- **kotlin-multiplatform**: Shared KMP code

## References

- `references/android-navigation.md` - Navigation patterns
- `references/android-permissions.md` - Permission handling
- `references/proguard-rules.md` - Proguard configuration
- `scripts/analyze-apk-size.sh` - APK size analysis
