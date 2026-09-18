import Foundation
import os


struct MigrationRunner: Sendable {
    let migrations: [any Migration]

    init(migrations: [any Migration] = [MigrationV1_InitialSchema()]) {
        self.migrations = migrations.sorted { $0.version < $1.version }
    }

    func run(on db: SQLiteDatabase) throws {
        let currentVersion = try db.userVersion()
        PersistenceLogger.migration.debug("Database current user_version is \(currentVersion)")

        for migration in migrations where migration.version > currentVersion {
            PersistenceLogger.migration.info("Applying migration v\(migration.version): \(migration.name)")
            do {
                try migration.apply(to: db)
                try db.setUserVersion(migration.version)
                PersistenceLogger.migration.info("Successfully applied migration v\(migration.version)")
            } catch {
                PersistenceLogger.migration.error("Migration v\(migration.version) failed: \(error.localizedDescription)")
                throw SQLiteError.migrationFailed(version: migration.version, reason: error.localizedDescription)
            }
        }
    }
}
