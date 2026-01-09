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

    
    @Published private(set) var state: State = .idle
    
    var appLibrary: AppLibraryService = AppLibraryService()
    let db: AppDatabase
    
    var audioPlayer: AudioPlayerService
    var appFrame: AppFrameDependencies
    var player: PlayerDependencies
    var library: LibraryDependencies


//    let artists: ArtistsDependencies

    init() throws {
        self.db = try AppDatabase(url: appLibrary.libraryDbURL!)

        // Infrastructure implementations (GRDB-backed)
        let trackRowQuery = GRDBTrackRowQuery(dbWriter: db.dbWriter)
        let albumsQueries = GRDBAlbumRowQuery(dbWriter: db.dbWriter)
        
        let 

        // Services
        let audioPlayer = AudioPlayerService()
        self.audioPlayer = audioPlayer

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
            trackRowQuery: trackRowQuery
        )
        
        state = .ready(
            FeatureDeps(
                appFrame: appFrame,
                player: player,
                library: library
            )
        )
        
        self.appFrame = appFrame
        self.player = player
        self.library = library

    }
}

