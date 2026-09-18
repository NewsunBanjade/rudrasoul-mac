import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct UpagrahaCalculatorTests {
    // 2024-01-07 is a Sunday and 2024-01-06 a Saturday. The vara is passed
    // explicitly, so the calendar date only keeps the fixtures readable.

    @Test func sundayDayBirthPlacesSaturnInTheSeventhPart() {
        let context = dayContext(vara: .sunday, birthHour: 12, birthMinute: 0)

        let lords = UpagrahaCalculator.partLords(for: context)
        #expect(lords.count == 8)
        #expect(lords.prefix(7).compactMap { $0 } == [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn])
        #expect(lords[7] == nil)

        // Twelve hours split into eight parts of 90 minutes; Saturn's part starts at 15:00.
        let times = UpagrahaCalculator.risingTimes(context: context)
        #expect(times[.gulika] == date(day: 7, hour: 15, minute: 0))
        #expect(times[.maandi] == date(day: 7, hour: 15, minute: 45))
    }

    @Test func sundayNightBirthStartsWithJupiter() {
        let context = dayContext(vara: .sunday, birthHour: 22, birthMinute: 0)

        let lords = UpagrahaCalculator.partLords(for: context)
        #expect(lords.prefix(7).compactMap { $0 } == [.jupiter, .venus, .saturn, .sun, .moon, .mars, .mercury])
        #expect(lords[7] == nil)

        // Saturn rules the third part of the night: 18:00 + 2 × 90 min.
        let times = UpagrahaCalculator.risingTimes(context: context)
        #expect(times[.gulika] == date(day: 7, hour: 21, minute: 0))
        #expect(times[.maandi] == date(day: 7, hour: 21, minute: 45))
    }

    @Test func saturdayDayBirthPutsGulikaAtSunrise() {
        let context = dayContext(vara: .saturday, birthHour: 9, birthMinute: 0, day: 6)

        let lords = UpagrahaCalculator.partLords(for: context)
        #expect(lords[0] == Graha.saturn)

        let times = UpagrahaCalculator.risingTimes(context: context)
        #expect(times[.gulika] == context.sunrise)
        #expect(times[.maandi] == date(day: 6, hour: 6, minute: 45))
    }

    @Test func partConventionMovesTheRisingInstantInsideSaturnsPart() {
        let context = dayContext(vara: .sunday, birthHour: 12, birthMinute: 0)

        let times = UpagrahaCalculator.risingTimes(context: context, gulika: .end, maandi: .start)
        #expect(times[.gulika] == date(day: 7, hour: 16, minute: 30))
        #expect(times[.maandi] == date(day: 7, hour: 15, minute: 0))
    }

    @Test func positionDerivesSignNakshatraAndPadaFromTheAscendant() {
        let rising = date(day: 7, hour: 15, minute: 0)

        // 95.5° is 5°30' into Cancer and 2°10' into Pushya (which begins at 93°20').
        let pushya = UpagrahaCalculator.position(kind: .gulika, ascendantLongitude: 95.5, risingDate: rising, bhava: 4)
        #expect(pushya.kind == .gulika)
        #expect(pushya.rasi == .cancer)
        #expect(abs(pushya.longitudeInRasi - 5.5) < 0.000_001)
        #expect(pushya.formattedDMS == "05° 30' 00\"")
        #expect(pushya.nakshatra == .pushya)
        #expect(pushya.pada == 1)
        #expect(pushya.bhava == 4)
        #expect(pushya.risingDate == rising)

        // 92.5° is 2°30' into Cancer and in the last pada of Punarvasu (90°–93°20').
        let punarvasu = UpagrahaCalculator.position(kind: .maandi, ascendantLongitude: 92.5, risingDate: rising, bhava: 4)
        #expect(punarvasu.rasi == .cancer)
        #expect(punarvasu.formattedDMS == "02° 30' 00\"")
        #expect(punarvasu.nakshatra == .punarvasu)
        #expect(punarvasu.pada == 4)
    }

    @Test func positionNormalizesLongitudesOutsideZeroToThreeSixty() {
        let rising = date(day: 7, hour: 15, minute: 0)

        let wrapped = UpagrahaCalculator.position(kind: .gulika, ascendantLongitude: -5, risingDate: rising, bhava: 12)
        #expect(abs(wrapped.longitude - 355) < 0.000_001)
        #expect(wrapped.rasi == .pisces)
        #expect(wrapped.nakshatra == .revati)
    }

    @Test func dayBirthIsHalfOpenOnSunriseAndSunset() {
        #expect(UpagrahaCalculator.isDayBirth(dayContext(vara: .sunday, birthHour: 6, birthMinute: 0)))
        #expect(UpagrahaCalculator.isDayBirth(dayContext(vara: .sunday, birthHour: 17, birthMinute: 59)))
        #expect(!UpagrahaCalculator.isDayBirth(dayContext(vara: .sunday, birthHour: 18, birthMinute: 0)))
        #expect(!UpagrahaCalculator.isDayBirth(dayContext(vara: .sunday, birthHour: 23, birthMinute: 30)))
        #expect(!UpagrahaCalculator.isDayBirth(dayContext(vara: .sunday, birthHour: 5, birthMinute: 59)))
    }

    // MARK: - Fixtures

    /// Sunrise 06:00, sunset 18:00, next sunrise 06:00 the following day, all UTC.
    private func dayContext(vara: Vara, birthHour: Int, birthMinute: Int, day: Int = 7) -> UpagrahaCalculator.DayContext {
        UpagrahaCalculator.DayContext(
            birth: date(day: day, hour: birthHour, minute: birthMinute),
            sunrise: date(day: day, hour: 6, minute: 0),
            sunset: date(day: day, hour: 18, minute: 0),
            nextSunrise: date(day: day + 1, hour: 6, minute: 0),
            vara: vara
        )
    }

    private func date(day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2024, month: 1, day: day, hour: hour, minute: minute))!
    }
}
