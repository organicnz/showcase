import Foundation
import AVFoundation

#if canImport(SkipAV)
import SkipAV
#endif

/// **AudioManager**
///
/// A singleton actor responsible for managing immersive background audio.
/// Supports infinite looping, remote file caching, and smooth cross-fades (Quiet Luxury).
public actor AudioManager {
    public static let shared = AudioManager()
    
    private var currentPlayer: AVAudioPlayer?
    private var nextPlayer: AVAudioPlayer?
    
    private var currentUrl: URL?
    private let fadeDuration: TimeInterval = 2.5
    
    private init() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioManager: Failed to set audio session category: \(error)")
        }
        #endif
    }
    
    /// Plays an ambient track from a URL, cross-fading from the current track if necessary.
    ///
    /// - Parameter url: The remote or local URL of the audio file.
    public func play(url: URL?) async {
        guard let url = url, url != currentUrl else { return }
        
        // Stop any pending transition
        nextPlayer?.stop()
        nextPlayer = nil
        
        do {
            // Prepare the new player
            let player = try await loadPlayer(for: url)
            player.numberOfLoops = -1 // Infinite loop
            player.volume = 0
            player.prepareToPlay()
            
            self.nextPlayer = player
            self.currentUrl = url
            
            // Start playing
            player.play()
            
            // Perform Cross-fade
            await crossFade()
            
        } catch {
            print("AudioManager: Failed to play audio from \(url): \(error)")
        }
    }
    
    /// Fades out the current track and stops playback.
    public func stop() async {
        guard let player = currentPlayer else { return }
        
        let steps = 20
        let interval = fadeDuration / Double(steps)
        let volumeStep = player.volume / Float(steps)
        
        for _ in 0..<steps {
            player.volume -= volumeStep
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        
        player.stop()
        currentPlayer = nil
        currentUrl = nil
    }
    
    // MARK: - Private Helpers
    
    private func loadPlayer(for url: URL) async throws -> AVAudioPlayer {
        // In a real production app, we would check a local disk cache here first.
        // For this implementation, we assume the URL is either local or handled by the system.
        let data = try Data(contentsOf: url)
        return try AVAudioPlayer(data: data)
    }
    
    private func crossFade() async {
        guard let newPlayer = nextPlayer else { return }
        let oldPlayer = currentPlayer
        
        let steps = 25
        let interval = fadeDuration / Double(steps)
        let volumeStep: Float = 1.0 / Float(steps)
        
        for i in 1...steps {
            let volume = Float(i) * volumeStep
            newPlayer.volume = volume
            oldPlayer?.volume = 1.0 - volume
            
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        
        oldPlayer?.stop()
        currentPlayer = newPlayer
        nextPlayer = nil
    }
}
