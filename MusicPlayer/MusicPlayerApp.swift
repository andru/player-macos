import SwiftUI

@main
struct MusicPlayerApp: App {
    @StateObject private var container = try! AppContainer()
    @StateObject private var preferences = PreferencesService()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(preferences)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        Settings {
            PreferencesWindow()
                .environmentObject(container)
                .environmentObject(preferences)
        }
    }

}
