import Foundation

/// Represents linkage from a LibraryTrack to a Recording
/// Used for future MusicBrainz identification
/// One library track can match multiple recordings (e.g., uncertain matches)
struct TrackMatch: Identifiable, Sendable {
    let id: Int64
    let libraryTrackId: Int64
    let recordingId: Int64
    let confidence: Double // 0.0 to 1.0
    let matchedAt: Date
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: Int64 = 0,
        libraryTrackId: Int64,
        recordingId: Int64,
        confidence: Double = 1.0,
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
}
