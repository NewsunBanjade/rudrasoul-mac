import Foundation

/// Removes the two records created by the pre-user-library fixture seeder.
/// Their fixed identifiers were never assignable to user-created charts.
struct MigrationV2_RemoveSeededCharts: Migration {
    let version = 2
    let name = "Remove seeded chart fixtures"

    func apply(to db: SQLiteDatabase) throws {
        try db.execute(sql: """
        DELETE FROM charts
        WHERE id IN (
            '11111111-2222-3333-4444-555555555555',
            '66666666-7777-8888-9999-000000000000'
        );
        """)
    }
}
