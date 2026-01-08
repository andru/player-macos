import Foundation

/// Protocol defining track persistence operations
protocol TrackRepository {
    /// Load all tracks from the repository
    /// - Returns: Array of tracks
    /// - Throws: Repository errors
    func loadTracks() async throws -> [Track]
    
    /// Load tracks for a specific release
    func loadTracks(forReleaseId releaseId: Int64, orderByDiscAndTrackNumber: Bool) async throws -> [Track]
    
    /// Load a specific track by ID with optional relationships
    func loadTrack(id: Int64, includeDigitalFiles: Bool) async throws -> Track?
    
    /// Save or update a track
    func saveTrack(_ track: Track) async throws -> Track
    
    /// Save multiple tracks
    /// - Parameter tracks: Array of tracks to save
    /// - Throws: Repository errors
    func saveTracks(_ tracks: [Track]) async throws
}
