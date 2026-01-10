protocol SongsQueries {
    func fetchSongRows(
        filter: SongRowFilter,
        sort: SongRowSortOption,
        limit: Int,
        offset: Int
    ) async throws -> [SongRow]
}
