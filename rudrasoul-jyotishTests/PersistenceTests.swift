import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct SQLiteDatabaseTests {

    @Test func openInMemoryDatabaseAndExecuteSimpleQuery() throws {
        let db = try SQLiteDatabase(path: ":memory:")
        try db.execute(sql: "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT);")
        try db.execute(sql: "INSERT INTO test (id, name) VALUES (1, 'Jyotish');")

        let stmt = try db.prepare(sql: "SELECT name FROM test WHERE id = 1;")
        defer { stmt.finalize() }

        #expect(try stmt.step() == true)
        #expect(stmt.columnText(at: 0) == "Jyotish")
    }

    @Test func parameterBindingsAndDataExtraction() throws {
        let db = try SQLiteDatabase(path: ":memory:")
        try db.execute(sql: """
        CREATE TABLE items (
            id TEXT PRIMARY KEY,
            count INTEGER,
            ratio REAL,
            is_active INTEGER,
            created_at TEXT
        );
        """)

        let insertStmt = try db.prepare(sql: """
        INSERT INTO items (id, count, ratio, is_active, created_at)
        VALUES (?, ?, ?, ?, ?);
        """)
        defer { insertStmt.finalize() }

        let testUUID = UUID()
        let testDate = Date(timeIntervalSince1970: 1700000000)

        try insertStmt.bind(uuid: testUUID, at: 1)
        try insertStmt.bind(int: 42, at: 2)
        try insertStmt.bind(double: 3.14159, at: 3)
        try insertStmt.bind(bool: true, at: 4)
        try insertStmt.bind(date: testDate, at: 5)

        #expect(try insertStmt.step() == false)

        let queryStmt = try db.prepare(sql: "SELECT id, count, ratio, is_active, created_at FROM items WHERE id = ?;")
        defer { queryStmt.finalize() }
        try queryStmt.bind(uuid: testUUID, at: 1)

        #expect(try queryStmt.step() == true)
        #expect(queryStmt.columnUUID(at: 0) == testUUID)
        #expect(queryStmt.columnInt(at: 1) == 42)
        #expect(abs(queryStmt.columnDouble(at: 2) - 3.14159) < 0.0001)
        #expect(queryStmt.columnBool(at: 3) == true)
        #expect(queryStmt.columnDate(at: 4) != nil)
    }

    @Test func transactionRollbackOnError() throws {
        let db = try SQLiteDatabase(path: ":memory:")
        try db.execute(sql: "CREATE TABLE accounts (balance INTEGER);")
        try db.execute(sql: "INSERT INTO accounts VALUES (100);")

        do {
            try db.transaction { database in
                try database.execute(sql: "UPDATE accounts SET balance = 50;")
                throw SQLiteError.executionFailed(sql: "test", code: -1, message: "Intentional error")
            }
        } catch {
            // Expected
        }

        let stmt = try db.prepare(sql: "SELECT balance FROM accounts;")
        defer { stmt.finalize() }
        #expect(try stmt.step() == true)
        #expect(stmt.columnInt(at: 0) == 100) // Rolled back
    }

    @Test func userVersionTracking() throws {
        let db = try SQLiteDatabase(path: ":memory:")
        #expect(try db.userVersion() == 0)

        try db.setUserVersion(1)
        #expect(try db.userVersion() == 1)

        try db.setUserVersion(2)
        #expect(try db.userVersion() == 2)
    }
}

@MainActor
struct MigrationTests {

    @Test func migrationV1CreatesRequiredTablesAndIndices() throws {
        let db = try SQLiteDatabase(path: ":memory:")
        let runner = MigrationRunner(migrations: [MigrationV1_InitialSchema()])

        try runner.run(on: db)
        #expect(try db.userVersion() == 1)

        // Verify tables exist
        let tablesStmt = try db.prepare(sql: "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='charts';")
        defer { tablesStmt.finalize() }
        #expect(try tablesStmt.step() == true)
        #expect(tablesStmt.columnInt(at: 0) == 1)

        let notesStmt = try db.prepare(sql: "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='chart_notes';")
        defer { notesStmt.finalize() }
        #expect(try notesStmt.step() == true)
        #expect(notesStmt.columnInt(at: 0) == 1)

        let predStmt = try db.prepare(sql: "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='chart_predictions';")
        defer { predStmt.finalize() }
        #expect(try predStmt.step() == true)
        #expect(predStmt.columnInt(at: 0) == 1)
    }

