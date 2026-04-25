import Foundation
import Observation
import SkipFuse

@MainActor
@Observable public class ViewModel {
    public var scenarios: [Scenario] = []
    public var videos: [UUID: [Video]] = [:] // scenarioId: [Videos]
    public var selectedScenario: Scenario?
    public var isLoading: Bool = false
    public var error: Error?

    public init() {
    }

    @MainActor
    public func loadData() async {
        isLoading = true
        error = nil
        do {
            self.scenarios = try await SupabaseManager.shared.fetchScenarios()
            if let first = scenarios.first {
                selectedScenario = first
                await loadVideos(for: first.id)
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
        Task {
            await loadVideos(for: scenario.id)
        }
    }
    
    public func videoURL(for video: Video) -> URL? {
        return SupabaseManager.shared.getPublicURL(for: video.storagePath)
    }
}
