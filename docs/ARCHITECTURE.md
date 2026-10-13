# Showcase App - Modular Architecture

## Overview

The Showcase app follows a modular Swift Package architecture with three distinct targets:

```
ShowcaseApp (SPM Package)
├── ShowcaseCore/      # Business logic, models, services
├── ShowcaseUI/        # SwiftUI views and components
└── ShowcaseApp/       # Application entry point
```

## Module Descriptions

### ShowcaseCore

**Purpose:** Core business logic, data models, and services

**Contents:**
- `Models/` - Data structures (Scenario, Video, Photo, LoadState)
- `Services/` - Business logic (SupabaseClient for API interactions)
- `Utilities/` - Helper functions (Logger)

**Dependencies:**
- SkipSupabase (for backend integration)

**Key Features:**
- Actor-isolated SupabaseClient for thread-safe network operations
- Sendable-conforming models for Swift 6 strict concurrency
- Retry logic with exponential backoff for network resilience

### ShowcaseUI

**Purpose:** User interface components and views

**Contents:**
- `Screens/` - Full-screen views (MainScreen, LibraryScreen, PlayerScreen)
- `Components/` - Reusable UI components (ScenarioCard, VideoCard, PlaybackControls)
- `Theme/` - Design system (LiquidGlassTheme, Typography)
- `Resources/` - Assets and localization files

**Dependencies:**
- ShowcaseCore (for models and services)
- SkipFuseUI (for SwiftUI → Jetpack Compose transpilation)
- SkipAV (for video playback)

**Key Features:**
- SwiftUI views that transpile to Jetpack Compose via SKIP
- Liquid Glass design language for iOS/iPadOS 26
- @Observable state management for reactive UI

### ShowcaseApp

**Purpose:** Application entry point and configuration

**Contents:**
- App lifecycle management
- Dependency injection setup
- Platform-specific configuration

**Dependencies:**
- ShowcaseCore
- ShowcaseUI

**Key Features:**
- Unified entry point for iOS/iPadOS and Android
- URLCache configuration for media caching
- App delegate lifecycle hooks

## Swift 6 Strict Concurrency

All targets are configured with strict concurrency checking enabled:

```swift
swiftSettings: [
    .enableUpcomingFeature("StrictConcurrency")
]
```

This ensures:
- All shared mutable state is properly isolated
- Actor isolation prevents data races
- Sendable types are used for cross-actor communication
- Async/await is used consistently for asynchronous operations

## SKIP Transpilation

Each module includes a `Skip/skip.yml` configuration file:

```yaml
skip:
  mode: 'native'
```

This enables SKIP to transpile Swift code to Kotlin/Jetpack Compose for Android deployment.

## Dependency Graph

```
ShowcaseApp
    ├── ShowcaseCore
    │   └── SkipSupabase
    └── ShowcaseUI
        ├── ShowcaseCore
        ├── SkipFuseUI
        └── SkipAV
```

## Building

Build individual modules:
```bash
swift build --target ShowcaseCore
swift build --target ShowcaseUI
swift build --target ShowcaseApp
```

Build all modules:
```bash
swift build
```

Run tests:
```bash
swift test
```

## Requirements Mapping

This architecture satisfies the following requirements:

- **Requirement 5.1:** Swift 6.3 with SwiftUI for iOS/iPadOS ✅
- **Requirement 5.2:** SKIP transpilation to Kotlin/Jetpack Compose ✅
- **Requirement 5.3:** Modular Swift Package architecture ✅
- **Requirement 5.5:** Swift 6 strict concurrency with Sendable types and Actor isolation ✅
