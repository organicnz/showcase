---
name: skip-transpilation-mastery
description: Best practices and transpilation rules for Skip 1.0+ (Swift to Kotlin and Jetpack Compose). Use when developing, debugging, or modifying cross-platform Swift code targeting Android via Skip, handling SkipUI/SwiftUI differences, #if SKIP conditionals, and Compose state bridges.
---

# Skip Transpilation Mastery (Swift 6 → Kotlin / Jetpack Compose)

This skill governs the development and cross-platform transpilation of the Showcase application using **Skip 1.0+**. It ensures that all Swift code in `ShowcaseCore` and `ShowcaseUI` transpiles seamlessly to Kotlin without build failures or Android runtime crashes.

---

## 1. Core Architecture & Mental Model

Skip transpiles Swift source code into Kotlin at the syntax tree level:
* **ShowcaseCore (Swift)** ➔ Transpiled to standard Kotlin JVM / Android library.
* **ShowcaseUI (SwiftUI)** ➔ Transpiled to Android Jetpack Compose via `SkipUI` / `SkipFuseUI`.
* **ShowcaseApp** ➔ Kotlin Android Application entry point (`MainActivity.kt`).

```
Swift 6 Code (SwiftUI + @Observable)
       │
       ▼ (skipstone compiler plugin)
Kotlin Code (Jetpack Compose + State)
```

---

## 2. Transpilation Rules & Safe Idioms

### ✅ Supported Swift Patterns in Skip:
- Structs, Enums with raw/associated values, and simple Protocols.
- `@Observable` models (Skip automatically adapts them to Compose mutable states).
- Async/await and structured tasks (`Task {}`).
- Standard SwiftUI views: `VStack`, `HStack`, `ZStack`, `ScrollView`, `Text`, `Image`, `Button`, `LazyVGrid`.
- Modern modifiers: `.padding()`, `.background()`, `.foregroundColor()`, `.cornerRadius()`, `.clipShape()`.

### ⚠️ Prohibited Idioms (Cause Transpilation Errors):
- **Complex dynamic key paths:** Avoid dynamic reflection or complex `\KeyPath` manipulations.
- **Custom UIKit / AppKit bridges:** Direct `UIViewRepresentable` without `#if !SKIP` guards.
- **Compiler macros:** Custom Swift syntax macros that do not have Kotlin equivalents.
- **Duplicate Static Products:** Mixing Lite (`skip-ui`) and Fuse (`skip-fuse-ui`) targets in a single package graph causes duplicate symbol errors under Swift 6.4.

---

## 3. Conditional Compilation Patterns

Always isolate platform-specific features using standard Skip macros:

```swift
// MARK: - Safe Platform Separation

#if SKIP
import android.content.Context
import androidx.compose.runtime.Composable
#else
import UIKit
import AVKit
#endif

public struct PlatformHelper {
    public static func getPlatformName() -> String {
        #if SKIP
        return "Android (Jetpack Compose)"
        #else
        return "Apple (iOS/iPadOS)"
        #endif
    }
}
```

### Video & Audio Bridging:
* **iOS:** Uses native `AVPlayer` and `AVPlayerViewController`.
* **Android:** Uses Skip's `skip-av` wrapper or native Android `VideoView` / `ExoPlayer`:
  ```swift
  #if SKIP
  // SkipAV or Compose AndroidView implementation
  #else
  import AVFoundation
  import AVKit
  // iOS AVPlayer Layer
  #endif
  ```

---

## 4. Compose State Recomposition Best Practices

1. **Keep Observable Properties Atomic:**
   Avoid heavy computed properties inside `@Observable` classes that trigger full screen recomposition on Android.
2. **Stable Identifiers in Lazy Stacks:**
   Always provide explicit `id: \.id` or conform to `Identifiable` with UUID/String for `ForEach` and `LazyVGrid` to enable Jetpack Compose item keys.
3. **Immutability First:**
   Prefer immutable `let` properties in data models (`Scenario`, `Video`, `Photo`).

---

## 5. Build & Validation Commands

To test and build Android via Skip locally:

```bash
# 1. Verify Skip CLI installation
skip check

# 2. Compile and test Swift library
swift build --target ShowcaseCore

# 3. Build Android debug APK
cd Android
./gradlew assembleDebug

# Output APK path:
# Android/app/build/outputs/apk/debug/app-debug.apk
```
