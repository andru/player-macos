import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    enum State {
        case idle
        case opening
        case ready(FeatureDeps)
        case error(Error)
    }

    struct FeatureDeps {
        let appFrame: AppFrameDependencies
        let player: PlayerDependencies
        let library: LibraryDependencies
    }

    let repositories: Repositories;
    
    @Published private(set) var state: State = .idle
    
    var appLibrary: AppLibraryService = AppLibraryService()
    let db: AppDatabase
    let musicImportService: MusicImportService;
    
    var audioPlayer: AudioPlayerService
    var appFrame: AppFrameDependencies
    var player: PlayerDependencies
    var library: LibraryDependencies


//    let artists: ArtistsDependencies

    init() throws {
        appLibrary.ensureAccess()
        db = try AppDatabase(url: appLibrary.libraryDbURL!)
        
        // Infrastructure implementations (GRDB-backed)
        let albumsQueries = GRDBAlbumRowQuery(dbWriter: db.dbWriter)
        let songsQueries = GRDBSongsQueries(dbWriter: db.dbWriter)
        
        repositories = Repositories(
            artist: GRDBArtistRepository(dbWriter: db.dbWriter),
            collection: GRDBCollectionRepository(dbWriter: db.dbWriter),
            digitalFile: GRDBDigitalFileRepository(dbWriter: db.dbWriter),
            label: GRDBLabelRepository(dbWriter: db.dbWriter),
            medium: GRDBMediumRepository(dbWriter: db.dbWriter),
            recording: GRDBRecordingRepository(dbWriter: db.dbWriter),
            releaseGroup: GRDBReleaseGroupRepository(dbWriter: db.dbWriter),
            release: GRDBReleaseRepository(dbWriter: db.dbWriter),
            track: GRDBTrackRepository(dbWriter: db.dbWriter),
            work: GRDBWorkRepository(dbWriter: db.dbWriter)
        )
        
        // pass repositories to services
        musicImportService = MusicImportService(repositories: repositories)

        // Services
        let audioPlayer = AudioPlayerService()
        self.audioPlayer = audioPlayer

        // Bundle per feature
        appFrame = AppFrameDependencies(
            appLibraryService: appLibrary,
            audioPlayer: audioPlayer
        )
        player = PlayerDependencies(
            audioPlayer: audioPlayer
        )
        library = LibraryDependencies(
            audioPlayer: audioPlayer,
            albumsQueries: albumsQueries,
            songsQueries: songsQueries
        )
        
        state = .ready(
            FeatureDeps(
                appFrame: appFrame,
                player: player,
                library: library
            )
        )

    }
}

struct Repositories {
    let artist: ArtistRepository
    let collection: CollectionRepository
    let digitalFile: DigitalFileRepository
    let label: LabelRepository
    let medium: MediumRepository
    let recording: RecordingRepository
    let releaseGroup: ReleaseGroupRepository
    let release: ReleaseRepository
    let track: TrackRepository
    let work: WorkRepository
}
