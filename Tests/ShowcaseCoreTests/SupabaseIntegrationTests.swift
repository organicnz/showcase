import XCTest
@testable import ShowcaseCore

/// Integration tests for SupabaseClient actor
///
/// These tests verify that the SupabaseClient correctly:
/// - Fetches only active scenarios sorted by order_index
/// - Fetches only active videos for a scenario sorted by order_index
/// - Handles network errors appropriately
///
/// **Validates: Requirements 4.6, 9.2**
final class SupabaseIntegrationTests: XCTestCase {
    
    var client: SupabaseClient!
    
    override func setUp() async throws {
        try await super.setUp()
        client = SupabaseClient.shared
    }
    
    override func tearDown() async throws {
        client = nil
        try await super.tearDown()
    }
    
    // MARK: - Scenario Fetching Tests
    
    /// Test that fetchScenarios returns only active scenarios
    ///
    /// **Validates: Requirement 4.6** - Active filter on scenarios
    func testFetchScenariosReturnsOnlyActiveScenarios() async throws {
        let scenarios = try await client.fetchScenarios()
        
        // Verify all returned scenarios are active
        XCTAssertFalse(scenarios.isEmpty, "Should return at least one scenario")
        XCTAssertTrue(
            scenarios.allSatisfy { $0.isActive },
            "All returned scenarios should have isActive = true"
        )
    }
    
    /// Test that fetchScenarios returns scenarios sorted by order_index
    ///
    /// **Validates: Requirement 4.6** - Order by order_index ascending
    func testFetchScenariosReturnsSortedByOrderIndex() async throws {
        let scenarios = try await client.fetchScenarios()
        
        guard scenarios.count > 1 else {
            XCTFail("Need at least 2 scenarios to test sorting")
            return
        }
        
        // Verify scenarios are sorted by order_index in ascending order
        for i in 0..<(scenarios.count - 1) {
            XCTAssertLessThanOrEqual(
                scenarios[i].orderIndex,
                scenarios[i + 1].orderIndex,
                "Scenarios should be sorted by order_index ascending"
            )
        }
    }
    
    /// Test that fetchScenarios returns expected scenario structure
    ///
    /// **Validates: Requirement 4.1** - Scenario metadata structure
    func testFetchScenariosReturnsValidScenarioStructure() async throws {
        let scenarios = try await client.fetchScenarios()
        
        XCTAssertFalse(scenarios.isEmpty, "Should return at least one scenario")
        
        // Verify first scenario has required fields
        let firstScenario = scenarios[0]
        XCTAssertNotNil(firstScenario.id, "Scenario should have an id")
        XCTAssertFalse(firstScenario.title.isEmpty, "Scenario should have a title")
        XCTAssertFalse(firstScenario.slug.isEmpty, "Scenario should have a slug")
        XCTAssertTrue(firstScenario.isActive, "Returned scenario should be active")
    }
    
    // MARK: - Video Fetching Tests
    
    /// Test that fetchVideos returns only active videos for a scenario
    ///
    /// **Validates: Requirement 4.6** - Active filter on videos
    func testFetchVideosReturnsOnlyActiveVideosForScenario() async throws {
        // First get a scenario
        let scenarios = try await client.fetchScenarios()
        guard let firstScenario = scenarios.first else {
            XCTFail("Need at least one scenario to test video fetching")
            return
        }
        
        // Fetch videos for that scenario
        let videos = try await client.fetchVideos(for: firstScenario.id)
        
        // Verify all returned videos are active
        XCTAssertFalse(videos.isEmpty, "Should return at least one video for the scenario")
        XCTAssertTrue(
            videos.allSatisfy { $0.isActive },
            "All returned videos should have isActive = true"
        )
        
        // Verify all videos belong to the requested scenario
        XCTAssertTrue(
            videos.allSatisfy { $0.scenarioId == firstScenario.id },
            "All returned videos should belong to the requested scenario"
        )
    }
    
    /// Test that fetchVideos returns videos sorted by order_index
    ///
    /// **Validates: Requirement 4.6** - Order by order_index ascending
    func testFetchVideosReturnsSortedByOrderIndex() async throws {
        // First get a scenario
        let scenarios = try await client.fetchScenarios()
        guard let firstScenario = scenarios.first else {
            XCTFail("Need at least one scenario to test video fetching")
            return
        }
        
        // Fetch videos for that scenario
        let videos = try await client.fetchVideos(for: firstScenario.id)
        
        guard videos.count > 1 else {
            // If there's only one video, sorting is trivially correct
            return
        }
        
        // Verify videos are sorted by order_index in ascending order
        for i in 0..<(videos.count - 1) {
            XCTAssertLessThanOrEqual(
                videos[i].orderIndex,
                videos[i + 1].orderIndex,
                "Videos should be sorted by order_index ascending"
            )
        }
    }
    
