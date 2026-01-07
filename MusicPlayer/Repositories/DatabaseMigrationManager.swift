import Foundation
import SQLite3

/// Manages database schema migrations
class DatabaseMigrationManager {
    private let db: OpaquePointer
    
    /// Current database schema version
    private let currentVersion = 1
    
    init(db: OpaquePointer) {
        self.db = db
    }
    
    /// Run all pending migrations
    func runMigrations() throws {
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
    
    // MARK: - Version Management
    
    private func getDatabaseVersion() throws -> Int {
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
    
    // MARK: - Schema Migrations
    
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
    
    // MARK: - Helper Methods
    
    private func execute(_ sql: String) throws {
        var errmsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errmsg)
        
        if result != SQLITE_OK {
            let message = errmsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errmsg)
            throw DatabaseError.executeFailed(message: message)
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
