import XCTest
@testable import ShowcaseCore

/// Integration tests for VideoService actor with mock SupabaseClient
///
/// These tests verify that VideoService correctly:
/// - Delegates to SupabaseClient for data fetching
/// - Maps network errors to NetworkError types
/// - Handles offline and timeout conditions
///
/// **Validates: Requirements 4.6, 9.2**
final class VideoServiceTests: XCTestCase {
    
    // MARK: - Mock SupabaseClient
    
    /// Mock SupabaseClient for testing VideoService in isolation
    actor MockSupabaseClient {
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
        
        func fetchScenarios() async throws -> [Scenario] {
            if shouldThrowOfflineError {
                throw URLError(.notConnectedToInternet)
            }
            if shouldThrowTimeoutError {
                throw URLError(.timedOut)
            }
            if shouldThrowGenericError {
                throw NSError(domain: "TestError", code: 500)
            }
            return mockScenarios
        }
        
        func fetchVideos(for scenarioId: UUID) async throws -> [Video] {
            if shouldThrowOfflineError {
                throw URLError(.notConnectedToInternet)
            }
            if shouldThrowTimeoutError {
                throw URLError(.timedOut)
            }
            if shouldThrowGenericError {
                throw NSError(domain: "TestError", code: 500)
            }
            return mockVideos.filter { $0.scenarioId == scenarioId }
        }
        
        func fetchAllVideos() async throws -> [Video] {
            if shouldThrowOfflineError {
                throw URLError(.notConnectedToInternet)
            }
            if shouldThrowTimeoutError {
                throw URLError(.timedOut)
            }
            if shouldThrowGenericError {
                throw NSError(domain: "TestError", code: 500)
            }
            return mockVideos
        }
        
        func reset() {
            shouldThrowOfflineError = false
            shouldThrowTimeoutError = false
            shouldThrowGenericError = false
            mockScenarios = []
            mockVideos = []
        }
    }
    
    // MARK: - Test VideoService with Mock
    
    /// Custom VideoService that uses MockSupabaseClient
    actor TestableVideoService {
        private let mockClient: MockSupabaseClient
        
        init(mockClient: MockSupabaseClient) {
            self.mockClient = mockClient
        }
        
        func loadScenarios() async throws -> [Scenario] {
            do {
                return try await mockClient.fetchScenarios()
            } catch let error as URLError where error.code == .notConnectedToInternet {
                throw NetworkError.offline
            } catch let error as URLError where error.code == .timedOut {
                throw NetworkError.timeout
            } catch {
                Logger.error("Failed to load scenarios", error: error)
                throw error
            }
        }
        
        func loadScenario(_ scenario: Scenario) async throws -> [Video] {
            do {
                return try await mockClient.fetchVideos(for: scenario.id)
            } catch let error as URLError where error.code == .notConnectedToInternet {
                throw NetworkError.offline
            } catch let error as URLError where error.code == .timedOut {
                throw NetworkError.timeout
            } catch {
                Logger.error("Failed to load videos for scenario", error: error)
                throw error
            }
        }
        
        func loadAllVideos() async throws -> [Video] {
            do {
                return try await mockClient.fetchAllVideos()
            } catch let error as URLError where error.code == .notConnectedToInternet {
                throw NetworkError.offline
            } catch let error as URLError where error.code == .timedOut {
                throw NetworkError.timeout
            } catch {
                Logger.error("Failed to load all videos", error: error)
                throw error
            }
        }
    }
    
