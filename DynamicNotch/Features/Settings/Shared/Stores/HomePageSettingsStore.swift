//
//  HomePageSettingsStore.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import Foundation
import Combine

@MainActor
final class HomePageSettingsStore: SettingsStoreBase {
    @Published var isHomePageLiveActivityEnabled: Bool {
        didSet {
            persist(isHomePageLiveActivityEnabled, for: GeneralSettingsStorage.Keys.homePageLiveActivity)
        }
    }
    
    func resetHomePage() {
        
    }
    
    override init(defaults: UserDefaults) {
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
        self.isHomePageLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.homePageLiveActivity
        )
        self.isHomePageLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.homePageLiveActivity
        )
        super.init(defaults: defaults)
    }
    
    private static func resolvedBool(defaults: UserDefaults, key: String) -> Bool {
        if let currentValue = defaults.object(forKey: key) as? Bool {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }
}
