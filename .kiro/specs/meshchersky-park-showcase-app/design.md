# Design Document: Meshchersky Park Showcase App

## Overview

The Meshchersky Park Showcase App is a tablet-controlled video presentation system designed for a premium residential complex sales office in Moscow. The system enables sales managers to select life scenario profiles on a tablet, triggering playback of curated video content on a wirelessly-mirrored large display screen.

### Design Goals

1. **Cross-Platform Native Performance**: Single Swift codebase transpiled to both iOS/iPadOS and Android via SKIP 1.0+
2. **Wireless Presentation**: Seamless AirPlay/Cast mirroring from tablet to external display
3. **Privacy-First Architecture**: No user authentication, no tracking, kiosk-mode operation
4. **Quiet Luxury UX**: Liquid Glass design language reflecting premium brand aesthetic
5. **Content Flexibility**: Supabase-backed content management with automated backups
6. **Production Reliability**: Swift 6 strict concurrency, actor isolation, comprehensive error handling

### Technical Constraints

- **Language**: Swift 6.3 with strict concurrency enabled
- **UI Framework**: SwiftUI (transpiled to Jetpack Compose via SKIP 1.0+)
- **State Management**: @Observable framework for reactive UI
- **Concurrency Model**: async/await exclusively, no callbacks
- **Backend**: Supabase (PostgreSQL + Storage + CDN)
- **Deployment**: TestFlight (iOS), APK sideload (Android)
- **Content Scale**: 5 scenarios, 20-25 videos (max 30 sec each)
- **Network**: Stable internet required (no offline mode)

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE BACKEND                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  PostgreSQL  │  │   Storage    │  │     CDN      │      │
│  │  (metadata)  │  │ (video files)│  │  (delivery)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │ REST API + Storage API
                         │
        ┌────────────────┴────────────────┐
        │                                  │
┌───────▼────────┐              ┌─────────▼────────┐
│   iOS/iPadOS   │              │     Android      │
│   Swift 6.3    │◄──── SKIP ───│  Kotlin/Compose  │
│   SwiftUI      │   Transpile  │                  │
└───────┬────────┘              └─────────┬────────┘
        │                                  │
        └────────────┬─────────────────────┘
                     │ Wireless Mirroring
                     │ (AirPlay / Cast)
              ┌──────▼──────┐
              │   External  │
              │   Display   │
              │  (TV Screen)│
              └─────────────┘
```

### Module Architecture

The application follows a modular Swift Package architecture:

```
ShowcaseApp (SPM Package)
├── ShowcaseCore/
│   ├── Models/
│   │   ├── Scenario.swift
│   │   ├── Video.swift
│   │   └── PlaybackState.swift
│   ├── Services/
│   │   ├── SupabaseClient.swift (Actor)
│   │   ├── VideoService.swift (Actor)
│   │   └── MirrorService.swift
│   └── Utilities/
│       ├── Logger.swift
│       └── Constants.swift
├── ShowcaseUI/
│   ├── Screens/
│   │   ├── MainScreen.swift
│   │   ├── LibraryScreen.swift
│   │   └── PlayerScreen.swift
│   ├── Components/
│   │   ├── ScenarioCard.swift
│   │   ├── VideoCard.swift
│   │   ├── PlaybackControls.swift
│   │   └── ServiceStateView.swift
│   └── Theme/
│       ├── LiquidGlassTheme.swift
│       └── Typography.swift
└── ShowcaseApp/
    ├── ShowcaseApp.swift (iOS/iPadOS entry)
    └── Skip/
        └── skip.yml (Android configuration)
```

### Data Flow

```
User Interaction → ViewModel (@Observable)
                        ↓
                   Actor Service (isolated)
                        ↓
                   Supabase API
                        ↓
                   Data Models (Sendable)
                        ↓
                   ViewModel Update
                        ↓
                   SwiftUI View Rerender
                        ↓
                   External Display (mirrored)
```

## Components and Interfaces

### Core Models

#### Scenario Model

```swift
import Foundation

/// Represents a life scenario category containing related videos
struct Scenario: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let title: String
    let slug: String
    let orderIndex: Int
    let active: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case slug
        case orderIndex = "order_index"
        case active
    }
}
```

#### Video Model

```swift
import Foundation

/// Represents a single video asset with metadata
struct Video: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let scenarioId: UUID
    let title: String?
    let storagePath: String
    let durationSec: Int?
    let orderIndex: Int
    let active: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case scenarioId = "scenario_id"
        case title
        case storagePath = "storage_path"
        case durationSec = "duration_sec"
        case orderIndex = "order_index"
        case active
        case createdAt = "created_at"
    }
    
    /// Computed CDN URL for video playback
    var videoURL: URL? {
        // Constructed from Supabase Storage CDN path
        URL(string: "https://[project-ref].supabase.co/storage/v1/object/public/\(storagePath)")
    }
}
```

#### PlaybackState Model

```swift
import Foundation

