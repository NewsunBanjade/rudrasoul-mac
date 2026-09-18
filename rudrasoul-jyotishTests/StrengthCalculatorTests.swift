import Foundation
import Testing
@testable import rudrasoul_jyotish

// Tests for the dignity, Ashtakavarga, Shadbala and Bhava Bala calculators. Inputs are
// constructed positions; the expectations are the classical anchor values.

private func position(_ graha: Graha, longitude: Double, speed: Double? = 1) -> PlanetPosition {
    let normalized = longitude.normalizedLongitude360
    return PlanetPosition(
        graha: graha,
        rasi: Rasi(absoluteLongitude: normalized),
        longitudeInRasi: normalized.longitudeWithinRasi,
        formattedDMS: normalized.dmsStringInRasi,
        nakshatra: Nakshatra(absoluteLongitude: normalized),
        pada: Nakshatra.pada(absoluteLongitude: normalized),
        isRetrograde: (speed ?? 0) < 0,
        isCombust: false,
        dignity: .neutral,
        bhava: 1,
        charaKaraka: nil,
        speedDegPerDay: speed
    )
}

/// Every planet at its deepest exaltation point.
private let exaltedPlanets: [PlanetPosition] = [
    position(.sun, longitude: 10),
    position(.moon, longitude: 33),
    position(.mars, longitude: 298),
    position(.mercury, longitude: 165),
    position(.jupiter, longitude: 95),
    position(.venus, longitude: 357),
    position(.saturn, longitude: 200),
    position(.rahu, longitude: 50),
    position(.ketu, longitude: 230),
]

@MainActor
struct GrahaDignityCalculatorTests {
    @Test func deepestExaltationPointsAreExalted() {
        let planets = GrahaDignityCalculator.applyingDignities(to: exaltedPlanets)
        for planet in planets {
            #expect(planet.dignity == .exalted, "\(planet.graha.rawValue)")
        }
    }

    @Test func mercuryInVirgoSplitsIntoExaltedMoolatrikonaAndOwn() {
        let sun = position(.sun, longitude: 100)
        #expect(GrahaDignityCalculator.dignity(of: .mercury, rasi: .virgo, degreeInRasi: 10, planets: [sun]) == .exalted)
        #expect(GrahaDignityCalculator.dignity(of: .mercury, rasi: .virgo, degreeInRasi: 17, planets: [sun]) == .moolatrikona)
        #expect(GrahaDignityCalculator.dignity(of: .mercury, rasi: .virgo, degreeInRasi: 25, planets: [sun]) == .ownSign)
        #expect(GrahaDignityCalculator.dignity(of: .mercury, rasi: .pisces, degreeInRasi: 5, planets: [sun]) == .debilitated)
        #expect(GrahaDignityCalculator.dignity(of: .moon, rasi: .taurus, degreeInRasi: 2, planets: [sun]) == .exalted)
        #expect(GrahaDignityCalculator.dignity(of: .moon, rasi: .taurus, degreeInRasi: 20, planets: [sun]) == .moolatrikona)
    }

    @Test func compoundRelationCombinesNaturalAndTemporaryFriendship() {
        // Jupiter in Aries, Sun in Taurus (2nd from Jupiter), Venus in Leo (5th from Jupiter).
        let planets = [
            position(.jupiter, longitude: 5),
            position(.sun, longitude: 35),
            position(.venus, longitude: 125),
        ]
        #expect(GrahaDignityCalculator.compoundRelation(of: .jupiter, to: .sun, planets: planets) == .adhiMitra)
        #expect(GrahaDignityCalculator.compoundRelation(of: .jupiter, to: .venus, planets: planets) == .adhiShatru)
        // Sun regards Venus: natural enemy, but Venus is 4th from the Sun (temporary friend).
        #expect(GrahaDignityCalculator.compoundRelation(of: .sun, to: .venus, planets: planets) == .sama)
        #expect(GrahaDignityCalculator.compoundRelation(of: .sun, to: .rahu, planets: planets) == nil)
    }

