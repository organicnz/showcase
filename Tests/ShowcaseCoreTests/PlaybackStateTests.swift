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
    
    func testCurrentVideoReturnsNilForLoadingState() {
        let state = PlaybackState.loading
        XCTAssertNil(state.currentVideo)
    }
    
    func testCurrentVideoReturnsNilForErrorState() {
        let state = PlaybackState.error(message: "Test error")
        XCTAssertNil(state.currentVideo)
    }
    
    func testCurrentVideoReturnsVideoForPlayingState() {
        let video = createMockVideo(title: "Playing Video")
        let queue = [video]
        let state = PlaybackState.playing(video: video, queue: queue, currentIndex: 0)
        
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
        XCTAssertEqual(state.currentVideo?.title, "Playing Video")
    }
    
    func testCurrentVideoReturnsVideoForPausedState() {
        let video = createMockVideo(title: "Paused Video")
        let queue = [video]
        let state = PlaybackState.paused(video: video, queue: queue, currentIndex: 0)
        
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
        XCTAssertEqual(state.currentVideo?.title, "Paused Video")
    }
    
    // MARK: - hasNext Tests
    
    func testHasNextReturnsFalseForIdleState() {
        let state = PlaybackState.idle
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextReturnsFalseForLoadingState() {
        let state = PlaybackState.loading
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextReturnsFalseForErrorState() {
        let state = PlaybackState.error(message: "Test error")
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextReturnsFalseForSingleVideoQueue() {
        let video = createMockVideo()
        let queue = [video]
        let state = PlaybackState.playing(video: video, queue: queue, currentIndex: 0)
        
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextReturnsTrueForFirstVideoInMultipleVideoQueue() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let video3 = createMockVideo(title: "Video 3")
        let queue = [video1, video2, video3]
        let state = PlaybackState.playing(video: video1, queue: queue, currentIndex: 0)
        
        XCTAssertTrue(state.hasNext)
    }
    
    func testHasNextReturnsTrueForMiddleVideoInQueue() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let video3 = createMockVideo(title: "Video 3")
        let queue = [video1, video2, video3]
        let state = PlaybackState.playing(video: video2, queue: queue, currentIndex: 1)
        
        XCTAssertTrue(state.hasNext)
    }
    
    func testHasNextReturnsFalseForLastVideoInQueue() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let video3 = createMockVideo(title: "Video 3")
        let queue = [video1, video2, video3]
        let state = PlaybackState.playing(video: video3, queue: queue, currentIndex: 2)
        
        XCTAssertFalse(state.hasNext)
    }
    
    func testHasNextWorksForPausedState() {
        let video1 = createMockVideo(title: "Video 1")
        let video2 = createMockVideo(title: "Video 2")
        let queue = [video1, video2]
        let state = PlaybackState.paused(video: video1, queue: queue, currentIndex: 0)
        
        XCTAssertTrue(state.hasNext)
    }
    
    // MARK: - State Transitions
    
    func testPlaybackStateTransitionsFromIdleToLoading() {
        var state = PlaybackState.idle
        XCTAssertNil(state.currentVideo)
        
        state = .loading
        XCTAssertNil(state.currentVideo)
    }
    
    func testPlaybackStateTransitionsFromLoadingToPlaying() {
        var state = PlaybackState.loading
        
        let video = createMockVideo()
        let queue = [video]
        state = .playing(video: video, queue: queue, currentIndex: 0)
        
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
    }
    
    func testPlaybackStateTransitionsFromPlayingToPaused() {
        let video = createMockVideo()
        let queue = [video]
        var state = PlaybackState.playing(video: video, queue: queue, currentIndex: 0)
        
        XCTAssertNotNil(state.currentVideo)
        
        state = .paused(video: video, queue: queue, currentIndex: 0)
        XCTAssertNotNil(state.currentVideo)
        XCTAssertEqual(state.currentVideo?.id, video.id)
    }
    
    func testPlaybackStateTransitionsFromPausedToPlaying() {
        let video = createMockVideo()
        let queue = [video]
        var state = PlaybackState.paused(video: video, queue: queue, currentIndex: 0)
        
        state = .playing(video: video, queue: queue, currentIndex: 0)
        XCTAssertNotNil(state.currentVideo)
    }
    
    func testPlaybackStateTransitionsToError() {
        var state = PlaybackState.loading
        
        state = .error(message: "Network error")
        XCTAssertNil(state.currentVideo)
        XCTAssertFalse(state.hasNext)
    }
}
