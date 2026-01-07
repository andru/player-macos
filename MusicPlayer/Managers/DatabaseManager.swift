import Foundation
import SQLite3

/// Manages the SQLite database connection and operations for the music library
@MainActor
class DatabaseManager {
    private var db: OpaquePointer?
    private let dbFileName = "library.db"
    private var libraryURL: URL?
    
    /// Current database schema version
    private let currentVersion = 1
    
    init() {
        // Database will be initialized when library location is set
    }
    
    /// Open database connection at the specified library bundle URL
    func openDatabase(at bundleURL: URL) throws {
        closeDatabase()
        
        let dbURL = bundleURL
            .appendingPathComponent("Contents/Resources/")
            .appendingPathComponent(dbFileName)
        
        self.libraryURL = bundleURL
        
        var db: OpaquePointer?
        let result = sqlite3_open(dbURL.path, &db)
        
        guard result == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            sqlite3_close(db)
            throw DatabaseError.openFailed(message: errmsg)
        }
        
        self.db = db
        
        // Enable foreign keys
        try execute("PRAGMA foreign_keys = ON")
        
        // Run migrations
        try runMigrations()
    }
    
    /// Close the database connection
    func closeDatabase() {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
    }
    
    // MARK: - Migrations
    
    private func runMigrations() throws {
        let currentVersion = try getDatabaseVersion()
        
        if currentVersion < 1 {
            try createInitialSchema()
            try setDatabaseVersion(1)
        }
        
        // Future migrations will be added here
        // if currentVersion < 2 {
        //     try migration_v2()
        //     try setDatabaseVersion(2)
        // }
    }
    
    private func getDatabaseVersion() throws -> Int {
        // Create user_version table or get version
        let query = "PRAGMA user_version"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(message: "Failed to prepare version query")
        }
        
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        
        return 0
    }
    
    private func setDatabaseVersion(_ version: Int) throws {
        try execute("PRAGMA user_version = \(version)")
    }
    
    private func createInitialSchema() throws {
        // Create tracks table
        try execute("""
            CREATE TABLE IF NOT EXISTS tracks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                artist TEXT NOT NULL,
                album TEXT NOT NULL,
                album_artist TEXT,
                duration REAL NOT NULL,
                file_url TEXT NOT NULL,
                artwork_url TEXT,
                artwork_data BLOB,
                genre TEXT,
                year INTEGER,
                track_number INTEGER
            )
        """)
        
        // Create collections table
        try execute("""
            CREATE TABLE IF NOT EXISTS collections (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL
            )
        """)
        
        // Create collection_tracks junction table
        try execute("""
            CREATE TABLE IF NOT EXISTS collection_tracks (
                collection_id TEXT NOT NULL,
                track_id TEXT NOT NULL,
                position INTEGER NOT NULL,
                PRIMARY KEY (collection_id, track_id),
                FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
                FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
            )
        """)
        
        // Create indexes for better performance
        try execute("CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks(artist)")
        try execute("CREATE INDEX IF NOT EXISTS idx_tracks_album ON tracks(album)")
        try execute("CREATE INDEX IF NOT EXISTS idx_tracks_album_artist ON tracks(album_artist)")
        try execute("CREATE INDEX IF NOT EXISTS idx_collection_tracks_collection ON collection_tracks(collection_id)")
    }
    
    // MARK: - Track Operations
    
    func saveTracks(_ tracks: [Track]) throws {
        guard db != nil else {
            throw DatabaseError.notOpen
        }
        
        try execute("BEGIN TRANSACTION")
        
        do {
            // Clear existing tracks
            try execute("DELETE FROM tracks")
            
            // Insert all tracks
            for track in tracks {
                try insertTrack(track)
            }
            
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }
    
    func loadTracks() throws -> [Track] {
        guard db != nil else {
            throw DatabaseError.notOpen
        }
        
        let query = "SELECT id, title, artist, album, album_artist, duration, file_url, artwork_url, artwork_data, genre, year, track_number FROM tracks"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(message: errmsg)
        }
        
        defer { sqlite3_finalize(statement) }
        
        var tracks: [Track] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let idString = String(cString: sqlite3_column_text(statement, 0))
            let id = UUID(uuidString: idString) ?? UUID()
            let title = String(cString: sqlite3_column_text(statement, 1))
            let artist = String(cString: sqlite3_column_text(statement, 2))
            let album = String(cString: sqlite3_column_text(statement, 3))
            
            let albumArtist: String? = {
                if let text = sqlite3_column_text(statement, 4) {
                    return String(cString: text)
                }
                return nil
            }()
            
            let duration = sqlite3_column_double(statement, 5)
            let fileURLString = String(cString: sqlite3_column_text(statement, 6))
            let fileURL = URL(fileURLWithPath: fileURLString)
            
            let artworkURL: URL? = {
                if let text = sqlite3_column_text(statement, 7) {
                    return URL(fileURLWithPath: String(cString: text))
                }
                return nil
            }()
            
            let artworkData: Data? = {
                if let blob = sqlite3_column_blob(statement, 8) {
                    let size = Int(sqlite3_column_bytes(statement, 8))
                    return Data(bytes: blob, count: size)
                }
                return nil
            }()
            
            let genre: String? = {
                if let text = sqlite3_column_text(statement, 9) {
                    return String(cString: text)
                }
                return nil
            }()
            
            let year: Int? = {
                if sqlite3_column_type(statement, 10) != SQLITE_NULL {
                    return Int(sqlite3_column_int(statement, 10))
                }
                return nil
            }()
            
            let trackNumber: Int? = {
                if sqlite3_column_type(statement, 11) != SQLITE_NULL {
                    return Int(sqlite3_column_int(statement, 11))
                }
                return nil
            }()
            
            let track = Track(
                id: id,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                duration: duration,
                fileURL: fileURL,
                artworkURL: artworkURL,
                artworkData: artworkData,
                genre: genre,
                year: year,
                trackNumber: trackNumber
            )
            
            tracks.append(track)
        }
        
        return tracks
    }
    
    private func insertTrack(_ track: Track) throws {
        let query = """
            INSERT INTO tracks (id, title, artist, album, album_artist, duration, file_url, 
                              artwork_url, artwork_data, genre, year, track_number)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(message: errmsg)
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, track.id.uuidString, -1, nil)
        sqlite3_bind_text(statement, 2, track.title, -1, nil)
        sqlite3_bind_text(statement, 3, track.artist, -1, nil)
        sqlite3_bind_text(statement, 4, track.album, -1, nil)
        
        if let albumArtist = track.albumArtist {
            sqlite3_bind_text(statement, 5, albumArtist, -1, nil)
        } else {
            sqlite3_bind_null(statement, 5)
        }
        
        sqlite3_bind_double(statement, 6, track.duration)
        sqlite3_bind_text(statement, 7, track.fileURL.path, -1, nil)
        
        if let artworkURL = track.artworkURL {
            sqlite3_bind_text(statement, 8, artworkURL.path, -1, nil)
        } else {
            sqlite3_bind_null(statement, 8)
        }
        
        if let artworkData = track.artworkData {
            artworkData.withUnsafeBytes { bytes in
                sqlite3_bind_blob(statement, 9, bytes.baseAddress, Int32(artworkData.count), nil)
            }
        } else {
            sqlite3_bind_null(statement, 9)
        }
        
        if let genre = track.genre {
            sqlite3_bind_text(statement, 10, genre, -1, nil)
        } else {
            sqlite3_bind_null(statement, 10)
        }
        
        if let year = track.year {
            sqlite3_bind_int(statement, 11, Int32(year))
        } else {
            sqlite3_bind_null(statement, 11)
        }
        
        if let trackNumber = track.trackNumber {
            sqlite3_bind_int(statement, 12, Int32(trackNumber))
        } else {
            sqlite3_bind_null(statement, 12)
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.insertFailed(message: errmsg)
        }
    }
    
    // MARK: - Collection Operations
    
    func saveCollections(_ collections: [Collection]) throws {
        guard db != nil else {
            throw DatabaseError.notOpen
        }
        
        try execute("BEGIN TRANSACTION")
        
        do {
            // Clear existing collections
            try execute("DELETE FROM collections")
            try execute("DELETE FROM collection_tracks")
            
            // Insert all collections
            for collection in collections {
                try insertCollection(collection)
            }
            
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }
    
    func loadCollections() throws -> [Collection] {
        guard db != nil else {
            throw DatabaseError.notOpen
        }
        
        let query = "SELECT id, name FROM collections"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(message: errmsg)
        }
        
        defer { sqlite3_finalize(statement) }
        
        var collections: [Collection] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let idString = String(cString: sqlite3_column_text(statement, 0))
            let id = UUID(uuidString: idString) ?? UUID()
            let name = String(cString: sqlite3_column_text(statement, 1))
            
            // Load track IDs for this collection
            let trackIDs = try loadCollectionTrackIDs(collectionID: id)
            
            let collection = Collection(id: id, name: name, trackIDs: trackIDs)
            collections.append(collection)
        }
        
        return collections
    }
    
    private func insertCollection(_ collection: Collection) throws {
        let query = "INSERT INTO collections (id, name) VALUES (?, ?)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(message: errmsg)
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, collection.id.uuidString, -1, nil)
        sqlite3_bind_text(statement, 2, collection.name, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.insertFailed(message: errmsg)
        }
        
        // Insert track associations
        for (index, trackID) in collection.trackIDs.enumerated() {
            try insertCollectionTrack(collectionID: collection.id, trackID: trackID, position: index)
        }
    }
    
    private func insertCollectionTrack(collectionID: UUID, trackID: UUID, position: Int) throws {
        let query = "INSERT INTO collection_tracks (collection_id, track_id, position) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(message: errmsg)
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, collectionID.uuidString, -1, nil)
        sqlite3_bind_text(statement, 2, trackID.uuidString, -1, nil)
        sqlite3_bind_int(statement, 3, Int32(position))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.insertFailed(message: errmsg)
        }
    }
    
    private func loadCollectionTrackIDs(collectionID: UUID) throws -> [UUID] {
        let query = "SELECT track_id FROM collection_tracks WHERE collection_id = ? ORDER BY position"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(message: errmsg)
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, collectionID.uuidString, -1, nil)
        
        var trackIDs: [UUID] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let trackIDString = String(cString: sqlite3_column_text(statement, 0))
            if let trackID = UUID(uuidString: trackIDString) {
                trackIDs.append(trackID)
            }
        }
        
        return trackIDs
    }
    
    // MARK: - Helper Methods
    
    private func execute(_ sql: String) throws {
        guard let db = db else {
            throw DatabaseError.notOpen
        }
        
        var errmsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errmsg)
        
        if result != SQLITE_OK {
            let message = errmsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errmsg)
            throw DatabaseError.executeFailed(message: message)
        }
    }
    
    deinit {
        Task { @MainActor [db] in
            if let db = db {
                sqlite3_close(db)
                self.db = nil
            }
        }
    }
}

// MARK: - Database Errors

enum DatabaseError: Error, LocalizedError {
    case notOpen
    case openFailed(message: String)
    case queryFailed(message: String)
    case insertFailed(message: String)
    case executeFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notOpen:
            return "Database is not open"
        case .openFailed(let message):
            return "Failed to open database: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .insertFailed(let message):
            return "Insert failed: \(message)"
        case .executeFailed(let message):
            return "Execution failed: \(message)"
        }
    }
}
