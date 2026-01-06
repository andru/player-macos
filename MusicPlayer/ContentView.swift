import SwiftUI

struct ContentView: View {
    @StateObject private var library = LibraryManager()
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var selectedView: LibraryView = .albums
    @State private var selectedCollection: Collection? = nil
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with playback controls
            TopBarView(audioPlayer: audioPlayer, searchText: $searchText)
            
            Divider()
            
            // Main content with sidebar
            HStack(spacing: 0) {
                SidebarView(
                    selectedView: $selectedView,
                    selectedCollection: $selectedCollection,
                    library: library
                )
                
                Divider()
                
                MainContentView(
                    library: library,
                    audioPlayer: audioPlayer,
                    selectedView: $selectedView,
                    selectedCollection: $selectedCollection,
                    searchText: $searchText
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
