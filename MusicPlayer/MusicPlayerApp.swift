import SwiftUI

@main
struct MusicPlayerApp: App {
    @StateObject private var library = LibraryManager()
    @StateObject private var preferences = PreferencesManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(preferences)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        Settings {
            PreferencesWindow(library: library, preferences: preferences)
        }
    }
}
