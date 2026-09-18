
import Foundation
import os

extension SQLiteChartRepository {
    func fetchAllCharts() throws -> [LibraryChartDisplayData] {
        let sql = """
        SELECT id, name, location_name, birth_date, calendar_system, lagna_rasi, moon_nakshatra, current_dasha, gender
        FROM charts
        ORDER BY updated_at DESC;
        """

        let stmt = try database.prepare(sql: sql)
        defer { stmt.finalize() }
        var results: [LibraryChartDisplayData] = []

        while try stmt.step() {
            guard let id = stmt.columnUUID(at: 0),
                  let name = stmt.columnText(at: 1),
                  let location = stmt.columnText(at: 2),
                  let birthDate = stmt.columnDate(at: 3)
            else {
                continue
            }

            let calendarStr = stmt.columnText(at: 4) ?? ""
            let calIdentifier: Calendar.Identifier = (calendarStr.contains("Bikram") || calendarStr.contains("B.S."))
                ? .indian
                : .gregorian

            let lagnaRasi = stmt.columnText(at: 5)
            let moonNakshatra = stmt.columnText(at: 6)
            let currentDasha = stmt.columnText(at: 7)
            let gender = stmt.columnText(at: 8)

            results.append(
                LibraryChartDisplayData(
                    id: id,
                    name: name,
                    location: location,
                    localDate: birthDate,
                    calendar: calIdentifier,
                    lagnaRasi: lagnaRasi,
                    moonNakshatra: moonNakshatra,
                    currentDasha: currentDasha,
                    gender: gender
                )
            )
        }

        return results
    }

    func searchCharts(query: String) throws -> [LibraryChartDisplayData] {
        let sql = """
        SELECT id, name, location_name, birth_date, calendar_system, lagna_rasi, moon_nakshatra, current_dasha, gender
        FROM charts
        WHERE name LIKE ? OR location_name LIKE ? OR lagna_rasi LIKE ? OR moon_nakshatra LIKE ? OR current_dasha LIKE ?
        ORDER BY updated_at DESC;
        """

        let stmt = try database.prepare(sql: sql)
        defer { stmt.finalize() }
        let pattern = "%\(query)%"
        try stmt.bind(text: pattern, at: 1)
        try stmt.bind(text: pattern, at: 2)
        try stmt.bind(text: pattern, at: 3)
        try stmt.bind(text: pattern, at: 4)
        try stmt.bind(text: pattern, at: 5)

        var results: [LibraryChartDisplayData] = []
        while try stmt.step() {
            guard let id = stmt.columnUUID(at: 0),
                  let name = stmt.columnText(at: 1),
                  let location = stmt.columnText(at: 2),
                  let birthDate = stmt.columnDate(at: 3)
            else {
                continue
            }

            let calendarStr = stmt.columnText(at: 4) ?? ""
            let calIdentifier: Calendar.Identifier = (calendarStr.contains("Bikram") || calendarStr.contains("B.S."))
                ? .indian
                : .gregorian

            let lagnaRasi = stmt.columnText(at: 5)
            let moonNakshatra = stmt.columnText(at: 6)
            let currentDasha = stmt.columnText(at: 7)
            let gender = stmt.columnText(at: 8)

            results.append(
                LibraryChartDisplayData(
                    id: id,
                    name: name,
                    location: location,
                    localDate: birthDate,
                    calendar: calIdentifier,
                    lagnaRasi: lagnaRasi,
                    moonNakshatra: moonNakshatra,
                    currentDasha: currentDasha,
                    gender: gender
                )
            )
        }

        return results
    }

    func fetchChartDetail(id: UUID) throws -> ChartDetail? {
        let sql = "SELECT raw_chart_json FROM charts WHERE id = ? LIMIT 1;"
        let stmt = try database.prepare(sql: sql)
        defer { stmt.finalize() }
        try stmt.bind(uuid: id, at: 1)

        guard try stmt.step(), let jsonString = stmt.columnText(at: 0) else {
            return nil
        }

        guard let data = jsonString.data(using: String.Encoding.utf8) else {
            throw SQLiteError.dataDecodingFailed("Invalid UTF-8 data for chart ID \(id.uuidString)")
        }

        let decoder = JSONDecoder()
        do {
            let detail = try decoder.decode(ChartDetail.self, from: data)
            return detail
        } catch {
            PersistenceLogger.repository.error("JSON decode failed: \(error.localizedDescription)")
            throw SQLiteError.dataDecodingFailed(error.localizedDescription)
        }
    }

