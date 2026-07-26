//
//  ShazamExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI
internal import AppKit

struct ShazamExpandedNotchView: View {
    @ObservedObject var shazamViewModel: ShazamViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    var onRequestClose: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            Spacer()
            
            Group {
                switch shazamViewModel.state {
                case .listening:
                    listeningView
                case .notFound:
                    notFoundView
                case .error(let message):
                    errorView(message)
                }
            }
            .transition(
                .blurAndFade
                    .combined(with: .opacity)
                    .animation(.spring(response: 0.6))
            )
        }
        .padding(.leading, isDynamicIsland ? 10 : 32)
        .padding(.trailing, isDynamicIsland ? 13 : 35)
        .padding(.bottom, isDynamicIsland ? 11 : 10)
    }
    
    private var listeningView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 45, height: 45)
                    
                    Image(systemName: "shazam.logo.fill")
                        .font(.system(size: 45, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                
                Text(verbatim: "Listening...")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                ShazamAudioEqualizerView(
                    isListening: shazamViewModel.isListening || shazamViewModel.state == .listening,
                    audioLevel: shazamViewModel.audioLevel,
                    bandLevels: shazamViewModel.bandLevels,
                    colors: [.blue, .systemMint, .blue],
                    barHeight: 16,
                    barWidth: 2.0
                )
                .frame(width: 18, height: 16)
                
                Button {
                    onRequestClose?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .blue.opacity(0.2)))
            }
        }
    }
    
    private var notFoundView: some View {
        HStack {
            Text(verbatim: "Couldn't identify song")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
            
            Spacer()
            
            Button {
                shazamViewModel.startListening()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .blue.opacity(0.2)))
        }
        .padding(.leading)
        .padding(.bottom, 5)
    }
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(2)
            
            Spacer()
            
            Button {
                onRequestClose?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .blue.opacity(0.2)))
        }
        .padding(.leading)
        .padding(.bottom, 5)
    }
}
