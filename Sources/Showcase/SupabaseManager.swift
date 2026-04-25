import Foundation
import SkipSupabase

@MainActor
public class SupabaseManager {
    public static let shared = SupabaseManager()
    
    public let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://smyfjmdjzfwdehynwfep.supabase.co")!,
            supabaseKey: "sb_publishable_36vglboOi9AkwTwCw_BqMg_uWQE8NV_"
        )
    }
    
    public func fetchScenarios() async throws -> [Scenario] {
        return try await client.from("scenarios")
            .select()
            .order("order_index", ascending: true)
            .execute()
            .value
    }
    
    public func fetchVideos(for scenarioId: UUID) async throws -> [Video] {
        return try await client.from("videos")
            .select()
            .eq("scenario_id", value: scenarioId)
            .order("order_index", ascending: true)
            .execute()
            .value
    }
    
    public func getPublicURL(for path: String) -> URL? {
        return try? client.storage.from("videos").getPublicURL(path: path)
    }
}
