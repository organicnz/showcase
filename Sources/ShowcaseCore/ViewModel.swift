import Foundation
import Observation
import SkipFuse

/// The central state manager for the Showcase application.
///
/// `ViewModel` coordinates data fetching from Supabase, manages playback state for videos and photos,
/// and handles user authentication and settings.
///
/// ### Architecture
/// - **Observation**: Uses the `@Observable` macro for reactive UI updates.
/// - **Concurrency**: Isolated to the `@MainActor` to ensure all UI-bound state changes are thread-safe.
/// - **Persistence**: Implements a simple `UserDefaults`-based cache for offline startup capability.
@MainActor
@Observable public class ViewModel {

    // MARK: - State: Content

    /// All available lifestyle scenarios.
    public var scenarios: [Scenario] = []
    
    /// Videos mapped by their parent scenario ID.
    public var videos: [UUID: [Video]] = [:]
    
    /// Photos mapped by their parent scenario ID.
    public var photos: [UUID: [Photo]] = [:]
    
    /// The currently selected scenario for the detail view.
    public var selectedScenario: Scenario? {
        didSet {
            if let scenario = selectedScenario {
                Task { @MainActor in
                    await triggerAmbientAudio(for: scenario)
                }
            }
        }
    }

    // MARK: - State: Playback

    /// The video currently being played on the external or local screen.
    public var currentVideo: Video?
    
    /// Whether a video is currently actively playing.
    public var isPlaying: Bool = false
    
    /// The ordered queue of videos for the current scenario.
    public var videoQueue: [Video] = []
    
    /// The index of the current video in the queue.
    public var currentVideoIndex: Int = 0
    
    /// The photo currently being viewed in the gallery.
    public var currentPhoto: Photo?
    
    /// The ordered queue of photos for the current scenario.
    public var photoQueue: [Photo] = []
    
    /// The index of the current photo in the gallery.
    public var currentPhotoIndex: Int = 0

    // MARK: - State: System

    /// The current loading or error state of the primary data load.
    public var loadState: LoadState = .idle
    
    /// The timestamp of the last successful synchronization with Supabase.
    public var lastSyncDate: Date?
    
    /// Whether the current session is authenticated (admin only).
    public var isAuthenticated: Bool = false
    
    /// The email address of the logged-in user.
    public var userEmail: String?
    
    /// The unique identifier of the logged-in user.
    public var currentUserId: UUID?
    
    /// User-specific application preferences (theme, autoplay, etc.).
    public var userSettings: UserSettings?
    
    public var isShowingDetail: Bool = false
    
    // MARK: - AWE Engine
    
    /// The workflow runner for handling complex async sequences.
    private let workflowRunner = AWE.Runner()
    
    /// The status of the currently running workflow (if any).
    public var currentWorkflowProgress: String?
    
    /// The current display mode for the scenario detail (Overview, Photo, or Video).
    public var contentMode: ContentMode = .overview
    
    /// The brand color palette derived from the currently selected scenario.
    public var currentThemeColors: [Color] {
        if let slug = selectedScenario?.slug {
            return ScenarioGradient.colors(for: slug)
        }
        return [Color.ink, Color.terracotta, Color.ochre]
    }

    // MARK: - Computed Properties

    /// A convenience shorthand to check if data is currently being fetched.
    public var isLoading: Bool { loadState.isLoading }

    /// The most recent error encountered during data loading, if any.
    public var error: Error? { loadState.error }

    /// Whether any video content has been successfully loaded into the cache.
    public var hasVideos: Bool {
        !videos.values.flatMap { $0 }.isEmpty
    }

    /// The total count of all videos across all scenarios.
    public var totalVideoCount: Int {
        videos.values.flatMap { $0 }.count
    }

    // MARK: - Initialization

    /// Initializes a new ViewModel. Call `loadData()` after initialization to populate state.
    public init() {}

    // MARK: - Data Loading

