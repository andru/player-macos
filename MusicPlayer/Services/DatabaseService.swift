import Foundation

/// Facade for database operations, providing a simple interface to the underlying repository
/// This bridges the old @MainActor DatabaseManager API with the new async repository pattern
class DatabaseService {
    private let repository: GRDBRepository
    private var importService: MusicImportService?
    
    init() {
        self.repository = GRDBRepository()
    }
    
    /// Open database connection at the specified library bundle URL
    func openDatabase(at bundleURL: URL) async throws {
        try await repository.openDatabase(at: bundleURL)
        self.importService = MusicImportService(repository: repository)
    }
    
    /// Close the database connection
    func closeDatabase() {
        repository.closeDatabase()
        importService = nil
    }
    
    // MARK: - Legacy Track Methods (for compatibility)
    
    /// Load all tracks from the database
    func loadTracks() async throws -> [Track] {
        try await repository.loadTracks()
    }
    
    /// Save tracks to the database
    func saveTracks(_ tracks: [Track]) async throws {
        try await repository.saveTracks(tracks)
    }
    
    // MARK: - Collection Methods
    
    /// Load all collections from the database
    func loadCollections() async throws -> [Collection] {
        try await repository.loadCollections()
    }
    
    /// Save collections to the database
    func saveCollections(_ collections: [Collection]) async throws {
        try await repository.saveCollections(collections)
    }
    
    // MARK: - Artist Methods
    
    func loadArtists() async throws -> [Artist] {
        try await repository.loadArtists()
    }
    
    func loadArtist(id: Int64, includeAlbums: Bool = false) async throws -> Artist? {
        try await repository.loadArtist(id: id, includeAlbums: includeAlbums)
    }
    
    // MARK: - Album Methods (UI compatibility layer)
    
    func loadAlbums() async throws -> [Album] {
        try await repository.loadAlbums()
    }
    
    func loadAlbums(forArtistId artistId: Int64) async throws -> [Album] {
        try await repository.loadAlbums(forArtistId: artistId)
    }
    
    func loadAlbum(id: Int64, includeReleases: Bool = false) async throws -> Album? {
        try await repository.loadAlbum(id: id, includeReleases: includeReleases)
    }
    
    // MARK: - Release Group Methods
    
    func loadReleaseGroups() async throws -> [ReleaseGroup] {
        try await repository.loadReleaseGroups()
    }
    
    func loadReleaseGroups(forArtistId artistId: Int64) async throws -> [ReleaseGroup] {
        try await repository.loadReleaseGroups(forArtistId: artistId)
    }
    
    func loadReleaseGroup(id: Int64, includeReleases: Bool = false) async throws -> ReleaseGroup? {
        try await repository.loadReleaseGroup(id: id, includeReleases: includeReleases)
    }
    
    // MARK: - Release Methods
    
    func loadReleases() async throws -> [Release] {
        try await repository.loadReleases()
    }
    
    func loadReleases(forReleaseGroupId releaseGroupId: Int64) async throws -> [Release] {
        try await repository.loadReleases(forReleaseGroupId: releaseGroupId)
    }
    
    func loadRelease(id: Int64, includeMedia: Bool = false) async throws -> Release? {
        try await repository.loadRelease(id: id, includeMedia: includeMedia)
    }
    
    func getDefaultRelease(forReleaseGroupId releaseGroupId: Int64) async throws -> Release? {
        try await repository.getDefaultRelease(forReleaseGroupId: releaseGroupId)
    }
    
    // MARK: - Medium Methods
    
    func loadMedia(forReleaseId releaseId: Int64) async throws -> [Medium] {
        try await repository.loadMedia(forReleaseId: releaseId)
    }
    
    // MARK: - Track Methods
    
    func loadTracks(forMediumId mediumId: Int64) async throws -> [Track] {
        try await repository.loadTracks(forMediumId: mediumId)
    }
    
    func loadTrack(id: Int64) async throws -> Track? {
        try await repository.loadTrack(id: id)
    }
    
    // MARK: - Recording Methods
    
    func loadRecordings() async throws -> [Recording] {
        try await repository.loadRecordings()
    }
    
    func loadRecording(id: Int64) async throws -> Recording? {
        try await repository.loadRecording(id: id)
    }
    
    // MARK: - Digital File Methods
    
    func loadDigitalFiles() async throws -> [DigitalFile] {
        try await repository.loadDigitalFiles()
    }
    
    func loadDigitalFiles(forRecordingId recordingId: Int64) async throws -> [DigitalFile] {
        try await repository.loadDigitalFiles(forRecordingId: recordingId)
    }
    
    // MARK: - Import Methods
    
    /// Import audio files using the MusicBrainz-aligned import service
    func importAudioFiles(urls: [URL]) async throws -> [Track] {
        guard let importService = importService else {
            throw NSError(domain: "DatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database not open"])
        }
        return try await importService.importAudioFiles(urls: urls)
    }
    
    /// Import a single audio file
    func importAudioFile(url: URL) async throws -> Track {
        guard let importService = importService else {
            throw NSError(domain: "DatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database not open"])
        }
        return try await importService.importAudioFile(url: url)
    }
}
