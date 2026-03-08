//
//  GeneralSettingsViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/8/26.
//

import Combine
import SwiftUI

enum NotchDisplayLocation: String, CaseIterable {
    case builtIn
    case main
    
    var title: String {
        switch self {
        case .builtIn: return "Show on other display"
        case .main:    return "Show on main screen"
        }
    }
    
    var symbolName: String {
        switch self {
        case .builtIn: return "laptopcomputer"
        case .main:    return "display.2"
        }
    }
}

final class GeneralSettingsViewModel: ObservableObject {
    @AppStorage("isLaunchAtLoginEnabled") var isLaunchAtLoginEnabled: Bool = false
    @AppStorage("isHideMenuBarIconEnabled") var isHideMenuBarIconEnabled: Bool = false
    @AppStorage("isShowNotchStrokeEnabled") var isShowNotchStrokeEnabled: Bool = false
    @AppStorage("displayLocation") private var storedDisplayLocationRaw: String = NotchDisplayLocation.main.rawValue
    @AppStorage("notchStrokeWidth") var notchStrokeWidth: Double = 1.5
    
    @Published var displayLocation: NotchDisplayLocation
    
    init() {
        let raw = UserDefaults.standard.string(forKey: "displayLocation") ?? NotchDisplayLocation.main.rawValue
        self.displayLocation = NotchDisplayLocation(rawValue: raw) ?? .main
        
        $displayLocation
            .sink { [weak self] newValue in
                self?.storedDisplayLocationRaw = newValue.rawValue
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

