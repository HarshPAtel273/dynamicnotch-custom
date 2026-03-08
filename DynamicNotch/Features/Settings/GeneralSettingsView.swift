//
//  SettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var powerService: PowerService
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    var body: some View {
        Form {
            systemSection
            notchSection
        }
        .formStyle(.grouped)
    }
    
    @ViewBuilder
    var systemSection: some View {
        Section("System") {
            Toggle("Launch at login", isOn: $generalSettingsViewModel.isLaunchAtLoginEnabled)
                .toggleStyle(CustomToggleStyle())
            
            Toggle("Hide menu bar icon", isOn: $generalSettingsViewModel.isHideMenuBarIconEnabled)
                .toggleStyle(CustomToggleStyle())
            
            CustomPicker(
                selection: $generalSettingsViewModel.displayLocation,
                options: Array(NotchDisplayLocation.allCases),
                title: { $0.title },
                symbolName: { $0.symbolName }
            )
            .padding(.top, 4)
        }
    }
    
    @ViewBuilder
    var notchSection: some View {
        Section("Notch") {
            ZStack(alignment: .top) {
                Image("background")
                    .resizable()
                    .frame(height: 100)
                    .cornerRadius(10)
                
                NotchShape(topCornerRadius: notchViewModel.notchModel.cornerRadius.top, bottomCornerRadius: notchViewModel.notchModel.cornerRadius.bottom)
                    .fill(.black)
                    .stroke(generalSettingsViewModel.isShowNotchStrokeEnabled ? .green.opacity(0.3) : Color.clear, lineWidth: generalSettingsViewModel.notchStrokeWidth)
                    .overlay(ChargerNotchView(powerService: powerService))
                    .frame(width: 370, height: notchViewModel.notchModel.size.height)
            }
            
            Toggle("Show notch stroke ", isOn: $generalSettingsViewModel.isShowNotchStrokeEnabled)
                .toggleStyle(CustomToggleStyle())
            
            TickedSlider(
                title: "Stroke width",
                value: $generalSettingsViewModel.notchStrokeWidth,
                range: 1...3,
                step: 0.5,
                valueFormatter: { "\($0) px" }
            )
        }
    }
}
