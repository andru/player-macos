import GRDB

final class GRDBSongsQueries: SongsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchSongRows(filter: SongRowFilter, sort: SongRowSortOption, limit: Int, offset: Int) async throws -> [SongRow] {
        return try await dbWriter.read { db in
            // Query songs from local_track_tags via library_tracks
            var sql = """
                SELECT
                  lt.id AS id,
                  COALESCE(tags.title, 'Unknown') AS title,
                  COALESCE(tags.artist, 'Unknown Artist') AS artistName,
                  COALESCE(tags.album, 'Unknown Album') AS albumTitle,
                  track.duration AS duration,
                  track.fileURL AS fileUrl
                FROM library_tracks lt
                JOIN local_track_tags tags ON tags.id = lt.localTrackTagsId
                JOIN local_tracks track ON track.id = lt.localTrackId
                WHERE 1=1
            """
            
            var arguments: [DatabaseValueConvertible] = []
            
            // Apply filters
            if let searchText = filter.searchText, !searchText.isEmpty {
                sql += " AND (tags.title LIKE ? OR tags.artist LIKE ? OR tags.album LIKE ?)"
                let searchPattern = "%\(searchText)%"
                arguments.append(contentsOf: [searchPattern, searchPattern, searchPattern])
            }
            
            // Apply sorting
            switch sort {
            case .titleAsc:
                sql += " ORDER BY tags.title COLLATE NOCASE ASC"
            case .titleDesc:
                sql += " ORDER BY tags.title COLLATE NOCASE DESC"
            case .artistAsc:
                sql += " ORDER BY tags.artist COLLATE NOCASE ASC"
            case .artistDesc:
                sql += " ORDER BY tags.artist COLLATE NOCASE DESC"
            case .albumAsc:
                sql += " ORDER BY tags.album COLLATE NOCASE ASC"
            case .albumDesc:
                sql += " ORDER BY tags.album COLLATE NOCASE DESC"
            case .durationAsc:
                sql += " ORDER BY track.duration ASC"
            case .durationDesc:
                sql += " ORDER BY track.duration DESC"
            }
            
            sql += " LIMIT ? OFFSET ?"
            arguments.append(limit)
            arguments.append(offset)
            
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))
            return rows.map { row in
                SongRow(
                    id: row["id"],
                    title: row["title"],
                    artistName: row["artistName"],
                    albumTitle: row["albumTitle"],
                    duration: row["duration"],
                    fileUrl: row["fileUrl"].flatMap { URL(fileURLWithPath: $0) }
                )
            }
        }
    }
}
