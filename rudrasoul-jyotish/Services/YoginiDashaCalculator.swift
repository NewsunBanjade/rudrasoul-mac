import Foundation

/// Calculates the Yogini dasha from the Moon's sidereal longitude.
///
/// The eight Yoginis run in a fixed order with durations equal to their ordinal
/// (Mangala 1y … Sankata 8y), a cycle of 36 years that repeats through life.
/// The Yogini running at birth is found from the Moon's 27-fold nakshatra:
/// (nakshatra number + 3) mod 8, where a remainder of 0 means Sankata. The
/// balance at birth is the untraversed fraction of the Moon's nakshatra times
/// that Yogini's years, exactly like the Vimshottari balance. Sub-periods start
/// with the parent Yogini and last parent duration × sub-Yogini years / 36.
/// Sources: Brihat Parashara Hora Shastra ch. 46 (Yogini dasha), and the
/// standard formula restated at vedicastro.com/yogini1.aspx.
struct YoginiDashaCalculator: Sendable {
    /// One full round of the eight Yoginis, in years.
    static let cycleYears: Double = 36

    let yearLengthDays: Double

    init(yearLengthDays: Double = VimshottariDashaCalculator.solarYearLengthDays) {
        precondition(yearLengthDays > 0, "A Yogini year length must be positive.")
        self.yearLengthDays = yearLengthDays
    }

    /// Builds the timeline from birth until `totalYears` have elapsed.
    ///
    /// Mahadashas are appended while their start lies before birth + `totalYears`,
    /// so the default of 120 years covers three full cycles plus the balance.
    /// `maximumLevel` 1 gives mahadashas only, 2 adds antardashas, and so on.
    func calculate(
        moonLongitude: Double,
        birthDate: Date,
        maximumLevel: Int = 3,
        totalYears: Double = 120
    ) -> DashaTimeline {
        let nakshatra = Nakshatra(absoluteLongitude: moonLongitude)
        let firstYogini = Self.startingYogini(for: nakshatra)
        let elapsedFraction = Nakshatra.fractionTraversed(absoluteLongitude: moonLongitude)
        let firstDurationDays = Double(firstYogini.years) * yearLengthDays
        let firstStart = birthDate.addingTimeInterval(-elapsedFraction * firstDurationDays * secondsPerDay)
        let horizon = birthDate.addingTimeInterval(totalYears * yearLengthDays * secondsPerDay)

        let sequence = Self.sequence(from: firstYogini)
        var periods: [DashaPeriod] = []
        var start = firstStart
        var index = 0
        // The cap only guards against a runaway horizon; 120 years needs 27 periods.
        while (periods.isEmpty || start < horizon), periods.count < Self.maximumPeriodCount {
            let yogini = sequence[index % sequence.count]
            let durationDays = Double(yogini.years) * yearLengthDays
            periods.append(makePeriod(yogini: yogini, startDate: start, durationDays: durationDays, level: 1, maximumLevel: maximumLevel))
            start = start.addingTimeInterval(durationDays * secondsPerDay)
            index += 1
        }

        let balanceDays = (1 - elapsedFraction) * firstDurationDays
        let balanceText = VimshottariDashaCalculator.formattedDuration(days: balanceDays, yearLengthDays: yearLengthDays)
        return DashaTimeline(
            system: .yogini,
            yearLengthDays: yearLengthDays,
            derivationNote: "Moon in \(nakshatra.name) (\(nakshatra.lord.rawValue)) · starts \(firstYogini.name), balance \(balanceText)",
            periods: periods
        )
    }

    /// The Yogini running at birth: (nakshatra number + 3) mod 8, with 0 meaning Sankata.
    ///
    /// Example: Anuradha is nakshatra 17; (17 + 3) mod 8 = 4, so Bhramari runs at birth.
    static func startingYogini(for nakshatra: Nakshatra) -> Yogini {
        let remainder = (nakshatra.rawValue + 3) % Yogini.allCases.count
        let ordinal = remainder == 0 ? Yogini.allCases.count : remainder
        return Yogini(rawValue: ordinal) ?? .sankata
    }

    /// The eight Yoginis in order, beginning with `start` and wrapping after Sankata.
    static func sequence(from start: Yogini) -> [Yogini] {
        let all = Yogini.allCases
        let offset = start.rawValue - 1
        return (0 ..< all.count).map { all[(offset + $0) % all.count] }
    }

    // MARK: - Private

    private static let maximumPeriodCount = 400

    private func makePeriod(
        yogini: Yogini,
        startDate: Date,
        durationDays: Double,
        level: Int,
        maximumLevel: Int
    ) -> DashaPeriod {
        let endDate = startDate.addingTimeInterval(durationDays * secondsPerDay)
        var children: [DashaPeriod] = []
        if level < maximumLevel {
            var childStart = startDate
            for child in Self.sequence(from: yogini) {
                let childDuration = durationDays * Double(child.years) / Self.cycleYears
                children.append(makePeriod(yogini: child, startDate: childStart, durationDays: childDuration, level: level + 1, maximumLevel: maximumLevel))
                childStart = childStart.addingTimeInterval(childDuration * secondsPerDay)
            }
        }
        return DashaPeriod(
            system: .yogini,
            level: level,
            name: yogini.name,
            graha: yogini.lord,
            rasi: nil,
            startDate: startDate,
            endDate: endDate,
            children: children
        )
    }

    private var secondsPerDay: TimeInterval { 86_400 }
}
