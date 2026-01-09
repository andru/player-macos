import GRDB

final class GRDBTrackRowQuery: TrackRowQuery {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchTrackRows(filter: TrackRowFilter, sort: TrackRowSortOption, limit: Int, offset: Int) async throws -> [TrackRow] {
        return try await dbWriter.read { db in
            // Find work by title with artist link
            let sql = """
                SELECT t.* FROM tracks t
            """
//            if let tracks = try WorkRecord.fetchAll(db, sql: sql, arguments: []) {
//                return record.toWork()
//            }
            return []
        }
    }
}
