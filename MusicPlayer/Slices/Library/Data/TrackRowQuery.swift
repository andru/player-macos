protocol TrackRowQuery {
    func fetchTrackRows(
        filter: TrackRowFilter,
        sort: TrackRowSortOption,
        limit: Int,
        offset: Int
    ) async throws -> [TrackRow]
}