/// Represents the current playback state
enum PlaybackState: Sendable {
    case idle
    case loading
    case playing(video: Video, queue: [Video], currentIndex: Int)
    case paused(video: Video, queue: [Video], currentIndex: Int)
    case error(message: String)
    
    var currentVideo: Video? {
        switch self {
        case .playing(let video, _, _), .paused(let video, _, _):
            return video
        default:
            return nil
        }
    }
    
    var hasNext: Bool {
        switch self {
        case .playing(_, let queue, let index), .paused(_, let queue, let index):
            return index < queue.count - 1
        default:
            return false
        }
    }
}
```

### Service Layer

#### SupabaseClient (Actor)

```swift
import Foundation
import Supabase

/// Thread-safe Supabase client for database and storage operations
actor SupabaseClient {
    private let client: SupabaseClient
    
    init(url: URL, anonKey: String) {
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
    }
    
    /// Fetch all active scenarios ordered by order_index
    func fetchScenarios() async throws -> [Scenario] {
        let response: [Scenario] = try await client
            .from("scenarios")
            .select()
            .eq("active", value: true)
            .order("order_index", ascending: true)
            .execute()
            .value
        return response
    }
    
    /// Fetch all active videos for a scenario ordered by order_index
    func fetchVideos(for scenarioId: UUID) async throws -> [Video] {
        let response: [Video] = try await client
            .from("videos")
            .select()
            .eq("scenario_id", value: scenarioId)
            .eq("active", value: true)
            .order("order_index", ascending: true)
            .execute()
            .value
        return response
    }
    
    /// Fetch all active videos grouped by scenario
    func fetchAllVideos() async throws -> [Video] {
        let response: [Video] = try await client
            .from("videos")
            .select()
            .eq("active", value: true)
            .order("scenario_id", ascending: true)
            .order("order_index", ascending: true)
            .execute()
            .value
        return response
    }
    
    /// Get public URL for a video file in storage
    func getVideoURL(path: String) -> URL? {
        client.storage
            .from("videos")
            .getPublicURL(path: path)
    }
}
```

#### VideoService (Actor)

```swift
import Foundation

/// Thread-safe service for video playback coordination
actor VideoService {
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    /// Load scenario with its videos
    func loadScenario(_ scenario: Scenario) async throws -> [Video] {
        try await supabaseClient.fetchVideos(for: scenario.id)
    }
    
    /// Load all scenarios
    func loadScenarios() async throws -> [Scenario] {
        try await supabaseClient.fetchScenarios()
    }
    
    /// Load all videos for library view
    func loadAllVideos() async throws -> [Video] {
        try await supabaseClient.fetchAllVideos()
    }
}
```

### ViewModel Layer

#### MainViewModel

```swift
import Foundation
import Observation

/// Main screen view model managing scenario selection
@Observable
final class MainViewModel: Sendable {
    private(set) var scenarios: [Scenario] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private let videoService: VideoService
    
    init(videoService: VideoService) {
        self.videoService = videoService
    }
    
    @MainActor
    func loadScenarios() async {
        isLoading = true
        errorMessage = nil
        
        do {
            scenarios = try await videoService.loadScenarios()
        } catch {
            errorMessage = "Failed to load scenarios: \(error.localizedDescription)"
            Logger.error("Scenario load failed", error: error)
        }
        
        isLoading = false
    }
    
    @MainActor
    func selectScenario(_ scenario: Scenario) async -> [Video]? {
        do {
            return try await videoService.loadScenario(scenario)
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
            Logger.error("Video load failed", error: error)
            return nil
        }
    }
}
```

#### PlayerViewModel

```swift
import Foundation
import Observation
import AVFoundation

/// Player screen view model managing playback state
@Observable
final class PlayerViewModel: Sendable {
    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    @MainActor
    func startPlayback(videos: [Video]) {
        guard !videos.isEmpty else {
            playbackState = .error(message: "No videos to play")
            return
        }
        
        playbackState = .loading
        playVideo(at: 0, in: videos)
    }
    
    @MainActor
    private func playVideo(at index: Int, in queue: [Video]) {
        guard index < queue.count else {
            playbackState = .idle
            return
        }
        
        let video = queue[index]
        guard let url = video.videoURL else {
            playbackState = .error(message: "Invalid video URL")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe playback completion
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.playNext()
            }
        }
        