    @Test func combustionUsesPlanetSpecificOrbs() {
        #expect(GrahaDignityCalculator.isCombust(position(.venus, longitude: 109), sunLongitude: 100))
        #expect(!GrahaDignityCalculator.isCombust(position(.venus, longitude: 111), sunLongitude: 100))
        #expect(!GrahaDignityCalculator.isCombust(position(.venus, longitude: 109, speed: -0.5), sunLongitude: 100))
        #expect(GrahaDignityCalculator.isCombust(position(.jupiter, longitude: 90), sunLongitude: 100))
        #expect(!GrahaDignityCalculator.isCombust(position(.sun, longitude: 100), sunLongitude: 100))
        #expect(!GrahaDignityCalculator.isCombust(position(.rahu, longitude: 100), sunLongitude: 100))
    }
}

@MainActor
struct AshtakavargaCalculatorTests {
    @Test func tablesCarryTheClassicalTotals() {
        #expect(AshtakavargaCalculator.expectedTotal(of: .sun) == 48)
        #expect(AshtakavargaCalculator.expectedTotal(of: .moon) == 49)
        #expect(AshtakavargaCalculator.expectedTotal(of: .mars) == 39)
        #expect(AshtakavargaCalculator.expectedTotal(of: .mercury) == 54)
        #expect(AshtakavargaCalculator.expectedTotal(of: .jupiter) == 56)
        #expect(AshtakavargaCalculator.expectedTotal(of: .venus) == 52)
        #expect(AshtakavargaCalculator.expectedTotal(of: .saturn) == 39)
    }

    @Test func sarvashtakavargaAlwaysSumsTo337() {
        let data = AshtakavargaCalculator.calculate(lagnaRasi: .pisces, planets: exaltedPlanets)
        #expect(data.totalBindus == 337)
        for planet in AshtakavargaCalculator.contributingPlanets {
            let total = data.bhinnashtakavarga[planet]?.values.reduce(0, +)
            #expect(total == AshtakavargaCalculator.expectedTotal(of: planet), "\(planet.rawValue)")
        }
    }

    @Test func everyReferenceInAriesPlacesSunBindusByTheTable() {
        let planets = GrahaDignityCalculator.sevenGrahas.map { position($0, longitude: 5) }
        let data = AshtakavargaCalculator.calculate(lagnaRasi: .aries, planets: planets)
        // House 1 is benefic for the Sun from the Sun, Mars and Saturn only.
        #expect(data.bhinnashtakavarga[.sun]?[.aries] == 3)
        // House 11 (Aquarius) is benefic for the Sun from every reference except Venus.
        #expect(data.bhinnashtakavarga[.sun]?[.aquarius] == 7)
    }
}

@MainActor
struct ShadbalaCalculatorTests {
    @Test func ucchaBalaIsFullAtExaltationAndZeroAtDebilitation() {
        #expect(abs(ShadbalaCalculator.ucchaBala(of: .sun, longitude: 10) - 60) < 1e-9)
        #expect(abs(ShadbalaCalculator.ucchaBala(of: .sun, longitude: 190)) < 1e-9)
        #expect(abs(ShadbalaCalculator.ucchaBala(of: .saturn, longitude: 20)) < 1e-9)
        #expect(abs(ShadbalaCalculator.ucchaBala(of: .moon, longitude: 123) - 30) < 1e-9)
    }

    @Test func sripatiAspectValuesHitTheClassicalAnchors() {
        #expect(ShadbalaCalculator.aspectValue(distance: 30) == 0)
        #expect(ShadbalaCalculator.aspectValue(distance: 60) == 15)
        #expect(ShadbalaCalculator.aspectValue(distance: 90) == 45)
        #expect(ShadbalaCalculator.aspectValue(distance: 120) == 30)
        #expect(ShadbalaCalculator.aspectValue(distance: 150) == 0)
        #expect(ShadbalaCalculator.aspectValue(distance: 180) == 60)
        #expect(ShadbalaCalculator.aspectValue(distance: 240) == 30)
        #expect(ShadbalaCalculator.aspectValue(distance: 300) == 0)
        #expect(ShadbalaCalculator.specialAspectValue(of: .saturn, signDistance: 10) == 45)
        #expect(ShadbalaCalculator.specialAspectValue(of: .mars, signDistance: 8) == 15)
        #expect(ShadbalaCalculator.specialAspectValue(of: .jupiter, signDistance: 9) == 30)
        #expect(ShadbalaCalculator.specialAspectValue(of: .venus, signDistance: 7) == 0)
    }

