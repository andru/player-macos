import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var container: AppContainer
    @EnvironmentObject var preferences: PreferencesService
    @Binding var selectedAlbum: Album?
    
    @State private var displayMode: DisplayMode = .grid
    @StateObject private var vm = AlbumsViewModel()
    
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
            
//            if displayMode == .grid {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)], spacing: 16) {
                        
                        ForEach(vm.albumRows) { album in
                            
                            AlbumGridItem(album: album, action: {
                                selectedAlbum = await vm.fetchAlbumDetails(albumID: album.id)
                                //                        audioPlayer.queueTracks(album.tracks, startPlaying: true, behavior: preferences.playbackBehavior)
                            }, audioPlayer: container.library.audioPlayer)
                            
                        }
                        
                    }
                    .padding()
                }
//            } else {
//                TrackTableView(
//                    filteredTracks: sortedTracks,
//                    audioPlayer: audioPlayer,
//                    sortOrder: $vm.sortOrder
//                )
//            }
        }.task {
            // Runs when the view appears; guard to ensure one-time configure
            vm.configureIfNeeded(deps: container.library)
            await vm.loadInitialIfNeeded()
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
    
    private var trackCount: Int {
        album.releases.reduce(0) { $0 + $1.tracks.count }
    }
    
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
                    AlbumContextMenu(album: album, audioPlayer: audioPlayer)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(album.albumArtistName ?? album.artist?.name ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(trackCount) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
