import Foundation

/// Represents a photo asset with metadata
public struct Photo: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var scenarioId: UUID
    public var title: String?
    public var subtitle: String?
    public var storagePath: String
    public var orderIndex: Int
    public var isActive: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        scenarioId: UUID,
        title: String? = nil,
        subtitle: String? = nil,
        storagePath: String,
        orderIndex: Int = 0,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scenarioId = scenarioId
        self.title = title
        self.subtitle = subtitle
        self.storagePath = storagePath
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case scenarioId = "scenario_id"
        case title
        case subtitle
        case storagePath = "storage_path"
        case orderIndex = "order_index"
        case isActive = "active"
        case createdAt = "created_at"
    }
}
