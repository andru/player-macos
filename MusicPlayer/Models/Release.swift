import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

enum ReleaseFormat: String, Codable, CaseIterable {
    case cd = "CD"
    case vinyl = "Vinyl"
    case tape = "Tape"
    case digital = "Digital"
    case other = "Other"
}

/// A specific issued product (format, edition, label, country, year)
struct Release: Identifiable, Hashable {
    let id: Int64
    var releaseGroupId: Int64
    var format: ReleaseFormat
    var edition: String?
    var year: Int?
    var country: String?
    var catalogNumber: String?
    var barcode: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var media: [Medium]
    var labels: [Label]
    var releaseGroup: ReleaseGroup?
    
    init(
        id: Int64,
        releaseGroupId: Int64,
        format: ReleaseFormat = .digital,
        edition: String? = nil,
        year: Int? = nil,
        country: String? = nil,
        catalogNumber: String? = nil,
        barcode: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        media: [Medium] = [],
        labels: [Label] = [],
        releaseGroup: ReleaseGroup? = nil
    ) {
        self.id = id
        self.releaseGroupId = releaseGroupId
        self.format = format
        self.edition = edition
        self.year = year
        self.country = country
        self.catalogNumber = catalogNumber
        self.barcode = barcode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.media = media
        self.labels = labels
        self.releaseGroup = releaseGroup
    }
    
    var displayTitle: String {
        releaseGroup?.title ?? "Unknown"
    }
    
    var trackCount: Int {
        media.reduce(0) { $0 + $1.tracks.count }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, releaseGroupId, format, edition, year, country, catalogNumber, barcode, createdAt, updatedAt
    }
}
