import Foundation
import Observation
#if os(iOS) || os(macOS)
import AVFoundation
#endif
import SkipAV

/// Player screen view model managing playback state
@Observable
public final class PlayerViewModel {
    public private(set) var playbackState: PlaybackState = .idle
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0
    
    public private(set) var player: AVPlayer?
    private var timeObserver: Any?
    
    public init() {}
    
    @MainActor
    public func startPlayback(videos: [Video]) {
        guard !videos.isEmpty else {
            playbackState = .error(message: "No videos to play")
            return
        }
        
        playbackState = .loading
        playVideo(at: 0, in: videos)
    }
    
    @MainActor
    private func playVideo(at index: Int, in queue: [Video]) {
        guard index < queue.count else {
            playbackState = .idle
            return
        }
        
        let video = queue[index]
        guard let url = video.videoURL else {
            playbackState = .error(message: "Invalid video URL")
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        #if os(iOS) || os(macOS)
        // Observe playback completion
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.playNext()
            }
        }
        #endif
        
        player?.play()
        playbackState = .playing(video: video, queue: queue, currentIndex: index)
    }
    
    @MainActor
    public func playNext() {
        guard case .playing(_, let queue, let index) = playbackState else { return }
        let nextIndex = index + 1
        
        if nextIndex < queue.count {
            playVideo(at: nextIndex, in: queue)
        } else {
            playbackState = .idle
        }
    }
    
    @MainActor
    public func pause() {
        player?.pause()
        if case .playing(let video, let queue, let index) = playbackState {
            playbackState = .paused(video: video, queue: queue, currentIndex: index)
        }
    }
    
    @MainActor
    public func resume() {
        player?.play()
        if case .paused(let video, let queue, let index) = playbackState {
            playbackState = .playing(video: video, queue: queue, currentIndex: index)
        }
    }
    
    @MainActor
    public func stop() {
        player?.pause()
        player = nil
        playbackState = .idle
    }
    
    @MainActor
    public func handlePlaybackError(_ error: Error) {
        Logger.error("Playback error", error: error)
        
        // Skip to next video on error
        if case .playing(_, let queue, let index) = playbackState {
            let nextIndex = index + 1
            if nextIndex < queue.count {
                playVideo(at: nextIndex, in: queue)
            } else {
                playbackState = .error(message: "Unable to play video")
            }
        }
    }
}
