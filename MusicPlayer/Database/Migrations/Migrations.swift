import GRDB

struct DatabaseMigrations {
    static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        // register each migration (add new registrations as you add new migration files)
        migrator.registerV1()
        return migrator
    }

    static func migrate(_ writer: DatabaseWriter) throws {
        try makeMigrator().migrate(writer)
    }
}
