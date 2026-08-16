import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Scenario

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

// MARK: - Video

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
}

// MARK: - Photo

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

// MARK: - User Settings

public struct UserSettings: Codable, Sendable, Equatable {
    public let userId: UUID
    public var appTheme: String
    public var autoPlayAudio: Bool
    public var updatedAt: Date

    public init(
        userId: UUID,
        appTheme: String = "system",
        autoPlayAudio: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.appTheme = appTheme
        self.autoPlayAudio = autoPlayAudio
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case appTheme = "app_theme"
        case autoPlayAudio = "auto_play_audio"
        case updatedAt = "updated_at"
    }
}

public enum AppTheme: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark
    
    #if canImport(SwiftUI)
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    #endif
}

// MARK: - Load State

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

// MARK: - Content Mode

public enum ContentMode: String, CaseIterable, Codable, Sendable {
    case overview = "Обзор"
    case photo = "Фото"
    case video = "Видео"
}

// MARK: - Playback State

public enum PlaybackState: Sendable {
    case idle
    case playing(video: Video, queue: [Video], index: Int)
    case paused(video: Video, queue: [Video], index: Int)
    
    public var currentVideo: Video? {
        switch self {
        case .idle: return nil
        case .playing(let video, _, _), .paused(let video, _, _): return video
        }
    }
    
    public var hasNext: Bool {
        switch self {
        case .idle: return false
        case .playing(_, let queue, let index), .paused(_, let queue, let index):
            return index < queue.count - 1
        }
    }
}
// MARK: - Workflow State

public struct WorkflowState: Identifiable, Codable, Sendable {
    public let id: UUID
    public var workflowName: String
    public var currentStepIndex: Int
    public var completedSteps: [String]
    public var status: Status
    public var updatedAt: Date

    public enum Status: String, Codable, Sendable {
        case pending, running, completed, failed
    }

    public init(
        id: UUID = UUID(),
        workflowName: String,
        currentStepIndex: Int = 0,
        completedSteps: [String] = [],
        status: Status = .pending,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.workflowName = workflowName
        self.currentStepIndex = currentStepIndex
        self.completedSteps = completedSteps
        self.status = status
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case workflowName = "workflow_name"
        case currentStepIndex = "current_step_index"
        case completedSteps = "completed_steps"
        case status
        case updatedAt = "updated_at"
    }
}
