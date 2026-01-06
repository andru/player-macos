import SwiftUI

struct MainContentView: View {
    @ObservedObject var library: LibraryManager
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var selectedView: LibraryView
    @Binding var selectedCollection: Collection?
    @Binding var searchText: String
    @State private var displayMode: DisplayMode = .grid
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(viewTitle)
                    .font(.title)
                    .bold()
                
                Spacer()
                
                // View mode toggle
                HStack(spacing: 4) {
                    Button(action: { displayMode = .grid }) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(displayMode == .grid ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { displayMode = .list }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(displayMode == .list ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                
                // Import button
                Button(action: importMusic) {
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
            ScrollView {
                if displayMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
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
                    AlbumGridItem(album: album) {
                        if let firstTrack = album.tracks.first {
                            audioPlayer.play(track: firstTrack)
                        }
                    }
                }
            } else if selectedView == .artists {
                ForEach(filteredArtists) { artist in
                    ArtistGridItem(artist: artist)
                }
            } else {
                ForEach(filteredTracks) { track in
                    TrackGridItem(track: track) {
                        audioPlayer.play(track: track)
                    }
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
                TrackListRow(track: track, index: index + 1) {
                    audioPlayer.play(track: track)
                }
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
    
    private func importMusic() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]
        
        if panel.runModal() == .OK {
            library.importFiles(urls: panel.urls)
        }
    }
}

// MARK: - Grid Items

struct AlbumGridItem: View {
    let album: Album
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    )
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(album.artist)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                )
            
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    )
            }
            .buttonStyle(.plain)
            
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
        .onHover { hovering in
            isHovered = hovering
        }
        
        Divider()
    }
}
