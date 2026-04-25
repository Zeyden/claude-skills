# Proguard Rules

Generic Proguard/R8 configuration for KMP Android apps.

## Core Rules

```proguard
# Kotlin metadata
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*, InnerClasses, Signature

# kotlinx.serialization
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** { kotlinx.serialization.KSerializer serializer(...); }

# Keep domain model classes (adjust package)
-keep class com.example.shared.model.** { *; }

# Compose
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

# OkHttp / Ktor
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-dontwarn io.ktor.**
-keep class io.ktor.** { *; }

# Coroutines
-keepnames class kotlinx.coroutines.** { *; }

# SQLDelight
-keep class app.cash.sqldelight.** { *; }
```

## Platform-Specific Native Libraries

```proguard
# If using native crypto libraries
# -keep class <your.crypto.package>.** { *; }

# If using Room
-keep class * extends androidx.room.RoomDatabase { *; }

# If using Koin
-keep class org.koin.** { *; }
```

## Common Issues

| Symptom | Fix |
|---------|-----|
| `NoClassDefFoundError` | Add `-keep` rule for the class |
| Serialization fails | Keep `@Serializable` classes and `Companion` objects |
| Reflection fails | Add `-keepattributes Signature` |
| Native lib crash | Keep JNI wrapper classes |

## Testing

```bash
# Build release and test
./gradlew :app:assembleRelease
# Install and verify all features work
./gradlew :app:installRelease
```
