import Foundation

/// Calculates Jaimini's Chara dasha (from the lagna) and the Lagnamsa dasha
/// (the same scheme started from the navamsa sign of the lagna).
///
/// Conventions, each kept in exactly one place below:
///
/// * Direction (Jaimini Sutras 2.1.x, "sama-pada / vishama-pada"): the twelve
///   signs run forward from a starting sign in the group Aries, Taurus, Gemini,
///   Libra, Scorpio, Sagittarius, and backward from one in the group Cancer, Leo,
///   Virgo, Capricorn, Aquarius, Pisces. The sutra tradition calls the forward
///   group sama-pada and the backward group vishama-pada; some modern authors
///   swap the labels, but the direction is the same. Raghava Bhatta's variant
///   instead uses odd (forward) and even (backward) signs; see `usesOddEvenDirection`.
/// * Duration (Jaimini Sutras 2.1.16–19, K. N. Rao, "Predicting through Jaimini's
///   Chara Dasha"): count from the sign to the sign holding its lord in the sign's
///   own direction (the sign itself is 1) and subtract one; a lord in its own
///   sign gives twelve years. Neelakantha's commentary adds one year for an
///   exalted lord and removes one for a debilitated lord; Rao omits this
///   adjustment. See `appliesDignityAdjustment`.
/// * Dual lords (Rao's practical rule): Scorpio has Mars and Ketu, Aquarius has
///   Saturn and Rahu. If one lord sits in the sign itself the other decides; if
///   both do, twelve years; otherwise the lord giving the longer period decides.
/// * Antardashas (Rao): twelve equal parts of the mahadasha, beginning from the
///   sign next to the mahadasha sign in the sign's own direction. Some authors
///   (following Neelakantha) begin from the sign itself; see `antardashasBeginFromNextSign`.
///
/// Only the first round of twelve signs is produced; Rao's second-round rule
/// (twelve minus the first-round years) is not implemented.
struct CharaDashaCalculator: Sendable {
    /// False: sama-pada / vishama-pada groups (Jaimini). True: odd/even signs (Raghava Bhatta).
    static let usesOddEvenDirection = false
    /// True: +1 year for an exalted lord, −1 for a debilitated one (Neelakantha). Rao omits it.
    static let appliesDignityAdjustment = true
    /// True: antardashas begin from the sign after the mahadasha sign (Rao). False: from the sign itself.
    static let antardashasBeginFromNextSign = true

    let yearLengthDays: Double

    init(yearLengthDays: Double = VimshottariDashaCalculator.solarYearLengthDays) {
        precondition(yearLengthDays > 0, "A Chara dasha year length must be positive.")
        self.yearLengthDays = yearLengthDays
    }

    /// Jaimini Chara dasha starting from the lagna sign.
    func calculate(lagnaRasi: Rasi, planets: [PlanetPosition], birthDate: Date, maximumLevel: Int = 2) -> DashaTimeline {
        timeline(system: .chara, startRasi: lagnaRasi, startLabel: "lagna", planets: planets, birthDate: birthDate, maximumLevel: maximumLevel)
    }

    /// Same scheme, but the sequence begins from the Lagnamsa (navamsa sign of the lagna).
    /// Durations still come from the D-1 placements in `planets`.
    func calculateLagnamsa(lagnamsaRasi: Rasi, planets: [PlanetPosition], birthDate: Date, maximumLevel: Int = 2) -> DashaTimeline {
        timeline(system: .lagnamsa, startRasi: lagnamsaRasi, startLabel: "lagnamsa", planets: planets, birthDate: birthDate, maximumLevel: maximumLevel)
    }

    /// Whether the dasha sequence and the lord count run forward (zodiacal) from `rasi`.
    static func countsForward(from rasi: Rasi) -> Bool {
        if usesOddEvenDirection {
            return rasi.isOdd
        }
        // Aries, Taurus, Gemini and Libra, Scorpio, Sagittarius are the first three of each half.
        return (rasi.rawValue - 1) % 6 < 3
    }

