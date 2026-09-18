import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct ShashtiamsaTableTests {
    @Test func tableHasSixtyDeitiesInParashariOrder() {
        #expect(ShashtiamsaTable.oddSignDeities.count == 60)
        #expect(ShashtiamsaTable.oddSignDeities.first == "Ghora")
        #expect(ShashtiamsaTable.oddSignDeities.last == "Chandrarekha")
        // Verse 34 of BPHS Ch. 6 names the first twelve.
        #expect(Array(ShashtiamsaTable.oddSignDeities.prefix(12)) == [
            "Ghora", "Rakshasa", "Deva", "Kubera", "Yaksha", "Kinnara",
            "Bhrashta", "Kulaghna", "Garala", "Vahni", "Maya", "Purishaka"
        ])
    }

    @Test func amsaIndexAdvancesEveryHalfDegree() {
        #expect(ShashtiamsaTable.amsaIndex(longitudeInRasi: 0) == 1)
        #expect(ShashtiamsaTable.amsaIndex(longitudeInRasi: 0.499) == 1)
        #expect(ShashtiamsaTable.amsaIndex(longitudeInRasi: 0.5) == 2)
        #expect(ShashtiamsaTable.amsaIndex(longitudeInRasi: 10.75) == 22)
        #expect(ShashtiamsaTable.amsaIndex(longitudeInRasi: 29.5) == 60)
        #expect(ShashtiamsaTable.amsaIndex(longitudeInRasi: 29.999) == 60)
    }

    @Test func oddSignsCountForwardFromGhora() {
        #expect(ShashtiamsaTable.deity(index: 1, isOddSign: true) == "Ghora")
        #expect(ShashtiamsaTable.deity(index: 22, isOddSign: true) == "Brahma")
        #expect(ShashtiamsaTable.deity(index: 60, isOddSign: true) == "Chandrarekha")
    }

    @Test func evenSignsCountBackwardFromChandrarekha() {
        #expect(ShashtiamsaTable.deity(index: 1, isOddSign: false) == "Chandrarekha")
        #expect(ShashtiamsaTable.deity(index: 2, isOddSign: false) == "Bhramana")
        // The 22nd amsa of an even sign is the 39th name of the odd list.
        #expect(ShashtiamsaTable.deity(index: 22, isOddSign: false) == "Purnachandra")
        #expect(ShashtiamsaTable.deity(index: 60, isOddSign: false) == "Ghora")
    }

    @Test func classifiesBeneficAndMaleficDeities() {
        #expect(ShashtiamsaTable.isBenefic(deity: "Deva"))
        #expect(ShashtiamsaTable.isBenefic(deity: "Amrita"))
        #expect(ShashtiamsaTable.isBenefic(deity: "Chandrarekha"))
        #expect(ShashtiamsaTable.isBenefic(deity: "Payodhi"))
        #expect(!ShashtiamsaTable.isBenefic(deity: "Ghora"))
        #expect(!ShashtiamsaTable.isBenefic(deity: "Mrityu"))
        #expect(!ShashtiamsaTable.isBenefic(deity: "Bhramana"))
        #expect(!ShashtiamsaTable.isBenefic(deity: "Not a deity"))
        // Every name in the table is classified one way or the other.
        let benefic = ShashtiamsaTable.oddSignDeities.filter { ShashtiamsaTable.isBenefic(deity: $0) }
        #expect(!benefic.isEmpty)
        #expect(benefic.count < ShashtiamsaTable.oddSignDeities.count)
    }

    @Test func detailHonoursSignParity() {
        let ariesStart = ShashtiamsaTable.detail(absoluteLongitude: 0)
        #expect(ariesStart.index == 1)
        #expect(ariesStart.deity == "Ghora")
        #expect(!ariesStart.isBenefic)

        let taurusStart = ShashtiamsaTable.detail(absoluteLongitude: 30)
        #expect(taurusStart.index == 1)
        #expect(taurusStart.deity == "Chandrarekha")
        #expect(taurusStart.isBenefic)

        let ariesBrahma = ShashtiamsaTable.detail(absoluteLongitude: 10.75)
        #expect(ariesBrahma.index == 22)
        #expect(ariesBrahma.deity == "Brahma")
        #expect(ariesBrahma.isBenefic)

        // Pisces 29°45' is the 60th amsa of an even sign: Ghora.
        let piscesEnd = ShashtiamsaTable.detail(absoluteLongitude: 359.75)
        #expect(piscesEnd.index == 60)
        #expect(piscesEnd.deity == "Ghora")
    }
}

