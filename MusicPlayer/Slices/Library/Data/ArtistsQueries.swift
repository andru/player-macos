protocol ArtistsQueries {
    func fetchArtistRows() async throws -> [ArtistRow]
}
