import Foundation
import AVFoundation

class LibraryManager: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var collections: [Collection] = []
    
    var albums: [Album] {
        var albumDict: [String: Album] = [:]
        
        for track in tracks {
            let key = "\(track.album)-\(track.artist)"
            if var album = albumDict[key] {
                album.tracks.append(track)
                albumDict[key] = album
            } else {
                let album = Album(
                    name: track.album,
                    artist: track.artist,
                    artworkURL: track.artworkURL,
                    tracks: [track],
                    year: track.year
                )
                albumDict[key] = album
            }
        }
        
        return Array(albumDict.values).sorted { $0.name < $1.name }
    }
    
    var artists: [Artist] {
        var artistDict: [String: Artist] = [:]
        
        for album in albums {
            if var artist = artistDict[album.artist] {
                artist.albums.append(album)
                artistDict[album.artist] = artist
            } else {
                let artist = Artist(name: album.artist, albums: [album])
                artistDict[album.artist] = artist
            }
        }
        
        return Array(artistDict.values).sorted { $0.name < $1.name }
    }
    
    init() {
        // Add some sample data for demonstration
        loadSampleData()
    }
    
    func addTrack(_ track: Track) {
        tracks.append(track)
    }
    
    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
    }
    
    func addCollection(_ collection: Collection) {
        collections.append(collection)
    }
    
    func removeCollection(_ collection: Collection) {
        collections.removeAll { $0.id == collection.id }
    }
    
    func importFiles(urls: [URL]) {
        for url in urls {
            if let track = createTrack(from: url) {
                addTrack(track)
            }
        }
    }
    
    private func createTrack(from url: URL) -> Track? {
        let asset = AVAsset(url: url)
        
        // Extract metadata
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var duration: TimeInterval = 0
        
        // Get duration
        duration = CMTimeGetSeconds(asset.duration)
        
        // Get metadata
        let metadata = asset.commonMetadata
        for item in metadata {
            guard let key = item.commonKey?.rawValue,
                  let value = item.stringValue else { continue }
            
            switch key {
            case "title":
                title = value
            case "artist":
                artist = value
            case "albumName":
                album = value
            default:
                break
            }
        }
        
        return Track(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            fileURL: url
        )
    }
    
    private func loadSampleData() {
        // Sample tracks for demonstration UI
        // Note: These use placeholder file paths. Import real music files to play audio.
        let sampleTracks = [
            Track(
                title: "Sample Song 1",
                artist: "Sample Artist 1",
                album: "Sample Album 1",
                duration: 180,
                fileURL: URL(fileURLWithPath: "/path/to/sample1.mp3"),
                genre: "Rock",
                year: 2023,
                trackNumber: 1
            ),
            Track(
                title: "Sample Song 2",
                artist: "Sample Artist 1",
                album: "Sample Album 1",
                duration: 200,
                fileURL: URL(fileURLWithPath: "/path/to/sample2.mp3"),
                genre: "Rock",
                year: 2023,
                trackNumber: 2
            ),
            Track(
                title: "Another Song",
                artist: "Sample Artist 2",
                album: "Another Album",
                duration: 220,
                fileURL: URL(fileURLWithPath: "/path/to/sample3.mp3"),
                genre: "Pop",
                year: 2024,
                trackNumber: 1
            )
        ]
        
        tracks = sampleTracks
        
        // Sample collection
        collections = [
            Collection(name: "Favorites", trackIDs: [sampleTracks[0].id, sampleTracks[2].id])
        ]
    }
}
