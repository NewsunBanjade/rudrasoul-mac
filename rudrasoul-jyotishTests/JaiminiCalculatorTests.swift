import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct JaiminiCalculatorTests {
    // MARK: - Chara karakas

    @Test func karakasRankByDegreeWithinSign() {
        let planets = [
            planet(.sun, .aries, 10),
            planet(.moon, .taurus, 29.5),
            planet(.mars, .gemini, 3),
            planet(.mercury, .cancer, 15),
            planet(.jupiter, .leo, 22),
            planet(.venus, .virgo, 8),
            planet(.saturn, .libra, 1),
            planet(.rahu, .scorpio, 2),
            planet(.ketu, .taurus, 2),
        ]

        let karakas = JaiminiCalculator.charaKarakas(planets: planets, scheme: .sevenKarakas)

        #expect(karakas.count == 7)
        #expect(karakas[.atmakaraka] == .moon)
        #expect(karakas[.amatyakaraka] == .jupiter)
        #expect(karakas[.bhratrukaraka] == .mercury)
        #expect(karakas[.matrukaraka] == .sun)
        #expect(karakas[.putrakaraka] == .venus)
        #expect(karakas[.gnatikaraka] == .mars)
        #expect(karakas[.darakaraka] == .saturn)
    }

    @Test func equalDegreesFallBackToFixedGrahaOrder() {
        let planets = [planet(.moon, .aries, 10), planet(.sun, .taurus, 10)]

        let karakas = JaiminiCalculator.charaKarakas(planets: planets, scheme: .sevenKarakas)

        #expect(karakas[.atmakaraka] == .sun)
        #expect(karakas[.amatyakaraka] == .moon)
        #expect(karakas[.bhratrukaraka] == nil)
    }

    @Test func eightKarakaSchemeCountsRahuFromTheEndOfItsSign() {
        // Rahu at 5° counts as 25°, above every other planet here.
        let planets = [
            planet(.sun, .aries, 20),
            planet(.moon, .taurus, 18),
            planet(.mars, .gemini, 16),
            planet(.mercury, .cancer, 14),
            planet(.jupiter, .leo, 12),
            planet(.venus, .virgo, 10),
            planet(.saturn, .libra, 8),
            planet(.rahu, .scorpio, 5),
        ]

        let seven = JaiminiCalculator.charaKarakas(planets: planets, scheme: .sevenKarakas)
        let eight = JaiminiCalculator.charaKarakas(planets: planets, scheme: .eightKarakas)

        #expect(seven[.atmakaraka] == .sun)
        #expect(seven[.darakaraka] == .saturn)
        #expect(eight[.atmakaraka] == .rahu)
        #expect(eight[.amatyakaraka] == .sun)
        #expect(eight[.darakaraka] == .venus)
        // The lowest of the eight planets has no `CharaKaraka` case to hold it.
        #expect(!eight.values.contains(.saturn))
    }

    // MARK: - Arudha padas

    @Test func arudhaLagnaIsAsFarFromTheLordAsTheLordIsFromTheBhava() throws {
        // Aries → Gemini is 3 signs; the 3rd sign from Gemini is Leo.
        let padas = JaiminiCalculator.arudhaPadas(
            lagnaRasi: .aries,
            planets: [planet(.mars, .gemini, 10)],
            applyExceptions: false
        )

        let arudhaLagna = try #require(padas.first(where: { $0.house == 1 }))
        #expect(arudhaLagna.name == "AL")
        #expect(arudhaLagna.lord == .mars)
        #expect(arudhaLagna.rasi == .leo)
        #expect(!arudhaLagna.exceptionApplied)
        // Mars also rules the 8th (Scorpio): Scorpio → Gemini is 8, the 8th from Gemini is Capricorn.
        #expect(padas.first(where: { $0.house == 8 })?.rasi == .capricorn)
        // Bhavas whose lord is absent from the chart are left out.
        #expect(padas.count == 2)
    }

    @Test func padaNamesFollowTheClassicalAbbreviations() {
        let padas = JaiminiCalculator.arudhaPadas(lagnaRasi: .aries, planets: fullSet(), applyExceptions: false)

        #expect(padas.count == 12)
        #expect(padas.map(\.house) == Array(1...12))
        #expect(padas.map(\.name) == ["AL", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10", "A11", "UL"])
        #expect(padas.allSatisfy { !$0.exceptionApplied })
    }

    @Test func sameSignExceptionMovesPadaToTheTenthOnlyWhenEnabled() throws {
        // Mars in Aries itself: count 1, so the pada lands in the bhava sign.
        let planets = [planet(.mars, .aries, 12)]

        let plain = try #require(JaiminiCalculator.arudhaPadas(lagnaRasi: .aries, planets: planets, applyExceptions: false).first)
        let moved = try #require(JaiminiCalculator.arudhaPadas(lagnaRasi: .aries, planets: planets, applyExceptions: true).first)

        #expect(plain.house == 1)
        #expect(plain.rasi == .aries)
        #expect(!plain.exceptionApplied)
        #expect(moved.house == 1)
        #expect(moved.rasi == .capricorn) // 10th from Aries
        #expect(moved.exceptionApplied)
    }

    @Test func seventhSignExceptionMovesPadaToTheFourthOnlyWhenEnabled() throws {
        // Mars in Cancer: Aries → Cancer is 4, the 4th from Cancer is Libra, the 7th from Aries.
        let planets = [planet(.mars, .cancer, 12)]

        let plain = try #require(JaiminiCalculator.arudhaPadas(lagnaRasi: .aries, planets: planets, applyExceptions: false).first)
        let moved = try #require(JaiminiCalculator.arudhaPadas(lagnaRasi: .aries, planets: planets, applyExceptions: true).first)

        #expect(plain.rasi == .libra)
        #expect(!plain.exceptionApplied)
        #expect(moved.rasi == .capricorn) // 4th from Libra
        #expect(moved.exceptionApplied)
    }

    // MARK: - Indu Lagna

    @Test func induLagnaWorkedExamples() {
        // Aries Lagna: 9th is Sagittarius (Jupiter, 10). Moon in Cancer: 9th is Pisces (Jupiter, 10).
        // 20 mod 12 = 8 → the 8th sign from Cancer is Aquarius.
        #expect(JaiminiCalculator.induLagna(lagnaRasi: .aries, moonRasi: .cancer) == .aquarius)
        // Leo Lagna and Moon in Leo: both 9ths are Aries (Mars, 6). 12 mod 12 = 0 → 12 → 12th from Leo is Cancer.
        #expect(JaiminiCalculator.induLagna(lagnaRasi: .leo, moonRasi: .leo) == .cancer)
        // Leo Lagna (Mars, 6) and Moon in Aries (Jupiter, 10): 16 mod 12 = 4 → 4th from Aries is Cancer.
        #expect(JaiminiCalculator.induLagna(lagnaRasi: .leo, moonRasi: .aries) == .cancer)
    }

    // MARK: - Bhava, Hora and Ghati lagnas

    @Test func timeLagnasAdvanceOneSignAtTheirOwnRates() {
        let sunrise = date(year: 2000, month: 1, day: 1)
        let twoHours = context(sunrise: sunrise, elapsedSeconds: 7_200, sunLongitude: 250)
        let oneHour = context(sunrise: sunrise, elapsedSeconds: 3_600, sunLongitude: 250)
        let oneGhati = context(sunrise: sunrise, elapsedSeconds: 1_440, sunLongitude: 250)

        #expect(abs(JaiminiCalculator.bhavaLagna(context: twoHours) - 280) < 1e-9)
        #expect(abs(JaiminiCalculator.horaLagna(context: oneHour) - 280) < 1e-9)
        #expect(abs(JaiminiCalculator.ghatiLagna(context: oneGhati) - 280) < 1e-9)
    }

    @Test func timeLagnasStartAtTheSunAndWrapPastTheZodiac() {
        let sunrise = date(year: 2000, month: 1, day: 1)
        let atSunrise = context(sunrise: sunrise, elapsedSeconds: 0, sunLongitude: 100)
        let sixHours = context(sunrise: sunrise, elapsedSeconds: 6 * 3_600, sunLongitude: 350)

        #expect(JaiminiCalculator.bhavaLagna(context: atSunrise) == 100)
        #expect(JaiminiCalculator.horaLagna(context: atSunrise) == 100)
        #expect(JaiminiCalculator.ghatiLagna(context: atSunrise) == 100)
        // 350 + 6 × 75 = 800 → 80
        #expect(abs(JaiminiCalculator.ghatiLagna(context: sixHours) - 80) < 1e-9)
    }

    // MARK: - Sree Lagna

    @Test func sreeLagnaEqualsLagnaWhenMoonIsAtANakshatraStart() {
        #expect(abs(JaiminiCalculator.sreeLagna(lagnaLongitude: 123.4, moonLongitude: 0) - 123.4) < 1e-9)
        // Start of Bharani.
        #expect(abs(JaiminiCalculator.sreeLagna(lagnaLongitude: 123.4, moonLongitude: 360.0 / 27.0) - 123.4) < 1e-9)
        // Halfway through Ashwini adds 180°, wrapping past 360.
        #expect(abs(JaiminiCalculator.sreeLagna(lagnaLongitude: 300, moonLongitude: 360.0 / 54.0) - 120) < 1e-9)
    }

    // MARK: - Varnada Lagna

    @Test func varnadaLagnaWorkedExamples() {
        // Aries (odd, 1) and Gemini (odd, 3): same kind → 4 → 4th from Aries is Cancer.
        #expect(JaiminiCalculator.varnadaLagna(lagnaRasi: .aries, horaLagnaRasi: .gemini) == .cancer)
        // Taurus (even, 11 counting back from Pisces) and Aries (odd, 1): 11 − 1 = 10 → 10th back from Pisces is Gemini.
        #expect(JaiminiCalculator.varnadaLagna(lagnaRasi: .taurus, horaLagnaRasi: .aries) == .gemini)
        // Pisces (even, 1) twice: 2 → 2nd back from Pisces is Aquarius.
        #expect(JaiminiCalculator.varnadaLagna(lagnaRasi: .pisces, horaLagnaRasi: .pisces) == .aquarius)
        // Aries (odd, 1) and Libra (even, 6): 6 − 1 = 5 → 5th from Aries is Leo.
        #expect(JaiminiCalculator.varnadaLagna(lagnaRasi: .aries, horaLagnaRasi: .libra) == .leo)
    }

    // MARK: - Full computation

    @Test func calculateOmitsSunriseLagnasWithoutContext() {
        let data = JaiminiCalculator().calculate(lagnaLongitude: 5, planets: fullSet(), sunriseContext: nil)

        #expect(data.scheme == .sevenKarakas)
        #expect(!data.arudhaExceptionsApplied)
        #expect(data.charaKarakas.count == 7)
        #expect(data.arudhaPadas.count == 12)
        #expect(data.specialLagnas.map(\.kind) == [.induLagna, .sreeLagna])
        #expect(data.lagnamsaRasi == VargaCalculator.rasi(for: 5, division: .d9))
    }

    @Test func calculateProducesAllSixLagnasWithSunriseContext() throws {
        let sunrise = date(year: 2000, month: 1, day: 1)
        let oneHour = context(sunrise: sunrise, elapsedSeconds: 3_600, sunLongitude: 100)

        let data = JaiminiCalculator().calculate(lagnaLongitude: 5, planets: fullSet(), sunriseContext: oneHour)

        #expect(data.specialLagnas.map(\.kind) == SpecialLagnaKind.allCases)
        let hora = try #require(data.specialLagnas.first(where: { $0.kind == .horaLagna }))
        #expect(hora.rasi == .leo) // 130°
        #expect(abs(hora.longitudeInRasi - 10) < 1e-9)
        #expect(hora.formattedDMS == "10° 00' 00\"")
        let indu = try #require(data.specialLagnas.first(where: { $0.kind == .induLagna }))
        #expect(indu.longitudeInRasi == 0)
    }

    @Test func karakamsaIsTheNavamsaOfTheAtmakaraka() throws {
        let planets = fullSet()

        let data = JaiminiCalculator().calculate(lagnaLongitude: 5, planets: planets, sunriseContext: nil)

        let atmakaraka = try #require(data.charaKarakas[.atmakaraka])
        let position = try #require(planets.first(where: { $0.graha == atmakaraka }))
        #expect(atmakaraka == .venus)
        #expect(data.karakamsaRasi == VargaCalculator.rasi(for: position.absoluteLongitude, division: .d9))
    }

    @Test func exceptionsFlagIsCarriedIntoTheResult() {
        var calculator = JaiminiCalculator()
        calculator.applyArudhaExceptions = true
        calculator.scheme = .eightKarakas

        let data = calculator.calculate(lagnaLongitude: 5, planets: fullSet(), sunriseContext: nil)

        #expect(data.arudhaExceptionsApplied)
        #expect(data.scheme == .eightKarakas)
    }

    // MARK: - Helpers

    /// Tagore-like D-1 positions with every graha present.
    private func fullSet() -> [PlanetPosition] {
        [
            planet(.sun, .aries, 23.7333),
            planet(.moon, .pisces, 11.8),
            planet(.mars, .taurus, 20.7),
            planet(.mercury, .aries, 4.35),
            planet(.jupiter, .cancer, 18.4166),
            planet(.venus, .aries, 25.2),
            planet(.saturn, .leo, 8.8666),
            planet(.rahu, .leo, 15.4),
            planet(.ketu, .aquarius, 15.4),
        ]
    }

    private func planet(_ graha: Graha, _ rasi: Rasi, _ degree: Double) -> PlanetPosition {
        PlanetPosition(
            graha: graha,
            rasi: rasi,
            longitudeInRasi: degree,
            formattedDMS: "",
            nakshatra: .ashwini,
            pada: 1,
            isRetrograde: false,
            isCombust: false,
            dignity: .neutral,
            bhava: 1,
            charaKaraka: nil,
            speedDegPerDay: nil
        )
    }

    private func context(sunrise: Date, elapsedSeconds: TimeInterval, sunLongitude: Double) -> JaiminiCalculator.SunriseContext {
        JaiminiCalculator.SunriseContext(
            birth: sunrise.addingTimeInterval(elapsedSeconds),
            sunrise: sunrise,
            sunLongitudeAtSunrise: sunLongitude
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
