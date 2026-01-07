import SwiftUI

struct MainContentView: View {
    @ObservedObject var library: LibraryManager
    var audioPlayer: AudioPlayer  // Not @ObservedObject - we don't need to observe it
    @EnvironmentObject var preferences: PreferencesManager
    @Binding var selectedView: LibraryView
    @Binding var selectedCollection: Collection?
    @Binding var searchText: String
    @Binding var selectedAlbum: Album?
    @State private var displayMode: DisplayMode = .grid
    
    // UserDefaults keys for view mode preferences
    private let artistsViewModeKey = "artistsViewMode"
    private let albumsViewModeKey = "albumsViewMode"
    private let songsViewModeKey = "songsViewMode"
    
    // Make `body` available for the deployment target (macOS 13+). If any
    // APIs used inside require macOS 14+, guard with `if #available` there.
    var body: some View {
        if #available(macOS 14.0, *) {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text(viewTitle)
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    // View mode toggle
                    HStack(spacing: 4) {
                        Button(action: {
                            displayMode = .grid
                            saveViewMode()
                        }) {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(displayMode == .grid ? .primary : .secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            displayMode = .list
                            saveViewMode()
                        }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(displayMode == .list ? .primary : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    
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
                
                // Import menu
//                Menu {
//                    Button(action: { Task { await importMusicFiles() } }) {
//                        Label("Import Files...", systemImage: "doc.badge.plus")
//                    }
//                    Button(action: { Task { await importMusicDirectory() } }) {
//                        Label("Import Folder...", systemImage: "folder.badge.plus")
//                    }
//                } label: {
//                    HStack {
//                        Image(systemName: "plus")
//                        Text("Import")
//                    }
//                }
//                .menuStyle(.borderlessButton)
//                .buttonStyle(.borderedProminent)
                // Content
                ScrollView {
                    if displayMode == .grid {
                        gridView
                    } else {
                        listView
                    }
                }
            }
            .onAppear {
                loadViewMode()
            }
            .onChange(of: selectedView) { _ in
                loadViewMode()
            }
        } else {
            // Fallback on earlier versions
        }
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
    
    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)], spacing: 16) {
            if selectedView == .albums || selectedCollection != nil {
                ForEach(filteredAlbums) { album in

                    AlbumGridItem(album: album, action: {
                        selectedAlbum = album
                        audioPlayer.queueTracks(album.tracks, startPlaying: true, behavior: preferences.playbackBehavior)
                    }, audioPlayer: audioPlayer, library: library)

                }
            } else if selectedView == .artists {
                ForEach(filteredArtists) { artist in
                    ArtistGridItem(artist: artist) {
//                        let allTracks = artist.albums.flatMap { $0.tracks }
//                        audioPlayer.queueTracks(allTracks, startPlaying: true, behavior: preferences.playbackBehavior)
                    }
                }
            } else {
                ForEach(filteredTracks) { track in

                    TrackGridItem(track: track, action: {
                        audioPlayer.queueTracks([track], startPlaying: true, behavior: preferences.playbackBehavior)
                    }, audioPlayer: audioPlayer, library: library)

                }
            }
        }
        .padding()
    }
    
    private var listView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("#")
                    .frame(width: 40)
                Text("Title")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Artist")
                    .frame(width: 200, alignment: .leading)
                Text("Album")
                    .frame(width: 200, alignment: .leading)
                Text("Duration")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Rows
            ForEach(Array(filteredTracks.enumerated()), id: \.element.id) { index, track in

                TrackListRow(track: track, index: index + 1, action: {
                    audioPlayer.queueTracks([track], startPlaying: true, behavior: preferences.playbackBehavior)
                }, audioPlayer: audioPlayer, library: library)

            }
        }
    }
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
    
    private func loadViewMode() {
        let key: String
        let defaultMode: DisplayMode
        
        switch selectedView {
        case .artists:
            key = artistsViewModeKey
            defaultMode = .grid  // Default: thumbnail
        case .albums:
            key = albumsViewModeKey
            defaultMode = .grid  // Default: thumbnail
        case .songs:
            key = songsViewModeKey
            defaultMode = .list  // Default: list
        }
        
        let savedValue = UserDefaults.standard.string(forKey: key)
        if let savedValue = savedValue {
            displayMode = savedValue == "grid" ? .grid : .list
        } else {
            displayMode = defaultMode
        }
    }
    
    private func saveViewMode() {
        let key: String
        
        switch selectedView {
        case .artists:
            key = artistsViewModeKey
        case .albums:
            key = albumsViewModeKey
        case .songs:
            key = songsViewModeKey
        }
        
        let value = displayMode == .grid ? "grid" : "list"
        UserDefaults.standard.set(value, forKey: key)
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

// MARK: - Grid Items

struct AlbumGridItem: View {
    let album: Album
    let action: () -> Void
    let audioPlayer: AudioPlayer?
    let library: LibraryManager?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                if let artwork = album.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 160, maxWidth: 200)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let audioPlayer = audioPlayer {
                    AlbumContextMenu(album: album, audioPlayer: audioPlayer, library: library)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(album.albumArtist ?? album.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(album.tracks.count) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ArtistGridItem: View {
    let artist: Artist
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    )
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(artist.albums.count) albums • \(artist.trackCount) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct TrackGridItem: View {
    let track: Track
    let action: () -> Void
    let audioPlayer: AudioPlayer?
    let library: LibraryManager?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                if let artwork = track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 160, maxWidth: 200)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                if let audioPlayer = audioPlayer {
                    TrackContextMenu(track: track, audioPlayer: audioPlayer, library: library)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(track.album)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - List Row

struct TrackListRow: View {
    let track: Track
    let index: Int
    let action: () -> Void
    let audioPlayer: AudioPlayer?
    let library: LibraryManager?
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(index)")
                    .frame(width: 40)
                    .foregroundColor(.secondary)
                
                Text(track.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(track.artist)
                    .frame(width: 200, alignment: .leading)
                    .foregroundColor(.secondary)
                
                Text(track.album)
                    .frame(width: 200, alignment: .leading)
                    .foregroundColor(.secondary)
                
                Text(track.formattedDuration)
                    .frame(width: 80, alignment: .trailing)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let audioPlayer = audioPlayer {
                TrackContextMenu(track: track, audioPlayer: audioPlayer, library: library)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        
        Divider()
    }
}

// MARK: - Context Menu Components

struct AlbumContextMenu: View {
    let album: Album
    let audioPlayer: AudioPlayer
    let library: LibraryManager?
    
    var body: some View {
        Button("Play Now") {
            audioPlayer.queueTracks(album.tracks, startPlaying: true)
        }
        
        Button("Next in Queue") {
            audioPlayer.addToQueueNext(album.tracks)
        }
        
        Button("End of Queue") {
            audioPlayer.addToQueueEnd(album.tracks)
        }
        
        Divider()
        
        Button("Favourite") {
            album.tracks.forEach { library?.toggleFavorite(track: $0) }
        }
        
        Button("Add to Collection") {
            // TODO: Show collection picker
            print("Add to collection")
        }
        
        Button("Add to Playlist") {
            // TODO: Show playlist picker
            print("Add to playlist")
        }
        
        Divider()
        
        Button("Remove from Library") {
            album.tracks.forEach { library?.removeFromLibrary(track: $0) }
        }
        
        Button("Refresh from Source") {
            album.tracks.forEach { library?.refreshFromSource(track: $0) }
        }
        
        Button("Edit Info") {
            // Edit first track or album info
            if let firstTrack = album.tracks.first {
                library?.editInfo(track: firstTrack)
            }
        }
    }
}

struct TrackContextMenu: View {
    let track: Track
    let audioPlayer: AudioPlayer
    let library: LibraryManager?
    
    var body: some View {
        Button("Play Now") {
            audioPlayer.playNow(track)
        }
        
        Button("Next in Queue") {
            audioPlayer.addToQueueNext(track)
        }
        
        Button("End of Queue") {
            audioPlayer.addToQueueEnd(track)
        }
        
        Divider()
        
        Button("Favourite") {
            library?.toggleFavorite(track: track)
        }
        
        Button("Add to Collection") {
            // TODO: Show collection picker
            print("Add to collection")
        }
        
        Button("Add to Playlist") {
            // TODO: Show playlist picker
            print("Add to playlist")
        }
        
        Divider()
        
        Button("Remove from Library") {
            library?.removeFromLibrary(track: track)
        }
        
        Button("Refresh from Source") {
            library?.refreshFromSource(track: track)
        }
        
        Button("Edit Info") {
            library?.editInfo(track: track)
        }
    }
}
