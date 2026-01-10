import GRDB


final class GRDBAlbumRowQuery: AlbumsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchAlbumRows() async throws -> [AlbumRow] {
        return try await dbWriter.read { db in
            // Group library tracks by album and albumArtist (or compilation)
            let sql = """
                SELECT
                    COALESCE(tags.album, 'Unknown Album') AS albumTitle,
                    CASE 
                        WHEN tags.isCompilation = 1 THEN NULL
                        ELSE tags.albumArtist
                    END AS albumArtist,
                    tags.isCompilation,
                    COUNT(DISTINCT lt.id) AS trackCount
                FROM library_track lt
                JOIN local_track_tags tags ON tags.id = lt.localTrackTagsId
                GROUP BY albumTitle, albumArtist, tags.isCompilation
                ORDER BY albumTitle COLLATE NOCASE
            """
            
            struct AlbumRowSQL: Decodable, FetchableRecord {
                let albumTitle: String
                let albumArtist: String?
                let isCompilation: Bool
                let trackCount: Int
            }
            
            let rows = try AlbumRowSQL.fetchAll(db, sql: sql)
            
            return rows.map { row in
                // Create a stable ID from album title + artist (or compilation marker)
                let idString: String
                if row.isCompilation {
                    idString = "compilation:\(row.albumTitle)"
                } else {
                    idString = "\(row.albumTitle):\(row.albumArtist ?? "unknown")"
                }
                
                return AlbumRow(
                    id: idString,
                    title: row.albumTitle,
                    albumArtist: row.albumArtist,
                    isCompilation: row.isCompilation,
                    trackCount: row.trackCount,
                    artwork: nil  // TODO: Load artwork from digital_file.artworkData via local_track join
                )
            }
        }
    }
}
