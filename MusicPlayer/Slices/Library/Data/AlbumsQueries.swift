protocol AlbumsQueries {
    func fetchAlbumRows() async throws -> [AlbumRow]
}
