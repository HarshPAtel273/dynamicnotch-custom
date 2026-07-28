//
//  ShazamNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI

struct ShazamNotchView: View {
    @ObservedObject var shazamViewModel: ShazamViewModel
    @Environment(\.notchScale) private var notchScale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        HStack {
            Image(systemName: "shazam.logo.fill")
                .font(.system(size: isDynamicIsland ? 16 : 20, weight: .semibold))
                .foregroundStyle(LinearGradient.cyanGradient)
            
            Spacer()
            
            if shazamViewModel.isListening {
                ShazamAudioEqualizerView(
                    isListening: shazamViewModel.isListening || shazamViewModel.state == .listening,
                    audioLevel: shazamViewModel.audioLevel,
                    bandLevels: shazamViewModel.bandLevels,
                    colors: [.cyan],
                    barHeight: isDynamicIsland ? 12 : 16,
                    barWidth: isDynamicIsland ? 1.8 : 2.0
                )
                .frame(width: isDynamicIsland ? 14 : 18, height: isDynamicIsland ? 12 : 16)
            }
        }
        .padding(.leading, isDynamicIsland ? 3.scaled(by: notchScale) : 14.scaled(by: notchScale))
        .padding(.trailing, isDynamicIsland ? 8.scaled(by: notchScale) : 14.scaled(by: notchScale))
    }
}
