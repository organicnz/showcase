import Foundation
import Observation
import SkipFuse

/// The main view model for the Showcase app.
///
/// Uses `@Observable` for modern reactive UI and `@MainActor` isolation
/// to ensure all state mutations happen on the main thread.
@MainActor
@Observable public class ViewModel {

    // MARK: - State

    public var scenarios: [Scenario] = []
    public var videos: [UUID: [Video]] = [:]
    public var selectedScenario: Scenario?
    public var currentVideo: Video?
    public var loadState: LoadState = .idle
    public var isPlaying: Bool = false
    public var videoQueue: [Video] = []
    public var currentVideoIndex: Int = 0
    public var lastSyncDate: Date?

    // MARK: - Computed Properties

    public var isLoading: Bool { loadState.isLoading }

    public var error: Error? { loadState.error }

    public var hasVideos: Bool {
        !videos.values.flatMap { $0 }.isEmpty
    }

    public var totalVideoCount: Int {
        videos.values.flatMap { $0 }.count
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Data Loading

    /// Loads all scenarios and their videos from Supabase.
    ///
    /// This is the primary data loading entry point. It fetches scenarios first,
    /// then concurrently preloads videos for each scenario.
    public func loadData() async {
        logger.debug("Starting loadData()")
        // Load from cache first for instant startup
        loadFromCache()

        // Only show full loading screen on initial load if cache was empty
        let isInitialLoad = scenarios.isEmpty
        if isInitialLoad {
            loadState = .loading
        }

        do {
            logger.debug("Fetching scenarios from backend...")
            // Fetch scenarios from backend
            let fetchedScenarios = try await SupabaseManager.shared.fetchScenarios()
            logger.debug("Fetched \(fetchedScenarios.count) scenarios.")
            self.scenarios = fetchedScenarios

            logger.debug("Starting video fetch task group...")
            // Concurrently load videos for all scenarios
            await withTaskGroup(of: (UUID, [Video]).self) { group in
                for scenario in fetchedScenarios {
                    group.addTask {
                        do {
                            let vids = try await SupabaseManager.shared.fetchVideos(for: scenario.id)
                            return (scenario.id, vids)
                        } catch {
                            logger.error("Failed to load videos for \(scenario.slug): \(error)")
                            return (scenario.id, [])
                        }
                    }
                }

                for await (scenarioId, vids) in group {
                    self.videos[scenarioId] = vids
                }
            }
            logger.debug("Video fetch task group completed.")

            // Save to cache
            saveToCache()

            // Auto-select first scenario if none selected
            if selectedScenario == nil, let first = scenarios.first {
                selectedScenario = first
            }

            lastSyncDate = Date()
            loadState = .loaded

        } catch {
            // Only show error on initial load; on refresh, keep showing stale data
            if isInitialLoad {
                loadState = .failed(error)
            }
            logger.error("Failed to load scenarios: \(error)")
        }
    }

    // MARK: - Caching

    private func saveToCache() {
        if let encodedScenarios = try? JSONEncoder().encode(scenarios) {
            UserDefaults.standard.set(encodedScenarios, forKey: "cached_scenarios")
        }
        if let encodedVideos = try? JSONEncoder().encode(videos) {
            UserDefaults.standard.set(encodedVideos, forKey: "cached_videos")
        }
    }

    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cached_scenarios"),
           let decoded = try? JSONDecoder().decode([Scenario].self, from: data) {
            self.scenarios = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "cached_videos"),
           let decoded = try? JSONDecoder().decode([UUID: [Video]].self, from: data) {
            self.videos = decoded
        }
    }

    /// Reloads videos for a single scenario.
    public func reloadVideos(for scenarioId: UUID) async {
        do {
            let fetchedVideos = try await SupabaseManager.shared.fetchVideos(for: scenarioId)
            self.videos[scenarioId] = fetchedVideos
        } catch {
            logger.error("Failed to reload videos for \(scenarioId): \(error)")
        }
    }

    // MARK: - Scenario Selection

