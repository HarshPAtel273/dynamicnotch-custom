import SwiftUI
internal import AppKit

struct AppleMusicHomePageNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @StateObject private var appleMusicViewModel = AppleMusicHomePageViewModel()
    @StateObject private var systemAudioViewModel = SystemAudioHomePageViewModel()
    @State private var scrubProgress: CGFloat?
    @State private var scrubVolume: Double?

    private let detailedPresentationSource = "homePage.music"

    private var usesSystemNowPlaying: Bool {
        nowPlayingViewModel.hasActiveSession
    }

    private var snapshot: NowPlayingSnapshot? {
        usesSystemNowPlaying ? nowPlayingViewModel.snapshot : appleMusicViewModel.snapshot
    }

    private var hasTrack: Bool {
        snapshot?.hasVisibleMetadata == true
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                if hasTrack, let snapshot {
                    playerView(snapshot: snapshot)
                } else {
                    emptyStateView
                }

                systemAudioControls
            }
        }
        .padding(.horizontal, isDynamicIsland ? 2 : 4)
        .onAppear {
            appleMusicViewModel.startMonitoring()
            systemAudioViewModel.startMonitoring()
            nowPlayingViewModel.refreshAudioOutputRoutes()
            nowPlayingViewModel.setDetailedPresentationActive(true, source: detailedPresentationSource)
        }
        .onDisappear {
            appleMusicViewModel.stopMonitoring()
            systemAudioViewModel.stopMonitoring()
            nowPlayingViewModel.setDetailedPresentationActive(false, source: detailedPresentationSource)
        }
    }

    @ViewBuilder
    private func playerView(snapshot: NowPlayingSnapshot) -> some View {
        TimelineView(.periodic(from: .now, by: snapshot.isPlaying ? 1.0 : 30.0)) { context in
            let elapsedTime = usesSystemNowPlaying
                ? nowPlayingViewModel.elapsedTime(at: context.date)
                : appleMusicViewModel.elapsedTime(at: context.date)
            let progress = progressValue(elapsedTime: elapsedTime, duration: snapshot.duration)
            let displayedProgress = min(max(scrubProgress ?? progress, 0), 1)
            let displayedElapsedTime = snapshot.duration > 0
                ? TimeInterval(displayedProgress) * snapshot.duration
                : elapsedTime

            VStack(spacing: 8) {
                header(snapshot: snapshot)

                PlayerProgressBar(
                    progress: displayedProgress,
                    displayedElapsedTime: displayedElapsedTime,
                    duration: snapshot.duration,
                    isInteractive: snapshot.duration > 0,
                    tintGradient: LinearGradient(
                        colors: [
                            Color(nsColor: artworkPalette.equalizerHighlightColor),
                            Color(nsColor: artworkPalette.equalizerBaseColor)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    primaryColor: .white.opacity(0.45),
                    secondaryColor: .white.opacity(0.35),
                    onScrubChanged: { newProgress in
                        scrubProgress = newProgress
                    },
                    onScrubEnded: { newProgress in
                        seek(to: snapshot.duration * TimeInterval(newProgress))
                        scrubProgress = nil
                    }
                )

                playbackControls(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private func header(snapshot: NowPlayingSnapshot) -> some View {
        HStack(spacing: 10) {
            Button(action: openPlaybackSource) {
                artwork
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                MarqueeText(
                    .constant(displayTitle(for: snapshot)),
                    font: .system(size: 16, weight: .medium),
                    nsFont: .headline,
                    textColor: .white.opacity(0.8),
                    backgroundColor: .clear,
                    minDuration: 2.0,
                    frameWidth: 140
                )

                MarqueeText(
                    .constant(displayArtist(for: snapshot)),
                    font: .system(size: 12),
                    nsFont: .body,
                    textColor: .white.opacity(0.5),
                    backgroundColor: .clear,
                    minDuration: 3.0,
                    frameWidth: 140
                )
            }

            Spacer()

            LightweightNowPlayingEqualizerView(
                isPlaying: snapshot.isPlaying,
                colors: [
                    artworkPalette.equalizerHighlightColor,
                    artworkPalette.equalizerBaseColor
                ],
                barHeight: 20,
                barWidth: 2.4
            )
            .frame(width: 20, height: 18)
        }
        .padding(.horizontal, 4)
    }

    private var artwork: some View {
        Group {
            if let artworkImage = displayedArtworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
            } else if let musicIcon = musicAppIcon {
                Image(nsImage: musicIcon)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.14, blue: 0.31).opacity(0.85))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func playbackControls(snapshot: NowPlayingSnapshot) -> some View {
        HStack(spacing: 18) {
            PlayerControlButton(
                systemImage: "backward.fill",
                fontSize: 18,
                width: 34,
                height: 34,
                feedbackStyle: .backward
            ) {
                previousTrack()
            }

            PlayerControlButton(
                systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
                fontSize: 24,
                width: 34,
                height: 34,
                feedbackStyle: .playPause
            ) {
                togglePlayPause()
            }

            PlayerControlButton(
                systemImage: "forward.fill",
                fontSize: 18,
                width: 34,
                height: 34,
                feedbackStyle: .forward
            ) {
                nextTrack()
            }

            Spacer(minLength: 8)

            outputPicker
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            if let musicIcon = musicAppIcon {
                Image(nsImage: musicIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            } else {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(red: 0.98, green: 0.14, blue: 0.31))
            }

            Text(verbatim: "Nothing Playing")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(verbatim: "System audio still works below.")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.7))
                .lineLimit(1)

            HStack(spacing: 8) {
                Button(action: appleMusicViewModel.play) {
                    Text(verbatim: appleMusicViewModel.isMusicRunning ? "Play Music" : "Open Apple Music")
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .buttonStyle(
                    PrimaryButtonStyle(
                        height: 30,
                        backgroundColor: Color(red: 0.98, green: 0.14, blue: 0.31).opacity(0.85)
                    )
                )

                outputPicker
            }
        }
        .padding(.horizontal, 8)
    }

    private var systemAudioControls: some View {
        HStack(spacing: 8) {
            Button(action: systemAudioViewModel.toggleMute) {
                Image(systemName: systemAudioViewModel.volumeSymbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            GeometryReader { proxy in
                let displayedVolume = min(max(scrubVolume ?? systemAudioViewModel.volume, 0), 1)
                let trackHeight: CGFloat = 7
                let filledWidth = proxy.size.width * displayedVolume

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.15))
                        .frame(height: trackHeight)

                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.7))
                        .frame(width: filledWidth, height: trackHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let nextVolume = min(max(value.location.x / max(proxy.size.width, 1), 0), 1)
                            scrubVolume = nextVolume
                            systemAudioViewModel.setVolume(nextVolume)
                        }
                        .onEnded { _ in
                            scrubVolume = nil
                            systemAudioViewModel.refresh()
                        }
                )
            }
            .frame(height: 16)

            Text(systemAudioViewModel.currentRoute?.name ?? systemAudioViewModel.deviceName ?? "System")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .frame(maxWidth: 72, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var outputPicker: some View {
        Menu {
            if systemAudioViewModel.routes.isEmpty {
                Text(verbatim: "No audio outputs available")
            } else {
                ForEach(systemAudioViewModel.routes) { route in
                    Button {
                        systemAudioViewModel.switchOutput(to: route)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: route.systemImageName)
                            Text(route.name)
                            if route.isCurrent {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: systemAudioViewModel.currentRoute?.systemImageName ?? "speaker.wave.2.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.white.opacity(0.1))
                )
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
    }

    private var displayedArtworkImage: NSImage? {
        usesSystemNowPlaying ? nowPlayingViewModel.artworkImage : appleMusicViewModel.artworkImage
    }

    private var artworkPalette: NowPlayingArtworkPalette {
        usesSystemNowPlaying ? nowPlayingViewModel.artworkPalette : appleMusicViewModel.artworkPalette
    }

    private var musicAppIcon: NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func togglePlayPause() {
        if usesSystemNowPlaying {
            nowPlayingViewModel.togglePlayPause()
        } else {
            appleMusicViewModel.togglePlayPause()
        }
    }

    private func previousTrack() {
        if usesSystemNowPlaying {
            nowPlayingViewModel.previousTrack()
        } else {
            appleMusicViewModel.previousTrack()
        }
    }

    private func nextTrack() {
        if usesSystemNowPlaying {
            nowPlayingViewModel.nextTrack()
        } else {
            appleMusicViewModel.nextTrack()
        }
    }

    private func seek(to elapsedTime: TimeInterval) {
        if usesSystemNowPlaying {
            nowPlayingViewModel.seek(to: elapsedTime)
        } else {
            appleMusicViewModel.seek(to: elapsedTime)
        }
    }

    private func openPlaybackSource() {
        if usesSystemNowPlaying {
            nowPlayingViewModel.openPlaybackSource()
        } else {
            appleMusicViewModel.openMusic()
        }
    }

    private func displayTitle(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.title.trimmed.isEmpty ? "Unknown Track" : snapshot.title
    }

    private func displayArtist(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.artist.trimmed.isEmpty ? "Unknown Artist" : snapshot.artist
    }

    private func progressValue(elapsedTime: TimeInterval, duration: TimeInterval) -> CGFloat {
        guard duration > 0 else { return 0 }
        return min(max(CGFloat(elapsedTime / duration), 0), 1)
    }
}
