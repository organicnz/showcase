import Foundation

// MARK: - Scenario

public struct Scenario: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var slug: String
    public var description: String?
    public var orderIndex: Int
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        slug: String,
        description: String? = nil,
        orderIndex: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.description = description
        self.orderIndex = orderIndex
        self.isActive = isActive
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case slug
        case description
        case orderIndex = "order_index"
        case isActive = "active"
    }
}

// MARK: - Video

public struct Video: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var scenarioId: UUID
    public var title: String?
    public var storagePath: String
    public var thumbnailPath: String?
    public var durationSec: Int?
    public var orderIndex: Int
    public var isActive: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        scenarioId: UUID,
        title: String? = nil,
        storagePath: String,
        thumbnailPath: String? = nil,
        durationSec: Int? = nil,
        orderIndex: Int = 0,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scenarioId = scenarioId
        self.title = title
        self.storagePath = storagePath
        self.thumbnailPath = thumbnailPath
        self.durationSec = durationSec
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case scenarioId = "scenario_id"
        case title
        case storagePath = "storage_path"
        case thumbnailPath = "thumbnail_path"
        case durationSec = "duration_sec"
        case orderIndex = "order_index"
        case isActive = "active"
        case createdAt = "created_at"
    }
}

// MARK: - Load State

/// Represents the loading state of async data operations.
public enum LoadState: Sendable {
    case idle
    case loading
    case loaded
    case failed(Error)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}
