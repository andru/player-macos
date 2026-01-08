import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

enum ReleaseFormat: String, Codable, CaseIterable {
    case cd = "CD"
    case vinyl = "Vinyl"
    case tape = "Tape"
    case digital = "Digital"
    case other = "Other"
}

struct Release: Identifiable, Hashable, Codable {
    let id: Int64
    var albumId: Int64
    var format: ReleaseFormat
    var edition: String?
    var label: String?
    var year: Int?
    var country: String?
    var catalogNumber: String?
    var barcode: String?
    var discs: Int
    var releaseTitleOverride: String?
    var userNotes: String?
    var isCompilation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var tracks: [Track]
    var album: Album?
    
    init(
        id: Int64,
        albumId: Int64,
        format: ReleaseFormat = .digital,
        edition: String? = nil,
        label: String? = nil,
        year: Int? = nil,
        country: String? = nil,
        catalogNumber: String? = nil,
        barcode: String? = nil,
        discs: Int = 1,
        releaseTitleOverride: String? = nil,
        userNotes: String? = nil,
        isCompilation: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tracks: [Track] = [],
        album: Album? = nil
    ) {
        self.id = id
        self.albumId = albumId
        self.format = format
        self.edition = edition
        self.label = label
        self.year = year
        self.country = country
        self.catalogNumber = catalogNumber
        self.barcode = barcode
        self.discs = discs
        self.releaseTitleOverride = releaseTitleOverride
        self.userNotes = userNotes
        self.isCompilation = isCompilation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tracks = tracks
        self.album = album
    }
    
    var displayTitle: String {
        releaseTitleOverride ?? album?.title ?? "Unknown"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, albumId, format, edition, label, year, country, catalogNumber, barcode
        case discs, releaseTitleOverride, userNotes, isCompilation, createdAt, updatedAt
    }
}
