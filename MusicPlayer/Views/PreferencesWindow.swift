import SwiftUI

struct PreferencesWindow: View {
    @ObservedObject var library: LibraryManager
    @ObservedObject var preferences: PreferencesManager
    
    var body: some View {
        TabView {
            GeneralPreferencesView(library: library)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            PlaybackPreferencesView(preferences: preferences)
                .tabItem {
                    Label("Playback", systemImage: "play.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}
