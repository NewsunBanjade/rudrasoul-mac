import Foundation
import os
import SQLite3

nonisolated final class SQLiteDatabase {
    private var db: OpaquePointer?
    let path: String
    let isInMemory: Bool

    init(path: String) throws {
        self.path = path
        let inMem = path == ":memory:" || path.isEmpty
        self.isInMemory = inMem

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let status = sqlite3_open_v2(path, &handle, flags, nil)

        guard status == SQLITE_OK, let dbHandle = handle else {
            let errorMsg = handle != nil ? String(cString: sqlite3_errmsg(handle)) : "Unknown"
            if let handle { sqlite3_close_v2(handle) }
            throw SQLiteError.connectionFailed("\(path) (\(status): \(errorMsg))")
        }

        self.db = dbHandle
        try configurePragmas(isInMemory: inMem)
        PersistenceLogger.sqlite.debug("Database opened successfully at \(path, privacy: .public)")
    }

    deinit {
        if let db {
            sqlite3_close_v2(db)
        }
    }

    func close() {
        if let db {
            sqlite3_close_v2(db)
            self.db = nil
        }
    }

    private func configurePragmas(isInMemory: Bool) throws {
        try execute(sql: "PRAGMA foreign_keys = ON;")
        try execute(sql: "PRAGMA busy_timeout = 5000;")

        if !isInMemory {
            try execute(sql: "PRAGMA journal_mode = WAL;")
            try execute(sql: "PRAGMA synchronous = NORMAL;")
        }
    }

    // MARK: - Execution

    func execute(sql: String) throws {
        guard let db else {
            throw SQLiteError.connectionFailed("Database connection closed")
        }

        var errmsg: UnsafeMutablePointer<CChar>?
        let status = sqlite3_exec(db, sql, nil, nil, &errmsg)

        if status != SQLITE_OK {
            let message = errmsg != nil ? String(cString: errmsg!) : "Unknown error"
            sqlite3_free(errmsg)
            throw SQLiteError.executionFailed(sql: sql, code: status, message: message)
        }
    }

    func prepare(sql: String) throws -> SQLiteStatement {
        guard let db else {
            throw SQLiteError.connectionFailed("Database connection closed")
        }

        var statement: OpaquePointer?
        let status = sqlite3_prepare_v2(db, sql, -1, &statement, nil)

        if status != SQLITE_OK {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.prepareFailed(query: sql, code: status, message: message)
        }

        return SQLiteStatement(db: db, statement: statement)
    }

    // MARK: - Transactions

    func beginTransaction() throws {
        try execute(sql: "BEGIN IMMEDIATE TRANSACTION;")
    }

    func commitTransaction() throws {
        try execute(sql: "COMMIT TRANSACTION;")
    }

    func rollbackTransaction() throws {
        try execute(sql: "ROLLBACK TRANSACTION;")
    }

    func transaction<T>(_ block: (SQLiteDatabase) throws -> T) throws -> T {
        try beginTransaction()
        do {
            let result = try block(self)
            try commitTransaction()
            return result
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }

    // MARK: - Pragmas & Versioning

    func userVersion() throws -> Int {
        let stmt = try prepare(sql: "PRAGMA user_version;")
        defer { stmt.finalize() }
        if try stmt.step() {
            return stmt.columnInt(at: 0)
        }
        return 0
    }

    func setUserVersion(_ version: Int) throws {
        try execute(sql: "PRAGMA user_version = \(version);")
    }

    // MARK: - Backup & Restore

    func backup(to destinationPath: String) throws {
        guard let db else {
            throw SQLiteError.connectionFailed("Database handle is null")
        }

        var destDb: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(destinationPath, &destDb, flags, nil) == SQLITE_OK else {
            let message = destDb != nil ? String(cString: sqlite3_errmsg(destDb)) : "Unknown"
            if let destDb { sqlite3_close_v2(destDb) }
            throw SQLiteError.backupFailed("Cannot open backup destination: \(message)")
        }
        defer { sqlite3_close_v2(destDb) }

        guard let backup = sqlite3_backup_init(destDb, "main", db, "main") else {
            let message = String(cString: sqlite3_errmsg(destDb))
            throw SQLiteError.backupFailed("sqlite3_backup_init failed: \(message)")
        }

        let stepResult = sqlite3_backup_step(backup, -1)
        let finishResult = sqlite3_backup_finish(backup)

        if stepResult != SQLITE_DONE || finishResult != SQLITE_OK {
            throw SQLiteError.backupFailed("Backup failed with code \(stepResult)")
        }
        PersistenceLogger.sqlite.info("Database backup completed successfully.")
    }

    func restore(from sourcePath: String) throws {
        guard let db else {
            throw SQLiteError.connectionFailed("Database handle is null")
        }

        var srcDb: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(sourcePath, &srcDb, flags, nil) == SQLITE_OK else {
            let message = srcDb != nil ? String(cString: sqlite3_errmsg(srcDb)) : "Unknown"
            if let srcDb { sqlite3_close_v2(srcDb) }
            throw SQLiteError.backupFailed("Cannot open restore source: \(message)")
        }
        defer { sqlite3_close_v2(srcDb) }

        guard let backup = sqlite3_backup_init(db, "main", srcDb, "main") else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.backupFailed("sqlite3_backup_init for restore failed: \(message)")
        }

        let stepResult = sqlite3_backup_step(backup, -1)
        let finishResult = sqlite3_backup_finish(backup)

        if stepResult != SQLITE_DONE || finishResult != SQLITE_OK {
            throw SQLiteError.backupFailed("Restore failed with code \(stepResult)")
        }
        PersistenceLogger.sqlite.info("Database restored successfully.")
    }
}
