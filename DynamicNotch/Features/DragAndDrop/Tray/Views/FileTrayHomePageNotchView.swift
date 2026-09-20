import SwiftUI

struct FileTrayHomePageNotchView: View {
    @ObservedObject var fileTrayViewModel: FileTrayViewModel
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    var onRequestCollapse: (@MainActor () -> Void)? = nil

    var body: some View {
        TrayExpandedActiveNotchView(
            fileTrayViewModel: fileTrayViewModel,
            mediaSettings: mediaSettings,
            onAddFiles: {
                onRequestCollapse?()
                DispatchQueue.main.async {
                    fileTrayViewModel.chooseFilesFromFinder(mode: mediaSettings.fileTrayUsageMode)
                }
            }
        )
        .padding(.top, 36)
    }
}
