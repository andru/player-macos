import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Artist: Identifiable, Hashable {
    let id: Int64
    var name: String
    var sortName: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var albums: [Album]
    
    init(
        id: Int64,
        name: String,
        sortName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        albums: [Album] = []
    ) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.albums = albums
    }
    
    var trackCount: Int {
        albums.reduce(0) { $0 + $1.trackCount }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, sortName, createdAt, updatedAt
    }
}
