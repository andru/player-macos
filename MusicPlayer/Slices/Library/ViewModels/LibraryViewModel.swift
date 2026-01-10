import SwiftUI

@MainActor
class LibraryViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published var selectedAlbum: Album? = nil
    
    @Published var selectedView: LibraryViewMode = .albums
    @Published var selectedCollection: Collection? = nil

    @Published  var displayMode: DisplayMode = .grid
    
    // Use SongRow here so the sortOrder can be bound to Table(sortOrder:)
    @Published var sortOrder = [KeyPathComparator(\SongRow.title)]
    @Published var albumRows: [AlbumRow] = []
    @Published var artistRows: [ArtistRow] = []
    @Published var songRows: [SongRow] = []
    
    let deps: LibraryDependencies
    let repos: Repositories
    
    init(deps: LibraryDependencies, repos: Repositories) {
        self.deps = deps
        self.repos = repos
    }
    
    func loadAlbumRows() async {
        do {
            albumRows = try await deps.albumsQueries.fetchAlbumRows()
        } catch {
            albumRows = []
        }
    }
    
    func loadSongRows() async {
//        do {
//            songRows = try await deps.songsQueries.fetchSongRows()
//        } catch {
//            songRows = []
//        }
    }

    func didClickAlbum(albumRow: AlbumRow) async {
        selectedAlbum = await loadAlbumDetails(releaseGroupId: albumRow.id)
    }
    
    func loadAlbumDetails(releaseGroupId: Int64) async -> Album? {
        do {
            let releaseGroup = try await repos.releaseGroup.loadReleaseGroup(id: releaseGroupId);
            guard let releaseGroup = releaseGroup else {
                return nil
            }
            
            let album = Album(from: releaseGroup)
            return album
            
        } catch {
        
        }
        return nil
    }
    
    func playTracks(tracks: [Track]) async {
        for track in tracks {
            guard let playerMedia = track.toPlayerMedia() else { continue }
            deps.audioPlayer.playNow(playerMedia)
        }
    }
        
    
    // Provide a safe default implementation for artists to keep the file compilable.
    var artists : [Artist] {
        // If `deps.artistRepository` provides a synchronous list use it here; otherwise return an empty array as a placeholder.
        return []
    }
    
}
