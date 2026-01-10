import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var container: AppContainer
    @EnvironmentObject var preferences: PreferencesService
    @State private var selectedView: LibraryViewMode = .albums
    @State private var selectedAlbum: Album? = nil
    @State private var selectedCollection: Collection? = nil
    @State private var searchText: String = ""
    @State private var showQueue: Bool = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedView: $selectedView,
                selectedAlbum: $selectedAlbum,
                selectedCollection: $selectedCollection
            )
        } detail: {
            VStack(spacing: 0) {
                // Top bar with playback controls
                TopBarView(
                    searchText: $searchText,
                    showQueue: $showQueue
                )
                
                Divider()
                
                // Main content with sidebar
                HStack(spacing: 0) {
                    
                    Divider()
                    
                    LibraryRootView()
                    
                    if showQueue {
                        Divider()
                        
                        QueueView()
                    }
                }
                .frame(maxHeight: .infinity) // allow HStack to take remaining vertical space
            }

        }
        .frame(minWidth: 900, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        // The LibraryLocationPicker component presents the alert and open panel when needed
        LibraryLocationPicker(library: container.appFrame.appLibraryService)
    }
}

//#Preview {
//    ContentView()
//        .environmentObject(AppContainer())
//        .environmentObject(PreferencesService())
//}
