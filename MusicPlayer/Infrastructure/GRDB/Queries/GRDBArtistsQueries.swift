import GRDB

final class GRDBArtistsQueries: ArtistsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchArtistRows() async throws -> [ArtistRow] {
        return try await dbWriter.read { db in
            // Group library tracks by artist name
            let sql = """
                SELECT DISTINCT
                    ROW_NUMBER() OVER (ORDER BY tags.artist COLLATE NOCASE) AS id,
                    COALESCE(tags.artist, 'Unknown Artist') AS name
                FROM library_track lt
                JOIN local_track_tags tags ON tags.id = lt.localTrackTagsId
                WHERE tags.artist IS NOT NULL AND tags.artist != ''
                ORDER BY name COLLATE NOCASE
            """
            
            struct ArtistRowSQL: Decodable, FetchableRecord {
                let id: Int64
                let name: String
            }
            
            let rows = try ArtistRowSQL.fetchAll(db, sql: sql)
            
            return rows.map { row in
                ArtistRow(id: row.id, name: row.name)
            }
        }
    }
}