    func saveChart(detail: ChartDetail) throws {
        let encoder = JSONEncoder()
        let jsonData: Data
        do {
            jsonData = try encoder.encode(detail)
        } catch {
            throw SQLiteError.dataEncodingFailed(error.localizedDescription)
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw SQLiteError.dataEncodingFailed("Cannot encode JSON to UTF-8")
        }

        let lagnaRasi = detail.lagnaPosition.rasi.sanskritName
        let moonNakshatra = detail.planets.first(where: { $0.graha == .moon })?.nakshatra.name ?? ""
        let now = Date()

        let sql = """
        INSERT INTO charts (
            id, name, gender, birth_date, birth_time_string, calendar_system,
            bikram_sambat_date, location_name, latitude, longitude, timezone_string,
            ayanamsa_name, ayanamsa_value_dms, node_calculation, sunrise_string,
            sunset_string, lagna_rasi, moon_nakshatra, current_dasha, engine_version,
            raw_chart_json, created_at, updated_at
        ) VALUES (
            ?, ?, ?, ?, ?, ?,
            ?, ?, ?, ?, ?,
            ?, ?, ?, ?,
            ?, ?, ?, ?, ?,
            ?, ?, ?
        )
        ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            gender = excluded.gender,
            birth_date = excluded.birth_date,
            birth_time_string = excluded.birth_time_string,
            calendar_system = excluded.calendar_system,
            bikram_sambat_date = excluded.bikram_sambat_date,
            location_name = excluded.location_name,
            latitude = excluded.latitude,
            longitude = excluded.longitude,
            timezone_string = excluded.timezone_string,
            ayanamsa_name = excluded.ayanamsa_name,
            ayanamsa_value_dms = excluded.ayanamsa_value_dms,
            node_calculation = excluded.node_calculation,
            sunrise_string = excluded.sunrise_string,
            sunset_string = excluded.sunset_string,
            lagna_rasi = excluded.lagna_rasi,
            moon_nakshatra = excluded.moon_nakshatra,
            current_dasha = excluded.current_dasha,
            engine_version = excluded.engine_version,
            raw_chart_json = excluded.raw_chart_json,
            updated_at = excluded.updated_at;
        """

        let stmt = try database.prepare(sql: sql)
        defer { stmt.finalize() }
        try stmt.bind(uuid: detail.id, at: 1)
        try stmt.bind(text: detail.name, at: 2)
        try stmt.bind(text: detail.gender, at: 3)
        try stmt.bind(date: detail.birthDate, at: 4)
        try stmt.bind(text: detail.birthTimeString, at: 5)
        try stmt.bind(text: detail.calendarSystem, at: 6)
        try stmt.bind(text: detail.bikramSambatDateString, at: 7)
        try stmt.bind(text: detail.locationName, at: 8)
        try stmt.bind(text: detail.latitude, at: 9)
        try stmt.bind(text: detail.longitude, at: 10)
        try stmt.bind(text: detail.timezoneString, at: 11)
        try stmt.bind(text: detail.ayanamsaName, at: 12)
        try stmt.bind(text: detail.ayanamsaValueDMS, at: 13)
        try stmt.bind(text: detail.nodeCalculation, at: 14)
        try stmt.bind(text: detail.sunriseString, at: 15)
        try stmt.bind(text: detail.sunsetString, at: 16)
        try stmt.bind(text: lagnaRasi, at: 17)
        try stmt.bind(text: moonNakshatra, at: 18)
        try stmt.bind(text: detail.currentDashaVector, at: 19)
        try stmt.bind(int: 1, at: 20)
        try stmt.bind(text: jsonString, at: 21)
        try stmt.bind(date: now, at: 22)
        try stmt.bind(date: now, at: 23)

        _ = try stmt.step()
        try syncNotesAndPredictions(for: detail, timestamp: now)
        PersistenceLogger.repository.info("Saved chart with ID: \(detail.id.uuidString, privacy: .public)")
    }

    private func syncNotesAndPredictions(for detail: ChartDetail, timestamp: Date) throws {
        let deleteNotes = try database.prepare(sql: "DELETE FROM chart_notes WHERE chart_id = ?;")
        defer { deleteNotes.finalize() }
        try deleteNotes.bind(uuid: detail.id, at: 1)
        _ = try deleteNotes.step()

        let insertNote = try database.prepare(sql: """
        INSERT INTO chart_notes (id, chart_id, date, category, content, tags, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """)
        defer { insertNote.finalize() }

        for note in detail.notes {
            insertNote.reset()
            try insertNote.bind(uuid: note.id, at: 1)
            try insertNote.bind(uuid: detail.id, at: 2)
            try insertNote.bind(date: note.date, at: 3)
            try insertNote.bind(text: note.category, at: 4)
            try insertNote.bind(text: note.content, at: 5)
            let tagsJson = (try? String(data: JSONEncoder().encode(note.tags), encoding: .utf8)) ?? "[]"
            try insertNote.bind(text: tagsJson, at: 6)
            try insertNote.bind(date: timestamp, at: 7)
            _ = try insertNote.step()
        }

        let deletePreds = try database.prepare(sql: "DELETE FROM chart_predictions WHERE chart_id = ?;")
        defer { deletePreds.finalize() }
        try deletePreds.bind(uuid: detail.id, at: 1)
        _ = try deletePreds.step()

        let insertPred = try database.prepare(sql: """
        INSERT INTO chart_predictions (id, chart_id, title, target_date, status, dasha_context, details, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """)
        defer { insertPred.finalize() }

        for pred in detail.predictions {
            insertPred.reset()
            try insertPred.bind(uuid: pred.id, at: 1)
            try insertPred.bind(uuid: detail.id, at: 2)
            try insertPred.bind(text: pred.title, at: 3)
            try insertPred.bind(date: pred.targetDate, at: 4)
            try insertPred.bind(text: pred.status.rawValue, at: 5)
            try insertPred.bind(text: pred.dashaContext, at: 6)
            try insertPred.bind(text: pred.details, at: 7)
            try insertPred.bind(date: timestamp, at: 8)
            _ = try insertPred.step()
        }
    }

    func deleteChart(id: UUID) throws {
        let sql = "DELETE FROM charts WHERE id = ?;"
        let stmt = try database.prepare(sql: sql)
        defer { stmt.finalize() }
        try stmt.bind(uuid: id, at: 1)
        _ = try stmt.step()
        PersistenceLogger.repository.info("Deleted chart with ID: \(id.uuidString, privacy: .public)")
    }
}
