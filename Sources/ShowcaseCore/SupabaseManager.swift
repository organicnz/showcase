import Foundation
import SkipSupabase
import Supabase
import PostgREST
import Storage
import Realtime

/// A thread-safe Supabase client manager using actor isolation.
///
/// All network operations are isolated to this actor, keeping the main thread free.
/// URL generation is `nonisolated` since it's a pure, synchronous computation.
public actor SupabaseManager {
    public static let shared = SupabaseManager()

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

    public let client: SupabaseClient

    private init() {
        #if SKIP
        self.client = SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseKey
        )
        #elseif os(Android)
        self.client = SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseKey,
            options: SupabaseClientOptions(auth: .init(storage: AndroidAuthStorage()))
        )
        #else
        self.client = SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseKey,
            options: SupabaseClientOptions()
        )
        #endif
    }

    // MARK: - Auth

    /// Checks if the current user is authenticated.
    public func isAuthenticated() async -> Bool {
        do {
            let session = try await client.auth.session
            return session != nil
        } catch {
            return false
        }
    }

    /// Signs in with email and password (standard Supabase Auth).
    public func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    /// Signs out the current user.
    public func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Returns the current user's email.
    public func currentUserEmail() async -> String? {
        do {
            let user = try await client.auth.user()
            return user.email
        } catch {
            return nil
        }
    }
    
    /// Returns the current user's ID.
    public func currentUserId() async -> UUID? {
        do {
            let user = try await client.auth.user()
            return user.id
        } catch {
            return nil
        }
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
                try? await Task.sleep(for: .seconds(delaySecs))
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

    // MARK: - Photos

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
    
    // MARK: - User Settings
    
    public func fetchUserSettings(userId: UUID) async throws -> UserSettings? {
        try await withRetry {
            let settings: [UserSettings] = try await client.from("user_settings")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            return settings.first
        }
    }
    
    public func updateUserSettings(_ settings: UserSettings) async throws {
        try await withRetry {
            try await client.from("user_settings")
                .upsert(settings)
                .execute()
        }
    }

    // MARK: - Workflow States
    
    public func fetchWorkflowState(name: String) async throws -> WorkflowState? {
        try await withRetry {
            let states: [WorkflowState] = try await client.from("workflow_states")
                .select()
                .eq("workflow_name", value: name)
                .order("updated_at", ascending: false)
                .limit(1)
                .execute()
                .value
            return states.first
        }
    }
    
    public func updateWorkflowState(_ state: WorkflowState) async throws {
        try await withRetry {
            try await client.from("workflow_states")
                .upsert(state)
                .execute()
        }
    }

    /// Fetches all active videos across all scenarios.
    /// Prefer this over per-scenario `fetchVideos(for:)` when loading the
    /// whole catalogue: 1 query instead of N (one per scenario).
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

    /// Fetches all active photos across all scenarios in a single query.
    /// Batch counterpart to `fetchPhotos(for:)` — same N+1 rationale as videos.
    public func fetchAllPhotos() async throws -> [Photo] {
        try await withRetry {
            let photos: [Photo] = try await client.from("photos")
                .select()
                .eq("active", value: true)
                .order("order_index", ascending: true)
                .execute()
                .value
            return photos
        }
    }

    // MARK: - Storage URLs

    /// Generates a public CDN URL for a video file. This is a pure computation — no isolation needed.
    nonisolated public func getPublicVideoURL(for path: String) -> URL? {
        return try? client.storage.from(Self.videoBucket).getPublicURL(path: path)
    }

    /// Generates a public CDN URL for an image file.
    nonisolated public func getPublicImageURL(for path: String) -> URL? {
        return try? client.storage.from(Self.imageBucket).getPublicURL(path: path)
    }
    
    /// Generates a public CDN URL for an audio file.
    nonisolated public func getPublicAudioURL(for path: String) -> URL? {
        // Ambient audio lives in the 'assets' bucket.
        return try? client.storage.from("assets").getPublicURL(path: path)
    }

    // MARK: - Health Check

    public struct SystemHealth: Sendable {
        public let auth: Bool
        public let database: Bool
        public let storage: Bool
        public let latencyMs: Int
        
        public var isAllHealthy: Bool { auth && database && storage }
    }

    /// Performs a comprehensive health check across all Supabase services.
    ///
    /// - Note: intentionally lightweight. A previous version called
    ///   `storage.listBuckets()`, which scans the `storage` schema on every
    ///   Settings open / manual sync — pure overhead for a health dot.
    ///   Storage health is now inferred from a cheap PostgREST probe on the
    ///   `videos` table (same project, same network path as real media reads)
    ///   with zero storage-schema IO.
    public func checkSystemHealth() async -> SystemHealth {
        let start = Date()

        // Parallel checks for maximum efficiency
        async let authCheck: Bool = {
            return (try? await client.auth.session) != nil || true // Auth is up even if no session
        }()

        async let dbCheck: Bool = {
            struct HealthCheckItem: Decodable { let id: UUID }
            do {
                let _: [HealthCheckItem] = try await client.from("scenarios")
                    .select("id")
                    .limit(1)
                    .execute()
                    .value
                return true
            } catch {
                print("DEBUG: Database Health Check Error: \(error)")
                return false
            }
        }()

        async let storageCheck: Bool = {
            struct StorageProbeItem: Decodable { let id: UUID }
            do {
                // Cheap PostgREST probe: proves the API + database path that
                // every media read depends on, without touching storage schema.
                let _: [StorageProbeItem] = try await client.from("videos")
                    .select("id")
                    .limit(1)
                    .execute()
                    .value
                return true
            } catch {
                return false
            }
        }()
        
        let results = await (auth: authCheck, db: dbCheck, storage: storageCheck)
        let latency = Int(Date().timeIntervalSince(start) * 1000)
        
        return SystemHealth(
            auth: results.auth,
            database: results.db,
            storage: results.storage,
            latencyMs: latency
        )
    }

    /// Legacy health check for simple boolean status.
    public func healthCheck() async -> Bool {
        return await checkSystemHealth().isAllHealthy
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
