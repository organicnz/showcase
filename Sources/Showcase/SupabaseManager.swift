import Foundation
import SkipSupabase
import Supabase

/// A thread-safe Supabase client manager using actor isolation.
///
/// All network operations are isolated to this actor, keeping the main thread free.
/// URL generation is `nonisolated` since it's a pure, synchronous computation.
public actor SupabaseManager {
    public static let shared = SupabaseManager()

    // MARK: - Configuration

    // Read from Info.plist (injected via xcconfig/Skip.env)
    private static var supabaseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    }
    
    private static var supabaseKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    }
    
    private static let storageBucket = "videos"

    // MARK: - Client

    public let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseKey,
            options: SupabaseClientOptions()
        )
    }

    // MARK: - Retry Logic

    /// Executes an async operation with exponential backoff retries.
    private func withRetry<T>(maxAttempts: Int = 3, operation: () async throws -> T) async throws -> T {
        var attempt = 0
        while true {
            do {
                return try await operation()
            } catch {
                attempt += 1
                if attempt >= maxAttempts {
                    throw error
                }
                // Exponential backoff: 1s, 2s, 4s
                let delaySecs = 1 << (attempt - 1)
                try? await Task.sleep(nanoseconds: UInt64(delaySecs) * 1_000_000_000)
            }
        }
    }

    // MARK: - Scenarios

    public func fetchScenarios() async throws -> [Scenario] {
        try await withRetry {
            let scenarios: [Scenario] = try await client.from("scenarios")
                .select()
                .eq("active", value: true)
                .order("order_index", ascending: true)
                .execute()
                .value
            return scenarios
        }
    }

    // MARK: - Videos

    public func fetchVideos(for scenarioId: UUID) async throws -> [Video] {
        try await withRetry {
            let videos: [Video] = try await client.from("videos")
                .select()
                .eq("scenario_id", value: scenarioId)
                .eq("active", value: true)
                .order("order_index", ascending: true)
                .execute()
                .value
            return videos
        }
    }

    /// Fetches all active videos across all scenarios.
    public func fetchAllVideos() async throws -> [Video] {
        try await withRetry {
            let videos: [Video] = try await client.from("videos")
                .select()
                .eq("active", value: true)
                .order("order_index", ascending: true)
                .execute()
                .value
            return videos
        }
    }

    // MARK: - Storage URLs

    /// Generates a public CDN URL for a video file. This is a pure computation — no isolation needed.
    nonisolated public func getPublicURL(for path: String) -> URL? {
        return try? client.storage.from(Self.storageBucket).getPublicURL(path: path)
    }

    // MARK: - Health Check

    /// Performs a lightweight query to verify Supabase connectivity.
    public func healthCheck() async -> Bool {
        do {
            let _: [Scenario] = try await client.from("scenarios")
                .select("id")
                .limit(1)
                .execute()
                .value
            return true
        } catch {
            logger.error("Supabase health check failed: \(error)")
            return false
        }
    }
}
