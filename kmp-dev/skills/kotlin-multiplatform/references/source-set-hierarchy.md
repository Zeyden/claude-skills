# Source Set Hierarchy

Visual guide to source set organisation for KMP projects.

## Standard Hierarchy

```
┌────────────────────────────────────────────────────┐
│                    commonMain                       │
│  Pure Kotlin, no platform APIs                      │
│  Deps: kotlin-stdlib, kotlinx-coroutines, ktor...   │
└────────────────┬───────────────────────────────────┘
                 │
    ┌────────────┼────────────┬──────────────┐
    ▼            ▼            ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐  ┌──────────┐
│android   │ │ jvmMain  │ │ iosMain  │  │ wasmJs/  │
│Main      │ │(Desktop) │ │ (+x64/   │  │  jsMain  │
│          │ │          │ │  arm64/  │  │          │
│Android   │ │Compose   │ │  sim)    │  │ Browser  │
│framework │ │Desktop   │ │iOS APIs  │  │ targets  │
└──────────┘ └──────────┘ └──────────┘  └──────────┘
```

## Dependency Flow

```
commonMain → Kotlin stdlib + kotlinx + ktor-client + SQLDelight (KMP-ready)
androidMain → commonMain + Android framework (android.*, AndroidX)
jvmMain     → commonMain + JVM stdlib + Compose Desktop (Skiko)
iosMain     → commonMain + platform.* via cinterop
jsMain      → commonMain + browser/Node APIs
```

## Default Hierarchy Template (modern approach)

`applyDefaultHierarchyTemplate()` sets up the standard intermediate source sets automatically (`appleMain`, `nativeMain`, `mobileMain` when applicable). Prefer this over manual `dependsOn` wiring unless you need a non-standard intermediate like `jvmAndroid`.

```kotlin
kotlin {
    applyDefaultHierarchyTemplate()   // adds appleMain, nativeMain, etc.

    androidTarget()
    jvm()
    iosX64(); iosArm64(); iosSimulatorArm64()
}
```

This gives you, for free:

```
commonMain
    ├── androidMain
    ├── jvmMain
    ├── nativeMain
    │   └── appleMain
    │       └── iosMain
    │           ├── iosX64Main
    │           ├── iosArm64Main
    │           └── iosSimulatorArm64Main
    ├── jsMain (if js target)
    └── wasmJsMain (if wasmJs target)
```

## Manual Intermediate: jvmAndroid

When you want to share JVM libraries (OkHttp, Jackson, JDK `java.time`) between Android and Desktop **without** pushing them into `commonMain`:

```kotlin
kotlin {
    applyDefaultHierarchyTemplate()

    sourceSets {
        val jvmAndroid by creating {
            dependsOn(commonMain.get())
            dependencies { api(libs.okhttp) }
        }
        androidMain { dependsOn(jvmAndroid) }
        jvmMain { dependsOn(jvmAndroid) }
    }
}
```

Do this BEFORE any target-specific configuration that consumes `androidMain` or `jvmMain`.

## Choosing the Right Source Set

```
Pure Kotlin, no platform APIs            → commonMain
JVM-only library, Android + Desktop only → jvmAndroid
Apple-only code (UIKit, platform.*)      → appleMain
Android only                             → androidMain
Desktop only                             → jvmMain
iOS only                                 → iosMain (or iosX64Main + iosArm64Main + iosSimulatorArm64Main)
Browser only                             → jsMain / wasmJsMain
```

## Summary

| Source set | Extends | Can use | Typical content |
|-----------|---------|---------|-----------------|
| commonMain | — | kotlin stdlib + kotlinx + KMP libs | Domain models, use cases, shared Compose |
| appleMain  | commonMain | platform.* (via default hierarchy) | Apple-only interop, Keychain wrappers |
| nativeMain | commonMain | cinterop, POSIX | Native-only helpers |
| jvmAndroid | commonMain (manual) | JVM stdlib, JVM-only libs | OkHttp, Jackson, `java.time` |
| androidMain | jvmAndroid / commonMain | Android framework | Activity, Context, Work Manager |
| jvmMain    | jvmAndroid / commonMain | JVM + AWT / Compose Desktop | Window, MenuBar, file dialogs |
| iosMain    | appleMain / commonMain | UIKit, Foundation | View controllers, Keychain |
| jsMain     | commonMain | Browser DOM | DOM wiring |
| wasmJsMain | commonMain | wasm-js bindings | wasm-js entry points |