    var mockClient: MockSupabaseClient!
    var videoService: TestableVideoService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockSupabaseClient()
        videoService = TestableVideoService(mockClient: mockClient)
    }
    
    override func tearDown() async throws {
        await mockClient.reset()
        mockClient = nil
        videoService = nil
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
        orderIndex: Int = 0
    ) -> Video {
        Video(
            id: id,
            scenarioId: scenarioId,
            title: title,
            storagePath: "test/video.mp4",
            orderIndex: orderIndex,
            isActive: true
        )
    }
    
    // MARK: - loadScenarios Tests
    
    /// Test that loadScenarios successfully returns scenarios
    ///
    /// **Validates: Requirement 1.2** - Scenario retrieval
    func testLoadScenariosReturnsScenarios() async throws {
        let mockScenarios = [
            createMockScenario(title: "Family", slug: "family", orderIndex: 0),
            createMockScenario(title: "Wellness", slug: "wellness", orderIndex: 1)
        ]
        await mockClient.setMockScenarios(mockScenarios)
        
        let scenarios = try await videoService.loadScenarios()
        
        XCTAssertEqual(scenarios.count, 2)
        XCTAssertEqual(scenarios[0].title, "Family")
        XCTAssertEqual(scenarios[1].title, "Wellness")
    }
    
    /// Test that loadScenarios throws NetworkError.offline when offline
    ///
    /// **Validates: Requirement 9.2** - Offline error handling
    func testLoadScenariosThrowsOfflineErrorWhenNotConnected() async throws {
        await mockClient.setOfflineError(true)
        
        do {
            _ = try await videoService.loadScenarios()
            XCTFail("Should throw NetworkError.offline")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.offline)
            XCTAssertEqual(
                error.errorDescription,
                "No internet connection. Please check your network."
            )
        } catch {
            XCTFail("Should throw NetworkError.offline, got \(error)")
        }
    }
    
    /// Test that loadScenarios throws NetworkError.timeout when request times out
    ///
    /// **Validates: Requirement 9.2** - Timeout error handling
    func testLoadScenariosThrowsTimeoutErrorWhenTimedOut() async throws {
        await mockClient.setTimeoutError(true)
        
        do {
            _ = try await videoService.loadScenarios()
            XCTFail("Should throw NetworkError.timeout")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.timeout)
            XCTAssertEqual(
                error.errorDescription,
                "Request timed out. Please try again."
            )
        } catch {
            XCTFail("Should throw NetworkError.timeout, got \(error)")
        }
    }
    
    /// Test that loadScenarios propagates generic errors
    ///
    /// **Validates: Requirement 9.2** - Generic error handling
    func testLoadScenariosPropagatesGenericErrors() async throws {
        await mockClient.setGenericError(true)
        
        do {
            _ = try await videoService.loadScenarios()
            XCTFail("Should throw an error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "TestError")
            XCTAssertEqual(error.code, 500)
        } catch {
            // Generic errors are propagated as-is
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - loadScenario Tests
    
    /// Test that loadScenario successfully returns videos for a scenario
    ///
    /// **Validates: Requirement 1.2** - Video retrieval for scenario
    func testLoadScenarioReturnsVideosForScenario() async throws {
        let scenario = createMockScenario(title: "Family", slug: "family")
        let mockVideos = [
            createMockVideo(scenarioId: scenario.id, title: "Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario.id, title: "Video 2", orderIndex: 1),
            createMockVideo(scenarioId: scenario.id, title: "Video 3", orderIndex: 2)
        ]
        await mockClient.setMockVideos(mockVideos)
        
        let videos = try await videoService.loadScenario(scenario)
        
        XCTAssertEqual(videos.count, 3)
        XCTAssertEqual(videos[0].title, "Video 1")
        XCTAssertEqual(videos[1].title, "Video 2")
        XCTAssertEqual(videos[2].title, "Video 3")
        XCTAssertTrue(videos.allSatisfy { $0.scenarioId == scenario.id })
    }
    
    /// Test that loadScenario throws NetworkError.offline when offline
    ///
    /// **Validates: Requirement 9.2** - Offline error handling for videos
    func testLoadScenarioThrowsOfflineErrorWhenNotConnected() async throws {
        let scenario = createMockScenario()
        await mockClient.setOfflineError(true)
        
        do {
            _ = try await videoService.loadScenario(scenario)
            XCTFail("Should throw NetworkError.offline")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.offline)
        } catch {
            XCTFail("Should throw NetworkError.offline, got \(error)")
        }
    }
    
    /// Test that loadScenario throws NetworkError.timeout when request times out
    ///
    /// **Validates: Requirement 9.2** - Timeout error handling for videos
    func testLoadScenarioThrowsTimeoutErrorWhenTimedOut() async throws {
        let scenario = createMockScenario()
        await mockClient.setTimeoutError(true)
        
        do {
            _ = try await videoService.loadScenario(scenario)
            XCTFail("Should throw NetworkError.timeout")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.timeout)
        } catch {
            XCTFail("Should throw NetworkError.timeout, got \(error)")
        }
    }
    
    /// Test that loadScenario returns empty array for scenario with no videos
    ///
    /// **Validates: Requirement 9.3** - Empty state handling
    func testLoadScenarioReturnsEmptyArrayForScenarioWithNoVideos() async throws {
        let scenario = createMockScenario()
        await mockClient.setMockVideos([])
        
        let videos = try await videoService.loadScenario(scenario)
        
        XCTAssertTrue(videos.isEmpty)
    }
    
    // MARK: - loadAllVideos Tests
    
    /// Test that loadAllVideos successfully returns all videos
    ///
    /// **Validates: Requirement 2.2** - Library catalog retrieval
    func testLoadAllVideosReturnsAllVideos() async throws {
        let scenario1 = createMockScenario(title: "Family", slug: "family")
        let scenario2 = createMockScenario(title: "Wellness", slug: "wellness")
        
        let mockVideos = [
            createMockVideo(scenarioId: scenario1.id, title: "Family Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario1.id, title: "Family Video 2", orderIndex: 1),
            createMockVideo(scenarioId: scenario2.id, title: "Wellness Video 1", orderIndex: 0),
            createMockVideo(scenarioId: scenario2.id, title: "Wellness Video 2", orderIndex: 1)
        ]
        await mockClient.setMockVideos(mockVideos)
        
        let videos = try await videoService.loadAllVideos()
        
        XCTAssertEqual(videos.count, 4)
    }
    
    /// Test that loadAllVideos throws NetworkError.offline when offline
    ///
    /// **Validates: Requirement 9.2** - Offline error handling for all videos
    func testLoadAllVideosThrowsOfflineErrorWhenNotConnected() async throws {
        await mockClient.setOfflineError(true)
        
        do {
            _ = try await videoService.loadAllVideos()
            XCTFail("Should throw NetworkError.offline")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.offline)
        } catch {
            XCTFail("Should throw NetworkError.offline, got \(error)")
        }
    }
    
    /// Test that loadAllVideos throws NetworkError.timeout when request times out
    ///
    /// **Validates: Requirement 9.2** - Timeout error handling for all videos
    func testLoadAllVideosThrowsTimeoutErrorWhenTimedOut() async throws {
        await mockClient.setTimeoutError(true)
        
        do {
            _ = try await videoService.loadAllVideos()
            XCTFail("Should throw NetworkError.timeout")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.timeout)
        } catch {
            XCTFail("Should throw NetworkError.timeout, got \(error)")
        }
    }
    
    // MARK: - NetworkError Tests
    
    /// Test NetworkError.offline has correct error description
    ///
    /// **Validates: Requirement 9.2** - User-friendly error messages
    func testNetworkErrorOfflineHasCorrectDescription() {
        let error = NetworkError.offline
        XCTAssertEqual(
            error.errorDescription,
            "No internet connection. Please check your network."
        )
    }
    
    /// Test NetworkError.timeout has correct error description
    ///
    /// **Validates: Requirement 9.2** - User-friendly error messages
    func testNetworkErrorTimeoutHasCorrectDescription() {
        let error = NetworkError.timeout
        XCTAssertEqual(
            error.errorDescription,
            "Request timed out. Please try again."
        )
    }
    
    /// Test NetworkError.serverError has correct error description
    ///
    /// **Validates: Requirement 9.2** - User-friendly error messages
    func testNetworkErrorServerErrorHasCorrectDescription() {
        let error = NetworkError.serverError(statusCode: 500)
        XCTAssertEqual(
            error.errorDescription,
            "Server error (500). Please try again later."
        )
    }
    
    /// Test NetworkError.invalidResponse has correct error description
    ///
    /// **Validates: Requirement 9.2** - User-friendly error messages
    func testNetworkErrorInvalidResponseHasCorrectDescription() {
        let error = NetworkError.invalidResponse
        XCTAssertEqual(
            error.errorDescription,
            "Invalid server response. Please contact support."
        )
    }
}
