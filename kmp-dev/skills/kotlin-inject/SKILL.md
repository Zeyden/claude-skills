---
name: kotlin-inject
description: Compile-time dependency injection for Kotlin and KMP — kotlin-inject core (@Component, @Inject, @Provides, @Qualifier, @Scope, @Assisted, @AssistedFactory) and kotlin-inject-anvil automatic merging (@ContributesTo, @ContributesBinding, @ContributesSubcomponent, @MergeComponent, @SingleIn). Covers KSP2 wiring, KMP component creation (@KmpComponentCreate, @MergeComponent.CreateComponent), Android patterns (Activity, Fragment, ViewModel with SavedStateHandle, Compose function injection), testing with fakes, scoping, qualifiers, and multi-bindings. Invoke proactively whenever a diff touches DI wiring in a KMP project — files containing `@Component`, `@Inject`, `@Provides`, `@MergeComponent`, `@ContributesTo`, `@ContributesBinding`, `@Assisted`, `@SingleIn`, `::class.create()`, `@KmpComponentCreate`, or when KSP processors for kotlin-inject-anvil are configured in `build.gradle.kts`. Load this skill even without explicit mention — if you see `@Inject class`, a component abstract class, or any file under a `di/` package in a KMP module, consult it before writing or reviewing. Delegates Gradle/KSP plumbing to gradle-expert and source set placement to kotlin-multiplatform.
---

# kotlin-inject Expert Skill

> **kotlin-inject** — compile-time DI for Kotlin via KSP. No reflection, no
> runtime cost, full KMP support.
>
> Latest stable: **0.9.0** (Jan 2026) · Kotlin 2.2.20 · **KSP2 only**

| Artifact | Coordinates |
|----------|------------|
| Runtime (JVM/Android) | `me.tatarka.inject:kotlin-inject-runtime:0.9.0` |
| Runtime (KMP) | `me.tatarka.inject:kotlin-inject-runtime-kmp:0.9.0` |
| KSP compiler | `me.tatarka.inject:kotlin-inject-compiler-ksp:0.9.0` |
| Anvil runtime | `software.amazon.lastmile.kotlin.inject.anvil:runtime:0.1.7` |
| Anvil compiler | `software.amazon.lastmile.kotlin.inject.anvil:compiler:0.1.7` |

---

## 1 · Core Concepts

### Components

Abstract class + `@Component` → generated `Inject`-prefixed implementation:

```kotlin
@Component
abstract class AppComponent {
    abstract val repo: Repository
    @Provides protected fun jsonParser(): JsonParser = JsonParser()
    protected val RealHttp.bind: Http @Provides get() = this  // interface binding
}
val component = AppComponent::class.create()   // generated extension function
```

`::class.create()` won't resolve until KSP runs — the #1 "unresolved reference" cause.

### @Inject — Constructor Injection

```kotlin
@Inject class Api(private val http: Http, private val jsonParser: JsonParser)
@Inject class Repository(private val api: Api)
```

### @Provides — External Dependencies

Always declare an explicit return type. Platform types from Java interop are a compile error.

### Interface Binding (Extension Receiver Syntax)

```kotlin
protected val RealHttp.bind: Http @Provides get() = this
```

Receiver is injected; return type is the provided binding.

### Component Arguments

```kotlin
@Component
abstract class AppComponent(@get:Provides protected val baseUrl: String)
val c = AppComponent::class.create("https://api.example.com")
```

### Parent / Child Components

```kotlin
@Component abstract class NetworkComponent { /* provides HttpClient */ }
@Component abstract class AppComponent(@Component val network: NetworkComponent)
val app = AppComponent::class.create(NetworkComponent::class.create())
```

Child accesses all parent bindings. Duplicate type in both = **compile error** (since 0.8.0).

---

## 2 · Qualifiers

### @Qualifier (Preferred)

```kotlin
@Qualifier
@Target(PROPERTY_GETTER, FUNCTION, VALUE_PARAMETER, TYPE)
annotation class Named(val value: String)

@Component abstract class MyComponent {
    @Provides fun dep1(): @Named("one") Dep = Dep("one")
    @Provides fun dep2(): @Named("two") Dep = Dep("two")
}
@Inject class Foo(@Named("one") val dep: Dep)
```

Multiple qualifiers on same site = compile error. Type aliases for qualification are **deprecated** — migrate to `@Qualifier`.

---

## 3 · Scoping

```kotlin
@Scope @Target(CLASS, FUNCTION, PROPERTY_GETTER) annotation class AppScope

@AppScope @Component
abstract class AppComponent {
    @AppScope @Provides protected fun database(): Database = Database.create()
}
@AppScope @Inject class Repository(private val db: Database)
```

Scoped instances live as long as the component. Annotate **both** the component and the provider/class.

### Component Inheritance for Testability

Define providers on an abstract class (not `@Component`) so implementations can be swapped:

