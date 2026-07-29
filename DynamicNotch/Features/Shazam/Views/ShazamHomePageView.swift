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
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
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
                RoundedRectangle(cornerRadius: isDynamicIsland ? 24 : 34)
                    .fill(.blue.opacity(0.2))
                    .frame(height: 110)
                
                Image(systemName: "shazam.logo.fill")
                    .font(.system(size: 55, weight: .semibold))
                    .foregroundStyle(.blue)
            }
        }
        .buttonStyle(.plain)
    }
}
