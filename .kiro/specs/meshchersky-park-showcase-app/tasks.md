# Implementation Plan: Meshchersky Park Showcase App

## Overview

This implementation plan breaks down the Meshchersky Park Showcase App into discrete, sequential coding tasks. The app is a cross-platform (iOS/iPadOS/Android) video presentation system built with Swift 6.3 + SwiftUI, transpiled to Android via SKIP 1.0+, backed by Supabase for content management.

The implementation follows a bottom-up approach: infrastructure → core models → services → viewmodels → UI → integration → deployment.

## Tasks

- [ ] 1. Set up Supabase backend infrastructure
  - [x] 1.1 Create Supabase database schema
    - Create `scenarios` table with fields: id, title, slug, order_index, active, created_at
    - Create `videos` table with fields: id, scenario_id, title, storage_path, duration_sec, order_index, active, created_at
    - Add foreign key constraint: videos.scenario_id → scenarios.id with CASCADE delete
    - Create indexes: idx_scenarios_active_order, idx_videos_scenario_active_order, idx_videos_active
    - _Requirements: 4.1, 4.2, 4.6_

  - [x] 1.2 Configure Supabase Storage bucket
    - Create `videos` storage bucket with public read access
    - Configure folder structure: family/, wellness/, guests/, investor/, architecture/
    - Set up CDN delivery for video files
    - _Requirements: 4.3, 4.4_

  - [x] 1.3 Set up GitHub Actions backup pipeline
    - Create `.github/workflows/backup.yml` workflow file
    - Configure scheduled trigger for daily execution at 02:00 UTC
    - Implement database dump step using Supabase CLI
    - Implement backup file commit step with format `backup_YYYYMMDD.sql`
    - Add failure notification configuration
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 2. Create Swift Package structure and core models
  - [x] 2.1 Initialize Swift Package with modular architecture
    - Create `Package.swift` with ShowcaseCore, ShowcaseUI, ShowcaseApp targets
    - Add Supabase Swift SDK dependency
    - Configure Swift 6.3 language version and strict concurrency
    - Set up SKIP configuration in `Skip/skip.yml`
    - _Requirements: 5.1, 5.2, 5.3, 5.5_

  - [x] 2.2 Implement core data models
    - Create `Scenario.swift` with Identifiable, Codable, Sendable, Hashable conformance
    - Create `Video.swift` with Identifiable, Codable, Sendable, Hashable conformance
    - Implement `videoURL` computed property for CDN URL construction
    - Create `PlaybackState.swift` enum with idle, loading, playing, paused, error cases
    - Add computed properties: currentVideo, hasNext
    - _Requirements: 4.1, 4.2, 5.4, 5.5_

  - [x] 2.3 Write unit tests for core models
    - Test Scenario/Video Codable encoding and decoding
    - Test PlaybackState transitions (idle → loading → playing → paused)
    - Test PlaybackState.hasNext with single and multiple videos
    - Test Video.videoURL construction
    - _Requirements: 4.1, 4.2_

- [ ] 3. Implement service layer with actor isolation
  - [x] 3.1 Create SupabaseClient actor
    - Implement actor with private SupabaseClient instance
    - Implement `fetchScenarios()` method with active filter and order_index sort
    - Implement `fetchVideos(for scenarioId:)` method with active filter and order_index sort
    - Implement `fetchAllVideos()` method for library view
    - Implement `getVideoURL(path:)` method for storage URL generation
    - _Requirements: 4.6, 5.5, 5.6_

  - [x] 3.2 Create VideoService actor
    - Implement actor with SupabaseClient dependency injection
    - Implement `loadScenarios()` method
    - Implement `loadScenario(_:)` method to fetch videos for a scenario
    - Implement `loadAllVideos()` method for library catalog
    - _Requirements: 1.2, 2.2, 5.5, 5.6_

  - [x] 3.3 Implement error handling types
    - Create `NetworkError` enum with cases: offline, timeout, serverError, invalidResponse
    - Implement LocalizedError conformance with user-friendly error messages
    - Add error mapping in service layer (URLError → NetworkError)
    - _Requirements: 9.2, 9.4, 9.5_

  - [x] 3.4 Write integration tests for Supabase services
    - Test SupabaseClient.fetchScenarios() returns only active scenarios sorted by order_index
    - Test SupabaseClient.fetchVideos() returns only active videos for a scenario
    - Test error handling for offline/timeout conditions
    - Test VideoService methods with mock SupabaseClient
    - _Requirements: 4.6, 9.2_

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement ViewModel layer with @Observable
  - [x] 5.1 Create MainViewModel
    - Implement @Observable class with Sendable conformance
    - Add state properties: scenarios, isLoading, errorMessage
    - Implement `loadScenarios()` method with @MainActor annotation
    - Implement `selectScenario(_:)` method returning [Video]?
    - Add error handling with NetworkError mapping
    - _Requirements: 1.1, 1.2, 5.4, 5.6, 9.1, 9.2_

  - [x] 5.2 Create PlayerViewModel
    - Implement @Observable class with Sendable conformance
    - Add state properties: playbackState, currentTime, duration
    - Implement `startPlayback(videos:)` method with @MainActor annotation
    - Implement `playVideo(at:in:)` private method with AVPlayer initialization
    - Implement `playNext()` method for auto-advance
    - Implement `pause()`, `resume()`, `stop()` methods
    - Add AVPlayerItemDidPlayToEndTime notification observer for auto-advance
    - _Requirements: 1.3, 1.4, 1.5, 5.4, 5.6_

  - [x] 5.3 Implement playback error recovery
    - Add `handlePlaybackError(_:)` method to PlayerViewModel
    - Implement skip-to-next-video logic on playback failure
    - Add error state transition when queue is exhausted
    - _Requirements: 9.4_

  - [x] 5.4 Write unit tests for ViewModels
    - Test MainViewModel state transitions during loadScenarios()
    - Test MainViewModel error handling paths
    - Test PlayerViewModel playback queue management
    - Test PlayerViewModel auto-advance logic
    - Test PlayerViewModel error recovery
    - _Requirements: 1.2, 1.5, 9.4_

