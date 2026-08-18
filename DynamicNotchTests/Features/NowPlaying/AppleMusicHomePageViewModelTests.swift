import XCTest
@testable import DynamicNotch

@MainActor
final class AppleMusicHomePageViewModelTests: XCTestCase {
    func testLoadsAppleMusicTrackWhenMonitoringStarts() async {
        let controller = FakeAppleMusicController(state: makeAppleMusicPlaybackState())
        let viewModel = AppleMusicHomePageViewModel(controller: controller)
        TestLifetime.retain(viewModel)

        viewModel.startMonitoring()
        try? await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertTrue(viewModel.isMusicRunning)
        XCTAssertTrue(viewModel.hasTrack)
        XCTAssertEqual(viewModel.snapshot?.title, "Blinding Lights")
        XCTAssertEqual(viewModel.snapshot?.artist, "The Weeknd")
        XCTAssertTrue(viewModel.snapshot?.isPlaying ?? false)
    }

    func testTogglePlayPauseSendsPauseWhenPlaying() async {
        let controller = FakeAppleMusicController(state: makeAppleMusicPlaybackState(isPlaying: true))
        let viewModel = AppleMusicHomePageViewModel(controller: controller)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()
        try? await Task.sleep(nanoseconds: 150_000_000)

        viewModel.togglePlayPause()

        XCTAssertEqual(controller.commands, [.pause])
        XCTAssertFalse(viewModel.snapshot?.isPlaying ?? true)
    }

    func testPlayWhenNothingIsLoadedSendsPlayAndOpensMusic() {
        var openCalls = 0
        let controller = FakeAppleMusicController(isMusicRunning: false, state: nil)
        let viewModel = AppleMusicHomePageViewModel(
            controller: controller,
            musicAppOpener: { openCalls += 1 }
        )
        TestLifetime.retain(viewModel)

        viewModel.play()
        viewModel.openMusic()

        XCTAssertEqual(controller.commands, [.play])
        XCTAssertEqual(openCalls, 2)
    }

    func testShowsEmptyStateWhenMusicIsNotRunning() async {
        let controller = FakeAppleMusicController(isMusicRunning: false, state: nil)
        let viewModel = AppleMusicHomePageViewModel(controller: controller)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()
        try? await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertFalse(viewModel.isMusicRunning)
        XCTAssertFalse(viewModel.hasTrack)
        XCTAssertNil(viewModel.snapshot)
    }
}

@MainActor
final class HomePageSettingsStoreTests: XCTestCase {
    func testResolvedMapsLegacyMediaPlayerPageToAppleMusic() {
        XCTAssertEqual(HomePages.resolved(from: "mediaPlayer"), .appleMusic)
        XCTAssertEqual(HomePages.resolved(from: "appleMusic"), .appleMusic)
        XCTAssertEqual(HomePages.resolved(from: "camera"), .camera)
        XCTAssertNil(HomePages.resolved(from: "vpn"))
        XCTAssertNil(HomePages.resolved(from: "unknown"))
    }

    func testDefaultOrderIncludesAppleMusic() {
        XCTAssertEqual(
            GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.homePageOrder] as? [String],
            ["camera", "appleMusic", "todos", "localTimer", "systemStats"]
        )
        XCTAssertTrue(HomePages.allCases.contains(.appleMusic))
        XCTAssertTrue(HomePages.allCases.contains(.todos))
    }
}
