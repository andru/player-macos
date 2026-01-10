import Foundation

/// Represents linkage from a LibraryTrack to a Recording
/// Used for future identification - not populated during import
struct TrackMatch: Identifiable, Hashable {
    let id: Int64
    var libraryTrackId: Int64  // FK to library_track
    var recordingId: Int64  // FK to recording
    var confidence: Double  // Match confidence score (0.0 to 1.0)
    var matchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: Int64,
        libraryTrackId: Int64,
        recordingId: Int64,
        confidence: Double,
        matchedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.libraryTrackId = libraryTrackId
        self.recordingId = recordingId
        self.confidence = confidence
        self.matchedAt = matchedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, libraryTrackId, recordingId, confidence, matchedAt, createdAt, updatedAt
    }
}
