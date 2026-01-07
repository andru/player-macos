import Foundation

/// Facade for database operations, providing a simple interface to the underlying repository
/// This bridges the old @MainActor DatabaseManager API with the new async repository pattern
class DatabaseManager {
    private let repository: SQLiteRepository
    
    init() {
        self.repository = SQLiteRepository()
    }
    
    /// Open database connection at the specified library bundle URL
    func openDatabase(at bundleURL: URL) async throws {
        try await repository.openDatabase(at: bundleURL)
    }
    
    /// Close the database connection
    func closeDatabase() {
        repository.closeDatabase()
    }
    
    /// Load all tracks from the database
    func loadTracks() async throws -> [Track] {
        try await repository.loadTracks()
    }
    
    /// Save tracks to the database
    func saveTracks(_ tracks: [Track]) async throws {
        try await repository.saveTracks(tracks)
    }
    
    /// Load all collections from the database
    func loadCollections() async throws -> [Collection] {
        try await repository.loadCollections()
    }
    
    /// Save collections to the database
    func saveCollections(_ collections: [Collection]) async throws {
        try await repository.saveCollections(collections)
    }
}
