//
//  FileConverterHomePageView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/22/26.
//

import SwiftUI

struct FileConverterHomePageView: View {
    var onRequestCollapse: (@MainActor () -> Void)? = nil

    @ObservedObject var fileConverterViewModel: FileConverterViewModel
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        Group {
            if fileConverterViewModel.hasItem {
                FileConverterExpandedActiveNotchView(
                    fileConverterViewModel: fileConverterViewModel,
                    mediaSettings: mediaSettings,
                    onRequestCollapse: onRequestCollapse
                )
            } else {
                emptyStateDropRow
            }
        }
        .onAppear {
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H",
                location: "FileConverterHomePageView.body",
                message: "homepage converter rendered",
                data: [
                    "hasItem": fileConverterViewModel.hasItem,
                    "selectedFormat": fileConverterViewModel.selectedFormat.rawValue,
                    "status": String(describing: fileConverterViewModel.status)
                ],
                runId: "post-fix"
            )
            // #endregion
        }
        .onChange(of: fileConverterViewModel.hasItem) { _, hasItem in
            // #region agent log
            AgentDebugLog.write(
                hypothesisId: "H",
                location: "FileConverterHomePageView.onChange",
                message: "homepage converter hasItem changed",
                data: ["hasItem": hasItem],
                runId: "post-fix"
            )
            // #endregion
        }
    }

    private var emptyStateDropRow: some View {
        Button(action: {
            // Keep the homepage open so the selected file appears in-place.
            fileConverterViewModel.chooseFileFromFinder()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: isDynamicIsland ? 24 : 34)
                    .fill(.gray.opacity(0.12))
                    .stroke(.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [10, 10]))
                    .frame(height: 110)

                VStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(verbatim: "Click to select file")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(fileConverterViewModel.isConverting)
        .buttonStyle(.plain)
        .padding(.horizontal, 1)
        .padding(.bottom, 1)
    }
}
