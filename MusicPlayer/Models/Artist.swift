import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Artist: Identifiable, Hashable {
    let id: Int64
    var name: String
    var sortName: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var albums: [ReleaseGroup]
    var works: [Work]
    
    init(
        id: Int64,
        name: String,
        sortName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        albums: [ReleaseGroup] = [],
        works: [Work] = []
    ) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.albums = albums
        self.works = works
    }
    
    var trackCount: Int {
        albums.reduce(0) { $0 + $1.trackCount }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, sortName, createdAt, updatedAt
    }
}
