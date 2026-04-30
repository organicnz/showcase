import Foundation
import Observation

/// Main screen view model managing scenario selection
@Observable
public final class MainViewModel {
    public private(set) var scenarios: [Scenario] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    
    private let videoService: VideoService
    
    public init(videoService: VideoService) {
        self.videoService = videoService
    }
    
    @MainActor
    public func loadScenarios() async {
        isLoading = true
        errorMessage = nil
        
        do {
            scenarios = try await videoService.loadScenarios()
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
            Logger.error("Scenario load failed", error: error)
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            Logger.error("Unexpected error loading scenarios", error: error)
        }
        
        isLoading = false
    }
    
    @MainActor
    public func selectScenario(_ scenario: Scenario) async -> [Video]? {
        do {
            return try await videoService.loadScenario(scenario)
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
            Logger.error("Video load failed", error: error)
            return nil
        } catch {
            errorMessage = "Failed to load videos. Please try again."
            Logger.error("Unexpected error loading videos", error: error)
            return nil
        }
    }
}
