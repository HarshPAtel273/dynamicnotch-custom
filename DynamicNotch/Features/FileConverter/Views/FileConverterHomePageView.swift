//
//  FileConverterHomePageView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/22/26.
//

import SwiftUI

struct FileConverterHomePageView: View {
    @ObservedObject var fileConverterViewModel: FileConverterViewModel
    var onRequestCollapse: (@MainActor () -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            emptyStateDropRow
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }
    
    private var emptyStateDropRow: some View {
        Button(action: {
            onRequestCollapse?()
            DispatchQueue.main.async {
                fileConverterViewModel.chooseFileFromFinder()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.gray.opacity(0.12))
                    .stroke(.gray.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [12, 10]))
                    .frame(height: 110)

                VStack(spacing: 10) {
                    Image(systemName: "document.fill")
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
    }
}