    /// Loads all scenarios and their videos/photos from the Supabase backend using the AWE engine.
    ///
    /// - Parameter forceRefresh: If `true`, wipes the local cache and fetches fresh data from the server.
    public func loadData(forceRefresh: Bool = false) async {
        logger.debug("Starting loadData(forceRefresh: \(forceRefresh))")
        
        if forceRefresh {
            clearCache()
        } else {
            loadFromCache()
        }

        let isInitialLoad = scenarios.isEmpty
        if isInitialLoad {
            loadState = .loading
        }

        let workflow = createLoadWorkflow()

        do {
            // persist: false — read-only catalogue load must not write to
            // `workflow_states` (see AWE.Runner docs). In-memory only.
            try await workflowRunner.execute(workflow, persist: false) { [weak self] state in
                Task { @MainActor in
                    self?.updateLoadProgress(state)
                }
            }
            
            lastSyncDate = Date()
            loadState = .loaded
            logger.info("AWE: Load workflow completed successfully.")
        } catch {
            if isInitialLoad {
                loadState = .failed(error)
            }
            logger.error("AWE: Load workflow failed: \(error)")
        }
    }
    
    private static let loadStepLabels = [
        "Загрузка сценариев",
        "Синхронизация медиа",
        "Оптимизация кэша",
    ]

    private func updateLoadProgress(_ state: AWE.WorkflowState) {
        // NOTE: labels live here (not in createLoadWorkflow) as the single
        // source of truth for progress text — keep the two in the same order.
        if state.currentStepIndex < Self.loadStepLabels.count {
            let label = Self.loadStepLabels[state.currentStepIndex]
            self.currentWorkflowProgress = label
            logger.debug("AWE Progress: \(label) (\(state.currentStepIndex + 1)/\(Self.loadStepLabels.count))")
        }
    }

    /// Creates the multi-step load workflow for the AWE engine.
    private func createLoadWorkflow() -> AWE.Workflow {
        AWE.Workflow(name: "Initial Load", steps: [
            AWE.Step(id: "fetch_scenarios", label: "Загрузка сценариев") { [weak self] in
                let fetched = try await SupabaseManager.shared.fetchScenarios()
                await MainActor.run {
                    self?.scenarios = fetched
                }
                return .success
            },
            AWE.Step(id: "fetch_media", label: "Синхронизация медиа") { [weak self] in
                guard let self = self else { return .success }

                // Batched fetch: 2 queries total instead of 2*N (one videos +
                // one photos query per scenario). Each PostgREST round-trip is
                // Disk IO + WAL + connection overhead on a tiny shared
                // instance — with 5 scenarios the old TaskGroup issued 10
                // queries per app launch; now it issues 2.
                // Group client-side by scenario_id.
                do {
                    async let allVideos = SupabaseManager.shared.fetchAllVideos()
                    async let allPhotos = SupabaseManager.shared.fetchAllPhotos()
                    let (videos, photos) = try await (allVideos, allPhotos)

                    let videosByScenario = Dictionary(grouping: videos, by: \.scenarioId)
                    let photosByScenario = Dictionary(grouping: photos, by: \.scenarioId)

                    // Get scenarios from MainActor
                    let currentScenarios = await MainActor.run { self.scenarios }

                    await MainActor.run {
                        for scenario in currentScenarios {
                            self.videos[scenario.id] = videosByScenario[scenario.id] ?? []
                            self.photos[scenario.id] = photosByScenario[scenario.id] ?? []
                        }
                    }
                } catch {
                    // Intentional: keep the last good cache on failure (kiosk
                    // must stay presentable offline) instead of clearing it.
                    // loadState still resolves to .loaded below.
                    logger.error("AWE: Failed to batch-load media: \(error)")
                }
                return .success
            },
            AWE.Step(id: "finalize_cache", label: "Оптимизация кэша") { [weak self] in
                await MainActor.run {
                    self?.saveToCache()
                    self?.prefetchImages()
                    
                    // Auto-select first scenario if none selected
                    if self?.selectedScenario == nil, let first = self?.scenarios.first {
                        self?.selectedScenario = first
                    }
                }
                return .success
            }
        ])
    }

