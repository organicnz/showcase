import XCTest
@testable import ShowcaseCore

final class VideoTests: XCTestCase {
    
    // MARK: - Storage URL Tests
    
    func testVideoURLConstructsValidURL() throws {
        let video = Video(
            scenarioId: UUID(),
            storagePath: "videos/family/video1.mp4"
        )
        
        let url = try XCTUnwrap(SupabaseManager.shared.getPublicVideoURL(for: video.storagePath))
        XCTAssertTrue(url.absoluteString.contains("storage/v1/object/public"))
        XCTAssertTrue(url.absoluteString.contains("videos/family/video1.mp4"))
    }
    
    func testVideoURLReturnsNilForEmptyStoragePath() {
        let video = Video(
            scenarioId: UUID(),
            storagePath: ""
        )
        
        XCTAssertNil(SupabaseManager.shared.getPublicVideoURL(for: video.storagePath))
    }
    
    func testVideoURLIncludesStoragePath() throws {
        let storagePath = "videos/wellness/meditation.mp4"
        let video = Video(
            scenarioId: UUID(),
            storagePath: storagePath
        )
        
        let url = try XCTUnwrap(SupabaseManager.shared.getPublicVideoURL(for: video.storagePath))
        XCTAssertTrue(url.absoluteString.hasSuffix(storagePath))
    }
    
    // MARK: - Model Conformance Tests
    
    func testVideoIsIdentifiable() {
        let video1 = Video(scenarioId: UUID(), storagePath: "test1.mp4")
        let video2 = Video(scenarioId: UUID(), storagePath: "test2.mp4")
        
        XCTAssertNotEqual(video1.id, video2.id)
    }
    
    func testVideoIsHashable() {
        let scenarioId = UUID()
        // createdAt participates in Hashable synthesis and defaults to Date(),
        // which differs per instance, so pin it to build genuinely equal values.
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let video1 = Video(id: UUID(), scenarioId: scenarioId, storagePath: "test.mp4", createdAt: createdAt)
        let video2 = Video(id: video1.id, scenarioId: scenarioId, storagePath: "test.mp4", createdAt: createdAt)
        
        XCTAssertEqual(video1, video2)
        
        var set = Set<Video>()
        set.insert(video1)
        XCTAssertTrue(set.contains(video2))
    }
    
    func testVideoIsCodable() throws {
        let originalVideo = Video(
            id: UUID(),
            scenarioId: UUID(),
            title: "Test Video",
            subtitle: "Test Subtitle",
            storagePath: "videos/test.mp4",
            thumbnailPath: "thumbnails/test.jpg",
            durationSec: 30,
            orderIndex: 1,
            isActive: true,
            highlights: ["Feature 1", "Feature 2"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalVideo)
        
        let decoder = JSONDecoder()
        let decodedVideo = try decoder.decode(Video.self, from: data)
        
        XCTAssertEqual(originalVideo.id, decodedVideo.id)
        XCTAssertEqual(originalVideo.scenarioId, decodedVideo.scenarioId)
        XCTAssertEqual(originalVideo.title, decodedVideo.title)
        XCTAssertEqual(originalVideo.subtitle, decodedVideo.subtitle)
        XCTAssertEqual(originalVideo.storagePath, decodedVideo.storagePath)
        XCTAssertEqual(originalVideo.thumbnailPath, decodedVideo.thumbnailPath)
        XCTAssertEqual(originalVideo.durationSec, decodedVideo.durationSec)
        XCTAssertEqual(originalVideo.orderIndex, decodedVideo.orderIndex)
        XCTAssertEqual(originalVideo.isActive, decodedVideo.isActive)
        XCTAssertEqual(originalVideo.highlights, decodedVideo.highlights)
    }
    
    func testVideoCodingKeysMatchDatabaseSchema() throws {
        // This test ensures the CodingKeys match the expected database column names
        let video = Video(
            scenarioId: UUID(),
            title: "Test",
            storagePath: "test.mp4",
            orderIndex: 5,
            isActive: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(video)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["scenario_id"]) // snake_case for database
        XCTAssertNotNil(json?["storage_path"])
        XCTAssertNotNil(json?["order_index"])
        XCTAssertNotNil(json?["active"])
        XCTAssertNotNil(json?["created_at"])
    }
    
    // MARK: - Initialization Tests
    
    func testVideoInitializationWithDefaults() {
        let scenarioId = UUID()
        let video = Video(
            scenarioId: scenarioId,
            storagePath: "test.mp4"
        )
        
        XCTAssertNotNil(video.id)
        XCTAssertEqual(video.scenarioId, scenarioId)
        XCTAssertNil(video.title)
        XCTAssertNil(video.subtitle)
        XCTAssertEqual(video.storagePath, "test.mp4")
        XCTAssertNil(video.thumbnailPath)
        XCTAssertNil(video.durationSec)
        XCTAssertEqual(video.orderIndex, 0)
        XCTAssertTrue(video.isActive)
        XCTAssertNil(video.highlights)
    }
    
    func testVideoInitializationWithAllParameters() {
        let id = UUID()
        let scenarioId = UUID()
        let createdAt = Date()
        
        let video = Video(
            id: id,
            scenarioId: scenarioId,
            title: "Full Video",
            subtitle: "Complete Test",
            storagePath: "videos/full.mp4",
            thumbnailPath: "thumbnails/full.jpg",
            durationSec: 45,
            orderIndex: 3,
            isActive: false,
            highlights: ["HD", "4K"],
            createdAt: createdAt
        )
        
        XCTAssertEqual(video.id, id)
        XCTAssertEqual(video.scenarioId, scenarioId)
        XCTAssertEqual(video.title, "Full Video")
        XCTAssertEqual(video.subtitle, "Complete Test")
        XCTAssertEqual(video.storagePath, "videos/full.mp4")
        XCTAssertEqual(video.thumbnailPath, "thumbnails/full.jpg")
        XCTAssertEqual(video.durationSec, 45)
        XCTAssertEqual(video.orderIndex, 3)
        XCTAssertFalse(video.isActive)
        XCTAssertEqual(video.highlights, ["HD", "4K"])
        XCTAssertEqual(video.createdAt, createdAt)
    }
}