    @Test func digBalaFollowsTheStrongestDirection() {
        // Lagna 0° Aries, Midheaven 0° Capricorn.
        let jupiter = position(.jupiter, longitude: 0)
        let saturn = position(.saturn, longitude: 0)
        let sun = position(.sun, longitude: 270)
        #expect(abs(ShadbalaCalculator.digBala(of: jupiter, lagnaLongitude: 0, midheavenLongitude: 270) - 60) < 1e-9)
        #expect(abs(ShadbalaCalculator.digBala(of: saturn, lagnaLongitude: 0, midheavenLongitude: 270)) < 1e-9)
        #expect(abs(ShadbalaCalculator.digBala(of: sun, lagnaLongitude: 0, midheavenLongitude: 270) - 60) < 1e-9)
    }

    @Test func kendradiOjayugmaAndDrekkanaBalas() {
        let sunInAries = position(.sun, longitude: 5) // odd sign, first drekkana, Taurus navamsha
        #expect(ShadbalaCalculator.kendradiBala(of: sunInAries, lagnaRasi: .aries) == 60)
        #expect(ShadbalaCalculator.kendradiBala(of: sunInAries, lagnaRasi: .pisces) == 30)
        #expect(ShadbalaCalculator.kendradiBala(of: sunInAries, lagnaRasi: .aquarius) == 15)
        #expect(ShadbalaCalculator.drekkanaBala(of: sunInAries) == 15)
        #expect(ShadbalaCalculator.ojayugmaBala(of: sunInAries) == 15)

        let moonInTaurus = position(.moon, longitude: 55) // even sign, third drekkana, Leo navamsha
        #expect(ShadbalaCalculator.drekkanaBala(of: moonInTaurus) == 15)
        #expect(ShadbalaCalculator.ojayugmaBala(of: moonInTaurus) == 15)
    }

    @Test func pakshaBalaDoublesForTheMoonAtFullMoon() {
        let planets = [
            position(.sun, longitude: 0),
            position(.moon, longitude: 180),
            position(.saturn, longitude: 100),
        ]
        #expect(abs(ShadbalaCalculator.pakshaBala(of: planets[1], planets: planets) - 120) < 1e-9)
        #expect(abs(ShadbalaCalculator.pakshaBala(of: planets[2], planets: planets)) < 1e-9)
    }

    @Test func yearAndMonthLordsFollowTheAharganaRule() {
        #expect(ShadbalaCalculator.yearLord(ahargana: 0) == .sun)
        #expect(ShadbalaCalculator.monthLord(ahargana: 0) == .sun)
        #expect(ShadbalaCalculator.yearLord(ahargana: 360) == .mercury)
        #expect(ShadbalaCalculator.monthLord(ahargana: 360) == .mercury)
    }

    @Test func horaLordStartsWithTheWeekdayLordAndFollowsChaldeanOrder() {
        let sunrise = Date(timeIntervalSince1970: 1_700_000_000)
        let day = UpagrahaCalculator.DayContext(
            birth: sunrise.addingTimeInterval(1_800),
            sunrise: sunrise,
            sunset: sunrise.addingTimeInterval(12 * 3_600),
            nextSunrise: sunrise.addingTimeInterval(24 * 3_600),
            vara: .monday
        )
        #expect(ShadbalaCalculator.horaLord(day: day, birth: day.birth) == .moon)
        #expect(ShadbalaCalculator.horaLord(day: day, birth: sunrise.addingTimeInterval(3_660)) == .saturn)
        // The thirteenth hora of a Monday (first of the night) belongs to Venus.
        #expect(ShadbalaCalculator.horaLord(day: day, birth: day.sunset.addingTimeInterval(60)) == .venus)
    }

