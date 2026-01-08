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
    
    // MARK: - Album Methods
    
    func loadAlbums() async throws -> [Album] {
        try await repository.loadAlbums()
    }
    
    func loadAlbums(forArtistId artistId: Int64) async throws -> [Album] {
        try await repository.loadAlbums(forArtistId: artistId)
    }
    
    func loadAlbum(id: Int64, includeReleases: Bool = false) async throws -> Album? {
        try await repository.loadAlbum(id: id, includeReleases: includeReleases)
    }
    
    // MARK: - Release Methods
    
    func loadReleases() async throws -> [Release] {
        try await repository.loadReleases()
    }
    
    func loadReleases(forAlbumId albumId: Int64) async throws -> [Release] {
        try await repository.loadReleases(forAlbumId: albumId)
    }
    
    func loadRelease(id: Int64, includeTracks: Bool = false) async throws -> Release? {
        try await repository.loadRelease(id: id, includeTracks: includeTracks)
    }
    
    func getDefaultRelease(forAlbumId albumId: Int64) async throws -> Release? {
        try await repository.getDefaultRelease(forAlbumId: albumId)
    }
    
    // MARK: - Track Methods
    
    func loadTracks(forReleaseId releaseId: Int64, orderByDiscAndTrackNumber: Bool = true) async throws -> [Track] {
        try await repository.loadTracks(forReleaseId: releaseId, orderByDiscAndTrackNumber: orderByDiscAndTrackNumber)
    }
    
    func loadTrack(id: Int64, includeDigitalFiles: Bool = false) async throws -> Track? {
        try await repository.loadTrack(id: id, includeDigitalFiles: includeDigitalFiles)
    }
    
    // MARK: - Digital File Methods
    
    func loadDigitalFiles() async throws -> [DigitalFile] {
        try await repository.loadDigitalFiles()
    }
    
    func loadDigitalFiles(forTrackId trackId: Int64) async throws -> [DigitalFile] {
        try await repository.loadDigitalFiles(forTrackId: trackId)
    }
    
    func loadTracksWithoutDigitalFiles() async throws -> [Track] {
        try await repository.loadTracksWithoutDigitalFiles()
    }
    
    func loadTracksWithDigitalFiles() async throws -> [Track] {
        try await repository.loadTracksWithDigitalFiles()
    }
    
    // MARK: - Import Methods
    
    func importAudioFile(url: URL) async throws -> Track {
        guard let importService = importService else {
            throw DatabaseError.notOpen
        }
        return try await importService.importAudioFile(url: url)
    }
    
    func importAudioFiles(urls: [URL]) async throws -> [Track] {
        guard let importService = importService else {
            throw DatabaseError.notOpen
        }
        return try await importService.importAudioFiles(urls: urls)
    }
}
