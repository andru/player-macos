import Foundation

/// Protocol defining artist persistence operations
protocol ArtistRepository {
    /// Load all artists from the repository
    func loadArtists() async throws -> [Artist]
    
    /// Load a specific artist by ID with optional relationships
    func loadArtist(id: Int64, includeAlbums: Bool) async throws -> Artist?
    
    /// Save or update an artist
    func saveArtist(_ artist: Artist) async throws -> Artist
    
    /// Find an artist by name
    func findArtist(byName name: String) async throws -> Artist?
    
    /// Upsert an artist by name (create if doesn't exist, return existing if it does)
    func upsertArtist(name: String, sortName: String?) async throws -> Artist
}

/// Protocol defining work persistence operations
protocol WorkRepository {
    /// Load all works from the repository
    func loadWorks() async throws -> [Work]
    
    /// Load a specific work by ID
    func loadWork(id: Int64) async throws -> Work?
    
    /// Save or update a work
    func saveWork(_ work: Work) async throws -> Work
    
    /// Find a work by title and primary artist
    func findWork(title: String, primaryArtistId: Int64) async throws -> Work?
    
    /// Upsert a work (create if doesn't exist, return existing if it does)
    func upsertWork(title: String, artistIds: [Int64]) async throws -> Work
}

/// Protocol defining recording persistence operations
protocol RecordingRepository {
    /// Load all recordings from the repository
    func loadRecordings() async throws -> [Recording]
    
    /// Load a specific recording by ID
    func loadRecording(id: Int64) async throws -> Recording?
    
    /// Save or update a recording
    func saveRecording(_ recording: Recording) async throws -> Recording
    
    /// Find a recording by title and duration
    func findRecording(title: String, duration: TimeInterval?) async throws -> Recording?
    
    /// Upsert a recording (create if doesn't exist, return existing if it does)
    func upsertRecording(title: String, duration: TimeInterval?, workIds: [Int64], artistIds: [Int64]) async throws -> Recording
    
    /// Link a recording to a digital file
    func linkRecordingToDigitalFile(recordingId: Int64, digitalFileId: Int64) async throws
}

/// Protocol defining label persistence operations
protocol LabelRepository {
    /// Load all labels from the repository
    func loadLabels() async throws -> [Label]
    
    /// Load a specific label by ID
    func loadLabel(id: Int64) async throws -> Label?
    
    /// Save or update a label
    func saveLabel(_ label: Label) async throws -> Label
    
    /// Find a label by name
    func findLabel(byName name: String) async throws -> Label?
    
    /// Upsert a label (create if doesn't exist, return existing if it does)
    func upsertLabel(name: String, sortName: String?) async throws -> Label
}

/// Protocol defining release group persistence operations (album concept)
protocol ReleaseGroupRepository {
    /// Load all release groups from the repository
    func loadReleaseGroups() async throws -> [ReleaseGroup]
    
    /// Load release groups for a specific artist
    func loadReleaseGroups(forArtistId artistId: Int64) async throws -> [ReleaseGroup]
    
    /// Load a specific release group by ID
    func loadReleaseGroup(id: Int64, includeReleases: Bool) async throws -> ReleaseGroup?
    
    /// Save or update a release group
    func saveReleaseGroup(_ releaseGroup: ReleaseGroup) async throws -> ReleaseGroup
    
    /// Find a release group by title and primary artist
    func findReleaseGroup(title: String, primaryArtistId: Int64?) async throws -> ReleaseGroup?
    
    /// Upsert a release group (create if doesn't exist, return existing if it does)
    func upsertReleaseGroup(title: String, primaryArtistId: Int64?, isCompilation: Bool) async throws -> ReleaseGroup
}

/// Protocol defining album persistence operations (UI compatibility layer)
protocol AlbumRepository {
    /// Load all albums (maps from ReleaseGroups)
    func loadAlbums() async throws -> [Album]
    
    /// Load albums for a specific artist
    func loadAlbums(forArtistId artistId: Int64) async throws -> [Album]
    
    /// Load a specific album by ID
    func loadAlbum(id: Int64, includeReleases: Bool) async throws -> Album?
}

/// Protocol defining release persistence operations
protocol ReleaseRepository {
    /// Load all releases from the repository
    func loadReleases() async throws -> [Release]
    
    /// Load releases for a specific release group
    func loadReleases(forReleaseGroupId releaseGroupId: Int64) async throws -> [Release]
    
    /// Load a specific release by ID
    func loadRelease(id: Int64, includeMedia: Bool) async throws -> Release?
    
    /// Save or update a release
    func saveRelease(_ release: Release) async throws -> Release
    
    /// Find a release by release group ID and identity key
    func findRelease(releaseGroupId: Int64, format: ReleaseFormat, edition: String?, year: Int?, country: String?) async throws -> Release?
    
    /// Upsert a release (create if doesn't exist, return existing if it does)
    func upsertRelease(releaseGroupId: Int64, format: ReleaseFormat, edition: String?, year: Int?, country: String?, catalogNumber: String?, barcode: String?) async throws -> Release
    
    /// Get the default release for a release group (prefer Digital if present)
    func getDefaultRelease(forReleaseGroupId releaseGroupId: Int64) async throws -> Release?
}

/// Protocol defining medium persistence operations
protocol MediumRepository {
    /// Load all media from the repository
    func loadMedia() async throws -> [Medium]
    
    /// Load media for a specific release
    func loadMedia(forReleaseId releaseId: Int64) async throws -> [Medium]
    
    /// Load a specific medium by ID
    func loadMedium(id: Int64) async throws -> Medium?
    
    /// Save or update a medium
    func saveMedium(_ medium: Medium) async throws -> Medium
    
    /// Find a medium by release ID and position
    func findMedium(releaseId: Int64, position: Int) async throws -> Medium?
    
    /// Upsert a medium (create if doesn't exist, return existing if it does)
    func upsertMedium(releaseId: Int64, position: Int, format: String?, title: String?) async throws -> Medium
}

/// Protocol defining track persistence operations
protocol TrackRepository {
    /// Load all tracks from the repository
    func loadTracks() async throws -> [Track]
    
    /// Load tracks for a specific medium
    func loadTracks(forMediumId mediumId: Int64) async throws -> [Track]
    
    /// Load a specific track by ID
    func loadTrack(id: Int64) async throws -> Track?
    
    /// Save or update a track
    func saveTrack(_ track: Track) async throws -> Track
    
    /// Save multiple tracks
    func saveTracks(_ tracks: [Track]) async throws
}

/// Protocol defining digital file persistence operations
protocol DigitalFileRepository {
    /// Load all digital files from the repository
    func loadDigitalFiles() async throws -> [DigitalFile]
    
    /// Load digital files for a specific recording
    func loadDigitalFiles(forRecordingId recordingId: Int64) async throws -> [DigitalFile]
    
    /// Load a specific digital file by ID
    func loadDigitalFile(id: Int64) async throws -> DigitalFile?
    
    /// Save or update a digital file
    func saveDigitalFile(_ digitalFile: DigitalFile) async throws -> DigitalFile
    
    /// Find a digital file by file URL
    func findDigitalFile(byFileURL fileURL: URL) async throws -> DigitalFile?
    
    /// Load recordings that have no digital files (physical-only)
    func loadRecordingsWithoutDigitalFiles() async throws -> [Recording]
    
    /// Load recordings that have digital files
    func loadRecordingsWithDigitalFiles() async throws -> [Recording]
}
