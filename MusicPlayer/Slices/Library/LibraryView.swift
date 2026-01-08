import SwiftUI

struct LibraryView: View {
    @ObservedObject var library: LibraryManager
    var audioPlayer: AudioPlayer  // Not @ObservedObject - we don't need to observe it
    @EnvironmentObject var preferences: PreferencesService
    @Binding var selectedView: LibraryViewMode
    @Binding var selectedCollection: Collection?
    @Binding var searchText: String
    @Binding var selectedAlbum: Album?
    @State private var displayMode: DisplayMode = .grid
    
    // Make `body` available for the deployment target (macOS 13+). If any
    // APIs used inside require macOS 14+, guard with `if #available` there.
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Import button
                Button(action: { Task { await importMusicDirectory() } }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Import")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Content
            Group {
                if selectedView == .albums || selectedCollection != nil {
                    ScrollView {
                        AlbumsView(selectedAlbum: $selectedAlbum, filteredAlbums: filteredAlbums, audioPlayer: audioPlayer)
                    }
                } else if selectedView == .artists {
                    ScrollView {
                        ArtistsView(filteredArtists: filteredArtists)
                    }
                } else {
                    // SongsView contains a SwiftUI Table which provides its own scrolling
                    // and should not be wrapped in an outer ScrollView if we want it to
                    // expand to fill available space.
                    SongsView(filteredTracks: filteredTracks, audioPlayer: audioPlayer)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    
    }
    
    private var viewTitle: String {
        if let collection = selectedCollection {
            return collection.name
        }
        return selectedView.rawValue
    }

    private var filteredTracks: [Track] {
        var tracks = library.tracks
        
        if let collection = selectedCollection {
            tracks = tracks.filter { collection.trackIDs.contains($0.id) }
        }
        
        if !searchText.isEmpty {
            tracks = tracks.filter { track in
                track.title.localizedCaseInsensitiveContains(searchText) ||
                track.artist.localizedCaseInsensitiveContains(searchText) ||
                track.album.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return tracks
    }
    
//    private var gridView: some
    
    
    private var filteredAlbums: [Album] {
        var albums = library.albums
        
        if !searchText.isEmpty {
            albums = albums.filter { album in
                album.name.localizedCaseInsensitiveContains(searchText) ||
                album.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return albums
    }
    
    private var filteredArtists: [Artist] {
        var artists = library.artists
        
        if !searchText.isEmpty {
            artists = artists.filter { artist in
                artist.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return artists
    }
    
    
    private func importMusicFiles() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]
        
        if panel.runModal() == .OK {
            await library.importFiles(urls: panel.urls)
        }
    }
    
    private func importMusicDirectory() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.message = "Choose a folder to import music from"
        panel.prompt = "Import"
        
        if panel.runModal() == .OK, let url = panel.url {
            await library.importDirectory(url: url)
        }
    }
}
