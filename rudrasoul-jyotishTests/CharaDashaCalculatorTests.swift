import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct CharaDashaCalculatorTests {
    private let calculator = CharaDashaCalculator()
    private let yearSeconds = VimshottariDashaCalculator.solarYearLengthDays * 86_400

    @Test func sequenceRunsForwardFromAriesAndBackwardFromCancer() {
        #expect(CharaDashaCalculator.sequence(from: .aries).prefix(3) == [.aries, .taurus, .gemini])
        #expect(CharaDashaCalculator.sequence(from: .cancer).prefix(3) == [.cancer, .gemini, .taurus])
        #expect(CharaDashaCalculator.sequence(from: .libra).count == 12)
        #expect(Set(CharaDashaCalculator.sequence(from: .pisces)).count == 12)
    }

    @Test func durationCountsForwardForAriesAndBackwardForCancer() {
        // Aries → Gemini forward is 3 signs, minus one = 2 years.
        let mars = position(.mars, in: .gemini)
        #expect(CharaDashaCalculator.duration(of: .aries, planets: [mars]) == 2)
        // Cancer → Taurus backward is 3 signs, minus one = 2 years.
        let moon = position(.moon, in: .taurus)
        #expect(CharaDashaCalculator.duration(of: .cancer, planets: [moon]) == 2)
    }

    @Test func lordInOwnSignGivesTwelveYearsAndDignityAdjusts() {
        #expect(CharaDashaCalculator.duration(of: .leo, planets: [position(.sun, in: .leo)]) == 12)
        // Sun exalted in Aries, counted from Leo backward: Leo→Aries is 5, minus one = 4, plus one = 5.
        let exaltedSun = position(.sun, in: .aries, dignity: .exalted)
        #expect(CharaDashaCalculator.duration(of: .leo, planets: [exaltedSun]) == 5)
    }

    @Test func dualLordsUseTheOtherLordWhenOneOccupiesTheSign() {
        // Mars in Scorpio itself, Ketu in Capricorn: Scorpio → Capricorn forward is 3, minus one = 2.
        let planets = [position(.mars, in: .scorpio), position(.ketu, in: .capricorn)]
        #expect(CharaDashaCalculator.duration(of: .scorpio, planets: planets) == 2)
        let both = [position(.saturn, in: .aquarius), position(.rahu, in: .aquarius)]
        #expect(CharaDashaCalculator.duration(of: .aquarius, planets: both) == 12)
    }

    @Test func antardashasAreTwelveEqualPartsBeginningFromTheNextSign() throws {
        let birth = utcDate(year: 2000, month: 1, day: 1)
        let timeline = calculator.calculate(lagnaRasi: .aries, planets: [position(.mars, in: .gemini)], birthDate: birth)
        let first = try #require(timeline.periods.first)

        #expect(timeline.system == .chara)
        #expect(first.rasi == .aries)
        #expect(first.startDate == birth)
        #expect(abs(first.endDate.timeIntervalSince(birth) - 2 * yearSeconds) < 0.001)
        #expect(first.children.count == 12)
        #expect(first.children.first?.rasi == .taurus)
        let childSpan = first.children.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        #expect(abs(childSpan - first.endDate.timeIntervalSince(first.startDate)) < 0.01)
    }

    @Test func lagnamsaVariantStartsFromTheGivenSign() throws {
        let birth = utcDate(year: 2000, month: 1, day: 1)
        let timeline = calculator.calculateLagnamsa(lagnamsaRasi: .virgo, planets: [position(.mercury, in: .virgo)], birthDate: birth)
        let first = try #require(timeline.periods.first)

        #expect(timeline.system == .lagnamsa)
        #expect(first.rasi == .virgo)
        #expect(abs(first.endDate.timeIntervalSince(birth) - 12 * yearSeconds) < 0.001)
        #expect(timeline.periods.map(\.rasi).prefix(2) == [.virgo, .leo])
    }

    // MARK: - Helpers

    private func position(_ graha: Graha, in rasi: Rasi, dignity: Dignity = .neutral) -> PlanetPosition {
        PlanetPosition(
            graha: graha,
            rasi: rasi,
            longitudeInRasi: 10,
            formattedDMS: "",
            nakshatra: .ashwini,
            pada: 1,
            isRetrograde: false,
            isCombust: false,
            dignity: dignity,
            bhava: 1,
            charaKaraka: nil,
            speedDegPerDay: nil
        )
    }

    private func utcDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

@MainActor
struct VimshottariSubPeriodTests {
    private let calculator = VimshottariDashaCalculator()

    @Test func subPeriodsBeginWithTheParentLordAndAdvanceOneLevel() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let birth = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let result = calculator.calculate(moonLongitude: 0, birthDate: birth, referenceDate: birth)
        let ketuMD = try #require(result.nodes.first)
        let ketuAD = try #require(ketuMD.children.first)
        let ketuPD = try #require(ketuAD.children.first)

        let sookshmas = calculator.subPeriods(of: ketuPD, birthDate: birth, referenceDate: birth)
        #expect(sookshmas.count == 9)
        #expect(sookshmas.first?.lord == .ketu)
        #expect(sookshmas.allSatisfy { $0.level == .sookshma })
        #expect(sookshmas.first?.startDate == ketuPD.startDate)
        #expect(abs((sookshmas.last?.endDate ?? .distantPast).timeIntervalSince(ketuPD.endDate)) < 0.01)

        let firstSookshma = try #require(sookshmas.first)
        let pranas = calculator.subPeriods(of: firstSookshma, birthDate: birth)
        #expect(pranas.allSatisfy { $0.level == .prana })
        let firstPrana = try #require(pranas.first)
        #expect(calculator.subPeriods(of: firstPrana, birthDate: birth).isEmpty)

        let path = VimshottariDashaCalculator.activePath(in: result.nodes, at: birth)
        #expect(path.map(\.level) == [.mahadasha, .antardasha, .pratyantardasha])
        #expect(VimshottariDashaCalculator.formattedDuration(days: VimshottariDashaCalculator.solarYearLengthDays * 7, yearLengthDays: VimshottariDashaCalculator.solarYearLengthDays) == "7y")
    }
}
