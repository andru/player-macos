import Foundation
@preconcurrency import AVFoundation
import CryptoKit

/// Service responsible for importing audio files into the music library
/// Implements the local tracks bridge import pipeline (no MusicBrainz entities created)
class MusicImportService {
    
    let fileAccess: any FileAccessCoordinating
    let bookmarkStore: any BookmarkRegistering
    let appLibrary: AppLibraryService
    let repos: Repositories
    
    // Supported audio file extensions
    private let audioExtensions: Set<String> = ["mp3", "m4a", "flac", "wav", "aac", "aiff", "aif", "opus", "ogg", "wma"]

    init (fileAccess: SecurityScopedFileAccessCoordinator, bookmarkStore: GRDBBookmarkStore, appLibrary: AppLibraryService, repositories: Repositories) {
        self.fileAccess = fileAccess
        self.bookmarkStore = bookmarkStore
        self.appLibrary = appLibrary
        self.repos = repositories
    }
    
    func importDirectory(url: URL) async throws -> ImportReport {
        // Persist bookmark for this directory to maintain access across app launches
        do {
            let locationID = try await bookmarkStore.registerLocation(url: url)

            let importedTracks = try await fileAccess.withAccess(to: locationID) { folderURL in
                // Recursively find all music files
                let musicFiles = try findMusicFiles(in: folderURL)
                // Import all found files
                return try await importAudioFiles(urls: musicFiles)
            }
            return ImportReport(libraryTracks: importedTracks)
        } catch {
            print("Warning: Failed to register bookmark for \(url.path): \(error)")
        }
        return ImportReport(libraryTracks: [])
    }
    
    private func findMusicFiles(in directory: URL) throws -> [URL] {
        var musicFiles: [URL] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return musicFiles
        }

        for case let fileURL as URL in enumerator {
            try Task.checkCancellation()

            do {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if values.isRegularFile == true,
                   audioExtensions.contains(fileURL.pathExtension.lowercased()) {
                    musicFiles.append(fileURL)
                }
            } catch is CancellationError {
                throw CancellationError() // critical: propagate cancellation
            } catch {
                // log + continue for ordinary filesystem errors
            }
        }

