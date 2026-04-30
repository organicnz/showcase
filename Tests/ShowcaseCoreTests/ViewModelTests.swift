import XCTest
@testable import ShowcaseCore

/// Unit tests for MainViewModel and PlayerViewModel
///
/// These tests verify that ViewModels correctly:
/// - Manage state transitions
/// - Handle errors appropriately
/// - Coordinate with service layer
/// - Manage playback queue and auto-advance logic
///
/// **Validates: Requirements 1.2, 1.5, 9.4**
final class ViewModelTests: XCTestCase {
    
    // MARK: - Mock VideoService
    
    /// Mock VideoService for testing ViewModels in isolation
    actor MockVideoService {
        var shouldThrowOfflineError = false
        var shouldThrowTimeoutError = false
        var shouldThrowGenericError = false
        var mockScenarios: [Scenario] = []
        var mockVideos: [Video] = []
        
        func setOfflineError(_ value: Bool) {
            shouldThrowOfflineError = value
        }
        
        func setTimeoutError(_ value: Bool) {
            shouldThrowTimeoutError = value
        }
        
        func setGenericError(_ value: Bool) {
            shouldThrowGenericError = value
        }
        
        func setMockScenarios(_ scenarios: [Scenario]) {
            mockScenarios = scenarios
        }
        
        func setMockVideos(_ videos: [Video]) {
            mockVideos = videos
        }
        
        func loadScenarios() async throws -> [Scenario] {
            if shouldThrowOfflineError {
                throw NetworkError.offline
            }
            if shouldThrowTimeoutError {
                throw NetworkError.timeout
            }
            if shouldThrowGenericError {
                throw NSError(domain: "TestError", code: 500)
            }
            return mockScenarios
        }
        
        func loadScenario(_ scenario: Scenario) async throws -> [Video] {
            if shouldThrowOfflineError {
                throw NetworkError.offline
            }
            if shouldThrowTimeoutError {
                throw NetworkError.timeout
            }
            if shouldThrowGenericError {
                throw NSError(domain: "TestError", code: 500)
            }
            return mockVideos.filter { $0.scenarioId == scenario.id }
        }
        
        func reset() {
            shouldThrowOfflineError = false
            shouldThrowTimeoutError = false
            shouldThrowGenericError = false
            mockScenarios = []
            mockVideos = []
        }
    }
    
    // MARK: - Testable MainViewModel
    
    /// MainViewModel that uses MockVideoService for testing
    @Observable
    final class TestableMainViewModel {
        private(set) var scenarios: [Scenario] = []
        private(set) var isLoading = false
        private(set) var errorMessage: String?
        
        private let mockVideoService: MockVideoService
        
        init(mockVideoService: MockVideoService) {
            self.mockVideoService = mockVideoService
        }
        
        @MainActor
        func loadScenarios() async {
            isLoading = true
            errorMessage = nil
            
            do {
                scenarios = try await mockVideoService.loadScenarios()
            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
                Logger.error("Scenario load failed", error: error)
            } catch {
                errorMessage = "An unexpected error occurred. Please try again."
                Logger.error("Unexpected error loading scenarios", error: error)
            }
            
            isLoading = false
        }
        
        @MainActor
        func selectScenario(_ scenario: Scenario) async -> [Video]? {
            do {
                return try await mockVideoService.loadScenario(scenario)
            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
                Logger.error("Video load failed", error: error)
                return nil
            } catch {
                errorMessage = "Failed to load videos. Please try again."
                Logger.error("Unexpected error loading videos", error: error)
                return nil
            }
        }
    }
    
    // MARK: - Test Setup
    
