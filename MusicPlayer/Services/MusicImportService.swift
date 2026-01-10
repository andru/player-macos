import Foundation
@preconcurrency import AVFoundation

/// Service responsible for importing audio files into the music library
/// Focuses on audio-file-first approach with bridge layer
class MusicImportService {

    let repos: Repositories;
    init (repositories: Repositories) {
        self.repos = repositories
    }
    
    /// Import an audio file into the bridge layer:
    /// 1. Compute content hash
    /// 2. Create/update LocalTrack
    /// 3. Extract tags
    /// 4. Create LocalTrackTags
    /// 5. Create/update LibraryTrack
    /// Does NOT create MusicBrainz entities during import
    func importAudioFile(url: URL) async throws -> LibraryTrack {
        // 1. Compute content hash for deduplication
        let contentHash = try FileHasher.computeContentHashStreaming(for: url)
        
        // 2. Check if we already have this file (by content hash)
        var localTrack: LocalTrack
        if let existing = try await repos.localTrack.findLocalTrack(byContentHash: contentHash) {
            // File already exists, update it
            localTrack = LocalTrack(
                id: existing.id,
                fileURL: url.path,
                bookmarkData: nil, // TODO: Create security-scoped bookmark
                contentHash: contentHash,
                fileSize: try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64,
                mtime: try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date,
                duration: nil, // Will be set from metadata
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
        } else {
            // New file
            localTrack = LocalTrack(
                id: 0,
                fileURL: url.path,
                bookmarkData: nil, // TODO: Create security-scoped bookmark
                contentHash: contentHash,
                fileSize: try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64,
                mtime: try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date,
                duration: nil // Will be set from metadata
            )
        }
        
        // 3. Extract metadata from the audio file
        let metadata = try await extractMetadata(from: url)
        
        // Update duration from metadata
        localTrack = LocalTrack(
            id: localTrack.id,
            fileURL: localTrack.fileURL,
            bookmarkData: localTrack.bookmarkData,
            contentHash: localTrack.contentHash,
            fileSize: localTrack.fileSize,
            mtime: localTrack.mtime,
            duration: metadata.duration,
            createdAt: localTrack.createdAt,
            updatedAt: localTrack.updatedAt
        )
        
        // Save LocalTrack
        let savedLocalTrack = try await repos.localTrack.saveLocalTrack(localTrack)
        
        // 4. Create LocalTrackTags from extracted metadata
        let tags = LocalTrackTags(
            id: 0,
            localTrackId: savedLocalTrack.id,
            title: metadata.title,
            artist: metadata.artistName,
            album: metadata.albumName,
            albumArtist: metadata.albumArtistName,
            composer: metadata.composerName,
            trackNumber: metadata.trackNumber,
            discNumber: metadata.discNumber,
            year: metadata.year,
            isCompilation: metadata.isCompilation,
            genre: metadata.genre,
            recordingMBID: metadata.recordingMBID,
            releaseMBID: metadata.releaseMBID,
            releaseGroupMBID: metadata.releaseGroupMBID,
            artistMBID: metadata.artistMBID,
            workMBID: metadata.workMBID
        )
        
        let savedTags = try await repos.localTrackTags.saveLocalTrackTags(tags)
        
        // 5. Create or update LibraryTrack linking both
        if let existingLibraryTrack = try await repos.libraryTrack.findLibraryTrack(byLocalTrackId: savedLocalTrack.id) {
            // Update existing LibraryTrack to point to new tags
            let updatedLibraryTrack = LibraryTrack(
                id: existingLibraryTrack.id,
                localTrackId: savedLocalTrack.id,
                localTrackTagsId: savedTags.id,
                createdAt: existingLibraryTrack.createdAt,
                updatedAt: Date()
            )
            return try await repos.libraryTrack.saveLibraryTrack(updatedLibraryTrack)
        } else {
            // Create new LibraryTrack
            let libraryTrack = LibraryTrack(
                id: 0,
                localTrackId: savedLocalTrack.id,
                localTrackTagsId: savedTags.id
            )
            return try await repos.libraryTrack.saveLibraryTrack(libraryTrack)
        }
    }
    
    /// Import multiple audio files
    func importAudioFiles(urls: [URL]) async throws -> [LibraryTrack] {
        var importedTracks: [LibraryTrack] = []
        
        for url in urls {
            do {
                let track = try await importAudioFile(url: url)
                importedTracks.append(track)
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
            }
        }
        
        return importedTracks
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
            isCompilation: isCompilation,
            recordingMBID: nil, // TODO: Extract from tags
            releaseMBID: nil, // TODO: Extract from tags
            releaseGroupMBID: nil, // TODO: Extract from tags
            artistMBID: nil, // TODO: Extract from tags
            workMBID: nil // TODO: Extract from tags
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
    
    // MusicBrainz IDs if present in tags
    let recordingMBID: String?
    let releaseMBID: String?
    let releaseGroupMBID: String?
    let artistMBID: String?
    let workMBID: String?
}
