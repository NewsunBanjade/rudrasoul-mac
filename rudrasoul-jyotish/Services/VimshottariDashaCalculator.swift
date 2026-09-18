import Foundation

/// Calculates the Vimshottari dasha sequence from the Moon's sidereal longitude.
///
/// The first mahadasha is the lord of the Moon's nakshatra. Its balance at birth
/// is the untraversed part of that nakshatra; each child period begins with its
/// parent lord and follows the fixed Vimshottari order. This is the standard
/// 120-year scheme described in Brihat Parashara Hora Shastra, chapter 46.
struct VimshottariDashaCalculator: Sendable {
    struct Result: Sendable {
        let nodes: [DashaNode]
        let currentDashaVector: String
    }

    /// The solar-year convention selected by the application settings.
    static let solarYearLengthDays = 365.2422

    private static let lords: [Graha] = [
        .ketu, .venus, .sun, .moon, .mars, .rahu, .jupiter, .saturn, .mercury,
    ]

    let yearLengthDays: Double

    init(yearLengthDays: Double = Self.solarYearLengthDays) {
        precondition(yearLengthDays > 0, "A Vimshottari year length must be positive.")
        self.yearLengthDays = yearLengthDays
    }

    func calculate(
        moonLongitude: Double,
        birthDate: Date,
        referenceDate: Date = Date(),
        maximumLevel: DashaLevel = .pratyantardasha
    ) -> Result {
        let firstLord = Self.lords[nakshatraIndex(for: moonLongitude) % Self.lords.count]
        let elapsedFraction = fractionTraversedInNakshatra(for: moonLongitude)
        let firstDurationDays = durationDays(parentDurationDays: 120 * yearLengthDays, lord: firstLord)
        let firstStart = birthDate.addingTimeInterval(-elapsedFraction * firstDurationDays * secondsPerDay)

        var nodes: [DashaNode] = []
        var start = firstStart
        for lord in lordsStarting(with: firstLord) {
            let duration = durationDays(parentDurationDays: 120 * yearLengthDays, lord: lord)
            nodes.append(
                makeNode(
                    lord: lord,
                    startDate: start,
                    periodDurationDays: duration,
                    level: .mahadasha,
                    maximumLevel: maximumLevel,
                    birthDate: birthDate,
                    referenceDate: referenceDate
                )
            )
            start = start.addingTimeInterval(duration * secondsPerDay)
        }

        return Result(nodes: nodes, currentDashaVector: activeVector(in: nodes, at: referenceDate).joined(separator: " › "))
    }

    /// The direct sub-periods of `node`, one level deeper than the node itself.
    ///
    /// Uses the same proportional rule as the stored tree: each child lasts the
    /// parent duration × the child lord's Vimshottari years / 120, the first child
    /// is the parent lord, and the fixed order follows (BPHS ch. 46). Sookshma and
    /// prana periods are produced on demand this way instead of being persisted.
    /// A prana node has no deeper level, so it returns an empty list.
    func subPeriods(of node: DashaNode, birthDate: Date, referenceDate: Date = Date()) -> [DashaNode] {
        guard node.level != .prana else { return [] }
        let childLevel = nextLevel(after: node.level)
        let parentDurationDays = node.endDate.timeIntervalSince(node.startDate) / secondsPerDay
        var childStart = node.startDate
        return lordsStarting(with: node.lord).map { childLord in
            let childDuration = durationDays(parentDurationDays: parentDurationDays, lord: childLord)
            defer { childStart = childStart.addingTimeInterval(childDuration * secondsPerDay) }
            return makeNode(
                lord: childLord,
                startDate: childStart,
                periodDurationDays: childDuration,
                level: childLevel,
                maximumLevel: childLevel,
                birthDate: birthDate,
                referenceDate: referenceDate
            )
        }
    }

    /// The chain of stored nodes containing `date`, outermost first.
    ///
    /// Only the children carried by the tree are followed; deeper levels come
    /// from `subPeriods(of:birthDate:referenceDate:)`.
    static func activePath(in nodes: [DashaNode], at date: Date) -> [DashaNode] {
        var path: [DashaNode] = []
        var candidates = nodes
        while let match = candidates.first(where: { date >= $0.startDate && date < $0.endDate }) {
            path.append(match)
            candidates = match.children
        }
        return path
    }

