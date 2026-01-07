import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Artist: Identifiable, Hashable {
    let id: UUID
    var name: String
    var albums: [Album]

    init(id: UUID = UUID(), name: String, albums: [Album] = []) {
        self.id = id
        self.name = name
        self.albums = albums
    }

    var trackCount: Int {
        albums.reduce(0) { $0 + $1.tracks.count }
    }
}
