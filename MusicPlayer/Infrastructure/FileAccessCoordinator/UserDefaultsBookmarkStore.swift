import Foundation

@MainActor
final class UserDefaultsBookmarkStore: BookmarkStoring, BookmarkRegistering {
    
    private let defaults: UserDefaults
    private let keyPrefix: String
    
    /// - Parameters:
    ///   - defaults: typically `.standard`, but inject for tests.
    ///   - keyPrefix: namespace to avoid key collisions.
    init(defaults: UserDefaults = .standard, keyPrefix: String = "bookmark.") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }
    
    private func key(for id: LocationID) -> String {
        "\(keyPrefix)\(id.rawValue)"
    }
    
    func bookmarkData(for id: LocationID) async throws -> Data {
        let k = key(for: id)
        guard let data = defaults.data(forKey: k) else {
            throw BookmarkStoreError.notFound(id)
        }
        return data
    }
    
    func saveBookmarkData(_ data: Data, for id: LocationID) async throws {
        defaults.set(data, forKey: key(for: id))
    }
    
    func registerLocation(url: URL) async throws -> LocationID {
        let id = LocationID(rawValue: UUID().uuidString)
        
        let data: Data
        do {
            data = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw BookmarkStoreError.invalidBookmarkCreation(url)
        }
        
        try await saveBookmarkData(data, for: id)
        return id
    }
    
    // Optional helper for bootstrap scenarios
    func deleteLocation(id: LocationID) async {
        defaults.removeObject(forKey: key(for: id))
    }
}

// MARK: - App Library Location Helpers
extension UserDefaultsBookmarkStore {
    static let appLibraryLocationID = LocationID(rawValue: "appLibrary")

    func bookmarkDataForAppLibrary() async throws -> Data {
        try await bookmarkData(for: Self.appLibraryLocationID)
    }

    func saveAppLibraryBookmarkData(_ data: Data) async throws {
        try await saveBookmarkData(data, for: Self.appLibraryLocationID)
    }

    func registerAppLibraryLocation(url: URL) async throws {
        let data = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        try await saveAppLibraryBookmarkData(data)
    }
}
