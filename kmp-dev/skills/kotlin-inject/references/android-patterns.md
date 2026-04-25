# kotlin-inject Android Patterns — Extended Reference

## Application-Level Component

The application component lives as long as the process. Store it on
`Application` and provide a helper to retrieve it:

```kotlin
@AppScope
@Component
abstract class ApplicationComponent {
    abstract val fragmentFactory: InjectFragmentFactory

    companion object {
        private var instance: ApplicationComponent? = null

        fun getInstance(context: Context): ApplicationComponent {
            return instance ?: ApplicationComponent::class.create().also {
                instance = it
            }
        }
    }
}

class MyApp : Application() {
    val component by lazy { ApplicationComponent.getInstance(this) }
}
```

## Activity-Scoped Component

Create a child component per Activity to scope deps to that Activity's
lifecycle:

```kotlin
@ActivityScope
@Component
abstract class ActivityComponent(@Component val parent: ApplicationComponent) {
    abstract val myScreen: MyScreen
    abstract val navigator: Navigator
}

class MyActivity : AppCompatActivity() {
    private val component by lazy {
        ActivityComponent::class.create(
            (application as MyApp).component
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val screen = component.myScreen
    }
}
```

## Fragment Injection — Full Pattern

### FragmentFactory Implementation

```kotlin
@Inject
class InjectFragmentFactory(
    private val homeFragment: () -> HomeFragment,
    private val settingsFragment: () -> SettingsFragment,
    private val profileFragment: () -> ProfileFragment,
) : FragmentFactory() {
    override fun instantiate(classLoader: ClassLoader, className: String): Fragment =
        when (className) {
            HomeFragment::class.qualifiedName -> homeFragment()
            SettingsFragment::class.qualifiedName -> settingsFragment()
            ProfileFragment::class.qualifiedName -> profileFragment()
            else -> super.instantiate(classLoader, className)
        }
}
```

### Setting Up in Activity

```kotlin
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // MUST set before super.onCreate() to handle config changes
        supportFragmentManager.fragmentFactory =
            MainActivityComponent::class.create(
                (application as MyApp).component
            ).fragmentFactory
        super.onCreate(savedInstanceState)
    }
}
```

### Fragments with Constructor Injection

```kotlin
@Inject
class HomeFragment(
    private val repo: HomeRepository,
    private val analytics: Analytics,
) : Fragment(R.layout.fragment_home) {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        // Use repo, analytics directly
    }
}
```

## ViewModel Patterns

### Basic ViewModel (No SavedState)

```kotlin
@Inject
class HomeViewModel(private val repo: HomeRepository) : ViewModel() {
    val items = repo.observeItems().stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList()
    )
}

@Inject
class HomeFragment(homeViewModel: () -> HomeViewModel) : Fragment() {
    private val viewModel by viewModels {
        viewModelFactory {
            addInitializer(HomeViewModel::class) { homeViewModel() }
        }
    }
}
```

### ViewModel with SavedStateHandle

```kotlin
@Inject
class DetailViewModel(
    private val repo: DetailRepository,
    @Assisted private val savedState: SavedStateHandle,
) : ViewModel() {
    private val itemId = savedState.get<String>("itemId") ?: ""
    val item = repo.getItem(itemId).stateIn(
        viewModelScope, SharingStarted.WhileSubscribed(5000), null
    )
}

@Inject
class DetailFragment(
    vmFactory: (SavedStateHandle) -> DetailViewModel,
) : Fragment() {
    private val viewModel by injectViewModel(vmFactory)
}

// Reusable helper:
inline fun <reified VM : ViewModel> Fragment.injectViewModel(
    crossinline factory: (SavedStateHandle) -> VM,
): Lazy<VM> = viewModels {
    viewModelFactory {
        addInitializer(VM::class) { factory(createSavedStateHandle()) }
    }
}
```

### ViewModel without SavedStateHandle (helper)

```kotlin
inline fun <reified VM : ViewModel> Fragment.injectViewModel(
    crossinline factory: () -> VM,
): Lazy<VM> = viewModels {
    viewModelFactory {
        addInitializer(VM::class) { factory() }
    }
}
```

## Compose Integration — Full Pattern

### Screen-Level Function Injection

```kotlin
// Type alias defines the injectable function type
typealias HomeScreen = @Composable () -> Unit
typealias SettingsScreen = @Composable () -> Unit
typealias ProfileScreen = @Composable (userId: String) -> Unit

// Implementation is an @Inject @Composable function
@Inject
@Composable
fun HomeScreen(repo: HomeRepository) {
    val items by repo.items.collectAsState(emptyList())
    LazyColumn {
        items(items) { item ->
            Text(item.title)
        }
    }
}

@Inject
@Composable
fun SettingsScreen(prefs: PreferencesRepository) {
    // ...
}

@Inject
@Composable
fun ProfileScreen(userRepo: UserRepository, @Assisted userId: String) {
    val user by userRepo.getUser(userId).collectAsState(null)
    // ...
}
```

### Component Exposing Screens

```kotlin
@AppScope
@Component
abstract class AppComponent {
    abstract val homeScreen: HomeScreen
    abstract val settingsScreen: SettingsScreen
    abstract val profileScreen: ProfileScreen
}
```

### Wiring into Activity

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val component = AppComponent::class.create()
        setContent {
            MyTheme {
                val navController = rememberNavController()
                NavHost(navController, startDestination = "home") {
                    composable("home") { component.homeScreen() }
                    composable("settings") { component.settingsScreen() }
                    composable("profile/{userId}") { backStackEntry ->
                        component.profileScreen(
                            backStackEntry.arguments?.getString("userId") ?: ""
                        )
                    }
                }
            }
        }
    }
}
```

### Compose ViewModel Helper

```kotlin
@Composable
inline fun <reified VM : ViewModel> injectViewModel(
    crossinline factory: () -> VM,
): VM = viewModel { factory() }

@Composable
inline fun <reified VM : ViewModel> injectViewModel(
    crossinline factory: (SavedStateHandle) -> VM,
): VM = viewModel {
    factory(createSavedStateHandle())
}

// Usage in an injected Composable:
@Inject
@Composable
fun HomeScreen(vmFactory: () -> HomeViewModel) {
    val viewModel = injectViewModel(vmFactory)
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    // ...
}
```

## Build Variant Injection

Provide different implementations per build type without `if` checks:

```kotlin
// src/main — shared interface
interface VariantComponent {
    val Client.bind: ApiClient
        @Provides get() = this
}

// src/debug
interface VariantComponent {
    val DebugClient.bind: ApiClient
        @Provides get() = this
}

// src/release
interface VariantComponent {
    val ReleaseClient.bind: ApiClient
        @Provides get() = this
}

// Component picks up the correct VariantComponent for current build type
@AppScope
@Component
abstract class AppComponent : VariantComponent {
    abstract val client: ApiClient
}
```

This pattern extends to any build dimension — flavours, build types, or
combinations.
