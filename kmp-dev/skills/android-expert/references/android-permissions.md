# Android Permissions

Permission handling patterns for KMP Android apps.

## Accompanist Permission Pattern

```kotlin
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraFeature() {
    val cameraPermission = rememberPermissionState(Manifest.permission.CAMERA)
    when {
        cameraPermission.status.isGranted -> CameraPreview()
        cameraPermission.status.shouldShowRationale -> {
            Column {
                Text("Camera permission is needed to scan QR codes")
                Button(onClick = { cameraPermission.launchPermissionRequest() }) { Text("Grant Permission") }
            }
        }
        else -> Button(onClick = { cameraPermission.launchPermissionRequest() }) { Text("Enable Camera") }
    }
}
```

## Multiple Permissions

```kotlin
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun MediaUploadFeature() {
    val permissions = rememberMultiplePermissionsState(
        listOf(Manifest.permission.CAMERA, Manifest.permission.READ_EXTERNAL_STORAGE)
    )
    when {
        permissions.allPermissionsGranted -> MediaUploadUI()
        permissions.shouldShowRationale -> RationaleDialog(onConfirm = { permissions.launchMultiplePermissionRequest() })
        else -> Button(onClick = { permissions.launchMultiplePermissionRequest() }) { Text("Grant Permissions") }
    }
}
```

## Common Permissions

```xml
<!-- AndroidManifest.xml -->
<!-- Network -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Media -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

<!-- Notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Foreground Services -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

## Best Practices

1. **Request contextually** - Before the feature that needs it, not at app start
2. **Show rationale** - Explain why the permission is needed
3. **Handle denial gracefully** - Provide fallback or guide to settings
4. **Check SDK version** - Some permissions only needed on certain API levels
