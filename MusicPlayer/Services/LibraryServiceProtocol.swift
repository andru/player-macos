import Foundation

@MainActor
protocol LibraryServiceProtocol: ObservableObject {
    var tracks: [Track] { get set }
    var collections: [Collection] { get set }
    var libraryURL: URL? { get set }
    var needsLibraryLocationSetup: Bool { get set }

    // Derived
    var albums: [Album] { get }
    var artists: [Artist] { get }

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
