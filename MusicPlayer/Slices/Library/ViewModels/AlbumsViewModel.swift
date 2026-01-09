import SwiftUI

@MainActor
class AlbumsViewModel: ObservableObject {

    @Published var sortOrder = [KeyPathComparator(\Track.title)]
    @Published var albumRows: [AlbumRow] = []
    
    private var deps: LibraryDependencies?
    private var isConfigured = false
    private var hasLoaded = false

    func configureIfNeeded(deps: LibraryDependencies) {
        guard !isConfigured else { return }
        self.deps = deps
        self.isConfigured = true
    }

    func loadInitialIfNeeded() async throws {
        guard isConfigured, !hasLoaded, let deps else { return }
        hasLoaded = true
        let filters = TrackRowFilter()
        let albums = try await deps.albumsQueries.fetchAlbumRows()
    }
    
    func fetchAlbumDetails(releaseGroupId: Int64) {
        deps.
    }
}