    /// Selects a scenario and prepares its video queue for playback.
    public func selectScenario(_ scenario: Scenario) {
        selectedScenario = scenario

        // Build video queue from cached data
        if let scenarioVideos = videos[scenario.id], !scenarioVideos.isEmpty {
            startPlayback(with: scenarioVideos)
        } else {
            // Videos not yet loaded — fetch them
            Task {
                await reloadVideos(for: scenario.id)
                if let scenarioVideos = videos[scenario.id], !scenarioVideos.isEmpty {
                    startPlayback(with: scenarioVideos)
                }
            }
        }
    }

    // MARK: - Playback Control

    /// Starts playback with the given video list.
    private func startPlayback(with videos: [Video]) {
        videoQueue = videos
        currentVideoIndex = 0
        currentVideo = videos.first
        isPlaying = true
    }

    /// Plays a specific video and updates the queue position.
    /// If called from Library (outside scenario context), finds the parent scenario
    /// and rebuilds the queue so prev/next navigation works correctly.
    public func playVideo(_ video: Video) {
        // Find and set the parent scenario if not already selected
        if selectedScenario?.id != video.scenarioId {
            if let parentScenario = scenarios.first(where: { $0.id == video.scenarioId }) {
                selectedScenario = parentScenario
                if let scenarioVideos = videos[parentScenario.id], !scenarioVideos.isEmpty {
                    videoQueue = scenarioVideos
                }
            }
        }

        currentVideo = video
        isPlaying = true

        if let index = videoQueue.firstIndex(where: { $0.id == video.id }) {
            currentVideoIndex = index
        }
    }

    /// Advances to the next video in the queue (wraps around).
    public func playNextVideo() {
        guard !videoQueue.isEmpty else { return }

        currentVideoIndex = (currentVideoIndex + 1) % videoQueue.count
        currentVideo = videoQueue[currentVideoIndex]
        isPlaying = true
    }

    /// Goes back to the previous video in the queue (wraps around).
    public func playPreviousVideo() {
        guard !videoQueue.isEmpty else { return }

        currentVideoIndex = (currentVideoIndex - 1 + videoQueue.count) % videoQueue.count
        currentVideo = videoQueue[currentVideoIndex]
        isPlaying = true
    }

    /// Stops all playback and clears the current video.
    public func stopPlayback() {
        isPlaying = false
        currentVideo = nil
    }

    // MARK: - Helpers

    /// Returns the public CDN URL for a video's storage path.
    public func videoURL(for video: Video) -> URL? {
        SupabaseManager.shared.getPublicURL(for: video.storagePath)
    }

    /// Returns the cached videos for a given scenario.
    public func videosForScenario(_ scenario: Scenario) -> [Video] {
        videos[scenario.id] ?? []
    }

    /// Returns the SF Symbol name for a scenario slug.
    public func iconName(for slug: String) -> String {
        switch slug {
        case "family": return "figure.2.and.child.holdinghands"
        case "wellness": return "leaf.fill"
        case "guests": return "building.2.fill"
        case "investor": return "chart.line.uptrend.xyaxis"
        case "architecture": return "building.columns.fill"
        default: return "sparkles"
        }
    }

    /// Returns a human-readable title for a scenario slug, translating it to Russian.
    public func scenarioTitle(for scenario: Scenario) -> String {
        switch scenario.slug {
        case "family": return "Семья с детьми"
        case "wellness": return "Здоровье и тишина"
        case "guests": return "Гости и отель"
        case "investor": return "Для инвестора"
        case "architecture": return "Архитектура и дизайн"
        default: return scenario.title
        }
    }

    /// Returns a human-readable description for a scenario slug.
    public func scenarioDescription(for scenario: Scenario) -> String {
        switch scenario.slug {
        case "family": return "Школа, площадка, безопасность, комьюнити"
        case "wellness": return "Спа, лесные прогулки, тишина"
        case "guests": return "Гостиничный номер вместо гостевой комнаты"
        case "investor": return "Ликвидность, ограниченное предложение, уникальная локация"
        case "architecture": return "Материалы, свет, панорамное остекление"
        default: return scenario.description ?? scenario.slug
        }
    }

    /// Returns the gradient colors for a scenario slug (brand palette).
    public func gradientColors(for slug: String) -> [Color] {
        ScenarioGradient.colors(for: slug)
    }
}

// MARK: - SwiftUI Color import (needed for gradient helpers)
import SwiftUI
