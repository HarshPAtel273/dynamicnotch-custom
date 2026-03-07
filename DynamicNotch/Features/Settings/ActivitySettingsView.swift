//
//  ActivitySettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/6/26.
//

import SwiftUI

struct ActivitySettingsView: View {
    var body: some View {
        TabView {
            LiveActivitySettingsView()
                .tabItem{
                    Text("Live Activity")
                }
            
            TemporarySettingsView()
                .tabItem{
                    Text("Temporary Activity")
                }
        }
        .padding(12)
        .tabViewStyle(.grouped)
    }
}

private struct LiveActivitySettingsView: View {
    var body: some View {
        Text("primer")
    }
}

private struct TemporarySettingsView: View {
    var body: some View {
        Text("pirmer 2")
    }
}
