import EphemerisKit
import Foundation

/// Ephemeris-backed helpers for the day of birth: sunrise, sunset, the vara,
/// the ascendant at an arbitrary instant, and formatting of derived values.
extension ChartCalculationService {
    /// The Jyotish day of a birth: the last sunrise at or before the birth, the
    /// following sunset, and the next sunrise. Nil when the Sun neither rises
    /// nor sets at that latitude around the birth (polar regions).
    func dayContext(
        birth: Date,
        coordinates: GeographicCoordinates,
        utcOffsetSeconds: TimeInterval
    ) async -> UpagrahaCalculator.DayContext? {
        let birthJD = JulianDay(date: birth)
        do {
            var sunrise = try await ephemeris.riseSetTime(
                of: .sun, event: .rise, after: JulianDay(birthJD.value - 1), coordinates: coordinates, source: .swiss
            )
            if sunrise.value > birthJD.value {
                // No sunrise inside the last 24 hours (drift at the day boundary): look one day further back.
                sunrise = try await ephemeris.riseSetTime(
                    of: .sun, event: .rise, after: JulianDay(birthJD.value - 2), coordinates: coordinates, source: .swiss
                )
            }
            let sunset = try await ephemeris.riseSetTime(
                of: .sun, event: .set, after: sunrise, coordinates: coordinates, source: .swiss
            )
            let nextSunrise = try await ephemeris.riseSetTime(
                of: .sun, event: .rise, after: sunset, coordinates: coordinates, source: .swiss
            )
            return UpagrahaCalculator.DayContext(
                birth: birth,
                sunrise: sunrise.date,
                sunset: sunset.date,
                nextSunrise: nextSunrise.date,
                vara: vara(ofSunrise: sunrise.date, utcOffsetSeconds: utcOffsetSeconds)
            )
        } catch {
            return nil
        }
    }

    /// The weekday of the local civil date on which the sunrise falls.
    func vara(ofSunrise sunrise: Date, utcOffsetSeconds: TimeInterval) -> Vara {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: Int(utcOffsetSeconds)) ?? TimeZone(secondsFromGMT: 0) ?? .current
        let weekday = calendar.component(.weekday, from: sunrise) // 1 = Sunday
        return Vara(rawValue: weekday - 1) ?? .sunday
    }

    /// Sidereal ascendant longitude at an instant.
    func ascendantLongitude(
        at date: Date,
        coordinates: GeographicCoordinates,
        houseSystem: HouseSystem,
        ayanamsa: Ayanamsa?
    ) async throws -> Double {
        let houses = try await ephemeris.houses(
            at: JulianDay(date: date), coordinates: coordinates, system: houseSystem, ayanamsa: ayanamsa
        )
        return houses.ascendant.normalizedLongitude360
    }

    /// Sidereal Sun longitude at an instant.
    func sunLongitude(at date: Date, ayanamsa: Ayanamsa?) async throws -> Double {
        let position = try await ephemeris.position(
            of: .sun, at: JulianDay(date: date), settings: EphemerisSettings(source: .swiss, ayanamsa: ayanamsa)
        )
        return position.longitude.normalizedLongitude360
    }

    /// Gulika and Maandi as D-1 positions, or an empty array when the day context is missing.
    func upagrahaPositions(
        context: UpagrahaCalculator.DayContext?,
        coordinates: GeographicCoordinates,
        houseSystem: HouseSystem,
        ayanamsa: Ayanamsa?,
        cusps: [Double]
    ) async -> [UpagrahaPosition] {
        guard let context else { return [] }
        let risingTimes = UpagrahaCalculator.risingTimes(context: context)
        var positions: [UpagrahaPosition] = []
        for kind in UpagrahaKind.allCases {
            guard let risingDate = risingTimes[kind],
                  let longitude = try? await ascendantLongitude(
                      at: risingDate, coordinates: coordinates, houseSystem: houseSystem, ayanamsa: ayanamsa
                  )
            else { continue }
            positions.append(
                UpagrahaCalculator.position(
                    kind: kind,
                    ascendantLongitude: longitude,
                    risingDate: risingDate,
                    bhava: houseNumber(for: longitude, cusps: cusps)
                )
            )
        }
        return positions
    }

    /// The whole-circle house (1 ... 12) containing a longitude, given the twelve cusps.
    func houseNumber(for longitude: Double, cusps: [Double]) -> Int {
        guard cusps.count == 12 else { return 1 }
        let normalized = longitude.normalizedLongitude360
        for index in 0 ..< 12 {
            let start = cusps[index].normalizedLongitude360
            let end = cusps[(index + 1) % 12].normalizedLongitude360
            let span = (end - start + 360).truncatingRemainder(dividingBy: 360)
            let distance = (normalized - start + 360).truncatingRemainder(dividingBy: 360)
            if distance < span { return index + 1 }
        }
        return 12
    }

    /// Formats a full-circle angle as `DD° MM' SS"`, used for the ayanamsa value.
    func dmsString(degrees: Double) -> String {
        let totalSeconds = Int((abs(degrees) * 3_600).rounded())
        let sign = degrees < 0 ? "-" : ""
        return String(
            format: "%@%02d° %02d' %02d\"", sign, totalSeconds / 3_600, (totalSeconds / 60) % 60, totalSeconds % 60
        )
    }

    /// Formats a UTC instant as local wall-clock time for the chart's offset.
    func localTimeString(_ date: Date, utcOffsetSeconds: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: Int(utcOffsetSeconds)) ?? TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
