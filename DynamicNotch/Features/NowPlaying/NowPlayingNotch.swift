import SwiftUI
import AppKit

struct NowPlayingNotchContent: NotchContentProtocol {
    let id = "nowPlaying"
    let nowPlayingViewModel: NowPlayingViewModel
    
    var priority: Int { 81 }
    var isExpandable: Bool { true }
    var expandedOffsetYTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 80, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 200, height: baseHeight + 160)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 34, bottom: 44)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NowPlayingMinimalNotchView(nowPlayingViewModel: nowPlayingViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(NowPlayingExpandedNotchView(nowPlayingViewModel: nowPlayingViewModel))
    }
}

private struct NowPlayingMinimalNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: "Nothing Playing",
            artist: "Nothing artists",
            album: "",
            duration: 0,
            elapsedTime: 0,
            playbackRate: 0,
            artworkData: nil,
            refreshedAt: .now
        )
    }
    
    var body: some View {
        let snapshot = resolvedSnapshot
        
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            HStack {
                ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 24, height: 24, cornerRadius: 5)
                Spacer()
                EqualizerView(isPlaying: snapshot.isPlaying, date: context.date, width: 2, height: 2)
            }
            .padding(.horizontal, 14.scaled(by: scale))
        }
    }
}

private struct NowPlayingExpandedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: "Nothing Playing",
            artist: "Start playback to see live metadata",
            album: "Debug Preview",
            duration: 0,
            elapsedTime: 0,
            playbackRate: 0,
            artworkData: nil,
            refreshedAt: .now
        )
    }
    
    var body: some View {
        let snapshot = resolvedSnapshot
        
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let elapsedTime = nowPlayingViewModel.snapshot != nil ?
            nowPlayingViewModel.elapsedTime(at: context.date) :
            snapshot.elapsedTime
            let progress = progressValue(elapsedTime: elapsedTime, duration: snapshot.duration)
            
            VStack {
                Spacer()
                
                HStack(spacing: 15) {
                    ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 60, height: 60, cornerRadius: 10)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 10) {
                            MarqueeText(
                                .constant(displayTitle(for: snapshot)),
                                font: .system(size: 16, weight: .medium),
                                nsFont: .headline,
                                textColor: .white.opacity(0.8),
                                backgroundColor: .clear,
                                minDuration: 0.5,
                                frameWidth: 175.scaled(by: scale)
                            )
                            
                            Spacer(minLength: 0)
                            
                            EqualizerView(
                                isPlaying: snapshot.isPlaying,
                                date: context.date,
                                width: 3,
                                height: 4
                            )
                            .padding(.top, 8)
                        }
                        
                        MarqueeText(
                            .constant(displayArtist(for: snapshot)),
                            font: .system(size: 14),
                            nsFont: .headline,
                            textColor: .secondary,
                            backgroundColor: .clear,
                            minDuration: 1.0,
                            frameWidth: 175.scaled(by: scale)
                        )
                    }
                }
                Spacer()
                
                HStack(spacing: 10) {
                    Text(formattedTime(elapsedTime))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    PlayerProgressBar(progress: progress)
                    
                    Text(snapshot.duration > 0 ? formattedTime(snapshot.duration) : "LIVE")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 25) {
                    PlayerControlButton(
                        systemImage: "backward.fill",
                        fontSize: 22,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.previousTrack()
                    }
                    
                    PlayerControlButton(
                        systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
                        fontSize: 32,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.togglePlayPause()
                    }
                    
                    PlayerControlButton(
                        systemImage: "forward.fill",
                        fontSize: 22,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.nextTrack()
                    }
                }
            }
            .padding(.horizontal, 55)
            .padding(.top, 25)
            .padding(.bottom, 15)
        }
    }
    
    private func displayTitle(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.title.trimmed.isEmpty ? "Unknown Track" : snapshot.title
    }
    
    private func displayArtist(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.artist.trimmed.isEmpty ? "Unknown Artist" : snapshot.artist
    }
    
    private func displayAlbum(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.album.trimmed.isEmpty ? "Unknown Album" : snapshot.album
    }
    
    private func progressValue(elapsedTime: TimeInterval, duration: TimeInterval) -> CGFloat {
        guard duration > 0 else { return 0 }
        return min(max(CGFloat(elapsedTime / duration), 0), 1)
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "--:--" }
        
        let totalSeconds = max(0, Int(time.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func playbackStatusColor(for snapshot: NowPlayingSnapshot) -> Color {
        if nowPlayingViewModel.snapshot == nil {
            return .white.opacity(0.48)
        }
        
        return snapshot.isPlaying ?
        Color(red: 0.97, green: 0.73, blue: 0.32) :
            .white.opacity(0.48)
    }
}

private struct ArtworkView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    var body: some View {
        Group {
            if let artworkImage = nowPlayingViewModel.artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct EqualizerView: View {
    let isPlaying: Bool
    let date: Date
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.6).gradient)
                    .frame(width: width, height: barHeight(for: index))
            }
        }
        .frame(height: height, alignment: .bottom)
        .opacity(isPlaying ? 1 : 0.55)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 18

        guard isPlaying else {
            let restingHeights: [CGFloat] = [0.45, 0.7, 0.95, 0.62]
            return minHeight + ((maxHeight - minHeight) * restingHeights[index])
        }

        let phaseOffsets: [Double] = [0.0, 0.9, 1.8, 2.7]
        let wave = (sin(date.timeIntervalSinceReferenceDate * 7 + phaseOffsets[index]) + 1) / 2
        return minHeight + ((maxHeight - minHeight) * CGFloat(wave))
    }
}

private struct PlayerProgressBar: View {
    let progress: CGFloat
    
    var body: some View {
        Capsule(style: .continuous)
            .fill(.white.opacity(0.15))
            .frame(height: 7)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.5))
                        .frame(width: max(proxy.size.width * progress, 6))
                }
            }
    }
}

private struct PlayerControlButton: View {
    @Environment(\.notchScale) var scale
    
    let systemImage: String
    let fontSize: CGFloat
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(PressedButtonStyle(width: width, height: height))
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