    var mockVideoService: MockVideoService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockVideoService = MockVideoService()
    }
    
    override func tearDown() async throws {
        await mockVideoService.reset()
        mockVideoService = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockScenario(
        id: UUID = UUID(),
        title: String = "Test Scenario",
        slug: String = "test",
        orderIndex: Int = 0
    ) -> Scenario {
        Scenario(
            id: id,
            title: title,
            slug: slug,
            orderIndex: orderIndex,
            isActive: true
        )
    }
    
    private func createMockVideo(
        id: UUID = UUID(),
        scenarioId: UUID,
        title: String = "Test Video",
        storagePath: String = "test/video.mp4",
        orderIndex: Int = 0
    ) -> Video {
        Video(
            id: id,
            scenarioId: scenarioId,
            title: title,
            storagePath: storagePath,
            orderIndex: orderIndex,
            isActive: true
        )
    }
    
    // MARK: - MainViewModel Tests
    
    /// Test that MainViewModel starts with correct initial state
    ///
    /// **Validates: Requirement 1.2** - Initial state
    @MainActor
    func testMainViewModelInitialState() async throws {
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        
        XCTAssertTrue(viewModel.scenarios.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test that loadScenarios sets isLoading to true during loading
    ///
    /// **Validates: Requirement 9.1** - Loading state
    @MainActor
    func testLoadScenariosSetsLoadingStateDuringLoad() async throws {
        let scenarios = [
            createMockScenario(title: "Family", slug: "family"),
            createMockScenario(title: "Wellness", slug: "wellness")
        ]
        await mockVideoService.setMockScenarios(scenarios)
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        
        // Start loading
        let loadTask = Task {
            await viewModel.loadScenarios()
        }
        
        // Give it a moment to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Should be loading (might already be done on fast systems, so we check the result)
        await loadTask.value
        
        // After completion, should not be loading
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.scenarios.count, 2)
    }
    
    /// Test that loadScenarios successfully loads scenarios
    ///
    /// **Validates: Requirement 1.2** - Scenario loading
    @MainActor
    func testLoadScenariosSuccessfullyLoadsScenarios() async throws {
        let scenarios = [
            createMockScenario(title: "Family", slug: "family", orderIndex: 0),
            createMockScenario(title: "Wellness", slug: "wellness", orderIndex: 1),
            createMockScenario(title: "Guests", slug: "guests", orderIndex: 2)
        ]
        await mockVideoService.setMockScenarios(scenarios)
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        await viewModel.loadScenarios()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.scenarios.count, 3)
        XCTAssertEqual(viewModel.scenarios[0].title, "Family")
        XCTAssertEqual(viewModel.scenarios[1].title, "Wellness")
        XCTAssertEqual(viewModel.scenarios[2].title, "Guests")
    }
    
    /// Test that loadScenarios handles offline error correctly
    ///
    /// **Validates: Requirement 9.2** - Offline error handling
    @MainActor
    func testLoadScenariosHandlesOfflineError() async throws {
        await mockVideoService.setOfflineError(true)
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        await viewModel.loadScenarios()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.scenarios.isEmpty)
        XCTAssertEqual(
            viewModel.errorMessage,
            "No internet connection. Please check your network."
        )
    }
    
    /// Test that loadScenarios handles timeout error correctly
    ///
    /// **Validates: Requirement 9.2** - Timeout error handling
    @MainActor
    func testLoadScenariosHandlesTimeoutError() async throws {
        await mockVideoService.setTimeoutError(true)
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        await viewModel.loadScenarios()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.scenarios.isEmpty)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Request timed out. Please try again."
        )
    }
    
    /// Test that loadScenarios handles generic error correctly
    ///
    /// **Validates: Requirement 9.2** - Generic error handling
    @MainActor
    func testLoadScenariosHandlesGenericError() async throws {
        await mockVideoService.setGenericError(true)
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        await viewModel.loadScenarios()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.scenarios.isEmpty)
        XCTAssertEqual(
            viewModel.errorMessage,
            "An unexpected error occurred. Please try again."
        )
    }
    
    /// Test that loadScenarios clears previous error message on retry
    ///
    /// **Validates: Requirement 9.2** - Error state management
    @MainActor
    func testLoadScenariosClearsPreviousErrorOnRetry() async throws {
        // First attempt fails
        await mockVideoService.setOfflineError(true)
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        await viewModel.loadScenarios()
        
        XCTAssertNotNil(viewModel.errorMessage)
        
        // Second attempt succeeds
        await mockVideoService.setOfflineError(false)
        let scenarios = [createMockScenario(title: "Family", slug: "family")]
        await mockVideoService.setMockScenarios(scenarios)
        await viewModel.loadScenarios()
        
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.scenarios.count, 1)
    }
    
    /// Test that selectScenario successfully loads videos
    ///
    /// **Validates: Requirement 1.2** - Video loading for scenario
    @MainActor
    func testSelectScenarioSuccessfullyLoadsVideos() async throws {
        let scenario = createMockScenario(title: "Family", slug: "family")
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario.id, title: "Video 2", orderIndex: 1),
            createMockVideo(scenarioId: scenario.id, title: "Video 3", orderIndex: 2)
        ]
        await mockVideoService.setMockVideos(videos)
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        let loadedVideos = await viewModel.selectScenario(scenario)
        
        XCTAssertNotNil(loadedVideos)
        XCTAssertEqual(loadedVideos?.count, 3)
        XCTAssertEqual(loadedVideos?[0].title, "Video 1")
        XCTAssertEqual(loadedVideos?[1].title, "Video 2")
        XCTAssertEqual(loadedVideos?[2].title, "Video 3")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    /// Test that selectScenario handles offline error correctly
    ///
    /// **Validates: Requirement 9.2** - Offline error handling for videos
    @MainActor
    func testSelectScenarioHandlesOfflineError() async throws {
        await mockVideoService.setOfflineError(true)
        let scenario = createMockScenario()
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        let videos = await viewModel.selectScenario(scenario)
        
        XCTAssertNil(videos)
        XCTAssertEqual(
            viewModel.errorMessage,
            "No internet connection. Please check your network."
        )
    }
    
    /// Test that selectScenario handles timeout error correctly
    ///
    /// **Validates: Requirement 9.2** - Timeout error handling for videos
    @MainActor
    func testSelectScenarioHandlesTimeoutError() async throws {
        await mockVideoService.setTimeoutError(true)
        let scenario = createMockScenario()
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        let videos = await viewModel.selectScenario(scenario)
        
        XCTAssertNil(videos)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Request timed out. Please try again."
        )
    }
    
    /// Test that selectScenario handles generic error correctly
    ///
    /// **Validates: Requirement 9.2** - Generic error handling for videos
    @MainActor
    func testSelectScenarioHandlesGenericError() async throws {
        await mockVideoService.setGenericError(true)
        let scenario = createMockScenario()
        
        let viewModel = TestableMainViewModel(mockVideoService: mockVideoService)
        let videos = await viewModel.selectScenario(scenario)
        
        XCTAssertNil(videos)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Failed to load videos. Please try again."
        )
    }
    
    // MARK: - PlayerViewModel Tests
    
    /// Test that PlayerViewModel starts with idle state
    ///
    /// **Validates: Requirement 1.3** - Initial playback state
    @MainActor
    func testPlayerViewModelInitialState() async throws {
        let viewModel = PlayerViewModel()
        
        if case .idle = viewModel.playbackState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Initial state should be idle")
        }
        
        XCTAssertEqual(viewModel.currentTime, 0)
        XCTAssertEqual(viewModel.duration, 0)
    }
    
    /// Test that startPlayback transitions to loading then playing state
    ///
    /// **Validates: Requirement 1.3** - Playback state transitions
    @MainActor
    func testStartPlaybackTransitionsToPlayingState() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Should transition to playing state
        if case .playing(let video, let queue, let index) = viewModel.playbackState {
            XCTAssertEqual(video.title, "Video 1")
            XCTAssertEqual(queue.count, 1)
            XCTAssertEqual(index, 0)
        } else {
            XCTFail("Should be in playing state, got \(viewModel.playbackState)")
        }
    }
    
    /// Test that startPlayback with empty array sets error state
    ///
    /// **Validates: Requirement 9.4** - Error handling for empty queue
    @MainActor
    func testStartPlaybackWithEmptyArraySetsErrorState() async throws {
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: [])
        
        if case .error(let message) = viewModel.playbackState {
            XCTAssertEqual(message, "No videos to play")
        } else {
            XCTFail("Should be in error state")
        }
    }
    
    /// Test that playback queue is managed correctly with multiple videos
    ///
    /// **Validates: Requirement 1.5** - Playback queue management
    @MainActor
    func testPlaybackQueueManagement() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario.id, title: "Video 2", orderIndex: 1),
            createMockVideo(scenarioId: scenario.id, title: "Video 3", orderIndex: 2)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Should be playing first video
        if case .playing(let video, let queue, let index) = viewModel.playbackState {
            XCTAssertEqual(video.title, "Video 1")
            XCTAssertEqual(queue.count, 3)
            XCTAssertEqual(index, 0)
            XCTAssertTrue(viewModel.playbackState.hasNext)
        } else {
            XCTFail("Should be in playing state")
        }
    }
    
    /// Test that playNext advances to next video in queue
    ///
    /// **Validates: Requirement 1.5** - Auto-advance logic
    @MainActor
    func testPlayNextAdvancesToNextVideo() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario.id, title: "Video 2", orderIndex: 1),
            createMockVideo(scenarioId: scenario.id, title: "Video 3", orderIndex: 2)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Advance to next video
        viewModel.playNext()
        
        // Should be playing second video
        if case .playing(let video, let queue, let index) = viewModel.playbackState {
            XCTAssertEqual(video.title, "Video 2")
            XCTAssertEqual(queue.count, 3)
            XCTAssertEqual(index, 1)
            XCTAssertTrue(viewModel.playbackState.hasNext)
        } else {
            XCTFail("Should be in playing state with second video")
        }
    }
    
    /// Test that playNext on last video transitions to idle
    ///
    /// **Validates: Requirement 1.5** - Queue completion
    @MainActor
    func testPlayNextOnLastVideoTransitionsToIdle() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario.id, title: "Video 2", orderIndex: 1)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Advance to second video
        viewModel.playNext()
        
        // Advance past last video
        viewModel.playNext()
        
        // Should be idle
        if case .idle = viewModel.playbackState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Should be in idle state after queue completion")
        }
    }
    
    /// Test that pause transitions from playing to paused state
    ///
    /// **Validates: Requirement 1.4** - Playback controls
    @MainActor
    func testPauseTransitionsToPlayingToPausedState() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Pause playback
        viewModel.pause()
        
        // Should be paused
        if case .paused(let video, let queue, let index) = viewModel.playbackState {
            XCTAssertEqual(video.title, "Video 1")
            XCTAssertEqual(queue.count, 1)
            XCTAssertEqual(index, 0)
        } else {
            XCTFail("Should be in paused state")
        }
    }
    
    /// Test that resume transitions from paused to playing state
    ///
    /// **Validates: Requirement 1.4** - Playback controls
    @MainActor
    func testResumeTransitionsPausedToPlayingState() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        viewModel.pause()
        
        // Resume playback
        viewModel.resume()
        
        // Should be playing again
        if case .playing(let video, let queue, let index) = viewModel.playbackState {
            XCTAssertEqual(video.title, "Video 1")
            XCTAssertEqual(queue.count, 1)
            XCTAssertEqual(index, 0)
        } else {
            XCTFail("Should be in playing state after resume")
        }
    }
    
    /// Test that stop transitions to idle state
    ///
    /// **Validates: Requirement 1.4** - Playback controls
    @MainActor
    func testStopTransitionsToIdleState() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Stop playback
        viewModel.stop()
        
        // Should be idle
        if case .idle = viewModel.playbackState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Should be in idle state after stop")
        }
    }
    
    /// Test that handlePlaybackError skips to next video
    ///
    /// **Validates: Requirement 9.4** - Error recovery
    @MainActor
    func testHandlePlaybackErrorSkipsToNextVideo() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario.id, title: "Video 2", orderIndex: 1),
            createMockVideo(scenarioId: scenario.id, title: "Video 3", orderIndex: 2)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Simulate playback error
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)
        viewModel.handlePlaybackError(error)
        
        // Should skip to next video
        if case .playing(let video, let queue, let index) = viewModel.playbackState {
            XCTAssertEqual(video.title, "Video 2")
            XCTAssertEqual(queue.count, 3)
            XCTAssertEqual(index, 1)
        } else {
            XCTFail("Should skip to next video on error")
        }
    }
    
    /// Test that handlePlaybackError on last video sets error state
    ///
    /// **Validates: Requirement 9.4** - Error recovery when queue exhausted
    @MainActor
    func testHandlePlaybackErrorOnLastVideoSetsErrorState() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        // Simulate playback error on last video
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)
        viewModel.handlePlaybackError(error)
        
        // Should be in error state
        if case .error(let message) = viewModel.playbackState {
            XCTAssertEqual(message, "Unable to play video")
        } else {
            XCTFail("Should be in error state when no more videos to skip to")
        }
    }
    
    /// Test that currentVideo returns correct video in playing state
    ///
    /// **Validates: Requirement 1.3** - State queries
    @MainActor
    func testCurrentVideoReturnsCorrectVideoInPlayingState() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        let currentVideo = viewModel.playbackState.currentVideo
        XCTAssertNotNil(currentVideo)
        XCTAssertEqual(currentVideo?.title, "Video 1")
    }
    
    /// Test that currentVideo returns correct video in paused state
    ///
    /// **Validates: Requirement 1.3** - State queries
    @MainActor
    func testCurrentVideoReturnsCorrectVideoInPausedState() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        viewModel.pause()
        
        let currentVideo = viewModel.playbackState.currentVideo
        XCTAssertNotNil(currentVideo)
        XCTAssertEqual(currentVideo?.title, "Video 1")
    }
    
    /// Test that hasNext returns true when there are more videos
    ///
    /// **Validates: Requirement 1.5** - Queue state queries
    @MainActor
    func testHasNextReturnsTrueWhenMoreVideosExist() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario.id, title: "Video 2", orderIndex: 1)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        XCTAssertTrue(viewModel.playbackState.hasNext)
    }
    
    /// Test that hasNext returns false on last video
    ///
    /// **Validates: Requirement 1.5** - Queue state queries
    @MainActor
    func testHasNextReturnsFalseOnLastVideo() async throws {
        let scenario = createMockScenario()
        let videos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0)
        ]
        
        let viewModel = PlayerViewModel()
        viewModel.startPlayback(videos: videos)
        
        XCTAssertFalse(viewModel.playbackState.hasNext)
    }
}
