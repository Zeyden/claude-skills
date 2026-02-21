# Source Set Hierarchy

Visual guide to source set organization for KMP projects.

## Standard Hierarchy

```
┌────────────────────────────────────────────────────┐
│                    commonMain                        │
│  Pure Kotlin, no platform APIs                      │
│  Examples: data models, business logic, validation  │
│  Dependencies: kotlin-stdlib, kotlinx-coroutines    │
└────────────────┬───────────────────────────────────┘
                 │
    ┌────────────┼────────────┬──────────────┐
    ▼            ▼            ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐  ┌──────────┐
│android   │ │ jvmMain  │ │ iosMain  │  │ Future:  │
│Main      │ │(Desktop) │ │          │  │ jsMain   │
│          │ │          │ │          │  │ wasmMain │
│Android   │ │Compose   │ │iOS APIs  │  └──────────┘
│framework │ │Desktop   │ │Security  │
└──────────┘ └──────────┘ └──────────┘
```

## Dependency Flow

```
commonMain → Nothing (only Kotlin stdlib + kotlinx)
androidMain → commonMain + Android framework
jvmMain → commonMain + JVM + Compose Desktop
iosMain → commonMain + iOS platform APIs
```

## Advanced: jvmAndroid Intermediate Source Set

For projects sharing JVM libraries (Jackson, OkHttp) between Android and Desktop:

```
commonMain
    ├── jvmAndroid (optional)    ← JVM libraries shared by Android + Desktop
    │   ├── androidMain
    │   └── jvmMain
    └── iosMain
```

```kotlin
// build.gradle.kts - MUST be defined BEFORE androidMain/jvmMain
val jvmAndroid = create("jvmAndroid") {
    dependsOn(commonMain.get())
    dependencies { api(libs.jackson.module.kotlin) }
}
jvmMain { dependsOn(jvmAndroid) }
androidMain { dependsOn(jvmAndroid) }
```

## Choosing the Right Source Set

```
Pure Kotlin? → commonMain
JVM-only library? → jvmAndroid (if shared) or platform-specific
Android API? → androidMain
Desktop API? → jvmMain
iOS API? → iosMain
```

## Summary

| Source Set | Extends | Can Use | Example Code |
|------------|---------|---------|-------------|
| commonMain | - | Kotlin stdlib only | Data models, business logic |
| androidMain | commonMain | Android framework | Activity, ViewModel |
| jvmMain | commonMain | JVM + Compose Desktop | Window, MenuBar |
| iosMain | commonMain | iOS platform | Security framework |
