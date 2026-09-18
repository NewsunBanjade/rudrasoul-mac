import Foundation

/// Decides when Gulika and Maandi rise, and builds their stored positions once the
/// caller has the sidereal ascendant at that instant.
///
/// The classical rule (Brihat Parashara Hora Shastra, Ch. 3 "Upagrahas", and
/// Phaladeepika, Ch. 25): the day (sunrise to sunset) or the night (sunset to the
/// next sunrise) of the birth is divided into eight equal parts. The first seven
/// parts belong to the weekday lords in weekday order; the eighth is lordless.
/// Saturn's part is Gulika's part. For a night birth the sequence starts from the
/// lord of the fifth weekday counted from the birth weekday.
///
/// This calculator is pure: it never touches the ephemeris. Sunrise, sunset, and the
/// ascendant at the rising instant are supplied by the service layer.
enum UpagrahaCalculator {
    /// The Jyotish day surrounding a birth. All dates are UTC instants.
    struct DayContext: Sendable {
        let birth: Date
        /// The last sunrise at or before the birth (start of the Jyotish day).
        let sunrise: Date
        /// The sunset following `sunrise`.
        let sunset: Date
        /// The sunrise following `sunset`.
        let nextSunrise: Date
        /// Weekday of `sunrise`.
        let vara: Vara
    }

    /// Where inside Saturn's eighth-part a point is taken to rise.
    ///
    /// Traditions differ. Phaladeepika 25 takes Gulika at the start of Saturn's part.
    /// The ghati table of BPHS 3.68–69 (Gulika at 26, 22, 18, 14, 10, 6, 2 ghatis
    /// after sunrise for Sunday through Saturday) places Gulika at the end of
    /// Saturn's part, and Maandi is commonly taken at the middle. The convention is a
    /// parameter so the app can expose it as a setting later.
    enum PartConvention: Sendable {
        case start
        case middle
        case end
    }

    /// Number of equal parts the day or the night is divided into.
    static let partCount = 8

    /// Night births start the lord sequence from the fifth weekday counted from the
    /// birth weekday, so the offset from the vara is four steps.
    private static let nightSequenceOffset = 4

    /// A birth is a day birth when it falls in [sunrise, sunset).
    static func isDayBirth(_ context: DayContext) -> Bool {
        context.birth >= context.sunrise && context.birth < context.sunset
    }

    /// The lords of the eight parts of the day or night of the birth, in order.
    ///
    /// Day: parts 1–7 are ruled by the weekday lords in weekday order starting from
    /// the vara lord (Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, cycling).
    /// Night: the sequence starts from the lord of the fifth weekday counted from the
    /// vara (Sunday night starts with Jupiter, Thursday's lord). The eighth part has
    /// no lord in either case (BPHS Ch. 3; Phaladeepika Ch. 25).
    static func partLords(for context: DayContext) -> [Graha?] {
        let sequence = Vara.lordSequence
        let offset = isDayBirth(context) ? 0 : nightSequenceOffset
        let start = (context.vara.rawValue + offset) % sequence.count
        var lords: [Graha?] = (0..<(partCount - 1)).map { step in
            sequence[(start + step) % sequence.count]
        }
        lords.append(nil)
        return lords
    }

    /// UTC instants at which Gulika and Maandi rise.
    ///
    /// Both points rise inside Saturn's part of the day or night of the birth.
    /// By default Gulika rises at the start of that part and Maandi at its middle.
    static func risingTimes(
        context: DayContext,
        gulika: PartConvention = .start,
        maandi: PartConvention = .middle
    ) -> [UpagrahaKind: Date] {
        let lords = partLords(for: context)
        guard let saturnIndex = lords.firstIndex(where: { $0 == Graha.saturn }) else {
            return [:]
        }
        let span = periodSpan(for: context)
        let partLength = span.end.timeIntervalSince(span.start) / Double(partCount)
        let partStart = span.start.addingTimeInterval(Double(saturnIndex) * partLength)
        return [
            .gulika: instant(partStart: partStart, partLength: partLength, convention: gulika),
            .maandi: instant(partStart: partStart, partLength: partLength, convention: maandi)
        ]
    }

    /// Builds the stored position from the sidereal ascendant longitude at the rising instant.
    ///
    /// The longitude of an upagraha is the longitude of the ascendant at the moment it
    /// rises (Phaladeepika 25.3). Sign, in-sign degrees, DMS text, nakshatra, and pada
    /// are all derived through the shared longitude helpers.
    static func position(
        kind: UpagrahaKind,
        ascendantLongitude: Double,
        risingDate: Date,
        bhava: Int
    ) -> UpagrahaPosition {
        let longitude = ascendantLongitude.normalizedLongitude360
        return UpagrahaPosition(
            kind: kind,
            longitude: longitude,
            rasi: Rasi(absoluteLongitude: longitude),
            longitudeInRasi: longitude.longitudeWithinRasi,
            formattedDMS: longitude.dmsStringInRasi,
            nakshatra: Nakshatra(absoluteLongitude: longitude),
            pada: Nakshatra.pada(absoluteLongitude: longitude),
            bhava: bhava,
            risingDate: risingDate
        )
    }

    // MARK: - Private

    /// The period that is divided into eight parts: the day for a day birth, the
    /// night for a night birth.
    private static func periodSpan(for context: DayContext) -> (start: Date, end: Date) {
        if isDayBirth(context) {
            return (context.sunrise, context.sunset)
        }
        return (context.sunset, context.nextSunrise)
    }

    private static func instant(
        partStart: Date,
        partLength: TimeInterval,
        convention: PartConvention
    ) -> Date {
        switch convention {
        case .start:
            partStart
        case .middle:
            partStart.addingTimeInterval(partLength / 2)
        case .end:
            partStart.addingTimeInterval(partLength)
        }
    }
}
