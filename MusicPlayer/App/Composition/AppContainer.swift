import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    enum State {
        case booting
        case failed(AppError)
        case idle
        case opening
        case ready(Ready)
        case error(Error)
    }
    
    struct Ready {
        let repos: Repositories
        let deps: FeatureDeps
    }

    struct FeatureDeps {
        let appFrame: AppFrameDependencies
        let player: PlayerDependencies
        let library: LibraryDependencies
    }

    var repositories: Repositories {
        guard case .ready(let ready) = state else {
            preconditionFailure("AppContainer.repositories accessed before container is ready")
        }
        return ready.repos
    }
    
    var featureDeps: FeatureDeps {
        guard case .ready(let ready) = state else {
            preconditionFailure("AppContainer.featureDeps accessed before container is ready")
        }
        return ready.deps
    }
    
    @Published private(set) var state: State = .idle
    
    var appLibrary: AppLibraryService = AppLibraryService()

    init() {
        self.state = .booting

        Task { [weak self] in
            await self?.bootstrap()
        }
    }
    
    private func bootstrap() async {
        do {
            let appLibraryContext = try await appLibrary.openLibrary()
            let db = try AppDatabase(url: appLibraryContext.libraryDbURL)
            
            // Infrastructure implementations (GRDB-backed)
            // Main Repos
            let repos = Repositories(
                artist: GRDBArtistRepository(dbWriter: db.dbWriter),
                collection: GRDBCollectionRepository(dbWriter: db.dbWriter),
                digitalFile: GRDBDigitalFileRepository(dbWriter: db.dbWriter),
                label: GRDBLabelRepository(dbWriter: db.dbWriter),
                medium: GRDBMediumRepository(dbWriter: db.dbWriter),
                recording: GRDBRecordingRepository(dbWriter: db.dbWriter),
                releaseGroup: GRDBReleaseGroupRepository(dbWriter: db.dbWriter),
                release: GRDBReleaseRepository(dbWriter: db.dbWriter),
                track: GRDBTrackRepository(dbWriter: db.dbWriter),
                work: GRDBWorkRepository(dbWriter: db.dbWriter),
                localTrack: GRDBLocalTrackRepository(dbWriter: db.dbWriter),
                localTrackTags: GRDBLocalTrackTagsRepository(dbWriter: db.dbWriter),
                libraryTrack: GRDBLibraryTrackRepository(dbWriter: db.dbWriter),
                trackMatch: GRDBTrackMatchRepository(dbWriter: db.dbWriter)
            )
            // Optimised Queries
            let albumsQueries = GRDBAlbumRowQuery(dbWriter: db.dbWriter)
            let songsQueries = GRDBSongsQueries(dbWriter: db.dbWriter)
            let artistsQueries = GRDBArtistsQueries(dbWriter: db.dbWriter)
            
            // Init services
            let musicImportService = MusicImportService(repositories: repos)
            let audioPlayer = AudioPlayerService()
            
            // Bundle per feature
            let appFrame = AppFrameDependencies(
                appLibraryService: appLibrary,
                audioPlayer: audioPlayer
            )
            let player = PlayerDependencies(
                audioPlayer: audioPlayer
            )
            let library = LibraryDependencies(
                audioPlayer: audioPlayer,
                albumsQueries: albumsQueries,
                songsQueries: songsQueries,
                artistsQueries: artistsQueries
            )
            
            let deps = FeatureDeps(
                appFrame: appFrame,
                player: player,
                library: library
            )
            
            state = .ready(Ready(repos: repos, deps:deps))
        } catch {
            self.state = .failed(AppError(error))
        }

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
    
    // Bridge layer repositories
    let localTrack: LocalTrackRepository
    let localTrackTags: LocalTrackTagsRepository
    let libraryTrack: LibraryTrackRepository
    let trackMatch: TrackMatchRepository
}

enum AppError: Error, Identifiable {
    // Stable, user-visible categories
    case library(Library)
    case database(Database)
    case permissions
    case corruptedData
    case unknown(underlying: Error)

    var id: String { code }
}

extension AppError {
    enum Library: Error {
        case missingLocation
        case bookmarkInvalid
        case openFailed(underlying: Error)
    }

    enum Database: Error {
        case openFailed(underlying: Error)
        case migrationFailed(underlying: Error)
    }
}

extension AppError {
    var code: String {
        switch self {
        case .library(.missingLocation):
            return "LIB_NO_LOCATION"
        case .library(.bookmarkInvalid):
            return "LIB_BOOKMARK_INVALID"
        case .library(.openFailed):
            return "LIB_OPEN_FAILED"

        case .database(.openFailed):
            return "DB_OPEN_FAILED"
        case .database(.migrationFailed):
            return "DB_MIGRATION_FAILED"

        case .permissions:
            return "PERMISSION_DENIED"
        case .corruptedData:
            return "DATA_CORRUPTED"

        case .unknown:
            return "UNKNOWN"
        }
    }
}

extension AppError {
    init(_ error: Error) {
        switch error {
        case let e as AppLibraryError:
            self = .library(e.toAppError)
        default:
            self = .unknown(underlying: error)
        }
    }
}

private extension AppLibraryError {
    var toAppError: AppError.Library {
        switch self {
        case .missingLibraryURL:
            return .missingLocation
        case .bookmarkInvalid:
            return .bookmarkInvalid
        case .openFailed:
            return .openFailed(underlying: self)
        }
    }
}
