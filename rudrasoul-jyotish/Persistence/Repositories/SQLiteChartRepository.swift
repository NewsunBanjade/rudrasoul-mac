import Foundation
import os

final class SQLiteChartRepository: ChartRepository {
    static let shared: SQLiteChartRepository = {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            let appFolder = appSupport.appendingPathComponent("rudrasoul-jyotish", isDirectory: true)
            try FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
            let dbURL = appFolder.appendingPathComponent("jyotish.sqlite3")
            let db = try SQLiteDatabase(path: dbURL.path)
            let repo = SQLiteChartRepository(database: db)
            Task {
                try? await repo.initialize()
            }
            return repo
        } catch {
            PersistenceLogger.repository.error("Failed to initialize on-disk SQLite, using in-memory: \(error.localizedDescription)")
            let fallbackDB = try! SQLiteDatabase(path: ":memory:")
            let repo = SQLiteChartRepository(database: fallbackDB)
            Task {
                try? await repo.initialize()
            }
            return repo
        }
    }()

    let database: SQLiteDatabase
    private let migrationRunner: MigrationRunner

    init(
        database: SQLiteDatabase,
        migrationRunner: MigrationRunner = MigrationRunner()
    ) {
        self.database = database
        self.migrationRunner = migrationRunner
    }

    static func inMemory() throws -> SQLiteChartRepository {
        let db = try SQLiteDatabase(path: ":memory:")
        let repo = SQLiteChartRepository(database: db)
        return repo
    }

    func initialize() throws {
        try migrationRunner.run(on: database)
    }

    func countCharts() throws -> Int {
        _ = try database.userVersion()
        let stmt = try database.prepare(sql: "SELECT COUNT(*) FROM charts;")
        defer { stmt.finalize() }
        if try stmt.step() {
            return stmt.columnInt(at: 0)
        }
        return 0
    }

    func exportDatabase(to destinationURL: URL) throws {
        try database.backup(to: destinationURL.path)
    }

    func restoreDatabase(from sourceURL: URL) throws {
        try database.restore(from: sourceURL.path)
    }
}
