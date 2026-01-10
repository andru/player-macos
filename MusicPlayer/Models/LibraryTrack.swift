import Foundation

/// Represents "a thing the user can play"
/// Links a local file to its current tags
struct LibraryTrack: Identifiable, Sendable {
    let id: Int64
    let localTrackId: Int64
    let localTrackTagsId: Int64
    let addedAt: Date
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: Int64 = 0,
        localTrackId: Int64,
        localTrackTagsId: Int64,
        addedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.localTrackId = localTrackId
        self.localTrackTagsId = localTrackTagsId
        self.addedAt = addedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
