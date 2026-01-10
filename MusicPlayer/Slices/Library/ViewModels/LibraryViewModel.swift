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
    
    func loadArtistRows() async {
        do {
            artistRows = try await deps.artistsQueries.fetchArtistRows()
        } catch {
            artistRows = []
        }
    }
    
    func loadSongRows() async {
        do {
            songRows = try await deps.songsQueries.fetchSongRows(
                filter: SongRowFilter(searchText: searchText.isEmpty ? nil : searchText),
                sort: .titleAsc,
                limit: 1000,
                offset: 0
            )
        } catch {
            songRows = []
        }
    }

    func didClickAlbum(albumRow: AlbumRow) async {
        // In the new model, we don't have a direct album entity
        // For now, just do nothing or load songs for this album
        // TODO: Implement album detail view based on local_track_tags
    }
    
    func loadAlbumDetails(albumId: String) async -> Album? {
        // This method is no longer relevant with the new model
        // TODO: Refactor to load songs for an album instead
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