    /// The twelve signs in dasha order, starting with `start`.
    static func sequence(from start: Rasi) -> [Rasi] {
        let step = countsForward(from: start) ? 1 : -1
        return (0 ..< 12).map { start.advanced(by: step * $0) }
    }

    /// Duration of the mahadasha of `rasi` in years, 1 … 12.
    static func duration(of rasi: Rasi, planets: [PlanetPosition]) -> Int {
        let lordPositions = lords(of: rasi).compactMap { lord in planets.first { $0.graha == lord } }
        guard let first = lordPositions.first else { return 12 }
        guard lordPositions.count == 2, let second = lordPositions.last else {
            return years(of: rasi, lordPosition: first)
        }
        let inOwnSign = lordPositions.filter { $0.rasi == rasi }
        if inOwnSign.count == 2 {
            return 12
        }
        if inOwnSign.count == 1, let deciding = lordPositions.first(where: { $0.rasi != rasi }) {
            return years(of: rasi, lordPosition: deciding)
        }
        return max(years(of: rasi, lordPosition: first), years(of: rasi, lordPosition: second))
    }

    // MARK: - Private

    /// Scorpio and Aquarius carry a co-lord (Ketu, Rahu) in Jaimini; every other sign has one lord.
    static func lords(of rasi: Rasi) -> [Graha] {
        switch rasi {
        case .scorpio: [.mars, .ketu]
        case .aquarius: [.saturn, .rahu]
        default: [rasi.lord]
        }
    }

    private static func years(of rasi: Rasi, lordPosition: PlanetPosition) -> Int {
        let count = countsForward(from: rasi)
            ? rasi.count(to: lordPosition.rasi)
            : lordPosition.rasi.count(to: rasi)
        var years = count == 1 ? 12 : count - 1
        if appliesDignityAdjustment {
            if lordPosition.dignity == .exalted { years += 1 }
            if lordPosition.dignity == .debilitated { years -= 1 }
        }
        return min(max(years, 1), 12)
    }

    private func timeline(
        system: DashaSystem,
        startRasi: Rasi,
        startLabel: String,
        planets: [PlanetPosition],
        birthDate: Date,
        maximumLevel: Int
    ) -> DashaTimeline {
        var periods: [DashaPeriod] = []
        var start = birthDate
        for rasi in Self.sequence(from: startRasi) {
            let years = Self.duration(of: rasi, planets: planets)
            let durationSeconds = Double(years) * yearLengthDays * secondsPerDay
            periods.append(makePeriod(system: system, rasi: rasi, startDate: start, durationSeconds: durationSeconds, level: 1, maximumLevel: maximumLevel))
            start = start.addingTimeInterval(durationSeconds)
        }
        let direction = Self.countsForward(from: startRasi) ? "forward (sama-pada)" : "backward (vishama-pada)"
        return DashaTimeline(
            system: system,
            yearLengthDays: yearLengthDays,
            derivationNote: "From \(startRasi.sanskritName) \(startLabel) · \(direction)",
            periods: periods
        )
    }

    private func makePeriod(
        system: DashaSystem,
        rasi: Rasi,
        startDate: Date,
        durationSeconds: TimeInterval,
        level: Int,
        maximumLevel: Int
    ) -> DashaPeriod {
        var children: [DashaPeriod] = []
        if level < maximumLevel {
            let step = Self.countsForward(from: rasi) ? 1 : -1
            let firstChild = Self.antardashasBeginFromNextSign ? rasi.advanced(by: step) : rasi
            let childDuration = durationSeconds / 12
            var childStart = startDate
            for offset in 0 ..< 12 {
                let childRasi = firstChild.advanced(by: step * offset)
                children.append(makePeriod(system: system, rasi: childRasi, startDate: childStart, durationSeconds: childDuration, level: level + 1, maximumLevel: maximumLevel))
                childStart = childStart.addingTimeInterval(childDuration)
            }
        }
        return DashaPeriod(
            system: system,
            level: level,
            name: rasi.sanskritName,
            graha: nil,
            rasi: rasi,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(durationSeconds),
            children: children
        )
    }

    private var secondsPerDay: TimeInterval { 86_400 }
}