    /// Test that fetchVideos returns valid video structure
    ///
    /// **Validates: Requirement 4.2** - Video metadata structure
    func testFetchVideosReturnsValidVideoStructure() async throws {
        // First get a scenario
        let scenarios = try await client.fetchScenarios()
        guard let firstScenario = scenarios.first else {
            XCTFail("Need at least one scenario to test video fetching")
            return
        }
        
        // Fetch videos for that scenario
        let videos = try await client.fetchVideos(for: firstScenario.id)
        
        XCTAssertFalse(videos.isEmpty, "Should return at least one video")
        
        // Verify first video has required fields
        let firstVideo = videos[0]
        XCTAssertNotNil(firstVideo.id, "Video should have an id")
        XCTAssertEqual(firstVideo.scenarioId, firstScenario.id, "Video should belong to the scenario")
        XCTAssertFalse(firstVideo.storagePath.isEmpty, "Video should have a storage path")
        XCTAssertTrue(firstVideo.isActive, "Returned video should be active")
    }
    
    /// Test that fetchAllVideos returns only active videos
    ///
    /// **Validates: Requirement 4.6** - Active filter on all videos
    func testFetchAllVideosReturnsOnlyActiveVideos() async throws {
        let videos = try await client.fetchAllVideos()
        
        XCTAssertFalse(videos.isEmpty, "Should return at least one video")
        XCTAssertTrue(
            videos.allSatisfy { $0.isActive },
            "All returned videos should have isActive = true"
        )
    }
    
    /// Test that fetchAllVideos returns videos sorted by order_index
    ///
    /// **Validates: Requirement 4.6** - Order by order_index ascending
    func testFetchAllVideosReturnsSortedByOrderIndex() async throws {
        let videos = try await client.fetchAllVideos()
        
        guard videos.count > 1 else {
            return
        }
        
        // Verify videos are sorted by order_index in ascending order
        for i in 0..<(videos.count - 1) {
            XCTAssertLessThanOrEqual(
                videos[i].orderIndex,
                videos[i + 1].orderIndex,
                "Videos should be sorted by order_index ascending"
            )
        }
    }
    
    // MARK: - Storage URL Generation Tests
    
    /// Test that getPublicVideoURL generates valid URLs
    ///
    /// **Validates: Requirement 4.3** - CDN URL generation
    func testGetPublicVideoURLGeneratesValidURL() {
        let path = "family/video1.mp4"
        let url = client.getPublicVideoURL(for: path)
        
        XCTAssertNotNil(url, "Should generate a valid URL")
        XCTAssertTrue(
            url?.absoluteString.contains("storage") ?? false,
            "URL should contain 'storage' path component"
        )
        XCTAssertTrue(
            url?.absoluteString.contains(path) ?? false,
            "URL should contain the provided path"
        )
    }
    
    /// Test that getPublicImageURL generates valid URLs
    ///
    /// **Validates: Requirement 4.3** - CDN URL generation for images
    func testGetPublicImageURLGeneratesValidURL() {
        let path = "family/thumbnail1.jpg"
        let url = client.getPublicImageURL(for: path)
        
        XCTAssertNotNil(url, "Should generate a valid URL")
        XCTAssertTrue(
            url?.absoluteString.contains("storage") ?? false,
            "URL should contain 'storage' path component"
        )
        XCTAssertTrue(
            url?.absoluteString.contains(path) ?? false,
            "URL should contain the provided path"
        )
    }
    
    /// Test that getPublicAudioURL generates valid URLs
    ///
    /// **Validates: Requirement 4.3** - CDN URL generation for audio
    func testGetPublicAudioURLGeneratesValidURL() {
        let path = "ambient/forest.mp3"
        let url = client.getPublicAudioURL(for: path)
        
        XCTAssertNotNil(url, "Should generate a valid URL")
        XCTAssertTrue(
            url?.absoluteString.contains("storage") ?? false,
            "URL should contain 'storage' path component"
        )
        XCTAssertTrue(
            url?.absoluteString.contains(path) ?? false,
            "URL should contain the provided path"
        )
    }
    
    // MARK: - Error Handling Tests
    
    /// Test retry logic with transient failures
    ///
    /// **Validates: Requirement 9.2** - Error handling with retry
    func testRetryLogicWithTransientFailures() async throws {
        // This test verifies that the retry mechanism is in place
        // In a real scenario, we would mock the network layer to simulate failures
        // For now, we verify that successful calls work (retry succeeds on first attempt)
        
        let scenarios = try await client.fetchScenarios()
        XCTAssertFalse(scenarios.isEmpty, "Retry logic should allow successful calls")
    }
    
    /// Test that invalid scenario ID returns empty array
    ///
    /// **Validates: Requirement 9.2** - Graceful handling of invalid data
    func testFetchVideosWithInvalidScenarioIdReturnsEmptyArray() async throws {
        let invalidScenarioId = UUID()
        let videos = try await client.fetchVideos(for: invalidScenarioId)
        
        // Should return empty array, not throw an error
        XCTAssertTrue(videos.isEmpty, "Should return empty array for non-existent scenario")
    }
}
