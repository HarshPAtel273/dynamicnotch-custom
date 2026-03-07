import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            TabView {
                #if DEBUG
                DebugPanelSettingsView(notchViewModel: appDelegate.notchViewModel, notchEventCoordinator: appDelegate.notchEventCoordinator)
                .tabItem {
                    Image(systemName: "lock.rectangle.stack")
                    Text("Debug Panel")
                }
                .frame(width: 600, height: 500)
                #endif
                
                GeneralSettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("General")
                    }
                    .frame(width: 600, height: 500)
                
                ActivitySettingsView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("Activities")
                    }
                    .frame(width: 600, height: 500)
                
                AboutAppSettingsView()
                    .tabItem {
                        Image(systemName: "ellipsis.circle.fill")
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
