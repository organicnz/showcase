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
    
    /// Plays ambient audio for a specific scenario with a smooth fade-in.
    /// The `path` parameter comes from the scenario's `ambient_audio_path` field in the database.
    public func playAmbient(path: String?) {
        guard let path = path, !path.isEmpty else {
            stopAmbient()
            return
        }
        
        if currentPath == path { return }
        let oldPath = currentPath
        currentPath = path
        
        // Resolve the storage URL from the DB-driven path via SupabaseManager
        guard let url = SupabaseManager.shared.getPublicVideoURL(for: path) else {
            logger.error("AudioManager: Could not resolve URL for ambient path: \(path)")
            return
        }
        
        #if canImport(AVFoundation)
        let playerItem = AVPlayerItem(url: url)
        
        Task {
            // Fade out old track if switching
            if oldPath != nil {
                await fade(to: 0.0, duration: 1.0)
            }
            
            if let player = player {
                player.replaceCurrentItem(with: playerItem)
            } else {
                player = AVPlayer(playerItem: playerItem)
            }
            
            player?.volume = 0
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
            
            // Fade in new track
            await fade(to: 0.3, duration: 2.0)
        }
        #endif
    }
    
    /// Stops all ambient audio playback with a smooth fade-out.
    public func stopAmbient() {
        Task {
            await fade(to: 0.0, duration: 1.5)
            player?.pause()
            player = nil
            currentPath = nil
        }
    }
    
    /// Ramps volume smoothly over a duration.
    private func fade(to targetVolume: Float, duration: Double) async {
        guard let player = player else { return }
        let startVolume = player.volume
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = (targetVolume - startVolume) / Float(steps)
        
        for _ in 0..<steps {
            player.volume += volumeStep
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        player.volume = targetVolume
    }
    
    /// Adjusts the volume of ambient audio.
    public func setVolume(_ volume: Float) {
        player?.volume = volume
    }
}
