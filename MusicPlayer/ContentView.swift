import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesManager
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var selectedView: LibraryView = .albums
    @State private var selectedCollection: Collection? = nil
    @State private var searchText: String = ""
    @State private var showQueue: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with playback controls
            TopBarView(audioPlayer: audioPlayer, searchText: $searchText, showQueue: $showQueue)
            
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
                .environmentObject(preferences)
                
                if showQueue {
                    Divider()
                    
                    QueueView(audioPlayer: audioPlayer)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        // The LibraryLocationPicker component presents the alert and open panel when needed
        LibraryLocationPicker(library: library)
    }
}

#Preview {
    ContentView()
        .environmentObject(LibraryManager())
        .environmentObject(PreferencesManager())
}
