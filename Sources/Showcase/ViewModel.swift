import Foundation
import Observation
import SkipFuse

@MainActor
@Observable public class ViewModel {
    public var scenarios: [Scenario] = []
    public var videos: [UUID: [Video]] = [:] // scenarioId: [Videos]
    public var selectedScenario: Scenario?
    public var currentVideo: Video?
    public var isLoading: Bool = false
    public var error: Error?
    public var isPlaying: Bool = false
    public var videoQueue: [Video] = []
    public var currentVideoIndex: Int = 0

    public init() {
    }

    @MainActor
    public func loadData() async {
        isLoading = true
        error = nil
        do {
            self.scenarios = try await SupabaseManager.shared.fetchScenarios()
            
            // Preload videos for all scenarios
            for scenario in scenarios {
                await loadVideos(for: scenario.id)
            }
            
            if let first = scenarios.first {
                selectedScenario = first
            }
        } catch {
            self.error = error
            logger.error("Failed to load scenarios: \(error)")
        }
        isLoading = false
    }

    @MainActor
    public func loadVideos(for scenarioId: UUID) async {
        do {
            let fetchedVideos = try await SupabaseManager.shared.fetchVideos(for: scenarioId)
            self.videos[scenarioId] = fetchedVideos
        } catch {
            self.error = error
            logger.error("Failed to load videos for \(scenarioId): \(error)")
        }
    }
    
    public func selectScenario(_ scenario: Scenario) {
        selectedScenario = scenario
        
        // Load video queue for this scenario
        if let scenarioVideos = videos[scenario.id], !scenarioVideos.isEmpty {
            videoQueue = scenarioVideos
            currentVideoIndex = 0
            currentVideo = videoQueue.first
            isPlaying = true
        } else {
            Task {
                await loadVideos(for: scenario.id)
                if let scenarioVideos = videos[scenario.id], !scenarioVideos.isEmpty {
                    videoQueue = scenarioVideos
                    currentVideoIndex = 0
                    currentVideo = videoQueue.first
                    isPlaying = true
                }
            }
        }
    }
    
    public func playVideo(_ video: Video) {
        currentVideo = video
        isPlaying = true
        
        // Find video in queue
        if let index = videoQueue.firstIndex(where: { $0.id == video.id }) {
            currentVideoIndex = index
        }
    }
    
    public func playNextVideo() {
        guard !videoQueue.isEmpty else { return }
        
        currentVideoIndex = (currentVideoIndex + 1) % videoQueue.count
        currentVideo = videoQueue[currentVideoIndex]
        isPlaying = true
    }
    
    public func playPreviousVideo() {
        guard !videoQueue.isEmpty else { return }
        
        currentVideoIndex = (currentVideoIndex - 1 + videoQueue.count) % videoQueue.count
        currentVideo = videoQueue[currentVideoIndex]
        isPlaying = true
    }
    
    public func stopPlayback() {
        isPlaying = false
        currentVideo = nil
    }
    
    public func videoURL(for video: Video) -> URL? {
        return SupabaseManager.shared.getPublicURL(for: video.storagePath)
    }
    
    public func videosForScenario(_ scenario: Scenario) -> [Video] {
        return videos[scenario.id] ?? []
    }
    
    public var hasVideos: Bool {
        return !videos.values.flatMap { $0 }.isEmpty
    }
}
