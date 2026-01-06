import Foundation
import SwiftUI

// MARK: - Track Model
struct Track: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var fileURL: URL
    var artworkURL: URL?
    var artworkData: Data?
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    
    init(id: UUID = UUID(), title: String, artist: String, album: String, duration: TimeInterval, fileURL: URL, artworkURL: URL? = nil, artworkData: Data? = nil, genre: String? = nil, year: Int? = nil, trackNumber: Int? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.artworkURL = artworkURL
        self.artworkData = artworkData
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var artwork: NSImage? {
        guard let artworkData = artworkData else { return nil }
        return NSImage(data: artworkData)
    }
}

// MARK: - Album Model
struct Album: Identifiable, Hashable {
    let id: UUID
    var name: String
    var artist: String
    var artworkURL: URL?
    var artworkData: Data?
    var tracks: [Track]
    var year: Int?
    
    init(id: UUID = UUID(), name: String, artist: String, artworkURL: URL? = nil, artworkData: Data? = nil, tracks: [Track] = [], year: Int? = nil) {
        self.id = id
        self.name = name
        self.artist = artist
        self.artworkURL = artworkURL
        self.artworkData = artworkData
        self.tracks = tracks
        self.year = year
    }
    
    var artwork: NSImage? {
        // Prefer artworkData if available
        if let artworkData = artworkData {
            return NSImage(data: artworkData)
        }
        // Fall back to first track's artwork
        if let firstTrackArtwork = tracks.first?.artwork {
            return firstTrackArtwork
        }
        return nil
    }
}

// MARK: - Artist Model
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

// MARK: - Collection Model
struct Collection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var trackIDs: [UUID]
    
    init(id: UUID = UUID(), name: String, trackIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
    }
}

// MARK: - View Selection
enum LibraryView: String, CaseIterable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"
}

// MARK: - Display Mode
enum DisplayMode {
    case grid
    case list
}
