import Foundation

actor SecurityScopedFileAccessCoordinator: FileAccessCoordinating {
    private let store: BookmarkStoring

    init(store: BookmarkStoring) {
        self.store = store
    }

    func withAccess<T>(
        to locationID: LocationID,
        _ body: @Sendable (URL) async throws -> T
    ) async throws -> T {

        var isStale = false
        let data = try await store.bookmarkData(for: locationID)

        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            let refreshed = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            try await store.saveBookmarkData(refreshed, for: locationID)
        }

        guard url.startAccessingSecurityScopedResource() else {
            throw AppError.permissions
        }
        defer { url.stopAccessingSecurityScopedResource() }

        return try await body(url)
    }
}
