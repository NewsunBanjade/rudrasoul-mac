import Foundation

/// Kala bala, the temporal strength: Nathonnatha, Paksha, Tribhaga, Abda, Masa, Vara, Hora
/// and Ayana balas (BPHS 27.12–24).
extension ShadbalaCalculator {
    /// Lords of the year, month, weekday and hora of a birth.
    struct KalaContext: Sendable {
        let yearLord: Graha?
        let monthLord: Graha?
        let varaLord: Graha?
        let horaLord: Graha?

        init(input: ShadbalaInput) {
            let ahargana = ShadbalaCalculator.ahargana(at: input.day?.sunrise ?? input.birth)
            yearLord = ShadbalaCalculator.yearLord(ahargana: ahargana)
            monthLord = ShadbalaCalculator.monthLord(ahargana: ahargana)
            varaLord = input.day?.vara.lord
            horaLord = input.day.flatMap { ShadbalaCalculator.horaLord(day: $0, birth: input.birth) }
        }
    }

    // MARK: - Ahargana, year and month lords

    /// Kali epoch, JD 588 465.5 (18 February 3102 BCE, midnight). The Ahargana is the count
    /// of civil days elapsed since then, taken at the sunrise of the birth day.
    static let kaliEpochJulianDay = 588_465.5

    static func ahargana(at date: Date) -> Int {
        let julianDay = 2_440_587.5 + date.timeIntervalSince1970 / 86_400
        return Int((julianDay - kaliEpochJulianDay).rounded(.down))
    }

    /// Lord of the year (BPHS 27.18): divide the Ahargana by 360, multiply the quotient by 3,
    /// add 1, divide by 7; the remainder counted from Sunday names the lord.
    static func yearLord(ahargana: Int) -> Graha {
        weekdayLord(remainder: (ahargana / 360 * 3 + 1) % 7)
    }

    /// Lord of the month (BPHS 27.19): divide the Ahargana by 30, multiply the quotient by 2,
    /// add 1, divide by 7; the remainder counted from Sunday names the lord.
    static func monthLord(ahargana: Int) -> Graha {
        weekdayLord(remainder: (ahargana / 30 * 2 + 1) % 7)
    }

    /// Remainder 1 is Sunday, 2 Monday, … 6 Friday and 0 Saturday.
    private static func weekdayLord(remainder: Int) -> Graha {
        let index = ((remainder + 6) % 7 + 7) % 7
        return Vara.lordSequence[index]
    }

    /// A birth between sunrise and sunset is a day birth; the instant is passed explicitly so
    /// that the hora and tribhaga functions can be evaluated for any moment of the day.
    static func isDayBirth(_ birth: Date, day: UpagrahaCalculator.DayContext) -> Bool {
        birth >= day.sunrise && birth < day.sunset
    }

    // MARK: - Hora lord

    /// The Chaldean order of the hora lords, starting from the Sun.
    static let horaSequence: [Graha] = [.sun, .venus, .mercury, .moon, .saturn, .jupiter, .mars]

    /// Lord of the hora of birth (BPHS 27.20): the first hora after sunrise belongs to the
    /// weekday lord; the day (sunrise to sunset) and the night are each divided into twelve
    /// horas whose lords follow the Chaldean order.
    static func horaLord(day: UpagrahaCalculator.DayContext, birth: Date) -> Graha? {
        guard let start = horaSequence.firstIndex(of: day.vara.lord) else { return nil }
        let index: Int
        if isDayBirth(birth, day: day) {
            let length = day.sunset.timeIntervalSince(day.sunrise) / 12
            guard length > 0 else { return nil }
            index = min(max(Int(birth.timeIntervalSince(day.sunrise) / length), 0), 11)
        } else {
            let length = day.nextSunrise.timeIntervalSince(day.sunset) / 12
            guard length > 0 else { return nil }
            index = 12 + min(max(Int(birth.timeIntervalSince(day.sunset) / length), 0), 11)
        }
        return horaSequence[(start + index) % horaSequence.count]
    }

    // MARK: - Nathonnatha bala

    /// Nathonnatha bala (BPHS 27.12–13): at local midnight the Moon, Mars and Saturn hold 60
    /// virupas and the Sun, Jupiter and Venus none; at local noon the reverse; between, the
    /// values change linearly with the time from midnight. Mercury always has 60. Local time
    /// is mean time for the birth longitude (4 minutes per degree).
    static func nathonnathaBala(of graha: Graha, birth: Date, geographicLongitude: Double) -> Double {
        if graha == .mercury { return 60 }
        let utcSeconds = birth.timeIntervalSince1970.truncatingRemainder(dividingBy: 86_400)
        let shifted = (utcSeconds + geographicLongitude * 240).truncatingRemainder(dividingBy: 86_400)
        let localSeconds = shifted < 0 ? shifted + 86_400 : shifted
        let hoursFromMidnight = min(localSeconds, 86_400 - localSeconds) / 3_600
        switch graha {
        case .moon, .mars, .saturn: return (12 - hoursFromMidnight) * 5
        case .sun, .jupiter, .venus: return hoursFromMidnight * 5
        default: return 0
        }
    }

