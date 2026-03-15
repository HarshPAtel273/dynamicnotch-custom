import AppKit
import Combine
import SwiftUI

@MainActor
final class LockScreenPanelAnimator: ObservableObject {
    @Published var isPresented = false
    @Published var disablesTransitionAnimation = false
}

final class LockScreenPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class LockScreenPanelManager {
    private let nowPlayingViewModel: NowPlayingViewModel
    private let lockScreenManager: LockScreenManager
    private let generalSettingsViewModel: GeneralSettingsViewModel
    private let animator = LockScreenPanelAnimator()

    private var panelWindow: LockScreenPanelWindow?
    private var hasDelegatedWindow = false
    private var appObservers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()

    init(
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        self.generalSettingsViewModel = generalSettingsViewModel

        bindState()
        registerObservers()
    }

    func invalidate() {
        appObservers.forEach(NotificationCenter.default.removeObserver)
        appObservers.removeAll()

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(workspaceCenter.removeObserver)
        workspaceObservers.removeAll()

        cancellables.removeAll()
        panelWindow?.orderOut(nil)
    }

    private func bindState() {
        Publishers.CombineLatest(
            lockScreenManager.$isLocked.removeDuplicates(),
            nowPlayingViewModel.$snapshot
                .map { $0 != nil }
                .removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isLocked, hasActiveSession in
            self?.updatePresentation(isLocked: isLocked, hasActiveSession: hasActiveSession)
        }
        .store(in: &cancellables)

        generalSettingsViewModel.$displayLocation
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshPosition(animated: false)
            }
            .store(in: &cancellables)
    }

    private func registerObservers() {
        appObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshPosition(animated: false)
                }
            }
        )

        appObservers.append(
            NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.updatePresentation(
                        isLocked: self.lockScreenManager.isLocked,
                        hasActiveSession: self.nowPlayingViewModel.hasActiveSession
                    )
                }
            }
        )

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshPosition(animated: false)
                }
            }
        )
    }

    private func updatePresentation(isLocked: Bool, hasActiveSession: Bool) {
        guard LockScreenSettings.isMediaPanelEnabled() else {
            hidePanel(animated: true)
            return
        }

        if isLocked && hasActiveSession {
            showPanel(animated: false)
        } else {
            hidePanel(animated: true)
        }
    }

    private func showPanel(animated: Bool) {
        guard let screen = currentScreen() else { return }

        let window = makeWindowIfNeeded()
        let targetFrame = panelFrame(for: screen)

        if window.frame != targetFrame {
            window.setFrame(targetFrame, display: true)
        }

        if window.contentView == nil {
            let hostingView = NSHostingView(
                rootView: LockScreenNowPlayingPanelView(
                    nowPlayingViewModel: nowPlayingViewModel,
                    lockScreenManager: lockScreenManager,
                    animator: animator
                )
            )
            hostingView.frame = NSRect(origin: .zero, size: targetFrame.size)
            hostingView.autoresizingMask = [.width, .height]
            window.contentView = hostingView
        }

        if !hasDelegatedWindow {
            SkyLightOperator.shared.delegateWindow(window)
            hasDelegatedWindow = true
        }

        window.orderFrontRegardless()

        animator.disablesTransitionAnimation = !animated

        guard animated else {
            animator.isPresented = true
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.animator.isPresented = true
        }
    }

    private func hidePanel(animated: Bool) {
        animator.disablesTransitionAnimation = !animated
        animator.isPresented = false

        guard let window = panelWindow else { return }
        let delay = animated ? 0.22 : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak window] in
            guard let self else { return }

            let shouldRemainVisible =
                self.lockScreenManager.isLocked &&
                self.nowPlayingViewModel.hasActiveSession &&
                LockScreenSettings.isMediaPanelEnabled()

            guard !shouldRemainVisible else { return }

            window?.orderOut(nil)
        }
    }

    private func refreshPosition(animated: Bool) {
        guard let window = panelWindow, window.isVisible, let screen = currentScreen() else {
            return
        }

        let targetFrame = panelFrame(for: screen)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            window.setFrame(targetFrame, display: true)
        }

        window.orderFrontRegardless()
    }

    private func makeWindowIfNeeded() -> LockScreenPanelWindow {
        if let panelWindow {
            return panelWindow
        }

        let window = LockScreenPanelWindow(
            contentRect: NSRect(origin: .zero, size: LockScreenWindowLayout.canvasSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isFloatingPanel = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        window.hidesOnDeactivate = false
        window.isMovable = false
        window.hasShadow = false
        window.animationBehavior = .none

        panelWindow = window
        return window
    }

    private func currentScreen() -> NSScreen? {
        NSScreen.preferredLockScreen ??
        NSScreen.preferredNotchScreen(for: generalSettingsViewModel.displayLocation) ??
        NSScreen.main ??
        NSScreen.screens.first
    }

    private func panelFrame(for screen: NSScreen) -> NSRect {
        let canvasSize = LockScreenWindowLayout.canvasSize
        let size = LockScreenNowPlayingPanelView.panelSize
        let screenFrame = screen.frame

        let desiredPanelX = screenFrame.midX - size.width / 2
        let desiredPanelY = screenFrame.midY - size.height - 28

        let x = floor(desiredPanelX - (canvasSize.width - size.width) / 2)
        let y = floor(desiredPanelY - (canvasSize.height - size.height) / 2)

        return NSRect(origin: CGPoint(x: x, y: y), size: canvasSize)
    }
}

private struct LockScreenNowPlayingPanelView: View {
    static let panelSize = CGSize(width: 420, height: 182)

    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var animator: LockScreenPanelAnimator

    @State private var scrubProgress: CGFloat?

    private let animationTick: TimeInterval = 1.0 / 10.0

    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: "Nothing Playing",
            artist: "Start playback to show the panel",
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

        TimelineView(.periodic(from: .now, by: animationTick)) { context in
            let elapsedTime = nowPlayingViewModel.snapshot != nil ?
                nowPlayingViewModel.elapsedTime(at: context.date) :
                snapshot.elapsedTime
            let progress = progressValue(elapsedTime: elapsedTime, duration: snapshot.duration)
            let displayedProgress = scrubProgress ?? progress
            let displayedElapsedTime = snapshot.duration > 0 ?
                TimeInterval(displayedProgress) * snapshot.duration :
                elapsedTime

            VStack(alignment: .leading, spacing: 18) {
                header(snapshot: snapshot)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(formattedTime(displayedElapsedTime))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        Spacer()

                        Text(snapshot.duration > 0 ? formattedTime(snapshot.duration) : "LIVE")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    LockScreenProgressBar(
                        progress: displayedProgress,
                        isInteractive: snapshot.duration > 0,
                        onScrubChanged: { scrubProgress = $0 },
                        onScrubEnded: { newProgress in
                            nowPlayingViewModel.seek(to: snapshot.duration * TimeInterval(newProgress))
                            scrubProgress = nil
                        }
                    )
                }

                controls(snapshot: snapshot)
            }
            .padding(20)
            .frame(width: Self.panelSize.width, height: Self.panelSize.height, alignment: .topLeading)
            .background {
                LockScreenPanelBackground(artworkImage: nowPlayingViewModel.artworkImage)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.24), radius: 26, x: 0, y: 14)
            .scaleEffect(
                animator.isPresented || animator.disablesTransitionAnimation ? 1 : 0.94
            )
            .opacity(animator.isPresented ? 1 : 0)
            .animation(
                animator.disablesTransitionAnimation ?
                .none :
                .spring(response: 0.5, dampingFraction: 0.82),
                value: animator.isPresented
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func header(snapshot: NowPlayingSnapshot) -> some View {
        HStack(alignment: .center, spacing: 16) {
            LockScreenArtworkView(
                artworkImage: nowPlayingViewModel.artworkImage,
                size: 70,
                cornerRadius: 18
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(displayTitle(for: snapshot))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(displayArtist(for: snapshot))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Image(systemName: lockScreenManager.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 11, weight: .semibold))

                    Text(lockScreenManager.isLocked ? "Screen Locked" : "Unlocking")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Circle()
                .fill(snapshot.isPlaying ? Color.white.opacity(0.16) : Color.white.opacity(0.09))
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: snapshot.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.84))
                }
        }
    }

    @ViewBuilder
    private func controls(snapshot: NowPlayingSnapshot) -> some View {
        HStack(spacing: 14) {
            Spacer()

            LockScreenControlButton(systemImage: "backward.fill") {
                nowPlayingViewModel.previousTrack()
            }

            LockScreenControlButton(
                systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
                isPrimary: true
            ) {
                nowPlayingViewModel.togglePlayPause()
            }

            LockScreenControlButton(systemImage: "forward.fill") {
                nowPlayingViewModel.nextTrack()
            }

            Spacer()
        }
    }

    private func displayTitle(for snapshot: NowPlayingSnapshot) -> String {
        let title = snapshot.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Unknown Track" : title
    }

    private func displayArtist(for snapshot: NowPlayingSnapshot) -> String {
        let artist = snapshot.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        return artist.isEmpty ? "Unknown Artist" : artist
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
}

