import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct YoginiDashaCalculatorTests {
    private let calculator = YoginiDashaCalculator()
    private let yearSeconds = VimshottariDashaCalculator.solarYearLengthDays * 86_400

    @Test func ashviniMoonStartsWithBhramariAndFullBalance() throws {
        let birth = utcDate(year: 2000, month: 1, day: 1)
        // Ashwini is nakshatra 1: (1 + 3) mod 8 = 4 → Bhramari (4 years, Mars).
        let timeline = calculator.calculate(moonLongitude: 0, birthDate: birth)
        let first = try #require(timeline.periods.first)

        #expect(timeline.system == .yogini)
        #expect(first.name == Yogini.bhramari.name)
        #expect(first.graha == .mars)
        #expect(first.startDate == birth)
        #expect(abs(first.endDate.timeIntervalSince(birth) - 4 * yearSeconds) < 0.001)
    }

    @Test func revatiMoonStartsWithUlka() {
        // Revati is nakshatra 27: (27 + 3) mod 8 = 6 → Ulka.
        #expect(YoginiDashaCalculator.startingYogini(for: .revati) == .ulka)
        // Mrigashira is nakshatra 5: (5 + 3) mod 8 = 0 → Sankata.
        #expect(YoginiDashaCalculator.startingYogini(for: .mrigashira) == .sankata)
        // Anuradha is nakshatra 17: (17 + 3) mod 8 = 4 → Bhramari.
        #expect(YoginiDashaCalculator.startingYogini(for: .anuradha) == .bhramari)
    }

    @Test func balanceUsesUntraversedFractionOfNakshatra() throws {
        let birth = utcDate(year: 2000, month: 1, day: 1)
        // Halfway through Ashwini leaves half of Bhramari's four years.
        let timeline = calculator.calculate(moonLongitude: Nakshatra.span / 2, birthDate: birth)
        let first = try #require(timeline.periods.first)

        #expect(abs(birth.timeIntervalSince(first.startDate) - 2 * yearSeconds) < 0.001)
        #expect(abs(first.endDate.timeIntervalSince(birth) - 2 * yearSeconds) < 0.001)
    }

    @Test func sequenceWrapsAfterSankata() {
        #expect(YoginiDashaCalculator.sequence(from: .siddha) == [.siddha, .sankata, .mangala, .pingala, .dhanya, .bhramari, .bhadrika, .ulka])
    }

    @Test func subPeriodsStartWithParentAndSumToParentDuration() throws {
        let birth = utcDate(year: 2000, month: 1, day: 1)
        let timeline = calculator.calculate(moonLongitude: 0, birthDate: birth, maximumLevel: 2)
        let first = try #require(timeline.periods.first)

        #expect(first.children.count == 8)
        #expect(first.children.first?.name == first.name)
        #expect(first.children.first?.level == 2)
        let childSpan = first.children.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        #expect(abs(childSpan - first.endDate.timeIntervalSince(first.startDate)) < 0.01)
        // Bhramari antardasha inside Bhramari mahadasha: 4 × 4 / 36 years.
        let expected = 4.0 * 4.0 / 36.0 * yearSeconds
        #expect(abs((first.children.first?.durationDays ?? 0) * 86_400 - expected) < 0.01)
    }

    @Test func timelineCoversAtLeastOneHundredTwentyYears() throws {
        let birth = utcDate(year: 2000, month: 1, day: 1)
        let timeline = calculator.calculate(moonLongitude: 0, birthDate: birth, maximumLevel: 1)
        let last = try #require(timeline.periods.last)

        #expect(last.endDate.timeIntervalSince(birth) >= 120 * yearSeconds)
        #expect(timeline.activePath(at: birth).first?.name == Yogini.bhramari.name)
    }

    private func utcDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
