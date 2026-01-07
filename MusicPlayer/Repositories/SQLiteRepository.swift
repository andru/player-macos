import Foundation
import SQLite3

/// SQLite-based implementation of track and collection repositories
/// This class is thread-safe and operates on a background queue
class SQLiteRepository: TrackRepository, CollectionRepository {
    private var db: OpaquePointer?
    private let dbFileName = "library.db"
    private let queue = DispatchQueue(label: "com.musicplayer.sqlite", qos: .userInitiated)
    
    // MARK: - Initialization
    
    /// Open database connection at the specified library bundle URL
    /// - Parameter bundleURL: URL to the library bundle
    /// - Throws: DatabaseError if the database cannot be opened
    func openDatabase(at bundleURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: DatabaseError.notOpen)
                    return
                }
                
                do {
                    self.closeDatabase()
                    
                    let dbURL = bundleURL
                        .appendingPathComponent("Contents/Resources/")
                        .appendingPathComponent(self.dbFileName)
                    
                    var db: OpaquePointer?
                    let result = sqlite3_open(dbURL.path, &db)
                    
                    guard result == SQLITE_OK else {
                        let errmsg = String(cString: sqlite3_errmsg(db))
                        sqlite3_close(db)
                        throw DatabaseError.openFailed(message: errmsg)
                    }
                    
                    self.db = db
                    
                    // Enable foreign keys
                    try self.executeSync("PRAGMA foreign_keys = ON")
                    
                    // Run migrations
                    guard let db = self.db else {
                        throw DatabaseError.notOpen
                    }
                    let migrationManager = DatabaseMigrationManager(db: db)
                    try migrationManager.runMigrations()
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Close the database connection
    func closeDatabase() {
        queue.sync {
            if let db = db {
                sqlite3_close(db)
                self.db = nil
            }
        }
    }
    
    // MARK: - TrackRepository
    
    func loadTracks() async throws -> [Track] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Track], Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: DatabaseError.notOpen)
                    return
                }
                
                do {
                    let tracks = try self.loadTracksSync()
                    continuation.resume(returning: tracks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveTracks(_ tracks: [Track]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: DatabaseError.notOpen)
                    return
                }
                
                do {
                    try self.saveTracksSync(tracks)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - CollectionRepository
    
    func loadCollections() async throws -> [Collection] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Collection], Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: DatabaseError.notOpen)
                    return
                }
                
                do {
                    let collections = try self.loadCollectionsSync()
                    continuation.resume(returning: collections)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveCollections(_ collections: [Collection]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: DatabaseError.notOpen)
                    return
                }
                
                do {
                    try self.saveCollectionsSync(collections)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Sync Methods (called on queue)
    
    private func loadTracksSync() throws -> [Track] {
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
    
    private func saveTracksSync(_ tracks: [Track]) throws {
        guard db != nil else {
            throw DatabaseError.notOpen
        }
        
        try executeSync("BEGIN TRANSACTION")
        
        do {
            // Clear existing tracks
            try executeSync("DELETE FROM tracks")
            
            // Insert all tracks
            for track in tracks {
                try insertTrack(track)
            }
            
            try executeSync("COMMIT")
        } catch {
            try? executeSync("ROLLBACK")
            throw error
        }
    }
    
    private func loadCollectionsSync() throws -> [Collection] {
        guard db != nil else {
            throw DatabaseError.notOpen
        }
        
        let query = "SELECT id, name FROM collections ORDER BY name"
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
    
    private func saveCollectionsSync(_ collections: [Collection]) throws {
        guard db != nil else {
            throw DatabaseError.notOpen
        }
        
        try executeSync("BEGIN TRANSACTION")
        
        do {
            // Clear existing collections
            try executeSync("DELETE FROM collections")
            try executeSync("DELETE FROM collection_tracks")
            
            // Insert all collections
            for collection in collections {
                try insertCollection(collection)
            }
            
            try executeSync("COMMIT")
        } catch {
            try? executeSync("ROLLBACK")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func executeSync(_ sql: String) throws {
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
        closeDatabase()
    }
}
