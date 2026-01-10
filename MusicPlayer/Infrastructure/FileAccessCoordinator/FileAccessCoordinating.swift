import Foundation

protocol FileAccessCoordinating: Sendable {
    func withAccess<T>(
        to locationID: LocationID,
        _ body: @Sendable (URL) async throws -> T
    ) async throws -> T
}
struct LocationID: Hashable, Sendable { let rawValue: String }
