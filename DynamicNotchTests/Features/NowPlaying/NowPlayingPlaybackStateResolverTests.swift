import XCTest
@testable import DynamicNotch

final class NowPlayingPlaybackStateResolverTests: XCTestCase {
    func testFrozenElapsedTimeWhilePlaybackRateStaysPositiveIsTreatedAsPaused() {
        var resolver = NowPlayingPlaybackStateResolver(
            stagnantElapsedTolerance: 0.05,
            stagnantObservationDelay: 1.1
        )
        let start = Date(timeIntervalSince1970: 100)

        let playing = makeNowPlayingSnapshot(
            elapsedTime: 42,
            playbackRate: 1,
            refreshedAt: start
        )
        let stalled = makeNowPlayingSnapshot(
            elapsedTime: 42,
            playbackRate: 1,
            refreshedAt: start.addingTimeInterval(1.3)
        )

        XCTAssertEqual(resolver.resolve(playing)?.playbackRate, 1)
        XCTAssertEqual(resolver.resolve(stalled)?.playbackRate, 0)
    }

    func testAdvancingElapsedTimeKeepsPlaybackActive() {
        var resolver = NowPlayingPlaybackStateResolver(
            stagnantElapsedTolerance: 0.05,
            stagnantObservationDelay: 1.1
        )
        let start = Date(timeIntervalSince1970: 200)

        let first = makeNowPlayingSnapshot(
            elapsedTime: 42,
            playbackRate: 1,
            refreshedAt: start
        )
        let progressed = makeNowPlayingSnapshot(
            elapsedTime: 43.1,
            playbackRate: 1,
            refreshedAt: start.addingTimeInterval(1.3)
        )

        XCTAssertEqual(resolver.resolve(first)?.playbackRate, 1)
        XCTAssertEqual(resolver.resolve(progressed)?.playbackRate, 1)
    }

    func testTrackChangeDoesNotForcePauseOnSameElapsedTime() {
        var resolver = NowPlayingPlaybackStateResolver(
            stagnantElapsedTolerance: 0.05,
            stagnantObservationDelay: 1.1
        )
        let start = Date(timeIntervalSince1970: 300)

        let first = makeNowPlayingSnapshot(
            title: "Voice Message 1",
            elapsedTime: 12,
            playbackRate: 1,
            refreshedAt: start
        )
        let nextTrack = makeNowPlayingSnapshot(
            title: "Voice Message 2",
            elapsedTime: 12,
            playbackRate: 1,
            refreshedAt: start.addingTimeInterval(1.3)
        )

        XCTAssertEqual(resolver.resolve(first)?.playbackRate, 1)
        XCTAssertEqual(resolver.resolve(nextTrack)?.playbackRate, 1)
    }
}