    // MARK: - Paksha bala

    /// Paksha bala (BPHS 27.14–15): with the Moon's elongation from the Sun reduced to
    /// 0 … 180°, benefics get elongation ÷ 3 and malefics 60 − elongation ÷ 3. The Moon's
    /// value is doubled.
    static func pakshaBala(of planet: PlanetPosition, planets: [PlanetPosition]) -> Double {
        guard let sun = planets.first(where: { $0.graha == .sun }),
              let moon = planets.first(where: { $0.graha == .moon })
        else {
            return 0
        }
        var elongation = (moon.absoluteLongitude - sun.absoluteLongitude).normalizedLongitude360
        if elongation > 180 { elongation = 360 - elongation }
        let bala = isBenefic(planet, planets: planets) ? elongation / 3 : (180 - elongation) / 3
        return planet.graha == .moon ? bala * 2 : bala
    }

    /// Natural benefics for Paksha, Drik and Bhava Drishti bala: Jupiter, Venus, the waxing
    /// Moon, and Mercury unless it shares its sign with a natural malefic (BPHS Ch. 3, vv. 24–25).
    static func isBenefic(_ planet: PlanetPosition, planets: [PlanetPosition]) -> Bool {
        switch planet.graha {
        case .jupiter, .venus:
            return true
        case .moon:
            guard let sun = planets.first(where: { $0.graha == .sun }) else { return true }
            return (planet.absoluteLongitude - sun.absoluteLongitude).normalizedLongitude360 <= 180
        case .mercury:
            let malefics: [Graha] = [.sun, .mars, .saturn, .rahu, .ketu]
            return !planets.contains { malefics.contains($0.graha) && $0.rasi == planet.rasi }
        default:
            return false
        }
    }

    // MARK: - Tribhaga bala

    /// Tribhaga bala (BPHS 27.16): the day is split into three parts ruled by Mercury, the Sun
    /// and Saturn, the night into three ruled by the Moon, Venus and Mars; the ruler of the
    /// part of birth gets 60. Jupiter always gets 60. Without sunrise data only Jupiter scores.
    static func tribhagaBala(of graha: Graha, day: UpagrahaCalculator.DayContext?, birth: Date) -> Double {
        if graha == .jupiter { return 60 }
        guard let day else { return 0 }
        let lords: [Graha]
        let fraction: Double
        if isDayBirth(birth, day: day) {
            lords = [.mercury, .sun, .saturn]
            fraction = birth.timeIntervalSince(day.sunrise) / day.sunset.timeIntervalSince(day.sunrise)
        } else {
            lords = [.moon, .venus, .mars]
            fraction = birth.timeIntervalSince(day.sunset) / day.nextSunrise.timeIntervalSince(day.sunset)
        }
        guard fraction.isFinite else { return 0 }
        let part = min(max(Int(fraction * 3), 0), 2)
        return lords[part] == graha ? 60 : 0
    }

    // MARK: - Ayana bala

    /// Ayana bala (BPHS 27.22–23; Raman): (24 ± declination) × 1.25 virupas. The declination
    /// adds for the Sun, Mars, Jupiter and Venus when north, for the Moon and Saturn when
    /// south, and always for Mercury. The Sun's value is doubled.
    static func ayanaBala(of planet: PlanetPosition, ayanamsaDegrees: Double, birth: Date) -> Double {
        let declination = declinationDegrees(
            siderealLongitude: planet.absoluteLongitude, ayanamsaDegrees: ayanamsaDegrees, birth: birth
        )
        let signed: Double
        switch planet.graha {
        case .sun, .mars, .jupiter, .venus: signed = declination
        case .moon, .saturn: signed = -declination
        case .mercury: signed = abs(declination)
        default: return 0
        }
        let bala = (24 + signed) * 1.25
        return planet.graha == .sun ? bala * 2 : bala
    }

    /// Declination of a point on the ecliptic (ecliptic latitude ignored) from its sidereal
    /// longitude, using the mean obliquity of date.
    static func declinationDegrees(siderealLongitude: Double, ayanamsaDegrees: Double, birth: Date) -> Double {
        let centuries = julianCenturiesSinceJ2000(birth)
        let obliquity = (23.439291 - 0.0130042 * centuries) * Double.pi / 180
        let tropical = (siderealLongitude + ayanamsaDegrees).normalizedLongitude360 * Double.pi / 180
        return asin(sin(obliquity) * sin(tropical)) * 180 / Double.pi
    }
}
