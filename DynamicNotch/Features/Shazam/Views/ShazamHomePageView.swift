//
//  ShazamHomePageView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI

struct ShazamHomePageView: View {
    @ObservedObject var shazamViewModel: ShazamViewModel
    let notchViewModel: NotchViewModel
    var onRequestCollapse: (@MainActor () -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: "shazam.logo.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Shazam")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Text(verbatim: "Identify music around you")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button {
                onRequestCollapse?()
                shazamViewModel.notchViewModel = notchViewModel
                shazamViewModel.startListening()
                notchViewModel.send(
                    .showLiveActivity(
                        ShazamNotchContent(
                            shazamViewModel: shazamViewModel,
                            notchViewModel: notchViewModel
                        )
                    )
                )
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(verbatim: "Listen")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
