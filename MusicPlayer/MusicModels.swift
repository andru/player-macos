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
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    
    init(id: UUID = UUID(), title: String, artist: String, album: String, duration: TimeInterval, fileURL: URL, artworkURL: URL? = nil, genre: String? = nil, year: Int? = nil, trackNumber: Int? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.artworkURL = artworkURL
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Album Model
struct Album: Identifiable, Hashable {
    let id: UUID
    var name: String
    var artist: String
    var artworkURL: URL?
    var tracks: [Track]
    var year: Int?
    
    init(id: UUID = UUID(), name: String, artist: String, artworkURL: URL? = nil, tracks: [Track] = [], year: Int? = nil) {
        self.id = id
        self.name = name
        self.artist = artist
        self.artworkURL = artworkURL
        self.tracks = tracks
        self.year = year
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
