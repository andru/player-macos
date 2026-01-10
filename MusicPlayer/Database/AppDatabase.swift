import Foundation
import GRDB

class AppDatabase {
    
    let dbWriter: any DatabaseWriter   // DatabaseQueue or DatabasePool

    init(url: URL) throws {
        do {
            self.dbWriter = try DatabaseQueue(path: url.path)
            try migrator.migrate(dbWriter)
        } catch {
            throw DatabaseError.openFailed(message: error.localizedDescription)
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerV1()
        return migrator
    }

}

enum DatabaseError: Error, LocalizedError {
    case notOpen
    case openFailed(message: String)
    case badSchema(message: String)
    var errorDescription: String? {
        switch self {
        case .notOpen:
            return "Database is not open"
        case .openFailed(let message):
            return "Failed to open database: \(message)"
        case .badSchema(let message):
            return "Database schema error: \(message)"
        }
    }
}
