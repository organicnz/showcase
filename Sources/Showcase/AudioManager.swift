import Foundation
import SkipAV
import Observation

#if canImport(AVFoundation)
import AVFoundation
#endif

/// Manages ambient background audio for scenarios.
@MainActor
@Observable public class AudioManager {
    public static let shared = AudioManager()
    
    private var player: AVPlayer?
    private var currentPath: String?
    
    private init() {}
    
    /// Plays ambient audio for a specific scenario.
    ///
    /// - Parameter path: The storage path or URL to the audio file.
    public func playAmbient(path: String?) {
        guard let path = path, !path.isEmpty else {
            stopAmbient()
            return
        }
        
        if currentPath == path { return }
        currentPath = path
        
        // In a real app, this would be a Supabase Storage URL
        // For demonstration, we'll use a stable ambient loop URL if the path matches our mocks
        let url: URL
        if path.contains("wellness") {
            url = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")! // Placeholder
        } else if path.contains("family") {
            url = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3")! // Placeholder
        } else {
            // Default ambient (very quiet)
            url = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3")! // Placeholder
        }
        
        #if canImport(AVFoundation)
        let playerItem = AVPlayerItem(url: url)
        if let player = player {
            player.replaceCurrentItem(with: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
        }
        
        player?.volume = 0.3 // Low volume for ambience
        player?.play()
        
        // Loop playback
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }
        #endif
    }
    
    /// Stops all ambient audio playback.
    public func stopAmbient() {
        player?.pause()
        player = nil
        currentPath = nil
    }
    
    /// Adjusts the volume of ambient audio.
    public func setVolume(_ volume: Float) {
        player?.volume = volume
    }
}
