import Foundation

/// Represents a single video asset with metadata
public struct Video: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var scenarioId: UUID
    public var title: String?
    public var subtitle: String?
    public var storagePath: String
    public var thumbnailPath: String?
    public var durationSec: Int?
    public var orderIndex: Int
    public var isActive: Bool
    public var highlights: [String]?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        scenarioId: UUID,
        title: String? = nil,
        subtitle: String? = nil,
        storagePath: String,
        thumbnailPath: String? = nil,
        durationSec: Int? = nil,
        orderIndex: Int = 0,
        isActive: Bool = true,
        highlights: [String]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scenarioId = scenarioId
        self.title = title
        self.subtitle = subtitle
        self.storagePath = storagePath
        self.thumbnailPath = thumbnailPath
        self.durationSec = durationSec
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.highlights = highlights
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case scenarioId = "scenario_id"
        case title
        case subtitle
        case storagePath = "storage_path"
        case thumbnailPath = "thumbnail_path"
        case durationSec = "duration_sec"
        case orderIndex = "order_index"
        case isActive = "active"
        case highlights
        case createdAt = "created_at"
    }

    /// Computed CDN URL for video playback
    public var videoURL: URL? {
        // Construct URL from Supabase Storage CDN path
        // Format: https://[project-ref].supabase.co/storage/v1/object/public/videos/[storagePath]
        guard !storagePath.isEmpty else { return nil }
        
        // The storagePath should already include the bucket path structure
        // We'll construct the full public URL
        let baseURL = "https://placeholder.supabase.co/storage/v1/object/public"
        return URL(string: "\(baseURL)/\(storagePath)")
    }
}
