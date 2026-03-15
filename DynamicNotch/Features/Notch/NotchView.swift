import SwiftUI
import Combine
import AppKit
internal import UniformTypeIdentifiers

struct NotchView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    @ObservedObject var powerViewModel: PowerViewModel
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var networkViewModel: NetworkViewModel
    @ObservedObject var focusViewModel: FocusViewModel
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    
    var body: some View {
        ZStack {
            notchBody
        }
        .environment(\.notchScale, notchViewModel.notchModel.scale)
        .modifier(
            NotchSystemEventBindings(
                powerViewModel: powerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                networkViewModel: networkViewModel,
                focusViewModel: focusViewModel,
                notchEventCoordinator: notchEventCoordinator
            )
        )
        .modifier(
            NotchLiveActivityEventBindings(
                airDropViewModel: airDropViewModel,
                generalSettingsViewModel: generalSettingsViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                lockScreenManager: lockScreenManager,
                notchEventCoordinator: notchEventCoordinator
            )
        )
        .modifier(
            NotchStateBindings(
                notchViewModel: notchViewModel,
                airDropViewModel: airDropViewModel,
                generalSettingsViewModel: generalSettingsViewModel
            )
        )
        .offset(y: 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension NotchView {
    var notchStrokeColor: Color {
        guard generalSettingsViewModel.isShowNotchStrokeEnabled else {
            return .clear
        }

        if notchViewModel.notchModel.content != nil {
            return notchViewModel.notchModel.strokeColor
        }

        return notchViewModel.cachedStrokeColor
    }

    @ViewBuilder
    var notchBody: some View {
        NotchShape(
            topCornerRadius: notchViewModel.notchModel.cornerRadius.top,
            bottomCornerRadius: notchViewModel.notchModel.cornerRadius.bottom
        )
        .fill(.black)
        .stroke(
            Color.clear,
            lineWidth: generalSettingsViewModel.notchStrokeWidth
        )
        .overlay { contentOverlay }
        .overlay { strokeOverlay }
        .customNotchPressable(
            notchViewModel: notchViewModel,
            isPressed: $notchViewModel.isPressed,
            baseSize: notchViewModel.notchModel.size
        )
        .frame(
            width: notchViewModel.notchModel.size.width,
            height: notchViewModel.notchModel.size.height
        )
        .shadow(
            color: .black.opacity(
                generalSettingsViewModel.isShowShadowEnabled && notchViewModel.showNotch ? 0.5 : 0
            ),
            radius: 15
        )
        .contextMenu {
            if !generalSettingsViewModel.isMenuBarIconVisible {
                contextMenuItem
            }
        }
        .animation(.easeInOut(duration: 0.3), value: generalSettingsViewModel.isShowNotchStrokeEnabled)
        .animation(.spring(duration: 0.6), value: notchViewModel.showNotch)
    }
    
    @ViewBuilder
    var contentOverlay: some View {
        if let content = notchViewModel.notchModel.content {
            renderedContentView(for: content)
                .id(notchViewModel.notchModel.presentationID)
                .transition(notchContentTransition)
        }
    }

    var strokeOverlay: some View {
        NotchShape(
            topCornerRadius: notchViewModel.notchModel.cornerRadius.top,
            bottomCornerRadius: notchViewModel.notchModel.cornerRadius.bottom
        )
        .stroke(
            notchStrokeColor,
            lineWidth: generalSettingsViewModel.notchStrokeWidth
        )
        .allowsHitTesting(false)
    }

    var notchContentTransition: AnyTransition {
        .blurAndFade
            .animation(.spring(duration: 0.5))
            .combined(with: .scale)
            .combined(with: .offset(
                x: notchViewModel.notchModel.offsetXTransition,
                y: notchViewModel.notchModel.offsetYTransition
            ))
    }
    
    @MainActor
    @ViewBuilder
    func renderedContentView(for content: NotchContentProtocol) -> some View {
        if notchViewModel.notchModel.isPresentingExpandedLiveActivity {
            content.makeExpandedView()
        } else {
            content.makeView()
        }
    }
    
    @ViewBuilder
    var contextMenuItem: some View {
        SettingsLink {
            Image(systemName: "gearshape")
            Text("Settings")
        }
        
        Divider()
        Button(action: { NSApp.terminate(nil) }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
            Text("Quit")
        }
    }
}

private struct NotchSystemEventBindings: ViewModifier {
    let powerViewModel: PowerViewModel
    let bluetoothViewModel: BluetoothViewModel
    let networkViewModel: NetworkViewModel
    let focusViewModel: FocusViewModel
    let notchEventCoordinator: NotchEventCoordinator

    func body(content: Content) -> some View {
        content
            .onReceive(powerViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handlePowerEvent)
            .onReceive(bluetoothViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handleBluetoothEvent)
            .onReceive(networkViewModel.$networkEvent.compactMap { $0 }, perform: notchEventCoordinator.handleNetworkEvent)
            .onReceive(focusViewModel.$focusEvent.compactMap { $0 }, perform: notchEventCoordinator.handleFocusEvent)
    }
}

private struct NotchLiveActivityEventBindings: ViewModifier {
    let airDropViewModel: AirDropNotchViewModel
    let generalSettingsViewModel: GeneralSettingsViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager
    let notchEventCoordinator: NotchEventCoordinator

    func body(content: Content) -> some View {
        content
            .onReceive(airDropViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handleAirDropEvent)
            .onReceive(nowPlayingViewModel.$event.compactMap { $0 }, perform: notchEventCoordinator.handleNowPlayingEvent)
            .onReceive(lockScreenManager.$event.compactMap { $0 }, perform: notchEventCoordinator.handleLockScreenEvent)
            .onReceive(generalSettingsViewModel.notchSizeEvent, perform: notchEventCoordinator.handleNotchWidthEvent)
    }
}

private struct NotchStateBindings: ViewModifier {
    let notchViewModel: NotchViewModel
    let airDropViewModel: AirDropNotchViewModel
    let generalSettingsViewModel: GeneralSettingsViewModel

    func body(content: Content) -> some View {
        content
            .onAppear {
                notchViewModel.handleStrokeVisibility()
            }
            .onChange(of: notchViewModel.notchModel.content?.id) {
                notchViewModel.handleStrokeVisibility()
            }
            .onChange(of: generalSettingsViewModel.notchWidth) {
                notchViewModel.updateDimensions()
            }
            .onChange(of: generalSettingsViewModel.notchHeight) {
                notchViewModel.updateDimensions()
            }
            .onDrop(
                of: [.fileURL],
                isTargeted: Binding(
                    get: { airDropViewModel.isDraggingFile },
                    set: { airDropViewModel.isDraggingFile = $0 }
                )
            ) { providers in
                let dropPoint = NSEvent.mouseLocation
                airDropViewModel.handleDrop(providers: providers, point: dropPoint)
                return true
            }
    }
}
