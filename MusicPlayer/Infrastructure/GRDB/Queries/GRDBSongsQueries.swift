import GRDB

final class GRDBSongsQueries: SongsQueries {
    
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func fetchSongRows(filter: SongRowFilter, sort: SongRowSortOption, limit: Int, offset: Int) async throws -> [SongRow] {
        return try await dbWriter.read { db in
            // Fetch songs from library_track + local_track_tags + local_track
            var sql = """
                SELECT
                    lt.id AS id,
                    COALESCE(tags.title, 'Unknown Title') AS title,
                    COALESCE(tags.artist, 'Unknown Artist') AS artist,
                    COALESCE(tags.album, 'Unknown Album') AS album,
                    tags.trackNumber,
                    tags.discNumber,
                    track.duration,
                    track.fileURL
                FROM library_track lt
                JOIN local_track_tags tags ON tags.id = lt.localTrackTagsId
                JOIN local_track track ON track.id = lt.localTrackId
            """
            
            var conditions: [String] = []
            var arguments: [DatabaseValueConvertible] = []
            
            // Apply search filter
            if let searchText = filter.searchText, !searchText.isEmpty {
                conditions.append("(tags.title LIKE ? OR tags.artist LIKE ? OR tags.album LIKE ?)")
                let searchPattern = "%\(searchText)%"
                arguments.append(contentsOf: [searchPattern, searchPattern, searchPattern])
            }
            
            // Apply artist filter
            if let artistNames = filter.artistNames, !artistNames.isEmpty {
                let placeholders = artistNames.map { _ in "?" }.joined(separator: ", ")
                conditions.append("tags.artist IN (\(placeholders))")
                arguments.append(contentsOf: artistNames)
            }
            
            // Apply album filter
            if let albumTitles = filter.albumTitles, !albumTitles.isEmpty {
                let placeholders = albumTitles.map { _ in "?" }.joined(separator: ", ")
                conditions.append("tags.album IN (\(placeholders))")
                arguments.append(contentsOf: albumTitles)
            }
            
            // Add WHERE clause if there are conditions
            if !conditions.isEmpty {
                sql += " WHERE " + conditions.joined(separator: " AND ")
            }
            
            // Add sorting
            sql += " ORDER BY "
            switch sort {
            case .titleAsc:
                sql += "tags.title COLLATE NOCASE ASC"
            case .titleDesc:
                sql += "tags.title COLLATE NOCASE DESC"
            case .artistAsc:
                sql += "tags.artist COLLATE NOCASE ASC"
            case .artistDesc:
                sql += "tags.artist COLLATE NOCASE DESC"
            case .albumAsc:
                sql += "tags.album COLLATE NOCASE ASC"
            case .albumDesc:
                sql += "tags.album COLLATE NOCASE DESC"
            case .durationAsc:
                sql += "track.duration ASC"
            case .durationDesc:
                sql += "track.duration DESC"
            }
            
            // Add pagination
            sql += " LIMIT ? OFFSET ?"
            arguments.append(limit)
            arguments.append(offset)
            
            struct SongRowSQL: Decodable, FetchableRecord {
                let id: Int64
                let title: String
                let artist: String
                let album: String
                let trackNumber: Int?
                let discNumber: Int?
                let duration: Double?
                let fileURL: String
            }
            
            let rows = try SongRowSQL.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))
            
            return rows.map { row in
                SongRow(
                    id: row.id,
                    title: row.title,
                    artistName: row.artist,
                    albumTitle: row.album,
                    trackNumber: row.trackNumber,
                    discNumber: row.discNumber,
                    duration: row.duration,
                    fileUrl: URL(fileURLWithPath: row.fileURL)
                )
            }
        }
    }
}
