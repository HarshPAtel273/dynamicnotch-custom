//
//  HomePageSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

struct HomePageSettingsView: View {
    @ObservedObject var settings: HomePageSettingsStore

    var body: some View {
        SettingsPageScrollView {
            homePageActivity
        }
    }

    private var homePageActivity: some View {
        SettingsCard(title: "Home Page activity") {
            SettingsToggleRow(
                title: "Home Page live activity",
                description: "Show the Home Page in the notch.",
                systemImage: "house",
                color: .blue,
                isOn: $settings.isHomePageLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.homePage"
            )
        }
    }
}
