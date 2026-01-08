import Foundation

@MainActor
protocol LibraryServiceProtocol: ObservableObject {
    var tracks: [Track] { get set }
    var collections: [Collection] { get set }
    var albums: [Album] { get set }
    var artists: [Artist] { get set }
    var libraryURL: URL? { get set }
    var needsLibraryLocationSetup: Bool { get set }

    // Actions
    func importFiles(urls: [URL]) async
    func importDirectory(url: URL) async
    func setLibraryLocation(url: URL)
    func saveLibrary()

    // Mutations
    func addTrack(_ track: Track)
    func removeTrack(_ track: Track)
    func addCollection(_ collection: Collection)
    func removeCollection(_ collection: Collection)
    func addTracksToCollection(tracks: [Track], collection: Collection)
}
