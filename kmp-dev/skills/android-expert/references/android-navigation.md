# Android Navigation Patterns

Type-safe Navigation Compose patterns for KMP Android apps.

## Type-Safe Routes

```kotlin
@Serializable
sealed class Route {
    @Serializable object Home : Route()
    @Serializable object Search : Route()
    @Serializable data class Detail(val itemId: String) : Route()
    @Serializable data class Profile(val userId: String) : Route()
    @Serializable object Settings : Route()
    @Serializable data class Editor(val itemId: String? = null) : Route()
}
```

## NavHost Setup

```kotlin
@Composable
fun AppNavigation(navController: NavHostController) {
    NavHost(
        navController = navController,
        startDestination = Route.Home,
        enterTransition = { fadeIn(tween(200)) },
        exitTransition = { fadeOut(tween(200)) }
    ) {
        composable<Route.Home> { HomeScreen(navController) }
        composable<Route.Detail> { entry ->
            val detail = entry.toRoute<Route.Detail>()
            DetailScreen(detail.itemId, navController)
        }
        composable<Route.Profile> { entry ->
            val profile = entry.toRoute<Route.Profile>()
            ProfileScreen(profile.userId, navController)
        }
    }
}
```

## Navigation Manager

```kotlin
class AppNavigator(
    val controller: NavHostController,
    val drawerState: DrawerState,
    val scope: CoroutineScope
) {
    fun nav(route: Route) { scope.launch { controller.navigate(route); drawerState.close() } }
    fun newStack(route: Route) { scope.launch { controller.navigate(route) { popUpTo(Route.Home) { inclusive = false } }; drawerState.close() } }
    fun popBack() { controller.popBackStack() }
}
```

## Bottom Navigation

```kotlin
@Composable
fun AppBottomBar(selectedRoute: Route, navigator: AppNavigator) {
    NavigationBar {
        BottomBarItem.entries.forEach { item ->
            NavigationBarItem(
                selected = selectedRoute::class == item.route::class,
                onClick = { navigator.nav(item.route) },
                icon = { Icon(item.icon, item.label) },
                label = { Text(item.label) }
            )
        }
    }
}

enum class BottomBarItem(val route: Route, val icon: ImageVector, val label: String) {
    HOME(Route.Home, Icons.Default.Home, "Home"),
    MESSAGES(Route.Search, Icons.Default.Search, "Search"),
    NOTIFICATIONS(Route.Home, Icons.Default.Notifications, "Alerts"),
    PROFILE(Route.Profile("me"), Icons.Default.Person, "Profile")
}
```

## Deep Link Handling

```kotlin
LaunchedEffect(activity?.intent) {
    activity?.intent?.let { intent ->
        when (intent.action) {
            Intent.ACTION_SEND -> {
                val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                navController.navigate(Route.Editor(sharedText))
            }
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri -> handleDeepLink(uri, navController) }
            }
        }
    }
}

fun handleDeepLink(uri: Uri, navController: NavHostController) {
    val pathSegments = uri.pathSegments
    when {
        pathSegments.contains("items") -> navController.navigate(Route.Detail(pathSegments.last()))
        pathSegments.contains("users") -> navController.navigate(Route.Profile(pathSegments.last()))
    }
}
```

## Anti-Patterns

1. **String-based navigation** → Use @Serializable routes
2. **Hardcoded route strings** → Use sealed class/object
3. **Passing complex objects as nav args** → Pass IDs, fetch in destination
