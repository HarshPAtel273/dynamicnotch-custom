internal import AppKit
import Combine
import Foundation

@MainActor
final class AppleMusicHomePageViewModel: ObservableObject {
    @Published private(set) var snapshot: NowPlayingSnapshot?
    @Published private(set) var artworkImage: NSImage?
    @Published private(set) var artworkPalette = NowPlayingArtworkPalette.fallback
    @Published private(set) var isMusicRunning = false

    private let controller: any AppleMusicControlling
    private let musicAppOpener: () -> Void
    private var pollTask: Task<Void, Never>?
    private var playerInfoObserver: NSObjectProtocol?
    private var lastArtworkTrackKey: String?

    var hasTrack: Bool {
        snapshot?.hasVisibleMetadata == true
    }

    init(
        controller: (any AppleMusicControlling)? = nil,
        musicAppOpener: (() -> Void)? = nil
    ) {
        let resolvedController = controller ?? NowPlayingApplicationBridge()
        self.controller = resolvedController
        self.musicAppOpener = musicAppOpener ?? {
            resolvedController.openMusicApp()
        }
    }

    func startMonitoring() {
        guard pollTask == nil else { return }

        isMusicRunning = controller.isMusicRunning
        startPlayerInfoObserver()
        Task { [weak self] in
            await self?.refresh(forceArtwork: true)
        }

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_250_000_000)
                await self?.refresh(forceArtwork: false)
            }
        }
    }

    func stopMonitoring() {
        pollTask?.cancel()
        pollTask = nil
        stopPlayerInfoObserver()
    }

    func togglePlayPause() {
        guard hasTrack else {
            play()
            return
        }

        let command: NowPlayingCommand = snapshot?.isPlaying == true ? .pause : .play
        if let snapshot {
            apply(snapshot.withPlaybackRate(snapshot.isPlaying ? 0 : 1))
        }

        _ = controller.send(command)
        refreshSoon()
    }

    func play() {
        if !controller.isMusicRunning {
            openMusic()
        }

        if let snapshot, !snapshot.isPlaying {
            apply(snapshot.withPlaybackRate(1))
        }

        _ = controller.send(.play)
        refreshSoon()
    }

    func pause() {
        if let snapshot, snapshot.isPlaying {
            apply(snapshot.withPlaybackRate(0))
        }

        _ = controller.send(.pause)
        refreshSoon()
    }

    func nextTrack() {
        _ = controller.send(.nextTrack)
        refreshSoon()
    }

    func previousTrack() {
        _ = controller.send(.previousTrack)
        refreshSoon()
    }

    func seek(to elapsedTime: TimeInterval) {
        if let snapshot {
            apply(snapshot.withElapsedTime(elapsedTime))
        }

        _ = controller.send(.seek(elapsedTime))
        refreshSoon()
    }

    func openMusic() {
        musicAppOpener()
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        snapshot?.elapsedTime(at: date) ?? 0
    }

    deinit {
        pollTask?.cancel()
        if let playerInfoObserver {
            DistributedNotificationCenter.default().removeObserver(playerInfoObserver)
        }
    }
}

private extension AppleMusicHomePageViewModel {
    func startPlayerInfoObserver() {
        guard playerInfoObserver == nil else { return }

        playerInfoObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh(forceArtwork: true)
            }
        }
    }

    func stopPlayerInfoObserver() {
        if let playerInfoObserver {
            DistributedNotificationCenter.default().removeObserver(playerInfoObserver)
        }

        playerInfoObserver = nil
    }

    func refreshSoon() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            await self?.refresh(forceArtwork: true)
        }
    }

    func refresh(forceArtwork: Bool) async {
        isMusicRunning = controller.isMusicRunning

        guard isMusicRunning else {
            apply(nil)
            lastArtworkTrackKey = nil
            return
        }

        let state = await controller.playbackState()
        let nextSnapshot = state?.asNowPlayingSnapshot(
            artworkData: snapshot?.artworkData,
            processIdentifier: snapshot?.playbackSource?.processIdentifier
        )

        guard let state, let nextSnapshot else {
            apply(nil)
            lastArtworkTrackKey = nil
            return
        }

        var resolvedSnapshot = nextSnapshot
        let shouldLoadArtwork = forceArtwork || lastArtworkTrackKey != state.trackKey

        if shouldLoadArtwork, let artworkData = await controller.artworkData() {
            resolvedSnapshot = nextSnapshot.withArtwork(artworkData)
            lastArtworkTrackKey = state.trackKey
        }

        apply(resolvedSnapshot)
    }

    func apply(_ snapshot: NowPlayingSnapshot?) {
        let artworkChanged = self.snapshot?.artworkData != snapshot?.artworkData
        self.snapshot = snapshot

        if artworkChanged {
            artworkImage = snapshot?.artworkData.flatMap { NSImage(data: $0) }
            artworkPalette = NowPlayingArtworkPaletteExtractor.extract(from: snapshot?.artworkData)
        } else if snapshot == nil {
            artworkImage = nil
            artworkPalette = .fallback
        }
    }
}

private extension NowPlayingSnapshot {
    func withPlaybackRate(_ playbackRate: Double) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
            playbackRate: playbackRate,
            artworkData: artworkData,
            playbackSource: playbackSource,
            mediaType: mediaType,
            contentItemIdentifier: contentItemIdentifier,
            isShuffled: isShuffled,
            repeatMode: repeatMode,
            volume: volume,
            isFavorite: isFavorite,
            supportsFavorite: supportsFavorite,
            supportsVolumeControl: supportsVolumeControl,
            refreshedAt: .now
        )
    }

    func withElapsedTime(_ elapsedTime: TimeInterval) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: max(0, elapsedTime),
            playbackRate: playbackRate,
            artworkData: artworkData,
            playbackSource: playbackSource,
            mediaType: mediaType,
            contentItemIdentifier: contentItemIdentifier,
            isShuffled: isShuffled,
            repeatMode: repeatMode,
            volume: volume,
            isFavorite: isFavorite,
            supportsFavorite: supportsFavorite,
            supportsVolumeControl: supportsVolumeControl,
            refreshedAt: .now
        )
    }

    func withArtwork(_ artworkData: Data?) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime,
            playbackRate: playbackRate,
            artworkData: artworkData,
            playbackSource: playbackSource,
            mediaType: mediaType,
            contentItemIdentifier: contentItemIdentifier,
            isShuffled: isShuffled,
            repeatMode: repeatMode,
            volume: volume,
            isFavorite: isFavorite,
            supportsFavorite: supportsFavorite,
            supportsVolumeControl: supportsVolumeControl,
            refreshedAt: refreshedAt
        )
    }
}
