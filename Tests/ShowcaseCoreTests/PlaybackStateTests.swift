import XCTest
@testable import ShowcaseCore

final class PlaybackStateTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func createMockVideo(id: UUID = UUID(), title: String = "Test Video") -> Video {
        Video(
            id: id,
            scenarioId: UUID(),
            title: title,
            storagePath: "test/video.mp4",
            orderIndex: 0
        )
    }
    
    // MARK: - currentVideo Tests
    
    func testCurrentVideoReturnsNilForIdleState() {
        let state = PlaybackState.idle
        XCTAssertNil(state.currentVideo)
    }
    
    func testCurrentVideoReturnsVideoForPlayingState() {
        let video = createMockVideo(title: "Playing Video")
        let queue = [video]
        let state = PlaybackState.playing(video: video, queue: queue, index: 0)
        
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
        XCTAssertEqual(state.currentVideo?.title, "Playing Video")
    }
    
    func testCurrentVideoReturnsVideoForPausedState() {
        let video = createMockVideo(title: "Paused Video")
        let queue = [video]
        let state = PlaybackState.paused(video: video, queue: queue, index: 0)
        
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
        XCTAssertEqual(state.currentVideo?.title, "Paused Video")
    }
    
    // MARK: - hasNext Tests
    
    func testHasNextReturnsFalseForIdleState() {
        let state = PlaybackState.idle
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextReturnsFalseForSingleVideoQueue() {
        let video = createMockVideo()
        let queue = [video]
        let state = PlaybackState.playing(video: video, queue: queue, index: 0)
        
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextReturnsTrueForFirstVideoInMultipleVideoQueue() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let video3 = createMockVideo(title: "Video 3")
        let queue = [video1, video2, video3]
        let state = PlaybackState.playing(video: video1, queue: queue, index: 0)
        
        XCTAssertTrue(state.hasNext)
    }
    
    func testHasNextReturnsTrueForMiddleVideoInQueue() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let video3 = createMockVideo(title: "Video 3")
        let queue = [video1, video2, video3]
        let state = PlaybackState.playing(video: video2, queue: queue, index: 1)
        
        XCTAssertTrue(state.hasNext)
    }
    
    func testHasNextReturnsFalseForLastVideoInQueue() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let video3 = createMockVideo(title: "Video 3")
        let queue = [video1, video2, video3]
        let state = PlaybackState.playing(video: video3, queue: queue, index: 2)
        
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextWorksForPausedState() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let queue = [video1, video2]
        let state = PlaybackState.paused(video: video1, queue: queue, index: 0)
        
        XCTAssertTrue(state.hasNext)
    }
    
    func testHasNextReturnsFalseForSingleVideoQueue() {
        let video = createMockVideo()
        let state = PlaybackState.playing(video: video, queue: [video], index: 0)

        XCTAssertFalse(state.hasNext)
    }

    // MARK: - State Transitions
    
    func testPlaybackStateTransitionsFromIdleToPlaying() {
        var state = PlaybackState.idle
        XCTAssertNil(state.currentVideo)
        XCTAssertFalse(state.hasNext)
        
        let video = createMockVideo()
        state = .playing(video: video, queue: [video], index: 0)
        
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
    }
    
    func testPlaybackStateTransitionsFromPlayingToPaused() {
        let video = createMockVideo()
        let queue = [video]
        var state = PlaybackState.playing(video: video, queue: queue, index: 0)
        
        XCTAssertNotNil(state.currentVideo)
        
        state = .paused(video: video, queue: queue, index: 0)
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
    }
    
    func testPlaybackStateTransitionsFromPausedToPlaying() {
        let video = createMockVideo()
        let queue = [video]
        var state = PlaybackState.paused(video: video, queue: queue, index: 0)
        
        state = .playing(video: video, queue: queue, index: 0)
        XCTAssertNotNil(state.currentVideo)
    }
    
    func testPlaybackStateBackToIdleDropsCurrentVideo() {
        let video = createMockVideo()
        var state = PlaybackState.playing(video: video, queue: [video], index: 0)
        
        state = .idle
        XCTAssertNil(state.currentVideo)
        XCTAssertFalse(state.hasNext)
    }
}

// MARK: - LoadState

/// `PlaybackState` once carried `.loading` and `.error` cases; both moved to
/// `LoadState` when playback state was narrowed to playback. These cover the
/// type that now owns that responsibility.
final class LoadStateTests: XCTestCase {

    func testIdleIsNotLoadingAndHasNoError() {
        let state = LoadState.idle

        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.error)
    }

    func testLoadingReportsLoading() {
        let state = LoadState.loading

        XCTAssertTrue(state.isLoading)
        XCTAssertNil(state.error)
    }

    func testLoadedIsNeitherLoadingNorFailed() {
        let state = LoadState.loaded

        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.error)
    }

    func testFailedExposesUnderlyingError() {
        let state = LoadState.failed(URLError(.notConnectedToInternet))

        XCTAssertFalse(state.isLoading)
        XCTAssertNotNil(state.error)
        XCTAssertEqual((state.error as? URLError)?.code, .notConnectedToInternet)
    }
}