```kotlin
@AppScope abstract class NetworkComponent {
    @AppScope @Provides abstract fun api(): Api
}
@Component abstract class RealNetwork : NetworkComponent() { override fun api() = RealApi() }
@Component abstract class FakeNetwork : NetworkComponent() { override fun api() = FakeApi() }

@Component abstract class AppComponent(@Component val network: NetworkComponent)
AppComponent::class.create(RealNetwork::class.create())   // production
AppComponent::class.create(FakeNetwork::class.create())    // tests
```

---

## 4 · Multi-bindings

```kotlin
// Sets
@Component abstract class AppComponent {
    abstract val interceptors: Set<Interceptor>
    @IntoSet @Provides protected fun logging(): Interceptor = LoggingInterceptor()
    @IntoSet @Provides protected fun auth(): Interceptor = AuthInterceptor()
}

// Maps — return Pair<K, V>
@Component abstract class AppComponent {
    abstract val screens: Map<String, Screen>
    @IntoMap @Provides protected fun home(): Pair<String, Screen> = "home" to HomeScreen()
}
```

---

## 5 · Function Injection & Assisted Injection

### () -> T (Deferred/Lazy Creation)

Any `T` in the graph can be injected as `() -> T`. Each call = new instance.

### @Assisted — Caller-Provided Parameters

```kotlin
@Inject class Foo(repo: Repository, @Assisted id: String, @Assisted name: String)
@Inject class Bar(createFoo: (id: String, name: String) -> Foo)
```

Assisted params become **trailing** lambda params. **Scoped + @Assisted = compile error.**

### @AssistedFactory (0.8.0+)

