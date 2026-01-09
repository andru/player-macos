import Foundation
@preconcurrency import AVFoundation

@MainActor
final class AppLibraryService: ObservableObject, AppLibraryServiceProtocol {

    // UI / setup state
    @Published var needsLibraryLocationSetup = false
    @Published var libraryURL: URL? = nil
    @Published var libraryDbURL: URL? = nil

    // Internal
    private let bookmarkKey = "MusicPlayerLibraryBookmark"
    internal let directoryBookmarksKey = "MusicPlayerDirectoryBookmarks"
    private var isSecurityScoped = false
    private var securityScopedURL: URL? = nil
    private var accessedDirectories: [URL] = []
    
    // Task management for proper lifecycle
    private var initializationTask: Task<Void, Never>?
    
    // Supported audio file extensions
    private let audioExtensions = ["mp3", "m4a", "flac", "wav", "aac", "aiff", "aif", "opus", "ogg", "wma"]

    // MARK: - Init
    func ensureAccess() async throws -> URL {
        // Restore directory bookmarks for previously imported directories
        restoreDirectoryBookmarks()
        
        // Attempt to restore a persisted library location via a security-scoped bookmark
        initializationTask = Task { @MainActor in
            if await restoreLibraryFromBookmark() {
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
                    try await startAccessingAndLoad(at: libraryBundleURL)

                    // Persist a security-scoped bookmark for next launch
                    persistBookmark(for: libraryBundleURL)
                } catch {
                    print("LibraryManager: couldn't setup default library: \(error)")
                    // Signal that we need user to select a location
                    self.needsLibraryLocationSetup = true
                }
            } else {
                // Couldn't determine Music directory; ask the user to pick a location
                self.needsLibraryLocationSetup = true
            }
        }
        
        return libraryURL!
    }

    /// Called by UI when user selects a folder to host the library.
    func setLibraryLocation(url: URL) {
        // User's selected folder -> create/ensure MusicPlayer.library inside it
        let libraryBundleURL = url.appendingPathComponent("MusicPlayer.library", isDirectory: true)
        // Stop previous access if any
        stopAccessingSecurityScopedURLIfNeeded()

        // Cancel any ongoing initialization
        initializationTask?.cancel()
        
        initializationTask = Task { @MainActor in
            do {
                if !FileManager.default.fileExists(atPath: libraryBundleURL.path) {
                    try createLibraryBundle(at: libraryBundleURL)
                }

                try await startAccessingAndLoad(at: libraryBundleURL)
                persistBookmark(for: libraryBundleURL)
                needsLibraryLocationSetup = false
            } catch {
                print("LibraryManager: failed to set library location: \(error)")
                needsLibraryLocationSetup = true
            }
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

        // Copy an embedded LibraryIcon.pdf into Resources if present in app bundle
        if let iconURL = Bundle.main.url(forResource: "LibraryIcon", withExtension: "pdf") {
            let dest = resourcesURL.appendingPathComponent("LibraryIcon.pdf")
            try? fm.copyItem(at: iconURL, to: dest)
        }
    }

    // MARK: - Load / Save
    private func startAccessingAndLoad(at bundleURL: URL) async throws {
        // Begin security-scoped access if available (sandboxed apps need this for user-chosen locations)
        if bundleURL.startAccessingSecurityScopedResource() {
            isSecurityScoped = true
            securityScopedURL = bundleURL
        }
        self.libraryURL = bundleURL
        self.libraryDbURL = bundleURL.appendingPathComponent("Contents/Resources/library.db")
    }

    private func stopAccessingSecurityScopedURLIfNeeded() {
        if isSecurityScoped, let u = securityScopedURL {
            u.stopAccessingSecurityScopedResource()
            isSecurityScoped = false
            securityScopedURL = nil
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

    private func restoreLibraryFromBookmark() async -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return false }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                print("LibraryManager: bookmark is stale")
            }

            try await startAccessingAndLoad(at: url)
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

    /*
    // MARK: - Track creation and metadata helpers
    func importFiles(urls: [URL]) async {
        for url in urls {
            do {
                let track = try await databaseManager.importAudioFile(url: url)
                print("Imported: \(track.title)")
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
            }
        }
        // Reload library to reflect changes
        await loadLibraryData()
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
            do {
                let track = try await databaseManager.importAudioFile(url: fileURL)
                print("Imported: \(track.title)")
            } catch {
                print("Failed to import \(fileURL.lastPathComponent): \(error)")
            }
        }
        
        // Reload library to reflect changes
        await loadLibraryData()
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
    }*/
    
    // MARK: - Cleanup
    deinit {
        // Cancel any pending tasks
        initializationTask?.cancel()
    
//        CoPilot - stop adding these to deinit
//        stopAccessingSecurityScopedURLIfNeeded()
//        stopAccessingDirectories()
    }

}