    // MARK: - Audio
    
    private func triggerAmbientAudio(for scenario: Scenario) async {
        guard userSettings?.autoPlayAudio != false else {
            await AudioManager.shared.stop()
            return
        }
        
        if let path = scenario.ambientAudioPath,
           let url = SupabaseManager.shared.getPublicAudioURL(for: path) {
            await AudioManager.shared.play(url: url)
        } else {
            await AudioManager.shared.stop()
        }
    }
    
    // MARK: - Auth Actions

    /// Refreshes the authentication state and loads user-specific settings.
    ///
    /// Updates `isAuthenticated`, `userEmail`, and `currentUserId`. If authenticated,
    /// also attempts to fetch or initialize `userSettings`.
    public func checkAuth() async {
        isAuthenticated = await SupabaseManager.shared.isAuthenticated()
        userEmail = await SupabaseManager.shared.currentUserEmail()
        currentUserId = await SupabaseManager.shared.currentUserId()
        
        if let uid = currentUserId {
            do {
                if let settings = try await SupabaseManager.shared.fetchUserSettings(userId: uid) {
                    self.userSettings = settings
                } else {
                    // Create default settings if none exist
                    let defaultSettings = UserSettings(userId: uid)
                    try await SupabaseManager.shared.updateUserSettings(defaultSettings)
                    self.userSettings = defaultSettings
                }
            } catch {
                logger.error("Failed to load user settings: \(error)")
            }
        }
    }

    /// Performs an email/password login.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Throws: An error if the credentials are invalid or network fails.
    public func login(email: String, password: String) async throws {
        try await SupabaseManager.shared.signIn(email: email, password: password)
        await checkAuth()
        await loadData()
    }

    public func logout() async {
        try? await SupabaseManager.shared.signOut()
        isAuthenticated = false
        userEmail = nil
        currentUserId = nil
        userSettings = nil
    }
    
    public func saveUserSettings() {
        guard let settings = userSettings else { return }
        Task {
            do {
                try await SupabaseManager.shared.updateUserSettings(settings)
            } catch {
                logger.error("Failed to save user settings: \(error)")
            }
        }
    }

    // MARK: - Caching
    
    private func prefetchImages() {
        #if !os(macOS)
        Task(priority: .background) {
            // Collect all image URLs
            var urlsToFetch = [URL]()
            
            // Scenario covers
            for scenario in scenarios {
                if let url = scenarioImageURL(for: scenario) {
                    urlsToFetch.append(url)
                }
            }
            
            // Video thumbnails & Photos
            for (_, videoList) in videos {
                for video in videoList {
                    if let url = videoThumbnailURL(for: video) {
                        urlsToFetch.append(url)
                    }
                }
            }
            
            for (_, photoList) in photos {
                for photo in photoList {
                    if let url = photoURL(for: photo) {
                        urlsToFetch.append(url)
                    }
                }
            }
            
            // Preload into global URLCache
            for url in urlsToFetch {
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
                if URLCache.shared.cachedResponse(for: request) == nil {
                    do {
                        let _ = try await URLSession.shared.data(for: request)
                    } catch {
                        // Silent fail for prefetch
                    }
                }
            }
        }
        #endif
    }

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
    ///
    /// Useful for debugging or forcing a clean state without re-authenticating.
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

    /// Selects a scenario and prepares its media content for presentation.
    ///
    /// - Parameter scenario: The scenario to select.
    ///
    /// This method updates `selectedScenario`, rebuilds the `videoQueue`, and
    /// triggers the slide-in detail animation by setting `isShowingDetail` to `true`.
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
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
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
