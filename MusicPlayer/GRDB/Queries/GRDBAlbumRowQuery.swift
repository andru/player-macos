import GRDB


final class GRDBAlbumRowQuery: AlbumsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchAlbumRows() async throws -> [AlbumRow] {
        return try await dbWriter.read { db in
            // Query albums from local_track_tags via library_tracks
            // Group by (album, albumArtist OR compilation handling)
            let sql = """
                SELECT
                  ROW_NUMBER() OVER (ORDER BY tags.album COLLATE NOCASE) AS id,
                  COALESCE(tags.album, 'Unknown Album') AS title,
                  NULL AS primaryArtistId,
                  CASE 
                    WHEN tags.isCompilation = 1 THEN 'Various Artists'
                    ELSE COALESCE(tags.albumArtist, tags.artist, 'Unknown Artist')
                  END AS primaryArtistName,
                  NULL AS artwork
                FROM library_tracks lt
                JOIN local_track_tags tags ON tags.id = lt.localTrackTagsId
                GROUP BY 
                  COALESCE(tags.album, 'Unknown Album'),
                  CASE 
                    WHEN tags.isCompilation = 1 THEN 'Various Artists'
                    ELSE COALESCE(tags.albumArtist, tags.artist, 'Unknown Artist')
                  END
                ORDER BY tags.album COLLATE NOCASE
            """
            
            let albums = try AlbumRowRecord.fetchAll(db, sql: sql)
            return albums.map { $0.toAlbumRow() }
        }
    }
}
