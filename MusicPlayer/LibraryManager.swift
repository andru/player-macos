import Foundation
@preconcurrency import AVFoundation

@MainActor
class LibraryManager: ObservableObject {
    // Persistent library state
    @Published var tracks: [Track] = []
    @Published var collections: [Collection] = []

    // UI / setup state
    @Published var needsLibraryLocationSetup = false
    @Published var libraryURL: URL? = nil

    // Internal
    private let libraryFileName = "library.json"
    private let bookmarkKey = "MusicPlayerLibraryBookmark"
    internal let directoryBookmarksKey = "MusicPlayerDirectoryBookmarks"
    private var isSecurityScoped = false
    private var securityScopedURL: URL? = nil
    private var accessedDirectories: [URL] = []
    
    // Supported audio file extensions
    private let audioExtensions = ["mp3", "m4a", "flac", "wav", "aac", "aiff", "aif", "opus", "ogg", "wma"]

    // MARK: - Derived views
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

    // MARK: - Init
    init() {
        // Restore directory bookmarks for previously imported directories
        restoreDirectoryBookmarks()
        
        // Attempt to restore a persisted library location via a security-scoped bookmark
        if restoreLibraryFromBookmark() {
            // Successfully restored and loaded
            return
        }

        // Try default ~/Music/MusicPlayer.library
        if let musicURL = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first {
            let libraryBundleURL = musicURL.appendingPathComponent("MusicPlayer.library", isDirectory: true)

            do {
                // Ensure the bundle directory exists (create if needed)
                if !FileManager.default.fileExists(atPath: libraryBundleURL.path) {
                    try createLibraryBundle(at: libraryBundleURL)
                }

                // Start access and load library contents
                try startAccessingAndLoad(at: libraryBundleURL)

                // Persist a security-scoped bookmark for next launch
                persistBookmark(for: libraryBundleURL)
            } catch {
                print("LibraryManager: couldn't setup default library: \(error)")
                // Signal that we need user to select a location
                DispatchQueue.main.async { [weak self] in
                    self?.needsLibraryLocationSetup = true
                }
            }
        } else {
            // Couldn't determine Music directory; ask the user to pick a location
            DispatchQueue.main.async { [weak self] in
                self?.needsLibraryLocationSetup = true
            }
        }
    }


