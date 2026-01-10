import GRDB

final class GRDBSongsQueries: SongsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchSongRows(filter: SongRowFilter, sort: SongRowSortOption, limit: Int, offset: Int) async throws -> [SongRow] {
        return try await dbWriter.read { db in
            // Find work by title with artist link
            let sql = """
                SELECT
                  t.id AS trackId,
                  t.position AS trackNumber,

                  COALESCE(NULLIF(t.titleOverride, ''), rec.title) AS trackTitle,

                  r.id AS releaseId,
                  rg.title AS releaseTitle,

                  ar.id AS artistId,
                  ar.name AS artistName,

                  rec.length AS durationMs,

                  f.url AS fileUrl
                FROM track t
                JOIN medium m
                  ON m.id = t.mediumId
                JOIN release r
                  ON r.id = m.releaseId
                LEFT JOIN release_group rg
                  ON rg.id = r.releaseGroupId
                LEFT JOIN artist ar
                  ON ar.id = rg.primaryArtistId
                JOIN recording rec
                  ON rec.id = t.recordingId
                LEFT JOIN media_file f
                  ON f.recordingId = rec.id
                ORDER BY
                  r.id, m.position, t.position;
            """
//            if let tracks = try WorkRecord.fetchAll(db, sql: sql, arguments: []) {
//                return record.toWork()
//            }
            return []
        }
    }
}