- [ ] 6. Implement UI components and screens
  - [x] 6.1 Create ServiceStateView component
    - Implement view with icon, message, and optional retry action
    - Support loading, error, and empty states
    - _Requirements: 9.1, 9.2, 9.3_

  - [x] 6.2 Create ScenarioCard component
    - Implement card with thumbnail placeholder, play icon, and title
    - Apply Liquid Glass design language (ultraThinMaterial, rounded corners)
    - Add tap gesture handler
    - _Requirements: 1.1, 10.1, 10.2, 10.5_

  - [x] 6.3 Create VideoCard component
    - Implement card with thumbnail, title, and duration display
    - Apply Liquid Glass design language
    - Add tap gesture handler
    - _Requirements: 2.3, 2.5, 10.1, 10.2, 10.5_

  - [x] 6.4 Create PlaybackControls component
    - Implement controls with play/pause, next, and stop buttons
    - Show current video title and queue position
    - Apply Liquid Glass design language with ultraThinMaterial background
    - _Requirements: 1.4, 10.1, 10.2, 10.5_

  - [x] 6.5 Create MainScreen
    - Implement NavigationStack with scenario grid layout
    - Integrate MainViewModel with @State property wrapper
    - Add loading, error, and empty state handling with ServiceStateView
    - Add toolbar with library navigation button
    - Implement scenario selection with navigation to PlayerScreen
    - Add .task modifier to trigger loadScenarios() on appear
    - _Requirements: 1.1, 1.2, 2.1, 9.1, 9.2, 9.3, 10.3, 10.4_

  - [x] 6.6 Create LibraryScreen
    - Implement list view with videos grouped by scenario
    - Add scenario filter picker
    - Integrate with VideoService to load all videos
    - Implement video selection with navigation to PlayerScreen
    - Display video metadata (title, duration)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 10.3, 10.4_

  - [x] 6.7 Create PlayerScreen
    - Implement fullscreen VideoPlayer with AVKit
    - Integrate PlayerViewModel with @State property wrapper
    - Add PlaybackControls overlay at bottom (tablet only)
    - Implement .task modifier to trigger startPlayback()
    - Add navigation back to main screen on stop
    - _Requirements: 1.3, 1.4, 1.5, 1.6, 3.3, 3.4, 10.3_

- [ ] 7. Implement wireless mirroring support
  - [ ] 7.1 Add AirPlay support for iOS/iPadOS
    - Configure AVPlayer for external display routing
    - Add AirPlay button to PlayerScreen toolbar
    - Implement external display detection
    - _Requirements: 3.1, 3.3_

  - [~] 7.2 Add Cast support for Android (SKIP configuration)
    - Configure SKIP transpilation for Cast API
    - Add Cast button to PlayerScreen toolbar (Android only)
    - Implement external display detection for Android
    - _Requirements: 3.2, 3.3_

  - [~] 7.3 Implement external display connection error handling
    - Add connection state monitoring
    - Display error message on tablet when connection is lost
    - _Requirements: 3.5, 9.2_

