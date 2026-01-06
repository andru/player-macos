import SwiftUI

struct PreferencesWindow: View {
    @ObservedObject var library: LibraryManager
    @ObservedObject var preferences: PreferencesManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesView(library: library)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            PlaybackPreferencesView(preferences: preferences)
                .tabItem {
                    Label("Playback", systemImage: "play.circle")
                }
                .tag(1)
        }
        .frame(width: 500, height: 350)
    }
}
