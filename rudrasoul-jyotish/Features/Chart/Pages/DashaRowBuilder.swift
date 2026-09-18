import Foundation

/// One row of the dasha hierarchy table, built from either a Vimshottari
/// `DashaNode` tree or a `DashaPeriod` tree of another system.
struct DashaRowItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    /// Planet glyph or sign glyph shown before the name.
    let glyph: String
    /// Compact label for the continuum strip: planet abbreviation or sign glyph.
    let shortLabel: String
    /// "MD", "AD", "PD", "SD", "PrD", or "L6" and beyond.
    let levelTag: String
    /// 0 for a mahadasha, 1 for an antardasha, and so on.
    let depth: Int
    let graha: Graha?
    let rasi: Rasi?
    let startDate: Date
    let endDate: Date
    let formattedDuration: String
    let ageAtStart: Double
    let ageAtEnd: Double
    /// True when the row contains the target date it was built for.
    let isActive: Bool
    /// Nil for a leaf so the table shows no disclosure control.
    var children: [DashaRowItem]?

    var durationDays: Double { endDate.timeIntervalSince(startDate) / 86_400 }

    func contains(_ date: Date) -> Bool { date >= startDate && date < endDate }
}

/// Pure conversion of dasha trees into table rows. No SwiftUI.
enum DashaRowBuilder {
    private static let rasiGlyphs = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"]

    static func rows(from nodes: [DashaNode], birthDate: Date, targetDate: Date, yearLengthDays: Double) -> [DashaRowItem] {
        nodes.map { node in
            DashaRowItem(
                id: node.id,
                name: node.lord.sanskritName,
                glyph: node.lord.astronomicalGlyph,
                shortLabel: node.lord.shortAbbreviation,
                levelTag: node.level.rawValue,
                depth: depth(of: node.level),
                graha: node.lord,
                rasi: nil,
                startDate: node.startDate,
                endDate: node.endDate,
                formattedDuration: formattedDuration(start: node.startDate, end: node.endDate, yearLengthDays: yearLengthDays),
                ageAtStart: age(of: node.startDate, birthDate: birthDate, yearLengthDays: yearLengthDays),
                ageAtEnd: age(of: node.endDate, birthDate: birthDate, yearLengthDays: yearLengthDays),
                isActive: targetDate >= node.startDate && targetDate < node.endDate,
                children: node.children.isEmpty
                    ? nil
                    : rows(from: node.children, birthDate: birthDate, targetDate: targetDate, yearLengthDays: yearLengthDays)
            )
        }
    }

    static func rows(from periods: [DashaPeriod], birthDate: Date, targetDate: Date, yearLengthDays: Double) -> [DashaRowItem] {
        periods.map { period in
            DashaRowItem(
                id: period.id,
                name: period.name,
                glyph: period.rasi.map(glyph(for:)) ?? period.graha?.astronomicalGlyph ?? "",
                shortLabel: period.rasi.map(glyph(for:)) ?? period.name,
                levelTag: levelTag(forLevel: period.level),
                depth: max(period.level - 1, 0),
                graha: period.graha,
                rasi: period.rasi,
                startDate: period.startDate,
                endDate: period.endDate,
                formattedDuration: formattedDuration(start: period.startDate, end: period.endDate, yearLengthDays: yearLengthDays),
                ageAtStart: age(of: period.startDate, birthDate: birthDate, yearLengthDays: yearLengthDays),
                ageAtEnd: age(of: period.endDate, birthDate: birthDate, yearLengthDays: yearLengthDays),
                isActive: period.contains(targetDate),
                children: period.children.isEmpty
                    ? nil
                    : rows(from: period.children, birthDate: birthDate, targetDate: targetDate, yearLengthDays: yearLengthDays)
            )
        }
    }

    /// The chain of rows containing `date`, outermost first.
    static func activePath(in rows: [DashaRowItem], at date: Date) -> [DashaRowItem] {
        var path: [DashaRowItem] = []
        var candidates = rows
        while let match = candidates.first(where: { $0.contains(date) }) {
            path.append(match)
            candidates = match.children ?? []
        }
        return path
    }

    /// Depth-first search for a row by identifier.
    static func row(withID id: UUID, in rows: [DashaRowItem]) -> DashaRowItem? {
        for row in rows {
            if row.id == id { return row }
            if let children = row.children, let found = row(withID: id, in: children) {
                return found
            }
        }
        return nil
    }

    static func levelTag(forLevel level: Int) -> String {
        switch level {
        case 1: DashaLevel.mahadasha.rawValue
        case 2: DashaLevel.antardasha.rawValue
        case 3: DashaLevel.pratyantardasha.rawValue
        case 4: DashaLevel.sookshma.rawValue
        case 5: DashaLevel.prana.rawValue
        default: "L\(level)"
        }
    }

    static func glyph(for rasi: Rasi) -> String {
        rasiGlyphs[(rasi.rawValue - 1) % rasiGlyphs.count]
    }

    /// Age in dasha years at `date`, negative before birth.
    static func age(of date: Date, birthDate: Date, yearLengthDays: Double) -> Double {
        guard yearLengthDays > 0 else { return 0 }
        return date.timeIntervalSince(birthDate) / (yearLengthDays * 86_400)
    }

    private static func formattedDuration(start: Date, end: Date, yearLengthDays: Double) -> String {
        VimshottariDashaCalculator.formattedDuration(days: end.timeIntervalSince(start) / 86_400, yearLengthDays: yearLengthDays)
    }

    private static func depth(of level: DashaLevel) -> Int {
        switch level {
        case .mahadasha: 0
        case .antardasha: 1
        case .pratyantardasha: 2
        case .sookshma: 3
        case .prana: 4
        }
    }
}

// MARK: - Continuum strip layout

/// Horizontal placement of one mahadasha block, in points.
struct DashaContinuumBlock: Identifiable, Sendable {
    var id: UUID { row.id }
    let row: DashaRowItem
    let x: Double
    let width: Double
}

/// Lays out mahadasha blocks with widths proportional to their durations,
/// never narrower than `minimumWidth`, so the strip may exceed the available
/// width and scroll. Pure geometry, kept out of the view for testing.
struct DashaContinuumLayout: Sendable {
    let blocks: [DashaContinuumBlock]
    let totalWidth: Double

    init(rows: [DashaRowItem], availableWidth: Double, minimumWidth: Double, spacing: Double) {
        let spanDays = rows.reduce(0.0) { $0 + max($1.durationDays, 0) }
        let gaps = spacing * Double(max(rows.count - 1, 0))
        let usableWidth = max(availableWidth - gaps, 0)
        var placed: [DashaContinuumBlock] = []
        var cursor = 0.0
        for row in rows {
            let proportional = spanDays > 0 ? usableWidth * max(row.durationDays, 0) / spanDays : 0
            let width = max(proportional, minimumWidth)
            placed.append(DashaContinuumBlock(row: row, x: cursor, width: width))
            cursor += width + spacing
        }
        blocks = placed
        totalWidth = placed.isEmpty ? 0 : max(cursor - spacing, 0)
    }

    /// Horizontal position of `date` inside the block that contains it, or nil when none does.
    func markerX(for date: Date) -> Double? {
        guard let block = blocks.first(where: { $0.row.contains(date) }) else { return nil }
        let span = block.row.endDate.timeIntervalSince(block.row.startDate)
        guard span > 0 else { return block.x }
        let fraction = date.timeIntervalSince(block.row.startDate) / span
        return block.x + block.width * min(max(fraction, 0), 1)
    }
}