- [~] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Create app entry point and configuration
  - [x] 9.1 Create ShowcaseApp.swift entry point
    - Implement @main App struct
    - Initialize SupabaseClient with environment variables
    - Initialize VideoService with SupabaseClient
    - Set up MainScreen as root view
    - _Requirements: 5.1, 5.3, 7.3, 7.5_

  - [x] 9.2 Configure environment variables
    - Create `.env.example` with SUPABASE_URL and SUPABASE_ANON_KEY placeholders
    - Document environment variable setup in README
    - _Requirements: 4.3, 7.4_

  - [~] 9.3 Configure SKIP for Android transpilation
    - Create `Skip/skip.yml` configuration file
    - Configure Kotlin/Compose transpilation settings
    - Add Android-specific dependencies (Cast SDK)
    - _Requirements: 5.2, 5.3, 7.2_

  - [x] 9.4 Implement Logger utility
    - Create Logger enum with error, info, warning methods
    - Add DEBUG conditional compilation for console output
    - Add placeholder for production analytics integration
    - _Requirements: 9.5_

  - [x] 9.5 Create Constants utility
    - Define content constraints: MAX_VIDEOS = 25, MAX_SCENARIOS = 5, MAX_VIDEO_DURATION = 30
    - Define performance thresholds: VIDEO_LOAD_TIMEOUT = 2.0, MIN_BANDWIDTH = 5.0
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 10. Implement Liquid Glass theme
  - [x] 10.1 Create LiquidGlassTheme.swift
    - Define color palette for luxury aesthetic
    - Define material styles (ultraThinMaterial, thinMaterial)
    - Define corner radius constants
    - _Requirements: 10.1, 10.4_

  - [x] 10.2 Create Typography.swift
    - Define font styles for headings, body, captions
    - Ensure touch-optimized sizing for tablet
    - _Requirements: 10.4, 10.5_

  - [~] 10.3 Apply theme to all UI components
    - Update ScenarioCard, VideoCard, PlaybackControls with theme
    - Update MainScreen, LibraryScreen, PlayerScreen with theme
    - Verify visual consistency across iOS and Android
    - _Requirements: 10.2, 10.3, 10.4_

- [ ] 11. Add integration and UI tests
  - [~] 11.1 Write UI tests for scenario selection flow
    - Test: Tap scenario card → videos load → player opens
    - Test: Back navigation returns to main screen
    - _Requirements: 1.1, 1.2, 1.3_

  - [~] 11.2 Write UI tests for library navigation
    - Test: Open library → filter by scenario → tap video → player opens
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [~] 11.3 Write UI tests for error states
    - Test: Offline state shows error message with retry button
    - Test: Empty state shows placeholder
    - _Requirements: 9.2, 9.3_

  - [~] 11.4 Write UI tests for playback controls
    - Test: Play/pause button toggles state
    - Test: Next button advances to next video
    - Test: Stop button returns to main screen
    - _Requirements: 1.4, 1.5_

- [~] 12. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Configure deployment pipelines
  - [~] 13.1 Set up iOS/iPadOS TestFlight deployment
    - Create Xcode project configuration for ShowcaseApp
    - Configure code signing and provisioning profiles
    - Create Fastlane configuration for TestFlight upload
    - Document TestFlight installation process
    - _Requirements: 7.1, 7.3_

  - [~] 13.2 Set up Android APK build and sideload
    - Configure Gradle build for Android target
    - Create Fastlane configuration for APK build
    - Document APK sideload installation process
    - _Requirements: 7.2, 7.3_

  - [~] 13.3 Configure GitHub Actions CI/CD
    - Create `.github/workflows/test.yml` for automated testing
    - Create `.github/workflows/deploy-ios.yml` for TestFlight deployment
    - Create `.github/workflows/deploy-android.yml` for APK build
    - _Requirements: 7.1, 7.2_

- [ ] 14. Create documentation and deployment guides
  - [~] 14.1 Write README.md
    - Document project overview and architecture
    - Document environment setup (Supabase credentials)
    - Document build and run instructions for iOS and Android
    - Document testing instructions
    - _Requirements: 5.1, 5.2, 7.4_

  - [~] 14.2 Write CONTENT_UPLOAD_GUIDE.md
    - Document Supabase Dashboard access
    - Document video upload process to Storage
    - Document scenario and video metadata management
    - Document active/inactive content control
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [~] 14.3 Write DEPLOYMENT.md
    - Document TestFlight deployment process
    - Document APK sideload process
    - Document backup restoration process
    - Document troubleshooting common issues
    - _Requirements: 7.1, 7.2, 6.1, 6.2, 6.3, 6.4, 6.5_

- [~] 15. Final checkpoint and production readiness
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- The implementation follows a bottom-up approach: infrastructure → models → services → viewmodels → UI → integration → deployment
- Swift 6.3 strict concurrency is enforced throughout with Sendable types and Actor isolation
- SKIP transpilation to Android happens automatically during build
- No property-based tests are included because this feature involves infrastructure, UI rendering, and external dependencies (not pure business logic)
