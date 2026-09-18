import Foundation
import os

nonisolated enum PersistenceLogger: Sendable {
    nonisolated static let sqlite = Logger(subsystem: "com.rudrasoul.jyotish", category: "sqlite")
    nonisolated static let migration = Logger(subsystem: "com.rudrasoul.jyotish", category: "migration")
    nonisolated static let repository = Logger(subsystem: "com.rudrasoul.jyotish", category: "repository")
    nonisolated static let store = Logger(subsystem: "com.rudrasoul.jyotish", category: "store")
}
