import SwiftUI

struct PreferencesWindow: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesService
    
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            PlaybackPreferencesView()
                .tabItem {
                    Label("Playback", systemImage: "play.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}
