import AppKit
import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published private(set) var snapshot: NowPlayingSnapshot?
    @Published private(set) var artworkImage: NSImage?
    @Published var event: NowPlayingEvent?

    private var service: any NowPlayingMonitoring
    private let pauseHideDelay: TimeInterval
    private var hasStartedMonitoring = false
    private var pauseHideTask: Task<Void, Never>?
    private var isNowPlayingVisible = false

    var hasActiveSession: Bool {
        isNowPlayingVisible
    }

    convenience init() {
        self.init(service: MediaRemoteNowPlayingService())
    }

    init(service: any NowPlayingMonitoring, pauseHideDelay: TimeInterval = 6) {
        self.service = service
        self.pauseHideDelay = pauseHideDelay
        self.service.onSnapshotChange = { [weak self] snapshot in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.apply(snapshot: snapshot)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.apply(snapshot: snapshot)
                }
            }
        }
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        service.startMonitoring()
    }

    func togglePlayPause() {
        if let snapshot {
            apply(snapshot: snapshot.togglingPlaybackState())
        }

        service.send(.togglePlayPause)
    }

    func nextTrack() {
        service.send(.nextTrack)
    }

    func previousTrack() {
        service.send(.previousTrack)
    }

    func seek(to elapsedTime: TimeInterval) {
        guard let snapshot, snapshot.duration > 0 else { return }

        let clampedElapsedTime = min(max(elapsedTime, 0), snapshot.duration)
        apply(snapshot: snapshot.settingElapsedTime(clampedElapsedTime))
        service.send(.seek(clampedElapsedTime))
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        snapshot?.elapsedTime(at: date) ?? 0
    }
}

private extension NowPlayingViewModel {
    func apply(snapshot newSnapshot: NowPlayingSnapshot?) {
        let wasVisible = isNowPlayingVisible
        let artworkDidChange = snapshot?.artworkData != newSnapshot?.artworkData

        snapshot = newSnapshot

        if artworkDidChange {
            artworkImage = newSnapshot?.artworkData.flatMap(NSImage.init(data:))
        }

        guard let newSnapshot else {
            cancelPauseHide()

            if wasVisible {
                isNowPlayingVisible = false
                event = .stopped
            }
            return
        }

        if newSnapshot.isPlaying {
            cancelPauseHide()

            if !wasVisible {
                isNowPlayingVisible = true
                event = .started
            } else {
                isNowPlayingVisible = true
            }
            return
        }

        if wasVisible {
            schedulePauseHide()
        }
    }

    func schedulePauseHide() {
        cancelPauseHide()

        pauseHideTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(
                nanoseconds: UInt64(pauseHideDelay * 1_000_000_000)
            )

            await MainActor.run {
                guard self.snapshot?.isPlaying == false else { return }
                guard self.isNowPlayingVisible else { return }

                self.isNowPlayingVisible = false
                self.event = .stopped
                self.pauseHideTask = nil
            }
        }
    }

    func cancelPauseHide() {
        pauseHideTask?.cancel()
        pauseHideTask = nil
    }
}

private extension NowPlayingSnapshot {
    func togglingPlaybackState() -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
            playbackRate: isPlaying ? 0 : 1,
            artworkData: artworkData,
            refreshedAt: .now
        )
    }

    func settingElapsedTime(_ newElapsedTime: TimeInterval) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: min(max(newElapsedTime, 0), duration > 0 ? duration : newElapsedTime),
            playbackRate: playbackRate,
            artworkData: artworkData,
            refreshedAt: .now
        )
    }
}
