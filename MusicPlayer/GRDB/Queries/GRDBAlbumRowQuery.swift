import GRDB


final class GRDBAlbumRowQuery: AlbumRowQuery {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchAlbumRows() async throws -> [AlbumRow] {
        return try await dbWriter.read { db in
            // Find work by title with artist link
            var sql = """
                SELECT 
                    rg.id as id, 
                    rg.primaryArtistId as primaryArtistId,
                    rg.title as title,
                    a.name as primaryArtistName
                LEFT JOIN artists a ON rg.primaryAristId = a.id
            """
            
            sql += " ORDER BY rg.title COLLATE NOCASE "
            sql += " LIMIT ? OFFSET ?"
          
        
//            let rows = try Row.fetchAll(db, sql: sql, arguments: [9999, 0])
//
//            return rows.map { row in
//                AlbumRow(
//                    id: row["id"],
//                    title: row["title"],
//                    primaryArtistId: row["primaryArtistId"],
//                    primaryArtistName: row["primaryArtistName"]
//                )
//            }
            
            let albums = try AlbumRowRecord.fetchAll(db, sql: sql, arguments: [9999, 0])
            return albums.map { $0.toAlbumRow() }
        }
    }
}
