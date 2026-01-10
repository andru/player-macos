import GRDB


final class GRDBAlbumRowQuery: AlbumsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchAlbumRows() async throws -> [AlbumRow] {
        return try await dbWriter.read { db in
            // Find work by title with artist link
            var sql = """
                SELECT
                  r.id AS id,
                  rg.primaryArtistId AS primaryArtistId,
                  rg.title AS title,
                  a.name AS primaryArtistName,
                  COALESCE(tc.trackCount, 0) AS trackCount
                FROM release r
                LEFT JOIN release_group rg ON r.releaseGroupId = rg.id
                LEFT JOIN artists a ON a.id = rg.primaryArtistId;
            """
            
            sql += " ORDER BY rg.title COLLATE NOCASE "
            sql += " LIMIT ? OFFSET ?"
          
            
            let albums = try AlbumRowRecord.fetchAll(db, sql: sql, arguments: [9999, 0])
            return albums.map { $0.toAlbumRow() }
        }
    }
}
