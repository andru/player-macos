import GRDB

final class GRDBArtistsQueries: ArtistsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchArtistRows() async throws -> [ArtistRow] {
        return try await dbWriter.read { db in
            // Query unique artists from local_track_tags
            let sql = """
                SELECT DISTINCT
                  ROW_NUMBER() OVER (ORDER BY artistName COLLATE NOCASE) AS id,
                  artistName AS name
                FROM (
                  SELECT COALESCE(tags.artist, 'Unknown Artist') AS artistName
                  FROM library_tracks lt
                  JOIN local_track_tags tags ON tags.id = lt.localTrackTagsId
                  UNION
                  SELECT COALESCE(tags.albumArtist, 'Unknown Artist') AS artistName
                  FROM library_tracks lt
                  JOIN local_track_tags tags ON tags.id = lt.localTrackTagsId
                  WHERE tags.albumArtist IS NOT NULL
                )
                ORDER BY artistName COLLATE NOCASE
            """
            
            let rows = try Row.fetchAll(db, sql: sql)
            return rows.map { row in
                ArtistRow(
                    id: row["id"],
                    name: row["name"]
                )
            }
        }
    }
}
