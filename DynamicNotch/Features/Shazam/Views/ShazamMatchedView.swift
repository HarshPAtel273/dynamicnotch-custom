//
//  ShazamMatchedView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI
internal import AppKit

struct ShazamMatchedView: View {
    let result: ShazamResult
    @ObservedObject var shazamViewModel: ShazamViewModel
    var notchViewModel: NotchViewModel? = nil
    var onRequestCollapse: (@MainActor () -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            if let url = result.artworkURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.2))
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                }
                .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(result.artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            if let openURL = result.appleMusicURL ?? result.shazamURL {
                Button {
                    NSWorkspace.shared.open(openURL)
                } label: {
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(width: 38, height: 38, backgroundColor: .blue.opacity(0.15)))
            }

            Button {
                shazamViewModel.matchedResult = nil
                shazamViewModel.startListening()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(width: 38, height: 38, backgroundColor: .blue))

            Button {
                shazamViewModel.matchedResult = nil
                onRequestCollapse?()
                if let notchVM = notchViewModel {
                    notchVM.send(.hideLiveActivity(id: NotchContentRegistry.Shazam.active.id))
                    notchVM.send(.hideLiveActivity(id: NotchContentRegistry.Shazam.matched.id))
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(width: 38, height: 38, backgroundColor: .white.opacity(0.15)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
