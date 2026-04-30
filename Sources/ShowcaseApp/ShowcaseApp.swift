#if os(iOS) || os(macOS)
import SwiftUI
import ShowcaseCore
import ShowcaseUI

@main
struct ShowcaseApp: App {
    init() {
        // Configure URLCache for media caching
        let cacheSizeMemory = 50 * 1024 * 1024 // 50 MB
        let cacheSizeDisk = 200 * 1024 * 1024 // 200 MB
        let cache = URLCache(memoryCapacity: cacheSizeMemory, diskCapacity: cacheSizeDisk)
        URLCache.shared = cache
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainScreen(viewModel: createMainViewModel())
            }
            .navigationViewStyle(.stack)
        }
    }
    
    private func createMainViewModel() -> MainViewModel {
        let supabaseClient = SupabaseClient.shared
        let videoService = VideoService(supabaseClient: supabaseClient)
        return MainViewModel(videoService: videoService)
    }
}
#endif