For named/default parameters (lambdas can't express these):

```kotlin
@Inject class Connection(@Assisted host: String, @Assisted port: Int = 443, ssl: SslContext)

@AssistedFactory
interface CreateConnection { fun create(host: String, port: Int = 443): Connection }

@Inject class NetworkManager(factory: CreateConnection) {
    fun connect(host: String) = factory.create(host) // port defaults to 443
}
```

### Top-Level Function Injection

```kotlin
typealias FormatDate = (LocalDate) -> String
@Inject fun FormatDate(locale: Locale, date: LocalDate): String = date.format(locale)
@Inject class Display(val formatDate: FormatDate)
```

Type alias name must match function name. Injected params come from graph; explicit args become function params.

---

## 6 · Lazy & Default Arguments

**Lazy:** `Lazy<T>` defers creation. Also breaks dependency cycles.

```kotlin
@Inject class Controller(lazyService: Lazy<ExpensiveService>) { val svc by lazyService }
```

**Defaults:** If a type isn't in the graph, the parameter's default value is used:

```kotlin
@Inject class Config(val timeout: Int = 30, val retries: Int = 3)
// Component providing only timeout → retries uses default 3
```

---

## 7 · KSP Options

```kotlin
ksp {
    arg("me.tatarka.inject.enableJavaxAnnotations", "true")   // javax.inject compat
    arg("me.tatarka.inject.generateCompanionExtensions", "true") // MyComponent.create()
    arg("me.tatarka.inject.dumpGraph", "true")                 // debug graph output
}
```

For companion extensions, add `companion object` to your component.

---

## 8 · Android Patterns

> Full patterns with helpers in `references/android-patterns.md`

**Activity:** Extract deps into an `@Inject` helper class, create via child component in `onCreate`.

**Fragment:** Use `FragmentFactory` with `() -> Fragment` constructor injection. Set factory **before** `super.onCreate()`.

**ViewModel + SavedStateHandle:**

```kotlin
@Inject class HomeViewModel(repo: HomeRepository, @Assisted handle: SavedStateHandle) : ViewModel()

@Inject class HomeFragment(vmFactory: (SavedStateHandle) -> HomeViewModel) : Fragment() {
    private val viewModel by viewModels {
        viewModelFactory { addInitializer(HomeViewModel::class) { vmFactory(createSavedStateHandle()) } }
    }
}
```

**Compose — Function Injection:**

```kotlin
typealias HomeScreen = @Composable () -> Unit
@Inject @Composable fun HomeScreen(repo: HomeRepository) { /* ... */ }

@Component abstract class AppComponent { abstract val homeScreen: HomeScreen }
// setContent { component.homeScreen() }
```

**Build Variants:** Per-variant `VariantComponent` interfaces with different `@Provides` bindings.

---

## 9 · Kotlin Multiplatform (KMP)

### Gradle Setup

```kotlin
plugins { kotlin("multiplatform"); id("com.google.devtools.ksp") }

kotlin {
    jvm(); iosX64(); iosArm64(); iosSimulatorArm64()
    sourceSets { commonMain.dependencies {
        implementation("me.tatarka.inject:kotlin-inject-runtime-kmp:0.9.0")
    }}
}
dependencies {
    // Option A: common source set (recommended)
    kspCommonMainMetadata("me.tatarka.inject:kotlin-inject-compiler-ksp:0.9.0")
    // Option B: per-target — add("kspJvm", ...), add("kspIosArm64", ...), etc.
}
// Required for Option A:
tasks.withType<KotlinCompilationTask<*>>().configureEach {
    if (name != "kspCommonMainKotlinMetadata") dependsOn("kspCommonMainKotlinMetadata")
}
```

Choose A **or** B — both causes redeclaration errors.

### @KmpComponentCreate

```kotlin
@Component abstract class AppComponent { abstract val repo: Repository }
@KmpComponentCreate expect fun createAppComponent(): AppComponent
// Extension form: @KmpComponentCreate expect fun AppComponent.Companion.create(): AppComponent
```

Generates `actual fun` in each target calling `::class.create()`.

### Platform-Specific Bindings

```kotlin
// commonMain
expect interface PlatformComponent
@Component abstract class AppComponent : PlatformComponent

// jvmMain
actual interface PlatformComponent {
    @Provides fun dispatcher(): CoroutineDispatcher = Dispatchers.IO
}
```

---

## 10 · kotlin-inject-anvil

> Full deep dive in `references/anvil-deep-dive.md`

Amazon's extension for automatic component merging. **Latest: 0.1.7**

```kotlin
// Contribute a binding from any module:
@Inject @SingleIn(AppScope::class) @ContributesBinding(AppScope::class)
class RealAuth(api: Api) : Authenticator

// Contribute a component interface:
@ContributesTo(AppScope::class)
interface AnalyticsComponent { @Provides fun analytics(): Analytics = MixpanelAnalytics() }

// Merge everything automatically:
@MergeComponent(AppScope::class) @SingleIn(AppScope::class)
abstract class AppComponent

// KMP: @MergeComponent.CreateComponent expect fun create(): AppComponent
```

Key annotations: `@ContributesTo`, `@ContributesBinding`, `@ContributesSubcomponent`, `@MergeComponent`, `@SingleIn`, `@MergeComponent.CreateComponent`.

---

## 11 · Testing

1. **Direct construction** (preferred for unit tests — no DI needed):
   ```kotlin
   val repo = Repository(FakeApi()); assertEquals("data", repo.fetch())
   ```

2. **Test component with fakes:**
   ```kotlin
   class TestFakes(@get:Provides val api: Api = FakeApi())
   @Component @AppScope
   abstract class TestAppComponent(@Component val fakes: TestFakes = TestFakes())
   ```

3. **Component inheritance** for shared bindings between prod/test.

4. **Avoid mocking** — fake only system edges (network, I/O, clock). Real deps > mocks.

---

## 12 · Common Pitfalls

| Problem | Fix |
|---------|-----|
| `Unresolved reference: create` | Build once / verify KSP config |
| Unexpected type provided | Add explicit return type to `@Provides` |
| Platform type error | Explicitly annotate nullability |
| Multiple qualifiers | Use only one qualifier per site |
| Scoped + @Assisted error | Remove scope from assisted types |
| Child/parent duplicate binding | Remove one or use qualifiers |
| KSP1 not working (0.9.0) | Upgrade to KSP2 |

---

## 13 · Gradle Setup Reference

**JVM:**
```kotlin
plugins { kotlin("jvm") version "2.2.20"; id("com.google.devtools.ksp") version "2.2.20-2.0.0" }
dependencies {
    ksp("me.tatarka.inject:kotlin-inject-compiler-ksp:0.9.0")
    implementation("me.tatarka.inject:kotlin-inject-runtime:0.9.0")
}
```

**Android:** Same deps, use `com.android.application` + `kotlin("android")` plugins.

**KMP Version Catalogue:**
```toml
[versions]
kotlin-inject = "0.9.0"
[libraries]
kotlinInject-runtime = { module = "me.tatarka.inject:kotlin-inject-runtime-kmp", version.ref = "kotlin-inject" }
kotlinInject-compiler = { module = "me.tatarka.inject:kotlin-inject-compiler-ksp", version.ref = "kotlin-inject" }
```

---

## 14 · Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| **0.9.0** | Jan 2026 | KSP1 removed, Android native arm32/arm64, Kotlin 2.2.20 |
| **0.8.0** | Apr 2025 | KSP2, `@AssistedFactory`, mingwX64, duplicate binding error |
| **0.7.0** | Jun 2024 | `@Qualifier`, `@KmpComponentCreate`, inner class injection |
| **0.6.0** | Dec 2022 | `@Assisted` required, scope+assisted = error |
| **0.4.0** | Oct 2021 | Multiplatform/native, default arguments |

## Further Reading

- `references/android-patterns.md` — extended Android patterns (Activity, Fragment, ViewModel, Compose)
- `references/anvil-deep-dive.md` — kotlin-inject-anvil in depth (@ContributesTo, @MergeComponent, subcomponents)
- https://github.com/evant/kotlin-inject
- https://github.com/evant/kotlin-inject-samples
- https://github.com/amzn/kotlin-inject-anvil
