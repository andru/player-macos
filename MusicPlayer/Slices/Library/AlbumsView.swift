import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject var container: AppContainer
    @EnvironmentObject var preferences: PreferencesService
    
    @State private var displayMode: DisplayMode = .grid
    @StateObject var vm: LibraryViewModel
    
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
                        
                        ForEach(vm.albumRows) { albumRow in
                            // Start an async Task from a synchronous closure so the action type stays () -> Void
                            AlbumGridItem(albumRow: albumRow, action: {
                                Task {
                                    await vm.didClickAlbum(albumRow: albumRow)
                                }
                            })
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
        }.onAppear {
            loadViewMode()
        }.task {
            await vm.loadAlbumRows()
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
    let albumRow: AlbumRow
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                if let artwork = albumRow.artwork {
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
                // fixed incorrect identifier: pass albumRow
                AlbumRowContextMenu(albumRow: albumRow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(albumRow.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(albumRow.primaryArtistName ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
