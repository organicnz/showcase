import Foundation

/// Represents a life scenario category containing related videos
public struct Scenario: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var slug: String
    public var description: String?
    public var orderIndex: Int
    public var isActive: Bool
    public var ambientAudioPath: String?
    public var imagePath: String?
    public var iconName: String?

    public init(
        id: UUID = UUID(),
        title: String,
        slug: String,
        description: String? = nil,
        orderIndex: Int = 0,
        isActive: Bool = true,
        ambientAudioPath: String? = nil,
        imagePath: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.description = description
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.ambientAudioPath = ambientAudioPath
        self.imagePath = imagePath
        self.iconName = iconName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case slug
        case description
        case orderIndex = "order_index"
        case isActive = "active"
        case ambientAudioPath = "ambient_audio_path"
        case imagePath = "image_path"
        case iconName = "icon_name"
    }
}
