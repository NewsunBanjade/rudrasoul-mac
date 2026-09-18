import Foundation

struct MigrationV1_InitialSchema: Migration {
    let version: Int = 1
    let name: String = "CreateInitialSchema"

    func apply(to db: SQLiteDatabase) throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS charts (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            gender TEXT NOT NULL,
            birth_date TEXT NOT NULL,
            birth_time_string TEXT NOT NULL,
            calendar_system TEXT NOT NULL,
            bikram_sambat_date TEXT NOT NULL,
            location_name TEXT NOT NULL,
            latitude TEXT NOT NULL,
            longitude TEXT NOT NULL,
            timezone_string TEXT NOT NULL,
            ayanamsa_name TEXT NOT NULL,
            ayanamsa_value_dms TEXT NOT NULL,
            node_calculation TEXT NOT NULL,
            sunrise_string TEXT NOT NULL,
            sunset_string TEXT NOT NULL,
            lagna_rasi TEXT NOT NULL,
            moon_nakshatra TEXT NOT NULL,
            current_dasha TEXT NOT NULL,
            engine_version INTEGER NOT NULL DEFAULT 1,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            tags TEXT NOT NULL DEFAULT '[]',
            raw_chart_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_charts_name ON charts(name);
        CREATE INDEX IF NOT EXISTS idx_charts_birth_date ON charts(birth_date);
        CREATE INDEX IF NOT EXISTS idx_charts_lagna_rasi ON charts(lagna_rasi);
        CREATE INDEX IF NOT EXISTS idx_charts_moon_nakshatra ON charts(moon_nakshatra);
        CREATE INDEX IF NOT EXISTS idx_charts_engine_version ON charts(engine_version);
        CREATE INDEX IF NOT EXISTS idx_charts_updated_at ON charts(updated_at);

        CREATE TABLE IF NOT EXISTS chart_notes (
            id TEXT PRIMARY KEY NOT NULL,
            chart_id TEXT NOT NULL,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT NOT NULL DEFAULT '[]',
            created_at TEXT NOT NULL,
            FOREIGN KEY (chart_id) REFERENCES charts(id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_chart_notes_chart_id ON chart_notes(chart_id);

        CREATE TABLE IF NOT EXISTS chart_predictions (
            id TEXT PRIMARY KEY NOT NULL,
            chart_id TEXT NOT NULL,
            title TEXT NOT NULL,
            target_date TEXT NOT NULL,
            status TEXT NOT NULL,
            dasha_context TEXT NOT NULL,
            details TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (chart_id) REFERENCES charts(id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_chart_predictions_chart_id ON chart_predictions(chart_id);
        """

        try db.execute(sql: sql)
    }
}