    @Test func migrationIsIdempotent() throws {
        let db = try SQLiteDatabase(path: ":memory:")
        let runner = MigrationRunner(migrations: [MigrationV1_InitialSchema()])

        try runner.run(on: db)
        #expect(try db.userVersion() == 1)

        // Running a second time should not throw
        try runner.run(on: db)
        #expect(try db.userVersion() == 1)
    }
}

@MainActor
struct SQLiteChartRepositoryTests {

    @Test func emptyRepositoryInitializationAndSeeding() async throws {
        let repo = try SQLiteChartRepository.inMemory()
        try await repo.initialize()

        let count = try await repo.countCharts()
        #expect(count >= 2)

        let charts = try await repo.fetchAllCharts()
        #expect(charts.contains(where: { $0.name == "Rabindranath Tagore" }))
        #expect(charts.contains(where: { $0.name == "Mahatma Gandhi" }))
    }

    @Test func saveAndFetchChartDetail() async throws {
        let repo = try SQLiteChartRepository.inMemory()
        try await repo.initialize()

        let tagore = GoldenChartFixtures.tagore
        try await repo.saveChart(detail: tagore)

        let fetched = try await repo.fetchChartDetail(id: tagore.id)
        #expect(fetched != nil)
        #expect(fetched?.name == tagore.name)
        #expect(fetched?.locationName == tagore.locationName)
        #expect(fetched?.lagnaPosition.rasi == .pisces)
        #expect(fetched?.lagnaPosition.formattedDMS == "02° 14' 00\"")
        #expect(fetched?.planets.count == 9)
        #expect(fetched?.bhavas.count == 12)
        #expect(fetched?.shadbala.count == 7)
        #expect(fetched?.notes.count == tagore.notes.count)
        #expect(fetched?.predictions.count == tagore.predictions.count)
    }

    @Test func searchChartsByNameAndLocation() async throws {
        let repo = try SQLiteChartRepository.inMemory()
        try await repo.initialize()

        let searchTagore = try await repo.searchCharts(query: "Tagore")
        #expect(searchTagore.count == 1)
        #expect(searchTagore.first?.name == "Rabindranath Tagore")

        let searchKolkata = try await repo.searchCharts(query: "Kolkata")
        #expect(searchKolkata.count == 1)
        #expect(searchKolkata.first?.name == "Rabindranath Tagore")

        let searchGandhi = try await repo.searchCharts(query: "Gandhi")
        #expect(searchGandhi.count == 1)
        #expect(searchGandhi.first?.name == "Mahatma Gandhi")

        let searchNone = try await repo.searchCharts(query: "NonExistent")
        #expect(searchNone.isEmpty)
    }

    @Test func deleteChartCascadesToNotesAndPredictions() async throws {
        let repo = try SQLiteChartRepository.inMemory()
        try await repo.initialize()

        let initialCount = try await repo.countCharts()
        let tagore = GoldenChartFixtures.tagore

        try await repo.deleteChart(id: tagore.id)
        let afterCount = try await repo.countCharts()
        #expect(afterCount == initialCount - 1)

        let fetched = try await repo.fetchChartDetail(id: tagore.id)
        #expect(fetched == nil)

        // Verify notes and predictions were removed
        let notes = try repo.database.prepare(sql: "SELECT count(*) FROM chart_notes WHERE chart_id = ?;")
        defer { notes.finalize() }
        try notes.bind(uuid: tagore.id, at: 1)
        #expect(try notes.step() == true)
        #expect(notes.columnInt(at: 0) == 0)
    }

    @Test func exportAndRestoreDatabase() async throws {
        let repo = try SQLiteChartRepository.inMemory()
        try await repo.initialize()

        let tempDir = FileManager.default.temporaryDirectory
        let exportURL = tempDir.appendingPathComponent("test_backup_\(UUID().uuidString).sqlite3")
        defer { try? FileManager.default.removeItem(at: exportURL) }

        try await repo.exportDatabase(to: exportURL)
        #expect(FileManager.default.fileExists(atPath: exportURL.path))

        // Create a new in-memory repo and restore into it
        let newRepo = try SQLiteChartRepository.inMemory()
        try await newRepo.restoreDatabase(from: exportURL)

        let restoredCount = try await newRepo.countCharts()
        #expect(restoredCount >= 2)

        let tagore = try await newRepo.fetchChartDetail(id: GoldenChartFixtures.tagore.id)
        #expect(tagore?.name == "Rabindranath Tagore")
    }
}
