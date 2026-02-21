# Target Compatibility Guide

Current targets and future targets with constraints.

## Cross-Target Compatibility Matrix

| Feature | Android | Desktop | iOS | Web (JS) | wasm |
|---------|---------|---------|-----|----------|------|
| Pure Kotlin | Yes | Yes | Yes | Yes | Yes |
| kotlinx.coroutines | Yes | Yes | Yes | Yes | Limited |
| kotlinx.serialization | Yes | Yes | Yes | Yes | Limited |
| kotlinx.datetime | Yes | Yes | Yes | Yes | Limited |
| ktor-client | Yes | Yes | Yes | Yes | No |
| Compose Multiplatform | Yes | Yes | Experimental | Experimental | No |

## Platform-Specific Constraints

**Android:** Mobile UX, touch-first, battery constraints, Activity lifecycle
**Desktop:** Sidebar nav, keyboard+mouse, multi-window, MenuBar
**iOS:** UIViewController, Swift interop, XCFramework
**Web:** Single-threaded event loop, no blocking calls, CORS

## Future-Proofing

**DO:** Use kotlinx.serialization, ktor-client, kotlinx.datetime, suspending functions, keep business logic in commonMain
**DON'T:** Put JVM libraries in commonMain, use blocking I/O, depend on threading (use coroutines)

## Testing Strategy

| Source Set | Test Location | Approach |
|-----------|--------------|----------|
| commonMain | commonTest | Business logic, runs on all platforms |
| androidMain | androidTest | Instrumented + unit tests |
| jvmMain | jvmTest | Desktop-specific tests |
| iosMain | iosTest | Simulator/device tests |
