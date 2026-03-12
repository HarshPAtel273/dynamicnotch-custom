import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isMenuBarIconVisible") var isMenuBarIconVisible: Bool = true
    
    var body: some Scene {
        MenuBarExtra("Dynamic Notch", systemImage: "rectangle.topthird.inset.filled", isInserted: $isMenuBarIconVisible) {
            SettingsLink {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        
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
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}
