import Foundation

/// Represents "a thing the user can play"
/// Links to a LocalTrack (file) and LocalTrackTags (current tags)
struct LibraryTrack: Identifiable, Hashable {
    let id: Int64
    var localTrackId: Int64  // FK to local_track
    var localTrackTagsId: Int64  // FK to local_track_tags
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var localTrack: LocalTrack?
    var tags: LocalTrackTags?
    
    init(
        id: Int64,
        localTrackId: Int64,
        localTrackTagsId: Int64,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        localTrack: LocalTrack? = nil,
        tags: LocalTrackTags? = nil
    ) {
        self.id = id
        self.localTrackId = localTrackId
        self.localTrackTagsId = localTrackTagsId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.localTrack = localTrack
        self.tags = tags
    }
    
    enum CodingKeys: String, CodingKey {
        case id, localTrackId, localTrackTagsId, createdAt, updatedAt
    }
}