    /// Formats a span of days as compact years, months, and days, e.g. "6y 4m 12d".
    ///
    /// A month is one twelfth of `yearLengthDays`. Zero units are omitted except
    /// that at least one unit is always shown.
    static func formattedDuration(days: Double, yearLengthDays: Double) -> String {
        guard yearLengthDays > 0, days.isFinite else { return "0d" }
        let monthLengthDays = yearLengthDays / 12
        // The epsilon keeps an exact multiple of a year from reading as "Ny 11m 30d".
        let tolerance = 1e-6
        var remaining = max(days, 0)
        let years = Int(remaining / yearLengthDays + tolerance)
        remaining -= Double(years) * yearLengthDays
        let months = Int(max(remaining, 0) / monthLengthDays + tolerance)
        remaining -= Double(months) * monthLengthDays
        let wholeDays = max(Int(remaining.rounded()), 0)

        var parts: [String] = []
        if years > 0 { parts.append("\(years)y") }
        if months > 0 { parts.append("\(months)m") }
        if wholeDays > 0 || parts.isEmpty { parts.append("\(wholeDays)d") }
        return parts.joined(separator: " ")
    }

    private func makeNode(
        lord: Graha,
        startDate: Date,
        periodDurationDays: Double,
        level: DashaLevel,
        maximumLevel: DashaLevel,
        birthDate: Date,
        referenceDate: Date
    ) -> DashaNode {
        let endDate = startDate.addingTimeInterval(periodDurationDays * secondsPerDay)
        let children: [DashaNode]
        if depth(of: level) < depth(of: maximumLevel) {
            var childStart = startDate
            children = lordsStarting(with: lord).map { childLord in
                let childDuration = durationDays(parentDurationDays: periodDurationDays, lord: childLord)
                defer { childStart = childStart.addingTimeInterval(childDuration * secondsPerDay) }
                return makeNode(
                    lord: childLord,
                    startDate: childStart,
                    periodDurationDays: childDuration,
                    level: nextLevel(after: level),
                    maximumLevel: maximumLevel,
                    birthDate: birthDate,
                    referenceDate: referenceDate
                )
            }
        } else {
            children = []
        }

        return DashaNode(
            level: level,
            lord: lord,
            startDate: startDate,
            endDate: endDate,
            formattedDuration: formattedDuration(days: periodDurationDays),
            ageAtStart: startDate.timeIntervalSince(birthDate) / (yearLengthDays * secondsPerDay),
            statusText: contains(referenceDate, start: startDate, end: endDate) ? "Focused" : "",
            role: level.rawValue,
            children: children
        )
    }

    private func activeVector(in nodes: [DashaNode], at date: Date) -> [String] {
        guard let node = nodes.first(where: { contains(date, start: $0.startDate, end: $0.endDate) }) else {
            return []
        }
        return [node.lord.rawValue] + activeVector(in: node.children, at: date)
    }

    private func nakshatraIndex(for longitude: Double) -> Int {
        Int(normalized(longitude) / (360.0 / 27.0))
    }

    private func fractionTraversedInNakshatra(for longitude: Double) -> Double {
        let nakshatraLength = 360.0 / 27.0
        return normalized(longitude).truncatingRemainder(dividingBy: nakshatraLength) / nakshatraLength
    }

    private func lordsStarting(with lord: Graha) -> [Graha] {
        guard let index = Self.lords.firstIndex(of: lord) else { return Self.lords }
        return (0 ..< Self.lords.count).map { Self.lords[(index + $0) % Self.lords.count] }
    }

    private func durationDays(parentDurationDays: Double, lord: Graha) -> Double {
        parentDurationDays * Double(lord.vimshottariYears) / 120
    }

    private func depth(of level: DashaLevel) -> Int {
        switch level {
        case .mahadasha: 1
        case .antardasha: 2
        case .pratyantardasha: 3
        case .sookshma: 4
        case .prana: 5
        }
    }

    private func nextLevel(after level: DashaLevel) -> DashaLevel {
        switch level {
        case .mahadasha: .antardasha
        case .antardasha: .pratyantardasha
        case .pratyantardasha: .sookshma
        case .sookshma: .prana
        case .prana: .prana
        }
    }

    private func formattedDuration(days: Double) -> String {
        Self.formattedDuration(days: days, yearLengthDays: yearLengthDays)
    }

    private func normalized(_ longitude: Double) -> Double {
        let remainder = longitude.truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }

    private func contains(_ date: Date, start: Date, end: Date) -> Bool {
        date >= start && date < end
    }

    private var secondsPerDay: TimeInterval { 86_400 }
}
