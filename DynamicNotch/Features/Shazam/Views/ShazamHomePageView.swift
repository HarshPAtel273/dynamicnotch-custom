//
//  ShazamHomePageView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/26/26.
//

import SwiftUI

struct ShazamHomePageView: View {
    let notchViewModel: NotchViewModel
    var onRequestCollapse: (@MainActor () -> Void)? = nil
    
    @ObservedObject var shazamViewModel: ShazamViewModel

    var body: some View {
        VStack {
            Spacer()
            button
        }
    }
    
    private var button: some View {
        Button {
            onRequestCollapse?()
            shazamViewModel.notchViewModel = notchViewModel
            shazamViewModel.startListening()
            notchViewModel.send(.showLiveActivity(ShazamNotchContent(shazamViewModel: shazamViewModel, notchViewModel: notchViewModel)))
            
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.blue.opacity(0.2))
                    .frame(height: 110)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "shazam.logo.fill")
                            .font(.system(size: 45, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    Text(verbatim: "Start listening")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
