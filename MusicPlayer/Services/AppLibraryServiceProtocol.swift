import Foundation

@MainActor
protocol AppLibraryServiceProtocol: ObservableObject {
    var libraryURL: URL? { get set }
    var libraryDbURL: URL? { get }
    var needsLibraryLocationSetup: Bool { get set }
    
    func setLibraryLocation(url: URL) async throws -> Void
}
