import Foundation
import SQLite3

nonisolated final class SQLiteStatement {
    private static let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private var statement: OpaquePointer?
    private let db: OpaquePointer?

    init(db: OpaquePointer?, statement: OpaquePointer?) {
        self.db = db
        self.statement = statement
    }

    deinit {
        finalize()
    }

    func finalize() {
        if let stmt = statement {
            sqlite3_finalize(stmt)
            statement = nil
        }
    }

    func reset() {
        if let stmt = statement {
            sqlite3_reset(stmt)
            sqlite3_clear_bindings(stmt)
        }
    }

    // MARK: - Bindings

    func bind(text: String?, at index: Int32) throws {
        guard let stmt = statement else { return }
        if let text {
            let result = sqlite3_bind_text(stmt, index, text, -1, Self.transientDestructor)
            if result != SQLITE_OK {
                throw SQLiteError.bindFailed(index: index, reason: "Text binding error: \(result)")
            }
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    func bind(int: Int?, at index: Int32) throws {
        guard let stmt = statement else { return }
        if let int {
            let result = sqlite3_bind_int64(stmt, index, Int64(int))
            if result != SQLITE_OK {
                throw SQLiteError.bindFailed(index: index, reason: "Int binding error: \(result)")
            }
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    func bind(double: Double?, at index: Int32) throws {
        guard let stmt = statement else { return }
        if let double {
            let result = sqlite3_bind_double(stmt, index, double)
            if result != SQLITE_OK {
                throw SQLiteError.bindFailed(index: index, reason: "Double binding error: \(result)")
            }
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    func bind(bool: Bool?, at index: Int32) throws {
        guard let stmt = statement else { return }
        if let bool {
            let result = sqlite3_bind_int(stmt, index, bool ? 1 : 0)
            if result != SQLITE_OK {
                throw SQLiteError.bindFailed(index: index, reason: "Bool binding error: \(result)")
            }
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    func bind(uuid: UUID?, at index: Int32) throws {
        try bind(text: uuid?.uuidString, at: index)
    }

    func bind(date: Date?, at index: Int32) throws {
        guard let date else {
            try bind(text: nil, at: index)
            return
        }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try bind(text: isoFormatter.string(from: date), at: index)
    }

    func bind(blob: Data?, at index: Int32) throws {
        guard let stmt = statement else { return }
        if let blob {
            let result = blob.withUnsafeBytes { rawBuffer in
                sqlite3_bind_blob(stmt, index, rawBuffer.baseAddress, Int32(blob.count), Self.transientDestructor)
            }
            if result != SQLITE_OK {
                throw SQLiteError.bindFailed(index: index, reason: "Blob binding error: \(result)")
            }
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    // MARK: - Step

    func step() throws -> Bool {
        guard let stmt = statement else { return false }
        let result = sqlite3_step(stmt)
        switch result {
        case SQLITE_ROW:
            return true
        case SQLITE_DONE:
            return false
        default:
            let message = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.stepFailed(code: result, message: message)
        }
    }

    // MARK: - Column extraction

    func isNull(at index: Int32) -> Bool {
        guard let stmt = statement else { return true }
        return sqlite3_column_type(stmt, index) == SQLITE_NULL
    }

    func columnText(at index: Int32) -> String? {
        guard let stmt = statement, !isNull(at: index) else { return nil }
        guard let cString = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: cString)
    }

    func columnInt(at index: Int32) -> Int {
        guard let stmt = statement else { return 0 }
        return Int(sqlite3_column_int64(stmt, index))
    }

    func columnDouble(at index: Int32) -> Double {
        guard let stmt = statement else { return 0.0 }
        return sqlite3_column_double(stmt, index)
    }

    func columnBool(at index: Int32) -> Bool {
        columnInt(at: index) != 0
    }

    func columnUUID(at index: Int32) -> UUID? {
        guard let text = columnText(at: index) else { return nil }
        return UUID(uuidString: text)
    }

    func columnDate(at index: Int32) -> Date? {
        guard let text = columnText(at: index) else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: text) {
            return date
        }
        let fallbackFormatter = ISO8601DateFormatter()
        return fallbackFormatter.date(from: text)
    }

    func columnData(at index: Int32) -> Data? {
        guard let stmt = statement, !isNull(at: index) else { return nil }
        guard let bytes = sqlite3_column_blob(stmt, index) else { return nil }
        let count = Int(sqlite3_column_bytes(stmt, index))
        return Data(bytes: bytes, count: count)
    }
}
