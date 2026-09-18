import Foundation

protocol Migration: Sendable {
    var version: Int { get }
    var name: String { get }
    func apply(to db: SQLiteDatabase) throws
}