        return musicFiles
    }
    
    /// Import an audio file following the local tracks bridge pipeline:
    /// 1. Compute content hash
    /// 2. Create/update LocalTrack
    /// 3. Extract tags → create LocalTrackTags
    /// 4. Create/update LibraryTrack linking both
    func importAudioFile(url: URL) async throws -> LibraryTrack {
        // 1. Compute content hash for deduplication
        let contentHash = try computeContentHash(url: url)
        
        // 2. Get file attributes
        let fileManager = FileManager.default
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64
        let modifiedAt = attributes[.modificationDate] as? Date
        
        // 3. Extract metadata from the audio file
        let metadata = try await extractMetadata(from: url)
        
        // 4. Upsert LocalTrack (dedupe by content hash)
        let localTrack = try await repos.localTrack.upsertLocalTrack(
            contentHash: contentHash,
            fileURL: url.path,
            bookmarkData: nil, // Could add security-scoped bookmark here if needed
            fileSize: fileSize,
            modifiedAt: modifiedAt,
            duration: metadata.duration
        )
        
        // 5. Create LocalTrackTags (snapshot of current tags)
        let tags = LocalTrackTags(
            localTrackId: localTrack.id,
            title: metadata.title,
            artist: metadata.artistName,
            album: metadata.albumName,
            albumArtist: metadata.albumArtistName,
            composer: metadata.composerName,
            trackNumber: metadata.trackNumber,
            discNumber: metadata.discNumber,
            year: metadata.year,
            genre: metadata.genre,
            isCompilation: metadata.isCompilation
        )
        
        let savedTags = try await repos.localTrackTags.saveTags(tags)
        
        // 6. Create/update LibraryTrack linking file and tags
        let libraryTrack = try await repos.libraryTrack.upsertLibraryTrack(
            localTrackId: localTrack.id,
            localTrackTagsId: savedTags.id
        )
        
        return libraryTrack
    }
    
    /// Import multiple audio files
    func importAudioFiles(urls: [URL]) async throws -> [LibraryTrack] {
        var importedTracks: [LibraryTrack] = []
        
        for url in urls {
            do {
                try Task.checkCancellation()
                let track = try await importAudioFile(url: url)
                importedTracks.append(track)
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
            }
        }
        
        return importedTracks
    }
    
    // MARK: - Content Hash
    
    /// Compute SHA256 hash of file content for deduplication
    private func computeContentHash(url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        
        var hasher = SHA256()
        
        // Read file in chunks to handle large files
        let chunkSize = 1024 * 1024 // 1MB chunks
        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: chunkSize)
            if chunk.isEmpty { return false }
            hasher.update(data: chunk)
            return true
        }) { }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from url: URL) async throws -> AudioMetadata {
        let asset = AVAsset(url: url)
        
        var duration: TimeInterval? = nil
        if let cmTime: CMTime = try? await asset.load(.duration) {
            let seconds = CMTimeGetSeconds(cmTime)
            if seconds.isFinite {
                duration = seconds
            }
        }
        
        var title = url.deletingPathExtension().lastPathComponent
        var artistName = "Unknown Artist"
        var albumName = "Unknown Album"
        var albumArtistName: String? = nil
        var composerName: String? = nil
        var year: Int? = nil
        var trackNumber: Int? = nil
        var discNumber: Int? = nil
        var genre: String? = nil
        var artworkData: Data? = nil
        var isCompilation = false
        
        if let commonMetadata: [AVMetadataItem] = try? await asset.load(.commonMetadata) {
            for item in commonMetadata {
                let key = item.commonKey?.rawValue
                guard let keyUnwrapped = key else { continue }
                
                let valueString = await extractStringValue(from: item)
                
                switch keyUnwrapped {
                case "title":
                    if let value = valueString {
                        title = value
                    }
                case "artist":
                    if let value = valueString {
                        artistName = value
                    }
                case "albumName":
                    if let value = valueString {
                        albumName = value
                    }
                case "type":
                    if let value = valueString, value.lowercased() == "compilation" {
                        isCompilation = true
                    }
                default:
                    break
                }
                
                if key == "artwork", let data = try? await item.load(.value) as? Data {
                    artworkData = data
                }
            }
        }
        
        if let formats: [AVMetadataFormat] = try? await asset.load(.availableMetadataFormats) {
            for format in formats {
                if let fmtItems = try? await asset.loadMetadata(for: format) {
                    if albumArtistName == nil {
                        albumArtistName = await extractAlbumArtist(from: fmtItems)
                    }

                    if composerName == nil {
                        composerName = await extractComposer(from: fmtItems)
                    }

                    for item in fmtItems {
                        let valueString = await extractStringValue(from: item)
                        
                        if year == nil {
                            if let key = item.commonKey?.rawValue, key == "creationDate" || key == "year" {
                                year = extractYear(from: valueString)
                            } else if let key = item.key as? String, key.lowercased().contains("year") || key.lowercased().contains("date") {
                                year = extractYear(from: valueString)
                            }
                        }
                        
                        if trackNumber == nil {
                            if let key = item.commonKey?.rawValue, key == "trackNumber" {
                                trackNumber = valueString.flatMap { Int($0) }
                            } else if let key = item.key as? String, key.uppercased() == "TRCK" || key == "©trkn" {
                                trackNumber = extractTrackNumber(from: valueString)
                            }
                        }
                        
                        if discNumber == nil {
                            if let key = item.key as? String, key.uppercased() == "TPOS" || key == "©disc" {
                                discNumber = extractDiscNumber(from: valueString)
                            }
                        }
                        
                        if genre == nil {
                            if let key = item.commonKey?.rawValue, key == "type" {
                                if let value = valueString, !value.isEmpty && value.lowercased() != "compilation" {
                                    genre = value
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return AudioMetadata(
            title: title,
            artistName: artistName,
            albumName: albumName,
            albumArtistName: albumArtistName,
            composerName: composerName,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genre: genre,
            duration: duration,
            artworkData: artworkData,
            isCompilation: isCompilation
        )
    }
    
    private func extractStringValue(from item: AVMetadataItem) async -> String? {
        if let sv: String = try? await item.load(.stringValue) {
            return sv
        }
        if let v = try? await item.load(.value) {
            if let s = v as? String { return s }
            if let n = v as? NSNumber { return n.stringValue }
            return String(describing: v)
        }
        return nil
    }
    
    private func extractAlbumArtist(from metadataItems: [AVMetadataItem]) async -> String? {
        for item in metadataItems {
            if let ck = item.commonKey?.rawValue, ck == "albumArtist", let v = await extractStringValue(from: item) {
                return v
            }
            
            if item.keySpace == .id3 {
                if let key = item.key as? String, key == "TPE2", let v = await extractStringValue(from: item) {
                    return v
                }
            }
            
            if item.keySpace == .iTunes {
                if let key = item.key as? String, key == "aART", let v = await extractStringValue(from: item) {
                    return v
                }
            }
            
            if let id = item.identifier?.rawValue.lowercased(), id.contains("albumartist") || id.contains("aart"), let v = await extractStringValue(from: item) {
                return v
            }
        }
        
        return nil
    }
    
    private func extractComposer(from metadataItems: [AVMetadataItem]) async -> String? {
        for item in metadataItems {
            if let ck = item.commonKey?.rawValue, ck == "creator", let v = await extractStringValue(from: item) {
                return v
            }
            
            if item.keySpace == .id3 {
                if let key = item.key as? String, key == "TCOM", let v = await extractStringValue(from: item) {
                    return v
                }
            }
            
            if item.keySpace == .iTunes {
                if let key = item.key as? String, key == "©wrt", let v = await extractStringValue(from: item) {
                    return v
                }
            }
        }
        
        return nil
    }
    
    private func extractYear(from string: String?) -> Int? {
        guard let string = string else { return nil }
        
        if let year = Int(string) {
            return year
        }
        
        let yearPattern = #/(\d{4})/#
        if let match = try? yearPattern.firstMatch(in: string) {
            return Int(match.1)
        }
        
        return nil
    }
    
    private func extractTrackNumber(from string: String?) -> Int? {
        guard let string = string else { return nil }
        
        if let slashIndex = string.firstIndex(of: "/") {
            let trackPart = String(string[..<slashIndex])
            return Int(trackPart)
        }
        
        return Int(string)
    }
    
    private func extractDiscNumber(from string: String?) -> Int? {
        guard let string = string else { return nil }
        
        if let slashIndex = string.firstIndex(of: "/") {
            let discPart = String(string[..<slashIndex])
            return Int(discPart)
        }
        
        return Int(string)
    }
}

// MARK: - Supporting Types

struct AudioMetadata {
    let title: String
    let artistName: String
    let albumName: String
    let albumArtistName: String?
    let composerName: String?
    let year: Int?
    let trackNumber: Int?
    let discNumber: Int?
    let genre: String?
    let duration: TimeInterval?
    let artworkData: Data?
    let isCompilation: Bool
}

struct ImportReport {
    let libraryTracks: [LibraryTrack]
}
