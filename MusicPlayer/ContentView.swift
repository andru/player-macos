import SwiftUI
import AppKit

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
        .alert("Choose Library Location", isPresented: $library.needsLibraryLocationSetup) {
            Button("Choose Location") {
                showLibraryLocationPicker()
            }
            Button("Cancel", role: .cancel) {
                library.needsLibraryLocationSetup = false
            }
        } message: {
            Text("The app needs permission to store your music library. Please select a folder where the library will be saved (e.g., Documents or Desktop).")
        }
    }
    
    private func showLibraryLocationPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose a location for your Music Library"
        panel.prompt = "Choose"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Ensure UI updates happen on main thread
                DispatchQueue.main.async {
                    self.library.setLibraryLocation(url: url)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
