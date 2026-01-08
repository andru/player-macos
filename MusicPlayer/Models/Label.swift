import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Label: Identifiable, Hashable {
    let id: Int64
    var name: String
    var sortName: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var releases: [Release]
    
    init(
        id: Int64,
        name: String,
        sortName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        releases: [Release] = []
    ) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.releases = releases
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, sortName, createdAt, updatedAt
    }
}
