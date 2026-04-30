import Foundation

/// Thread-safe service for video playback coordination
public actor VideoService {
    private let supabaseClient: SupabaseClient
    
    public init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    /// Load all scenarios
    public func loadScenarios() async throws -> [Scenario] {
        do {
            return try await supabaseClient.fetchScenarios()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.timeout
        } catch {
            Logger.error("Failed to load scenarios", error: error)
            throw error
        }
    }
    
    /// Load scenario with its videos
    public func loadScenario(_ scenario: Scenario) async throws -> [Video] {
        do {
            return try await supabaseClient.fetchVideos(for: scenario.id)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.timeout
        } catch {
            Logger.error("Failed to load videos for scenario", error: error)
            throw error
        }
    }
    
    /// Load all videos for library view
    public func loadAllVideos() async throws -> [Video] {
        do {
            return try await supabaseClient.fetchAllVideos()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.timeout
        } catch {
            Logger.error("Failed to load all videos", error: error)
            throw error
        }
    }
}
