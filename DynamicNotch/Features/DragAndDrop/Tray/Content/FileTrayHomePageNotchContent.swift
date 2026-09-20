import SwiftUI

struct FileTrayHomePageNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.active.id
    let fileTrayViewModel: FileTrayViewModel
    let mediaSettings: MediaAndFilesSettingsStore
    let onRequestCollapse: (@MainActor () -> Void)?

    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth, height: baseHeight)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 208, height: baseHeight + 156)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 260, height: baseHeight + 156)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            FileTrayHomePageNotchView(
                fileTrayViewModel: fileTrayViewModel,
                mediaSettings: mediaSettings,
                onRequestCollapse: onRequestCollapse
            )
        )
    }
}
