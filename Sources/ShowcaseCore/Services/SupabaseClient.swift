import Foundation
import SkipSupabase
import Supabase

/// A thread-safe Supabase client manager using actor isolation
///
/// All network operations are isolated to this actor, keeping the main thread free.
/// URL generation is `nonisolated` since it's a pure, synchronous computation.
public actor SupabaseClient {
    public static let shared = SupabaseClient()

    // MARK: - Configuration

    // Read from Info.plist (injected via xcconfig/Skip.env)
    private static var supabaseURL: String {
        let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        return (url.isEmpty || url.contains("$(")) ? "https://smyfjmdjzfwdehynwfep.supabase.co" : url
    }

    private static var supabaseKey: String {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        return (key.isEmpty || key.contains("$(")) ? "sb_publishable_36vglboOi9AkwTwCw_BqMg_uWQE8NV_" : key
    }

    private static let videoBucket = "videos"
    private static let imageBucket = "photos"

    // MARK: - Client

    public let client: Supabase.SupabaseClient

    private init() {
        #if SKIP
        self.client = Supabase.SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseKey
        )
        #elseif os(Android)
        self.client = Supabase.SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseKey,
            options: SupabaseClientOptions(auth: .init(storage: AndroidAuthStorage()))
        )
        #else
        self.client = Supabase.SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseKey,
            options: SupabaseClientOptions()
        )
        #endif
    }

    // MARK: - Retry Logic

    /// Executes an async operation with exponential backoff retries
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

    /// Fetch all active scenarios ordered by order_index
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

    /// Fetch all active videos for a scenario ordered by order_index
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

    /// Fetch all active videos across all scenarios
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

    // MARK: - Photos

    /// Fetch all active photos for a scenario ordered by order_index
    public func fetchPhotos(for scenarioId: UUID) async throws -> [Photo] {
        try await withRetry {
            let photos: [Photo] = try await client.from("photos")
                .select()
                .eq("scenario_id", value: scenarioId)
                .eq("active", value: true)
                .order("order_index", ascending: true)
                .execute()
                .value
            return photos
        }
    }

    // MARK: - Storage URLs

    /// Generates a public CDN URL for a video file
    nonisolated public func getPublicVideoURL(for path: String) -> URL? {
        return try? client.storage.from(Self.videoBucket).getPublicURL(path: path)
    }

    /// Generates a public CDN URL for an image file
    nonisolated public func getPublicImageURL(for path: String) -> URL? {
        return try? client.storage.from(Self.imageBucket).getPublicURL(path: path)
    }

    /// Generates a public CDN URL for an audio file
    nonisolated public func getPublicAudioURL(for path: String) -> URL? {
        return try? client.storage.from("assets").getPublicURL(path: path)
    }
}

// MARK: - Android Compatibility

#if os(Android)
struct AndroidAuthStorage: AuthLocalStorage {
    func store(key: String, value: Data) throws {}
    func retrieve(key: String) throws -> Data? { nil }
    func remove(key: String) throws {}
}
#endif
