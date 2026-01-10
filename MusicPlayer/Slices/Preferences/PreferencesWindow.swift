import SwiftUI

struct PreferencesWindow: View {
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem {
                    SwiftUI.Label("General", systemImage: "gear")
                }
            
            PlaybackPreferencesView()
                .tabItem {
                    SwiftUI.Label("Playback", systemImage: "play.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}
