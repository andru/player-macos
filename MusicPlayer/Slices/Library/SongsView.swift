import SwiftUI

struct SongsView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesService
    var filteredTracks: [Track]
    let audioPlayer: AudioPlayer
    
    var body: some View {
        
            TrackTableView(filteredTracks: filteredTracks, audioPlayer: audioPlayer)

    }
        
    
}

#Preview {
    ContentView()
        .environmentObject(LibraryManager())
        .environmentObject(PreferencesService())
}
