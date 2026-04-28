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
    public var photos: [UUID: [Photo]] = [:]
    public var selectedScenario: Scenario?
    public var currentVideo: Video?
    public var loadState: LoadState = .idle
    public var isPlaying: Bool = false
    public var videoQueue: [Video] = []
    public var currentVideoIndex: Int = 0
    public var currentPhoto: Photo?
    public var photoQueue: [Photo] = []
    public var currentPhotoIndex: Int = 0
    public var lastSyncDate: Date?
    public var isAuthenticated: Bool = false
    public var userEmail: String?
    public var isShowingDetail: Bool = false

    /// The current display mode for the scenario detail
    public var contentMode: ContentMode = .overview
    
    public var currentThemeColors: [Color] {
        if let slug = selectedScenario?.slug {
            return ScenarioGradient.colors(for: slug)
        }
        return [Color.ink, Color.terracotta, Color.ochre]
    }

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
    public func loadData(forceRefresh: Bool = false) async {
        logger.debug("Starting loadData(forceRefresh: \(forceRefresh))")
        
        if forceRefresh {
            clearCache()
        } else {
            // Load from cache first for instant startup
            loadFromCache()
        }

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

            logger.debug("Starting media fetch task group...")
            // Concurrently load videos and photos for all scenarios
            await withTaskGroup(of: (UUID, [Video], [Photo]).self) { group in
                for scenario in fetchedScenarios {
                    group.addTask {
                        do {
                            async let vids = SupabaseManager.shared.fetchVideos(for: scenario.id)
                            async let phs = SupabaseManager.shared.fetchPhotos(for: scenario.id)
                            return (scenario.id, try await vids, try await phs)
                        } catch {
                            logger.error("Failed to load media for \(scenario.slug): \(error)")
                            return (scenario.id, [], [])
                        }
                    }
                }

                for await (scenarioId, vids, phs) in group {
                    self.videos[scenarioId] = vids
                    self.photos[scenarioId] = phs
                }
            }
            logger.debug("Media fetch task group completed.")

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

    // MARK: - Auth Actions

    public func checkAuth() async {
        isAuthenticated = await SupabaseManager.shared.isAuthenticated()
        userEmail = await SupabaseManager.shared.currentUserEmail()
    }

    public func login(email: String, password: String) async throws {
        try await SupabaseManager.shared.signIn(email: email, password: password)
        await checkAuth()
        await loadData()
    }

    public func logout() async {
        try? await SupabaseManager.shared.signOut()
        isAuthenticated = false
        userEmail = nil
    }

    // MARK: - Caching

    private func saveToCache() {
        if let encodedScenarios = try? JSONEncoder().encode(scenarios) {
            UserDefaults.standard.set(encodedScenarios, forKey: "cached_scenarios")
        }
        if let encodedVideos = try? JSONEncoder().encode(videos) {
            UserDefaults.standard.set(encodedVideos, forKey: "cached_videos")
        }
        if let encodedPhotos = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(encodedPhotos, forKey: "cached_photos")
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
        if let data = UserDefaults.standard.data(forKey: "cached_photos"),
           let decoded = try? JSONDecoder().decode([UUID: [Photo]].self, from: data) {
            self.photos = decoded
        }
    }

    /// Wipes all locally cached data and resets the state.
    public func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cached_scenarios")
        UserDefaults.standard.removeObject(forKey: "cached_videos")
        UserDefaults.standard.removeObject(forKey: "cached_photos")
        
        self.scenarios = []
        self.videos = [:]
        self.photos = [:]
        self.lastSyncDate = nil
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
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isShowingDetail = true
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
    
    // MARK: - Photo Gallery Control
    
    public func startPhotoGallery(with photos: [Photo], startingAt index: Int = 0) {
        photoQueue = photos
        guard !photoQueue.isEmpty else { return }
        currentPhotoIndex = max(0, min(index, photoQueue.count - 1))
        currentPhoto = photoQueue[currentPhotoIndex]
    }
    
    public func showNextPhoto() {
        guard !photoQueue.isEmpty else { return }
        currentPhotoIndex = (currentPhotoIndex + 1) % photoQueue.count
        currentPhoto = photoQueue[currentPhotoIndex]
    }
    
    public func showPreviousPhoto() {
        guard !photoQueue.isEmpty else { return }
        currentPhotoIndex = (currentPhotoIndex - 1 + photoQueue.count) % photoQueue.count
        currentPhoto = photoQueue[currentPhotoIndex]
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
        SupabaseManager.shared.getPublicVideoURL(for: video.storagePath)
    }

    /// Returns the public CDN URL for a video's thumbnail path.
    public func videoThumbnailURL(for video: Video) -> URL? {
        guard let path = video.thumbnailPath, !path.isEmpty else { return nil }
        return SupabaseManager.shared.getPublicImageURL(for: path)
    }

    /// Returns the public CDN URL for a photo's storage path.
    public func photoURL(for photo: Photo) -> URL? {
        SupabaseManager.shared.getPublicImageURL(for: photo.storagePath)
    }

    /// Returns the cached videos for a given scenario.
    public func videosForScenario(_ scenario: Scenario) -> [Video] {
        videos[scenario.id] ?? []
    }

    /// Returns the SF Symbol name for a scenario.
    public func iconName(for scenario: Scenario) -> String {
        if let icon = scenario.iconName, !icon.isEmpty {
            return icon
        }
        // Fallback for older data
        switch scenario.slug {
        case "family": return "figure.2.and.child.holdinghands"
        case "wellness": return "leaf.fill"
        case "guests": return "building.2.fill"
        case "investor": return "chart.line.uptrend.xyaxis"
        case "architecture": return "building.columns.fill"
        default: return "sparkles"
        }
    }

    /// Returns the public CDN URL for a scenario's cover image.
    public func scenarioImageURL(for scenario: Scenario) -> URL? {
        guard let path = scenario.imagePath, !path.isEmpty else { return nil }
        return SupabaseManager.shared.getPublicImageURL(for: path)
    }

    /// Returns a human-readable title for a scenario slug, translating it to Russian.
    public func scenarioTitle(for scenario: Scenario) -> String {
        return scenario.title
    }

    /// Returns a human-readable description for a scenario slug.
    public func scenarioDescription(for scenario: Scenario) -> String {
        return scenario.description ?? ""
    }

    /// Returns the gradient colors for a scenario slug (brand palette).
    public func gradientColors(for slug: String) -> [Color] {
        ScenarioGradient.colors(for: slug)
    }
}

// MARK: - SwiftUI Color import (needed for gradient helpers)
import SwiftUI