@MainActor
struct VargaCalculatorUpagrahaTests {
    @Test func d60SignIsCountedFromTheSignItselfEveryHalfDegree() {
        #expect(VargaCalculator.rasi(for: 0, division: .d60) == .aries)
        #expect(VargaCalculator.rasi(for: 0.5, division: .d60) == .taurus)
        #expect(VargaCalculator.rasi(for: 29.5, division: .d60) == .pisces)
        #expect(VargaCalculator.rasi(for: 30, division: .d60) == .taurus)
    }

    @Test func legacyCallWithoutUpagrahasStillReturnsEveryDivision() {
        let charts = VargaCalculator.charts(lagnaLongitude: 3.0, planets: [planet(.sun, longitude: 3.0)])

        #expect(charts.count == VargaDivision.allCases.count)
        #expect(Set(charts.map(\.division)) == Set(VargaDivision.allCases))
        #expect(charts.allSatisfy { $0.upagrahaRasis != nil })
        #expect(charts.allSatisfy { ($0.upagrahaRasis ?? [:]).isEmpty })
    }

    @Test func upagrahasArePlacedInEveryDivisionByTheSameRule() {
        let gulika = upagraha(.gulika, longitude: 123.4)
        let maandi = upagraha(.maandi, longitude: 301.25)
        let charts = VargaCalculator.charts(
            lagnaLongitude: 45.0,
            planets: [planet(.sun, longitude: 3.0), planet(.moon, longitude: 200.0)],
            upagrahas: [gulika, maandi]
        )

        #expect(charts.count == VargaDivision.allCases.count)
        for chart in charts {
            let placed = chart.upagrahaRasis ?? [:]
            #expect(placed.count == 2)
            #expect(placed[.gulika] == VargaCalculator.rasi(for: 123.4, division: chart.division))
            #expect(placed[.maandi] == VargaCalculator.rasi(for: 301.25, division: chart.division))
        }
    }

    @Test func amsaDetailsAreAttachedOnlyToD60() throws {
        let charts = VargaCalculator.charts(
            lagnaLongitude: 10.75,
            planets: [planet(.sun, longitude: 30.0), planet(.moon, longitude: 359.75)],
            upagrahas: [upagraha(.gulika, longitude: 0)]
        )

        for chart in charts where chart.division != .d60 {
            #expect(chart.lagnaAmsaDetail == nil)
            #expect(chart.planetAmsaDetails == nil)
        }

        let d60 = try #require(charts.first(where: { $0.division == .d60 }))
        let lagnaAmsa = try #require(d60.lagnaAmsaDetail)
        #expect(lagnaAmsa.index == 22)
        #expect(lagnaAmsa.deity == "Brahma")

        let planetAmsas = try #require(d60.planetAmsaDetails)
        #expect(planetAmsas.count == 2)
        #expect(planetAmsas[.sun]?.deity == "Chandrarekha")
        #expect(planetAmsas[.sun]?.isBenefic == true)
        #expect(planetAmsas[.moon]?.deity == "Ghora")
        #expect(planetAmsas[.moon]?.isBenefic == false)
    }

    // MARK: - Fixtures

    private func planet(_ graha: Graha, longitude: Double) -> PlanetPosition {
        PlanetPosition(
            graha: graha,
            rasi: Rasi(absoluteLongitude: longitude),
            longitudeInRasi: longitude.longitudeWithinRasi,
            formattedDMS: longitude.dmsStringInRasi,
            nakshatra: Nakshatra(absoluteLongitude: longitude),
            pada: Nakshatra.pada(absoluteLongitude: longitude),
            isRetrograde: false,
            isCombust: false,
            dignity: .neutral,
            bhava: 1,
            charaKaraka: nil,
            speedDegPerDay: nil
        )
    }

    private func upagraha(_ kind: UpagrahaKind, longitude: Double) -> UpagrahaPosition {
        UpagrahaPosition(
            kind: kind,
            longitude: longitude,
            rasi: Rasi(absoluteLongitude: longitude),
            longitudeInRasi: longitude.longitudeWithinRasi,
            formattedDMS: longitude.dmsStringInRasi,
            nakshatra: Nakshatra(absoluteLongitude: longitude),
            pada: Nakshatra.pada(absoluteLongitude: longitude),
            bhava: 1,
            risingDate: Date(timeIntervalSince1970: 0)
        )
    }
}
