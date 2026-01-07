import Foundation

/// Protocol defining collection persistence operations
protocol CollectionRepository {
    /// Load all collections from the repository
    /// - Returns: Array of collections
    /// - Throws: Repository errors
    func loadCollections() async throws -> [Collection]
    
    /// Save collections to the repository
    /// - Parameter collections: Array of collections to save
    /// - Throws: Repository errors
    func saveCollections(_ collections: [Collection]) async throws
}
