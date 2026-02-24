# kotlin-inject-anvil Deep Dive

> **kotlin-inject-anvil** by Amazon adds automatic component merging to
> kotlin-inject — inspired by Anvil for Dagger. Contributions are discovered
> at compile time and merged into components by scope.
>
> Latest: **0.1.7** · Requires kotlin-inject 0.9.0

## Why Use Anvil?

Without Anvil, adding a new feature module means:

1. Create the binding interface
2. Find the correct component
3. Make that component extend the new interface
4. Repeat for every scope

With Anvil, you annotate your binding with a scope and the compiler does the
wiring. Feature modules never import the app module.

## Setup

```kotlin
// build.gradle.kts (KMP)
plugins {
    kotlin("multiplatform")
    id("com.google.devtools.ksp")
}

dependencies {
    kspCommonMainMetadata("software.amazon.lastmile.kotlin.inject.anvil:compiler:0.1.7")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation("software.amazon.lastmile.kotlin.inject.anvil:runtime:0.1.7")
            // Optional: @SingleIn scope annotation
            implementation("software.amazon.lastmile.kotlin.inject.anvil:runtime-optional:0.1.7")
        }
    }
}
```

For per-target KSP (not commonMain metadata):

```kotlin
dependencies {
    add("kspAndroid", "software.amazon.lastmile.kotlin.inject.anvil:compiler:0.1.7")
    add("kspJvm", "software.amazon.lastmile.kotlin.inject.anvil:compiler:0.1.7")
    add("kspIosArm64", "software.amazon.lastmile.kotlin.inject.anvil:compiler:0.1.7")
    // ... etc.
}
```

## Core Annotations

### @SingleIn(scope)

A convenience `@Scope` annotation from the `runtime-optional` artifact:

```kotlin
@Inject
@SingleIn(AppScope::class)
class UserRepository(private val api: Api)
```

Equivalent to creating your own `@AppScope` annotation, but saves
boilerplate. Multiple scopes: `AppScope`, `UserScope`, `ScreenScope`, etc.

### @ContributesTo(scope)

Contribute a component interface to a scope. The `@MergeComponent` for that
scope automatically extends it:

```kotlin
// In :feature-analytics module
@ContributesTo(AppScope::class)
interface AnalyticsComponent {
    @Provides
    fun analytics(impl: MixpanelAnalytics): Analytics = impl
}

// In :feature-auth module
@ContributesTo(AppScope::class)
interface AuthComponent {
    @Provides
    @SingleIn(AppScope::class)
    fun authManager(api: Api): AuthManager = AuthManagerImpl(api)
}
```

Neither module needs to know about the other or about the final app
component.

### @ContributesBinding(scope)

Shorthand for the common "bind implementation to interface" pattern:

```kotlin
interface ImageLoader

@Inject
@SingleIn(AppScope::class)
@ContributesBinding(AppScope::class)
class CoilImageLoader(private val context: Context) : ImageLoader
```

This generates a `@Provides` method that returns `CoilImageLoader` as
`ImageLoader`.

**With a specific bound type** (when implementing multiple interfaces):

```kotlin
@Inject
@ContributesBinding(AppScope::class, boundType = ImageLoader::class)
class CoilImageLoader(/*...*/) : ImageLoader, ImageTransformer
```

**Multi-binding into a Set:**

```kotlin
@Inject
@ContributesBinding(AppScope::class, multibinding = true)
class LoggingInterceptor : Interceptor

@Inject
@ContributesBinding(AppScope::class, multibinding = true)
class AuthInterceptor(private val token: TokenProvider) : Interceptor
```

The merged component will have `Set<Interceptor>` containing both.

### @MergeComponent(scope)

Replaces `@Component`. Collects every `@ContributesTo` and
`@ContributesBinding` for the given scope and merges them:

```kotlin
@MergeComponent(AppScope::class)
@SingleIn(AppScope::class)
abstract class AppComponent(
    @get:Provides val config: AppConfig,
)

val appComponent = AppComponent::class.create(AppConfig(...))
```

The generated class extends all contributed interfaces automatically.

### @ContributesSubcomponent(scope)

Define a child component that's contributed to a parent scope:

```kotlin
@ContributesSubcomponent(UserScope::class)
@SingleIn(UserScope::class)
interface UserComponent {
    val profileScreen: ProfileScreen

    @ContributesSubcomponent.Factory(AppScope::class)
    interface Factory {
        fun create(@get:Provides userId: String): UserComponent
    }
}

// The factory is automatically available from the parent:
@MergeComponent(AppScope::class)
@SingleIn(AppScope::class)
abstract class AppComponent {
    // UserComponent.Factory is auto-contributed to AppScope
}

val userComponent = appComponent.userComponentFactory.create("user-123")
```

## KMP Component Creation

In KMP, generated code can't be referenced from common source sets. Use
`@MergeComponent.CreateComponent`:

```kotlin
// commonMain
@MergeComponent(AppScope::class)
@SingleIn(AppScope::class)
abstract class AppComponent(@get:Provides val config: AppConfig)

@MergeComponent.CreateComponent
expect fun createAppComponent(config: AppConfig): AppComponent
```

The compiler generates `actual fun` implementations for each target.

## Replacing Contributions in Tests

Use `@ContributesTo` with the `replaces` parameter:

```kotlin
// Production
@ContributesTo(AppScope::class)
interface ProdAnalyticsComponent {
    @Provides fun analytics(): Analytics = RealAnalytics()
}

// Test
@ContributesTo(AppScope::class, replaces = [ProdAnalyticsComponent::class])
interface TestAnalyticsComponent {
    @Provides fun analytics(): Analytics = FakeAnalytics()
}
```

When both are on the classpath (test source set), the replacement wins.

## Custom Contributing Annotations

Create your own annotations that trigger code generation:

```kotlin
@ContributingAnnotation
@Target(AnnotationTarget.CLASS)
annotation class ContributesViewModel(val scope: KClass<*>)
```

Then implement a custom KSP processor that generates `@ContributesTo`
interfaces. See the kotlin-inject-anvil README for the full extension API.

## Architecture Example

A typical multi-module project:

```
:app                   — @MergeComponent(AppScope), platform entry points
:core:network          — @ContributesTo(AppScope) providing HttpClient
:core:database         — @ContributesTo(AppScope) providing Database
:feature:auth          — @ContributesBinding(AppScope) for AuthManager
:feature:home          — @ContributesTo(AppScope) for HomeScreen
:feature:settings      — @ContributesTo(AppScope) for SettingsScreen
```

The `:app` module's `@MergeComponent` automatically collects all
contributions. Feature modules are completely decoupled — they only depend
on `:core` modules and shared interfaces, never on each other or on `:app`.

## Disabling Built-in Processors

For advanced use cases, disable specific Anvil processors via KSP options:

```kotlin
ksp {
    // Disable a specific processor
    arg(
        "software.amazon.lastmile.kotlin.inject.anvil.processor.ContributesBindingProcessor",
        "disabled"
    )
}
```

Use the processor's fully qualified class name as the key.
