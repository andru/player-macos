import SwiftUI

struct SongsView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesService
    @StateObject private var viewModel = SongsViewModel()
    var filteredTracks: [Track]
    let audioPlayer: AudioPlayer
    
    var body: some View {
        TrackTableView(
            filteredTracks: viewModel.sortedTracks(from: filteredTracks),
            audioPlayer: audioPlayer,
            sortOrder: $viewModel.sortOrder
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(LibraryManager())
        .environmentObject(PreferencesService())
}