    @Test func nathonnathaBalaIsSymmetricAroundLocalMidnight() {
        let midnight = Date(timeIntervalSince1970: 0)
        #expect(abs(ShadbalaCalculator.nathonnathaBala(of: .moon, birth: midnight, geographicLongitude: 0) - 60) < 1e-9)
        #expect(abs(ShadbalaCalculator.nathonnathaBala(of: .sun, birth: midnight, geographicLongitude: 0)) < 1e-9)
        let noon = midnight.addingTimeInterval(12 * 3_600)
        #expect(abs(ShadbalaCalculator.nathonnathaBala(of: .sun, birth: noon, geographicLongitude: 0) - 60) < 1e-9)
        #expect(ShadbalaCalculator.nathonnathaBala(of: .mercury, birth: noon, geographicLongitude: 0) == 60)
        // 90° east moves local midnight six hours earlier in UTC.
        let easternMidnight = midnight.addingTimeInterval(-6 * 3_600)
        #expect(abs(ShadbalaCalculator.nathonnathaBala(of: .moon, birth: easternMidnight, geographicLongitude: 90) - 60) < 1e-9)
    }

    @Test func fullCalculationRanksSevenPlanetsAndSumsComponents() {
        let input = ShadbalaInput(
            planets: exaltedPlanets,
            lagnaLongitude: 0,
            midheavenLongitude: 270,
            ayanamsaDegrees: 24,
            birth: Date(timeIntervalSince1970: 0),
            geographicLongitude: 85.3,
            day: nil
        )
        let result = ShadbalaCalculator.calculate(input)
        #expect(result.count == 7)
        #expect(Set(result.map(\.rank)) == Set(1 ... 7))
        for row in result {
            let sum = row.sthanaBala + row.dikBala + row.kalaBala + row.cheshtaBala + row.naisargikaBala + row.drikBala
            #expect(abs(sum - row.totalVirupas) < 1e-9)
            #expect(abs(row.totalVirupas / 60 - row.totalRupas) < 1e-9)
            #expect(row.components != nil)
            #expect(row.requiredRupas > 0)
        }
    }
}

@MainActor
struct BhavaBalaCalculatorTests {
    @Test func bhavaDigBalaDropsTenPerHouseFromTheStrongestHouse() {
        // Gemini (a human sign) is strongest in the 1st house.
        #expect(BhavaBalaCalculator.bhavaDigBala(house: 1, cuspLongitude: 60) == 60)
        #expect(BhavaBalaCalculator.bhavaDigBala(house: 7, cuspLongitude: 60) == 0)
        #expect(BhavaBalaCalculator.bhavaDigBala(house: 12, cuspLongitude: 60) == 50)
        // Sagittarius splits: first half human (1st), second half quadruped (10th).
        #expect(BhavaBalaCalculator.strongestHouse(forCuspLongitude: 245) == 1)
        #expect(BhavaBalaCalculator.strongestHouse(forCuspLongitude: 250) == 10)
        // Scorpio is strongest in the 7th.
        #expect(BhavaBalaCalculator.bhavaDigBala(house: 7, cuspLongitude: 215) == 60)
    }

    @Test func bhavaBalaUsesTheHouseLordShadbala() {
        let input = ShadbalaInput(
            planets: exaltedPlanets,
            lagnaLongitude: 0,
            midheavenLongitude: 270,
            ayanamsaDegrees: 24,
            birth: Date(timeIntervalSince1970: 0),
            geographicLongitude: 0,
            day: nil
        )
        let shadbala = ShadbalaCalculator.calculate(input)
        let cusps = (0 ..< 12).map { Double($0 * 30) }
        let bhavas = BhavaBalaCalculator.calculate(cusps: cusps, shadbala: shadbala, planets: exaltedPlanets)
        #expect(bhavas.count == 12)
        #expect(bhavas[0].lord == .mars)
        #expect(bhavas[0].bhavadhipatiBala == shadbala.first { $0.graha == .mars }?.totalVirupas)
        #expect(Set(bhavas.map(\.rank)) == Set(1 ... 12))
    }
}