private struct LockScreenPanelBackground: View {
    let artworkImage: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.76),
                    Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 42)
                    .scaleEffect(1.24)
                    .opacity(0.16)
            }
        }
    }
}

private struct LockScreenArtworkView: View {
    let artworkImage: NSImage?
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white.opacity(0.1))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white.opacity(0.55))
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct LockScreenProgressBar: View {
    let progress: CGFloat
    let isInteractive: Bool
    let onScrubChanged: (CGFloat) -> Void
    let onScrubEnded: (CGFloat) -> Void

    var body: some View {
        GeometryReader { proxy in
            let resolvedProgress = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.12))
                    .frame(height: 7)

                Capsule(style: .continuous)
                    .fill(.white.opacity(0.55))
                    .frame(width: proxy.size.width * resolvedProgress, height: 7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isInteractive else { return }
                        onScrubChanged(progress(at: value.location.x, in: proxy.size.width))
                    }
                    .onEnded { value in
                        guard isInteractive else { return }
                        onScrubEnded(progress(at: value.location.x, in: proxy.size.width))
                    }
            )
        }
        .frame(height: 18)
    }

    private func progress(at locationX: CGFloat, in width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        return min(max(locationX / width, 0), 1)
    }
}

private struct LockScreenControlButton: View {
    let systemImage: String
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: isPrimary ? 18 : 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: isPrimary ? 52 : 42, height: isPrimary ? 52 : 42)
                .background(
                    Circle()
                        .fill(isPrimary ? .white.opacity(0.18) : .white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}
