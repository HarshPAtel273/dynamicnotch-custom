import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            TabView {
                GeneralSettingsView(
                    notchViewModel: appDelegate.notchViewModel,
                    powerService: appDelegate.powerService,
                    generalSettingsViewModel: appDelegate.generalSettingsViewModel
                )
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("General")
                }
                .frame(width: 500, height: 560)
                
                ActivitySettingsView(
                    notchViewModel: appDelegate.notchViewModel,
                    notchEventCoordinator: appDelegate.notchEventCoordinator
                )
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Activities")
                }
                .frame(width: 500, height: 560)
                
                AboutAppSettingsView()
                    .tabItem {
                        Image(systemName: "info.circle.fill")
                        Text("About")
                    }
                    .frame(width: 500, height: 560)
            }
            .background(.ultraThinMaterial)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}