        player?.play()
        playbackState = .playing(video: video, queue: queue, currentIndex: index)
    }
    
    @MainActor
    func playNext() {
        guard case .playing(_, let queue, let index) = playbackState else { return }
        let nextIndex = index + 1
        
        if nextIndex < queue.count {
            playVideo(at: nextIndex, in: queue)
        } else {
            playbackState = .idle
        }
    }
    
    @MainActor
    func pause() {
        player?.pause()
        if case .playing(let video, let queue, let index) = playbackState {
            playbackState = .paused(video: video, queue: queue, currentIndex: index)
        }
    }
    
    @MainActor
    func resume() {
        player?.play()
        if case .paused(let video, let queue, let index) = playbackState {
            playbackState = .playing(video: video, queue: queue, currentIndex: index)
        }
    }
    
    @MainActor
    func stop() {
        player?.pause()
        player = nil
        playbackState = .idle
    }
}
```

### UI Components

#### MainScreen

```swift
import SwiftUI

/// Main screen displaying scenario grid
struct MainScreen: View {
    @State private var viewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading scenarios...")
                } else if let error = viewModel.errorMessage {
                    ServiceStateView(
                        icon: "wifi.slash",
                        message: error,
                        action: { Task { await viewModel.loadScenarios() } }
                    )
                } else if viewModel.scenarios.isEmpty {
                    ServiceStateView(
                        icon: "film",
                        message: "No scenarios available",
                        action: nil
                    )
                } else {
                    ScenarioGrid(
                        scenarios: viewModel.scenarios,
                        onSelect: { scenario in
                            Task {
                                if let videos = await viewModel.selectScenario(scenario) {
                                    // Navigate to player
                                }
                            }
                        }
                    )
                }
            }
            .navigationTitle("Meshchersky Park")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LibraryScreen()) {
                        Image(systemName: "square.grid.2x2")
                    }
                }
            }
        }
        .task {
            await viewModel.loadScenarios()
        }
    }
}
```

#### ScenarioCard

```swift
import SwiftUI

/// Card component for scenario display
struct ScenarioCard: View {
    let scenario: Scenario
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Placeholder for scenario thumbnail
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                Text(scenario.title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}
```

#### PlayerScreen

```swift
import SwiftUI
import AVKit

/// Fullscreen video player with tablet controls
struct PlayerScreen: View {
    @State private var viewModel: PlayerViewModel
    let videos: [Video]
    
