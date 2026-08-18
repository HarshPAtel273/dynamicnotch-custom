import Combine
import CoreAudio
import Foundation

@MainActor
final class SystemAudioHomePageViewModel: ObservableObject {
    @Published private(set) var volume: Double = 0
    @Published private(set) var isMuted = false
    @Published private(set) var deviceName: String?
    @Published private(set) var routes: [AudioOutputRoute] = []
    @Published private(set) var currentRoute: AudioOutputRoute?

    private let volumeService: any SystemAudioVolumeControlling
    private let routing: any AudioOutputRouting
    private var pollTask: Task<Void, Never>?

    var volumeSymbolName: String {
        if isMuted || volume < 0.001 {
            return "speaker.slash.fill"
        }
        if volume < 0.33 {
            return "speaker.wave.1.fill"
        }
        if volume < 0.66 {
            return "speaker.wave.2.fill"
        }
        return "speaker.wave.3.fill"
    }

    init(
        volumeService: (any SystemAudioVolumeControlling)? = nil,
        routing: (any AudioOutputRouting)? = nil
    ) {
        self.volumeService = volumeService ?? SystemAudioVolumeService()
        self.routing = routing ?? SystemAudioOutputRoutingService()
        refresh()
    }

    func startMonitoring() {
        guard pollTask == nil else { return }

        refresh()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        pollTask?.cancel()
        pollTask = nil
    }

    func setVolume(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        _ = volumeService.setVolume(Float(clamped))
        refresh()
    }

    func toggleMute() {
        _ = volumeService.toggleMute()
        refresh()
    }

    func switchOutput(to route: AudioOutputRoute) {
        _ = routing.setCurrentRoute(route.id)
        refresh()
    }

    func refresh() {
        volume = Double(volumeService.currentEffectiveVolume)
        isMuted = volumeService.isMuted
        deviceName = volumeService.currentDeviceName
        routes = routing.availableRoutes()
        currentRoute = routing.currentRoute() ?? routes.first(where: \.isCurrent)
    }

    deinit {
        pollTask?.cancel()
    }
}
