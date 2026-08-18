import CoreAudio
import XCTest
@testable import DynamicNotch

@MainActor
final class SystemAudioHomePageViewModelTests: XCTestCase {
    func testReadsSystemVolumeAndOutputRoute() {
        let speakers = AudioOutputRoute(
            id: AudioDeviceID(7),
            name: "MacBook Speakers",
            transportType: kAudioDeviceTransportTypeBuiltIn,
            isCurrent: true
        )
        let viewModel = SystemAudioHomePageViewModel(
            volumeService: FakeSystemAudioVolumeService(volume: 0.4, currentDeviceName: "MacBook Speakers"),
            routing: FakeAudioOutputRoutingService(routes: [speakers])
        )
        TestLifetime.retain(viewModel)

        XCTAssertEqual(viewModel.volume, 0.4, accuracy: 0.001)
        XCTAssertFalse(viewModel.isMuted)
        XCTAssertEqual(viewModel.currentRoute?.name, "MacBook Speakers")
        XCTAssertEqual(viewModel.volumeSymbolName, "speaker.wave.2.fill")
    }

    func testSetVolumeUpdatesEffectiveLevel() {
        let volumeService = FakeSystemAudioVolumeService(volume: 0.2)
        let viewModel = SystemAudioHomePageViewModel(
            volumeService: volumeService,
            routing: FakeAudioOutputRoutingService()
        )
        TestLifetime.retain(viewModel)

        viewModel.setVolume(0.8)

        XCTAssertEqual(volumeService.volume, 0.8, accuracy: 0.001)
        XCTAssertEqual(viewModel.volume, 0.8, accuracy: 0.001)
        XCTAssertFalse(viewModel.isMuted)
    }

    func testToggleMuteSilencesSystemAudio() {
        let volumeService = FakeSystemAudioVolumeService(volume: 0.6)
        let viewModel = SystemAudioHomePageViewModel(
            volumeService: volumeService,
            routing: FakeAudioOutputRoutingService()
        )
        TestLifetime.retain(viewModel)

        viewModel.toggleMute()

        XCTAssertTrue(viewModel.isMuted)
        XCTAssertEqual(viewModel.volume, 0, accuracy: 0.001)
        XCTAssertEqual(viewModel.volumeSymbolName, "speaker.slash.fill")
    }

    func testSwitchOutputChangesCurrentRoute() {
        let speakers = AudioOutputRoute(
            id: AudioDeviceID(7),
            name: "MacBook Speakers",
            transportType: kAudioDeviceTransportTypeBuiltIn,
            isCurrent: true
        )
        let headphones = AudioOutputRoute(
            id: AudioDeviceID(11),
            name: "AirPods",
            transportType: kAudioDeviceTransportTypeBluetooth,
            isCurrent: false
        )
        let routing = FakeAudioOutputRoutingService(routes: [speakers, headphones])
        let viewModel = SystemAudioHomePageViewModel(
            volumeService: FakeSystemAudioVolumeService(),
            routing: routing
        )
        TestLifetime.retain(viewModel)

        viewModel.switchOutput(to: headphones)

        XCTAssertEqual(routing.selectedRouteIDs, [headphones.id])
        XCTAssertEqual(viewModel.currentRoute?.name, "AirPods")
    }
}