    var body: some View {
        ZStack {
            // Video player (mirrored to external display)
            if case .playing(let video, _, _) = viewModel.playbackState,
               let url = video.videoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }
            
            // Tablet-only controls overlay
            VStack {
                Spacer()
                
                PlaybackControls(
                    state: viewModel.playbackState,
                    onPlayPause: {
                        if case .playing = viewModel.playbackState {
                            viewModel.pause()
                        } else {
                            viewModel.resume()
                        }
                    },
                    onNext: { viewModel.playNext() },
                    onStop: { viewModel.stop() }
                )
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .task {
            await viewModel.startPlayback(videos: videos)
        }
    }
}
```

## Data Models

### Database Schema

#### Scenarios Table

```sql
CREATE TABLE scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scenarios_active_order ON scenarios(active, order_index);
```

#### Videos Table

```sql
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
    title TEXT,
    storage_path TEXT NOT NULL,
    duration_sec INTEGER,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_videos_scenario_active_order ON videos(scenario_id, active, order_index);
CREATE INDEX idx_videos_active ON videos(active);
```

### Storage Structure

```
supabase-storage/
└── videos/
    ├── family/
    │   ├── family_01.mp4
    │   ├── family_02.mp4
    │   └── ...
    ├── wellness/
    │   ├── wellness_01.mp4
    │   └── ...
    ├── guests/
    ├── investor/
    └── architecture/
```

### Data Relationships

```
Scenario (1) ──< (N) Video
    ↓
  active filter
    ↓
  order_index sort
```

## Error Handling

### Error Categories

1. **Network Errors**: Connection failures, timeouts, API errors
2. **Data Errors**: Missing content, invalid data, parsing failures
3. **Playback Errors**: Video load failures, streaming issues
4. **Mirror Errors**: External display connection issues

### Error Handling Strategy

#### Network Layer

```swift
enum NetworkError: LocalizedError, Sendable {
    case offline
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection. Please check your network."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid server response. Please contact support."
        }
    }
}
```

#### Service Layer Error Handling

```swift
actor VideoService {
    func loadScenarios() async throws -> [Scenario] {
        do {
            return try await supabaseClient.fetchScenarios()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.timeout
        } catch {
            Logger.error("Failed to load scenarios", error: error)
            throw error
        }
    }
}
```

#### UI Layer Error Handling

```swift
@Observable
final class MainViewModel {
    @MainActor
    func loadScenarios() async {
        isLoading = true
        errorMessage = nil
        
        do {
            scenarios = try await videoService.loadScenarios()
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            Logger.error("Unexpected error", error: error)
        }
        
        isLoading = false
    }
}
```

### Playback Error Recovery

```swift
extension PlayerViewModel {
    @MainActor
    func handlePlaybackError(_ error: Error) {
        Logger.error("Playback error", error: error)
        
        // Skip to next video on error
        if case .playing(_, let queue, let index) = playbackState {
            let nextIndex = index + 1
            if nextIndex < queue.count {
                playVideo(at: nextIndex, in: queue)
            } else {
                playbackState = .error(message: "Unable to play video")
            }
        }
    }
}
```

### Logging Strategy

```swift
enum Logger {
    static func error(_ message: String, error: Error? = nil) {
        #if DEBUG
        print("❌ ERROR: \(message)")
        if let error = error {
            print("   Details: \(error)")
        }
        #endif
        // In production: send to analytics/crash reporting
    }
    
    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ INFO: \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ WARNING: \(message)")
        #endif
    }
}
```

## Testing Strategy

### Testing Approach

The Meshchersky Park Showcase App testing strategy combines **unit tests** for business logic and **integration tests** for external dependencies. Property-based testing is **not applicable** for this feature because:

1. **Infrastructure as Code**: Supabase schema and storage configuration are declarative
2. **UI Rendering**: SwiftUI views are best tested with snapshot tests
3. **External Dependencies**: Video playback, network calls, and wireless mirroring require integration testing
4. **Side-Effect Operations**: Video streaming and display mirroring have no pure return values to test

### Unit Testing

**Scope**: Pure business logic, data transformations, state management

**Framework**: XCTest (Swift)

**Test Coverage**:

1. **Model Tests**
   - Scenario/Video Codable conformance
   - PlaybackState transitions
   - Video URL construction

2. **ViewModel Tests**
   - State transitions (idle → loading → playing)
   - Error handling paths
   - Playback queue management

3. **Utility Tests**
   - Logger output formatting
   - Constants validation

**Example Unit Test**:

```swift
import XCTest
@testable import ShowcaseCore

final class PlaybackStateTests: XCTestCase {
    func testPlaybackStateTransitions() {
        let video = Video.mock()
        let queue = [video]
        
        var state = PlaybackState.idle
        XCTAssertNil(state.currentVideo)
        XCTAssertFalse(state.hasNext)
        
        state = .playing(video: video, queue: queue, currentIndex: 0)
        XCTAssertEqual(state.currentVideo?.id, video.id)
        XCTAssertFalse(state.hasNext)
        
        state = .paused(video: video, queue: queue, currentIndex: 0)
        XCTAssertEqual(state.currentVideo?.id, video.id)
    }
    
    func testHasNextWithMultipleVideos() {
        let videos = [Video.mock(), Video.mock(), Video.mock()]
        let state = PlaybackState.playing(video: videos[0], queue: videos, currentIndex: 0)
        
        XCTAssertTrue(state.hasNext)
    }
}
```

### Integration Testing

**Scope**: Supabase API calls, video streaming, external display mirroring

**Framework**: XCTest with async/await

**Test Coverage**:

1. **Supabase Integration**
   - Fetch scenarios from database
   - Fetch videos by scenario
   - Storage URL generation
   - Error handling for network failures

2. **Video Playback Integration**
   - AVPlayer initialization with remote URLs
   - Playback completion notifications
   - Error recovery on stream failure

3. **Wireless Mirroring**
   - AirPlay/Cast connection detection
   - External display availability
   - Fallback behavior when disconnected

**Example Integration Test**:

```swift
import XCTest
@testable import ShowcaseCore

final class SupabaseIntegrationTests: XCTestCase {
    var client: SupabaseClient!
    
    override func setUp() async throws {
        client = SupabaseClient(
            url: URL(string: "https://test.supabase.co")!,
            anonKey: "test-key"
        )
    }
    
    func testFetchScenariosReturnsActiveOnly() async throws {
        let scenarios = try await client.fetchScenarios()
        
        XCTAssertFalse(scenarios.isEmpty)
        XCTAssertTrue(scenarios.allSatisfy { $0.active })
        XCTAssertEqual(scenarios, scenarios.sorted { $0.orderIndex < $1.orderIndex })
    }
    
