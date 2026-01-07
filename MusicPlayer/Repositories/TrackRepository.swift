import Foundation

/// Protocol defining track persistence operations
protocol TrackRepository {
    /// Load all tracks from the repository
    /// - Returns: Array of tracks
    /// - Throws: Repository errors
    func loadTracks() async throws -> [Track]
    
    /// Save tracks to the repository
    /// - Parameter tracks: Array of tracks to save
    /// - Throws: Repository errors
    func saveTracks(_ tracks: [Track]) async throws
}