    // MARK: - Public API
    func addTrack(_ track: Track) {
        tracks.append(track)
        saveLibrary()
    }

    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        saveLibrary()
    }

    func addCollection(_ collection: Collection) {
        collections.append(collection)
        saveLibrary()
    }

    func removeCollection(_ collection: Collection) {
        collections.removeAll { $0.id == collection.id }
        saveLibrary()
    }

    /// Called by UI when user selects a folder to host the library.
    func setLibraryLocation(url: URL) {
        // User's selected folder -> create/ensure MusicPlayer.library inside it
        let libraryBundleURL = url.appendingPathComponent("MusicPlayer.library", isDirectory: true)

        // Stop previous access if any
        stopAccessingSecurityScopedURLIfNeeded()

        do {
            if !FileManager.default.fileExists(atPath: libraryBundleURL.path) {
                try createLibraryBundle(at: libraryBundleURL)
            }

            try startAccessingAndLoad(at: libraryBundleURL)
            persistBookmark(for: libraryBundleURL)
            needsLibraryLocationSetup = false
        } catch {
            print("LibraryManager: failed to set library location: \(error)")
            needsLibraryLocationSetup = true
        }
    }

    // MARK: - Bundle creation
    private func createLibraryBundle(at bundleURL: URL) throws {
        let fm = FileManager.default

        // Create bundle, Contents, and Resources folders
        try fm.createDirectory(at: bundleURL, withIntermediateDirectories: true, attributes: nil)
        let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)
        try fm.createDirectory(at: contentsURL, withIntermediateDirectories: true, attributes: nil)
        try fm.createDirectory(at: resourcesURL, withIntermediateDirectories: true, attributes: nil)

        // Write Contents/Info.plist using a minimal template
        let infoPlist: [String: Any] = [
            "CFBundlePackageType": "BNDL",
            "CFBundleIdentifier": "com.musicplayer.library",
            "CFBundleName": "MusicPlayer Library",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "CFBundleIconFile": "LibraryIcon.pdf",
            "VibezLibraryFormatVersion": 1
        ]

        let plistData = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")
        try plistData.write(to: infoURL, options: .atomic)

        // Create initial empty library JSON in Contents/Resources/
        let initial = LibraryFile(version: 1, tracks: [], collections: [])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(initial)
        let libraryJSONURL = resourcesURL.appendingPathComponent(libraryFileName)
        try data.write(to: libraryJSONURL, options: .atomic)

        // Copy an embedded LibraryIcon.pdf into Resources if present in app bundle
        if let iconURL = Bundle.main.url(forResource: "LibraryIcon", withExtension: "pdf") {
            let dest = resourcesURL.appendingPathComponent("LibraryIcon.pdf")
            try? fm.copyItem(at: iconURL, to: dest)
        }
    }

    // MARK: - Load / Save
    private func startAccessingAndLoad(at bundleURL: URL) throws {
        // Begin security-scoped access if available (sandboxed apps need this for user-chosen locations)
        if bundleURL.startAccessingSecurityScopedResource() {
            isSecurityScoped = true
            securityScopedURL = bundleURL
        }
        self.libraryURL = bundleURL
        try loadLibrary()
    }

    private func stopAccessingSecurityScopedURLIfNeeded() {
        if isSecurityScoped, let u = securityScopedURL {
            u.stopAccessingSecurityScopedResource()
            isSecurityScoped = false
            securityScopedURL = nil
        }
    }

    private func loadLibrary() throws {
        guard let bundleURL = libraryURL else { return }
        let libraryJSON = bundleURL.appendingPathComponent("Contents/Resources/").appendingPathComponent(libraryFileName)

        let fm = FileManager.default
        if !fm.fileExists(atPath: libraryJSON.path) {
            // No saved library yet: write initial file and keep sample data
            saveLibrary()
            return
        }

        let data = try Data(contentsOf: libraryJSON)
        let decoder = JSONDecoder()
        let file = try decoder.decode(LibraryFile.self, from: data)
        self.tracks = file.tracks
        self.collections = file.collections
    }

    func saveLibrary() {
        guard let bundleURL = libraryURL else { return }
        let libraryJSON = bundleURL.appendingPathComponent("Contents/Resources/").appendingPathComponent(libraryFileName)

        let file = LibraryFile(version: 1, tracks: tracks, collections: collections)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(file)
            try data.write(to: libraryJSON, options: .atomic)
        } catch {
            print("LibraryManager: failed to save library: \(error)")
        }
    }

    // MARK: - Bookmarks
    private func persistBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        } catch {
            print("LibraryManager: failed to create bookmark: \(error)")
        }
    }

    private func restoreLibraryFromBookmark() -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return false }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                print("LibraryManager: bookmark is stale")
            }

            try startAccessingAndLoad(at: url)
            return true
        } catch {
            print("LibraryManager: failed to resolve bookmark: \(error)")
            return false
        }
    }

    // MARK: - Directory bookmarks
    private func persistDirectoryBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            var bookmarks = UserDefaults.standard.dictionary(forKey: directoryBookmarksKey) as? [String: Data] ?? [:]
            bookmarks[url.path] = bookmarkData
            UserDefaults.standard.set(bookmarks, forKey: directoryBookmarksKey)
        } catch {
            print("LibraryManager: failed to create directory bookmark: \(error)")
        }
    }
    
    private func restoreDirectoryBookmarks() {
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: directoryBookmarksKey) as? [String: Data] else { return }
        
        for (path, bookmarkData) in bookmarks {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                if isStale {
                    print("LibraryManager: directory bookmark is stale, refreshing: \(url.path)")
                    // Refresh the stale bookmark by creating a new one
                    let newBookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                    // Get fresh bookmarks from UserDefaults to avoid losing concurrent updates
                    var updatedBookmarks = UserDefaults.standard.dictionary(forKey: directoryBookmarksKey) as? [String: Data] ?? [:]
                    updatedBookmarks[path] = newBookmarkData
                    UserDefaults.standard.set(updatedBookmarks, forKey: directoryBookmarksKey)
                }
                
                if url.startAccessingSecurityScopedResource() {
                    accessedDirectories.append(url)
                }
            } catch {
                print("LibraryManager: failed to resolve directory bookmark: \(error)")
            }
        }
    }
    
    private func stopAccessingDirectories() {
        for url in accessedDirectories {
            url.stopAccessingSecurityScopedResource()
        }
        accessedDirectories.removeAll()
    }

    // MARK: - Track creation and metadata helpers
    func importFiles(urls: [URL]) async {
        for url in urls {
            if let track = await createTrack(from: url) {
                tracks.append(track)
            }
        }
        saveLibrary()
    }
    
    func importDirectory(url: URL) async {
        // Persist bookmark for this directory to maintain access across app launches
        persistDirectoryBookmark(for: url)
        
        // Start accessing the selected directory and keep it accessed
        if url.startAccessingSecurityScopedResource() {
            // Add to accessed directories for resource management (cleaned up in deinit)
            if !accessedDirectories.contains(url) {
                accessedDirectories.append(url)
            }
        }
        
        // Recursively find all music files
        let musicFiles = findMusicFiles(in: url)
        
        // Import all found files
        for fileURL in musicFiles {
            if let track = await createTrack(from: fileURL) {
                tracks.append(track)
            }
        }
        saveLibrary()
    }
    
    private func findMusicFiles(in directory: URL) -> [URL] {
        var musicFiles: [URL] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return musicFiles
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if let isRegularFile = resourceValues.isRegularFile, isRegularFile {
                    let fileExtension = fileURL.pathExtension.lowercased()
                    if audioExtensions.contains(fileExtension) {
                        musicFiles.append(fileURL)
                    }
                }
            } catch {
                print("LibraryManager: error checking file: \(error)")
            }
        }
        
        return musicFiles
    }

    private func createTrack(from url: URL) async -> Track? {
        let asset = AVAsset(url: url)

        // Extract metadata
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"

        // Load duration and metadata using availability-safe helper
        let (duration, metadataItems) = await loadDurationAndMetadata(for: asset)

        for item in metadataItems {
            // Prefer modern async loading on macOS 13+
            var valueString: String? = nil
            if #available(macOS 13.0, *) {
                if let sv: String = try? await item.load(.stringValue) {
                    valueString = sv
                } else if let v = try? await item.load(.value) {
                    if let s = v as? String { valueString = s }
                    else if let n = v as? NSNumber { valueString = n.stringValue }
                    else { valueString = String(describing: v) }
                }
            } else {
                // Legacy fallback
                valueString = item.stringValue
                if valueString == nil {
                    if let v = item.value as? String { valueString = v }
                    else if let v = item.value as? NSNumber { valueString = v.stringValue }
                    else if let v = item.value { valueString = String(describing: v) }
                }
            }

            let key = item.commonKey?.rawValue
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
            fileURL: url
        )
    }

    private func loadDurationAndMetadata(for asset: AVAsset) async -> (TimeInterval, [AVMetadataItem]) {
        var duration: TimeInterval = 0
        var metadataItems: [AVMetadataItem] = []

        if #available(macOS 12.0, *) {
            if let durationTime: CMTime = try? await asset.load(.duration), CMTIME_IS_NUMERIC(durationTime) {
                duration = CMTimeGetSeconds(durationTime)
            }
            metadataItems = (try? await asset.load(.commonMetadata)) ?? []
        } else {
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

}

// MARK: - Library file structure used on disk
private struct LibraryFile: Codable {
    var version: Int
    var tracks: [Track]
    var collections: [Collection]
}