    func testFetchVideosForScenario() async throws {
        let scenarios = try await client.fetchScenarios()
        guard let firstScenario = scenarios.first else {
            XCTFail("No scenarios available")
            return
        }
        
        let videos = try await client.fetchVideos(for: firstScenario.id)
        
        XCTAssertFalse(videos.isEmpty)
        XCTAssertTrue(videos.allSatisfy { $0.scenarioId == firstScenario.id })
        XCTAssertTrue(videos.allSatisfy { $0.active })
    }
    
    func testOfflineErrorHandling() async {
        // Simulate offline condition
        // Verify NetworkError.offline is thrown
    }
}
```

### UI Testing

**Scope**: User interaction flows, navigation, error states

**Framework**: XCTest UI Testing

**Test Coverage**:

1. **Scenario Selection Flow**
   - Tap scenario card → videos load → player opens
   - Back navigation returns to main screen

2. **Library Navigation**
   - Open library → filter by scenario → tap video → player opens

3. **Error State Display**
   - Offline state shows error message
   - Empty state shows placeholder
   - Retry button triggers reload

4. **Playback Controls**
   - Play/pause button toggles state
   - Next button advances to next video
   - Stop button returns to main screen

### Manual Testing Checklist

**Pre-Release Validation**:

- [ ] iOS/iPadOS TestFlight build installs successfully
- [ ] Android APK sideloads and launches
- [ ] AirPlay connects to external display
- [ ] Cast connects to external display
- [ ] All 5 scenarios load and display correctly
- [ ] Video playback is smooth without buffering (>5 Mbps network)
- [ ] Autoplay advances through video queue
- [ ] Playback controls work on tablet only
- [ ] External display shows fullscreen video without UI
- [ ] Error states display correctly (offline, empty, playback failure)
- [ ] App recovers gracefully from network interruption
- [ ] Liquid Glass design language renders correctly on both platforms

### Test Data

**Mock Data for Testing**:

```swift
extension Scenario {
    static func mock(
        id: UUID = UUID(),
        title: String = "Family Living",
        slug: String = "family",
        orderIndex: Int = 0,
        active: Bool = true
    ) -> Scenario {
        Scenario(
            id: id,
            title: title,
            slug: slug,
            orderIndex: orderIndex,
            active: active
        )
    }
}

extension Video {
    static func mock(
        id: UUID = UUID(),
        scenarioId: UUID = UUID(),
        title: String? = "Sample Video",
        storagePath: String = "family/sample.mp4",
        durationSec: Int? = 30,
        orderIndex: Int = 0,
        active: Bool = true
    ) -> Video {
        Video(
            id: id,
            scenarioId: scenarioId,
            title: title,
            storagePath: storagePath,
            durationSec: durationSec,
            orderIndex: orderIndex,
            active: active,
            createdAt: Date()
        )
    }
}
```

### Continuous Integration

**GitHub Actions Workflow**:

```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  test-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run iOS Tests
        run: |
          xcodebuild test \
            -scheme ShowcaseApp \
            -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)'
  
  test-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Android Tests
        run: |
          ./gradlew test
```

### Performance Testing

**Metrics to Monitor**:

- Video load time: < 2 seconds on stable internet
- Scenario list load time: < 1 second
- Memory usage during playback: < 200 MB
- Frame rate during mirroring: 60 fps
- App launch time: < 3 seconds

**Performance Test Approach**:

1. Use Xcode Instruments to profile memory and CPU usage
2. Test with production-scale content (25 videos)
3. Measure network request latency with Charles Proxy
4. Validate smooth playback on target iPad hardware
5. Test wireless mirroring performance with actual TV displays

---

## Summary

This design document provides a comprehensive technical architecture for the Meshchersky Park Showcase App, translating the 10 requirements into a production-ready implementation plan. The design emphasizes:

1. **Cross-platform native performance** through Swift 6.3 + SKIP transpilation
2. **Type-safe concurrency** with actors and Sendable types
3. **Reactive UI** with @Observable state management
4. **Robust error handling** across network, data, and playback layers
5. **Comprehensive testing** with unit, integration, and UI tests
6. **Production reliability** with logging, monitoring, and graceful degradation

The modular architecture (ShowcaseCore, ShowcaseUI, ShowcaseApp) ensures clean separation of concerns, testability, and maintainability. The Supabase backend provides scalable content delivery with automated backups, while the wireless mirroring architecture enables seamless tablet-to-display presentation.

Next steps: Review this design with stakeholders, then proceed to task breakdown and implementation.
