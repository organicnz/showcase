import Foundation

public struct Scenario: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var slug: String
    public var orderIndex: Int
    public var isActive: Bool

    public init(id: UUID = UUID(), title: String, slug: String, orderIndex: Int = 0, isActive: Bool = true) {
        self.id = id
        self.title = title
        self.slug = slug
        self.orderIndex = orderIndex
        self.isActive = isActive
    }
}

public struct Video: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var scenarioId: UUID
    public var title: String?
    public var storagePath: String
    public var durationSec: Int?
    public var orderIndex: Int
    public var isActive: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), scenarioId: UUID, title: String? = nil, storagePath: String, durationSec: Int? = nil, orderIndex: Int = 0, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.scenarioId = scenarioId
        self.title = title
        self.storagePath = storagePath
        self.durationSec = durationSec
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
