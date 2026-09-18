import Foundation

enum SQLiteError: Error, Sendable, LocalizedError, Equatable {
    case connectionFailed(String)
    case prepareFailed(query: String, code: Int32, message: String)
    case stepFailed(code: Int32, message: String)
    case bindFailed(index: Int32, reason: String)
    case executionFailed(sql: String, code: Int32, message: String)
    case migrationFailed(version: Int, reason: String)
    case recordNotFound(String)
    case dataEncodingFailed(String)
    case dataDecodingFailed(String)
    case backupFailed(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let path):
            return "Failed to open SQLite database at path: \(path)"
        case .prepareFailed(let query, let code, let message):
            return "Failed to prepare statement (\(code): \(message)) for query: \(query)"
        case .stepFailed(let code, let message):
            return "Failed to step statement (\(code): \(message))"
        case .bindFailed(let index, let reason):
            return "Failed to bind parameter at index \(index): \(reason)"
        case .executionFailed(let sql, let code, let message):
            return "Failed to execute SQL (\(code): \(message)): \(sql)"
        case .migrationFailed(let version, let reason):
            return "Database migration to version \(version) failed: \(reason)"
        case .recordNotFound(let id):
            return "Record not found with identifier: \(id)"
        case .dataEncodingFailed(let reason):
            return "Failed to encode chart data: \(reason)"
        case .dataDecodingFailed(let reason):
            return "Failed to decode chart data: \(reason)"
        case .backupFailed(let reason):
            return "Database backup failed: \(reason)"
        }
    }
}
