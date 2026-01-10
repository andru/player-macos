import Foundation

protocol BookmarkStoring: Sendable {
    func bookmarkData(for id: LocationID) async throws -> Data
    func saveBookmarkData(_ data: Data, for id: LocationID) async throws
    func registerLocation(url: URL) async throws -> LocationID
}

protocol BookmarkRegistering: Sendable {
    func registerLocation(url: URL) async throws -> LocationID
}

enum BookmarkStoreError: Error {
    case notFound(LocationID)
    case invalidBookmarkCreation(URL)
}
