import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesService
    @Binding var selectedAlbum: Album?
    var filteredAlbums: [Album]
    let audioPlayer: AudioPlayer
    @State private var displayMode: DisplayMode = .grid
    @State private var sortOrder = [KeyPathComparator(\Track.title)]
    
    private var sortedTracks: [Track] {
        let allTracks = filteredAlbums.flatMap { $0.tracks }
        return allTracks.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // View mode toggle
            HStack{
                Spacer()
                
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
            }
            
            if displayMode == .grid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)], spacing: 16) {
                    
                    ForEach(filteredAlbums) { album in
                        
                        AlbumGridItem(album: album, action: {
                            selectedAlbum = album
                            //                        audioPlayer.queueTracks(album.tracks, startPlaying: true, behavior: preferences.playbackBehavior)
                        }, audioPlayer: audioPlayer, library: library)
                        
                    }
                    
                }
                .padding()
            } else {
                TrackTableView(
                    filteredTracks: sortedTracks,
                    audioPlayer: audioPlayer,
                    sortOrder: $sortOrder
                )
            }
        }.onAppear {
            loadViewMode()
        }
//        .onChange(of: selectedView) { _ in
//            loadViewMode()
//        }
    }
    
    
    private func loadViewMode() {
        let defaultMode: DisplayMode = .grid
        
        let savedValue = UserDefaults.standard.string(forKey: "albumsViewModeKey")
        if let savedValue = savedValue {
            displayMode = savedValue == "grid" ? .grid : .list
        } else {
            displayMode = defaultMode
        }
    }
    
    private func saveViewMode() {
        let value = displayMode == .grid ? "grid" : "list"
        UserDefaults.standard.set(value, forKey: "albumsViewModeKey")
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
