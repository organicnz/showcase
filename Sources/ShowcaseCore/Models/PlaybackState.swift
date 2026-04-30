import Foundation

/// Represents the current playback state of the video player
public enum PlaybackState: Sendable {
    case idle
    case loading
    case playing(video: Video, queue: [Video], currentIndex: Int)
    case paused(video: Video, queue: [Video], currentIndex: Int)
    case error(message: String)
    
    /// Returns the currently playing or paused video, if any
    public var currentVideo: Video? {
        switch self {
        case .playing(let video, _, _), .paused(let video, _, _):
            return video
        default:
            return nil
        }
    }
    
    /// Returns true if there is a next video in the queue
    public var hasNext: Bool {
        switch self {
        case .playing(_, let queue, let index), .paused(_, let queue, let index):
            return index < queue.count - 1
        default:
            return false
        }
    }
}
