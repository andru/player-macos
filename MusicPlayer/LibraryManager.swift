import Foundation
import AVFoundation

class LibraryManager: ObservableObject {
    @Published var tracks: [Track] = [] {
        didSet {
            if isLoaded {
                saveLibrary()
            }
        }
    }
    @Published var collections: [Collection] = [] {
        didSet {
            if isLoaded {
                saveLibrary()
            }
        }
    }
    
    private let libraryFileName = "MusicLibrary.json"
    private var isLoaded = false
    private var saveWorkItem: DispatchWorkItem?
    private let saveDebounceInterval: TimeInterval = 0.5  // Wait 0.5 seconds before saving
    
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
                    artworkData: track.artworkData,
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
        // Load existing library data, or use sample data if none exists
        loadLibrary()
        isLoaded = true
    }
    
    // MARK: - Persistence
    
    /// Get the URL for the library file in Application Support directory
    private func getLibraryFileURL() -> URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Error: Could not find Application Support directory")
            return nil
        }
        
        // Create app-specific directory
        let appDirectory = appSupportURL.appendingPathComponent("MusicPlayer", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating app directory: \(error)")
                return nil
            }
        }
        
        return appDirectory.appendingPathComponent(libraryFileName)
    }
    
    /// Save the library data to disk
    private func saveLibrary() {
        // Cancel any pending save operation
        saveWorkItem?.cancel()
        
        // Create a new debounced save operation
        let workItem = DispatchWorkItem { [unowned self] in
            self.performSave()
        }
        
        saveWorkItem = workItem
        
        // Schedule the save operation after the debounce interval
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
    }
    
    /// Perform the actual save operation to disk
    private func performSave() {
        guard let fileURL = getLibraryFileURL() else {
            print("Error: Could not get library file URL")
            return
        }
        
        let libraryData = LibraryData(tracks: tracks, collections: collections)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(libraryData)
            try data.write(to: fileURL, options: .atomic)
            print("Library saved to: \(fileURL.path)")
        } catch {
            print("Error saving library: \(error)")
        }
    }
    
    /// Load the library data from disk
    private func loadLibrary() {
        guard let fileURL = getLibraryFileURL() else {
            print("Error: Could not get library file URL, loading sample data")
            loadSampleData()
            return
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No existing library file found, loading sample data")
            loadSampleData()
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let libraryData = try decoder.decode(LibraryData.self, from: data)
            
            tracks = libraryData.tracks
            collections = libraryData.collections
            
            print("Library loaded from: \(fileURL.path)")
            print("Loaded \(tracks.count) tracks and \(collections.count) collections")
        } catch {
            print("Error loading library: \(error), loading sample data")
            loadSampleData()
        }
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
    
    func importFiles(urls: [URL]) async {
        var newTracks: [Track] = []
        for url in urls {
            if let track = await createTrack(from: url) {
                newTracks.append(track)
            }
        }
        
        // Add all tracks at once to trigger save only once
        if !newTracks.isEmpty {
            tracks.append(contentsOf: newTracks)
        }
    }
    
    private  func createTrack(from url: URL) async -> Track? {
        let asset = AVAsset(url: url)
        
        // Extract metadata
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var artworkData: Data? = nil
        
        // Load duration and metadata using availability-safe helper
        let (duration, metadataItems) = await loadDurationAndMetadata(for: asset)
        
        for item in metadataItems {
            let key = item.commonKey?.rawValue
            
            // Handle artwork separately
            if key == "artwork" {
                // Try to extract artwork data from various possible formats
                if let data = item.value as? Data {
                    artworkData = data
                } else if let dict = item.value as? [AnyHashable: Any],
                          let imageData = dict["data"] as? Data {
                    artworkData = imageData
                } else if let nsData = item.dataValue {
                    artworkData = nsData
                }
                continue
            }
            
            // Try stringValue first, then fall back to the raw value for better compatibility
            var valueString: String? = item.stringValue
            if valueString == nil {
                if let v = item.value as? String {
                    valueString = v
                } else if let v = item.value as? NSNumber {
                    valueString = v.stringValue
                } else if let v = item.value {
                    // Last resort: string-describe the value
                    valueString = String(describing: v)
                }
            }
            guard let keyUnwrapped = key, let value = valueString else { continue }
            
            switch keyUnwrapped {
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
            fileURL: url,
            artworkData: artworkData
        )
    }

    // Helper to centralize AVAsset property loading and keep deprecated APIs isolated
    private func loadDurationAndMetadata(for asset: AVAsset) async -> (TimeInterval, [AVMetadataItem]) {
        var duration: TimeInterval = 0
        var metadataItems: [AVMetadataItem] = []
        
        if #available(macOS 12.0, *) {
            // Modern async API
            if let durationTime: CMTime = try? await asset.load(.duration), CMTIME_IS_NUMERIC(durationTime) {
                duration = CMTimeGetSeconds(durationTime)
            }
            metadataItems = (try? await asset.load(.commonMetadata)) ?? []
        } else {
            // Legacy fallback: use loadValuesAsynchronously and bridge to async
            let (loadedDuration, loadedMetadata) = await withCheckedContinuation { (continuation: CheckedContinuation<(TimeInterval, [AVMetadataItem]), Never>) in
                let keys = ["duration", "commonMetadata"]
                asset.loadValuesAsynchronously(forKeys: keys) {
                    var loadedDuration: TimeInterval = 0
                    let durationValue = asset.duration
                    if CMTIME_IS_NUMERIC(durationValue) {
                        loadedDuration = CMTimeGetSeconds(durationValue)
                    }
                    let loadedMetadata = asset.commonMetadata
                    continuation.resume(returning: (loadedDuration, loadedMetadata))
                }
            }
            duration = loadedDuration
            metadataItems = loadedMetadata
        }
        
        return (duration, metadataItems)
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

// MARK: - Library Data Container
/// Container for encoding/decoding library data to JSON
private struct LibraryData: Codable {
    let tracks: [Track]
    let collections: [Collection]
}
