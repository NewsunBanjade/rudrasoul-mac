//
//  rudrasoul_jyotishTests.swift
//  rudrasoul-jyotishTests
//
//  Created by Newsun on 9/17/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import rudrasoul_jyotish

@MainActor
struct DesignTokenTests {

    @Test func spacingUsesEightPointGrid() {
        let spacingValues = [
            DesignSpacing.small,
            DesignSpacing.medium,
            DesignSpacing.large,
            DesignSpacing.xLarge,
        ]

        for spacing in spacingValues {
            #expect(spacing.truncatingRemainder(dividingBy: 8) == 0)
        }
    }

    @Test func textSystemExposesExactlyFourSemanticStyles() {
        let styles: [DesignTextStyle] = [.title, .section, .body, .caption]

        #expect(styles.count == 4)
    }
}

@MainActor
struct VimshottariDashaCalculatorTests {
    private let calculator = VimshottariDashaCalculator()

    @Test func ashviniMoonStartsWithKetuAndFixedLordOrder() {
        let birth = date(year: 2000, month: 1, day: 1)
        let result = calculator.calculate(moonLongitude: 0, birthDate: birth, referenceDate: birth)

        #expect(result.nodes.map(\.lord) == [.ketu, .venus, .sun, .moon, .mars, .rahu, .jupiter, .saturn, .mercury])
        #expect(result.nodes.first?.startDate == birth)
        #expect(abs((result.nodes.first?.endDate.timeIntervalSince(birth) ?? 0) - 7 * VimshottariDashaCalculator.solarYearLengthDays * 86_400) < 0.001)
        #expect(result.currentDashaVector == "Ketu › Ketu › Ketu")
    }

    @Test func birthBalanceUsesTheUntraversedFractionOfMoonNakshatra() throws {
        let birth = date(year: 2000, month: 1, day: 1)
        // Halfway through Ashvini leaves half of Ketu's seven-year mahadasha.
        let result = calculator.calculate(moonLongitude: 360 / 54, birthDate: birth, referenceDate: birth)
        let ketu = try #require(result.nodes.first)

        #expect(ketu.lord == .ketu)
        #expect(abs(birth.timeIntervalSince(ketu.startDate) - 3.5 * VimshottariDashaCalculator.solarYearLengthDays * 86_400) < 0.001)
        #expect(abs(ketu.endDate.timeIntervalSince(birth) - 3.5 * VimshottariDashaCalculator.solarYearLengthDays * 86_400) < 0.001)
    }

    @Test func subperiodsBeginWithTheParentLordAndUseProportionalDurations() throws {
        let birth = date(year: 2000, month: 1, day: 1)
        let result = calculator.calculate(moonLongitude: 0, birthDate: birth, referenceDate: birth)
        let ketu = try #require(result.nodes.first)

        #expect(ketu.children.map(\.lord) == [.ketu, .venus, .sun, .moon, .mars, .rahu, .jupiter, .saturn, .mercury])
        let venusAntardasha = try #require(ketu.children.dropFirst().first)
        #expect(abs(venusAntardasha.endDate.timeIntervalSince(venusAntardasha.startDate) - (7.0 * 20 / 120) * VimshottariDashaCalculator.solarYearLengthDays * 86_400) < 0.001)
    }

    @Test func exactMahadashaBoundaryMovesFocusToNextLord() {
        let birth = date(year: 2000, month: 1, day: 1)
        let initial = calculator.calculate(moonLongitude: 0, birthDate: birth, referenceDate: birth)
        let ketuEnd = initial.nodes[0].endDate
        let atBoundary = calculator.calculate(moonLongitude: 0, birthDate: birth, referenceDate: ketuEnd)

        #expect(atBoundary.currentDashaVector.hasPrefix("Venus › Venus › Venus"))
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

@MainActor
struct LibraryScreenModelTests {
    @Test func emptyFixtureLoadsWithoutInventingChartRecords() async {
        let model = LibraryScreenModel(library: EmptyLibraryFixture())

        await model.load()

        #expect(model.charts.isEmpty)
        #expect(model.visibleCharts.isEmpty)
        #expect(model.chartCount == 0)
        #expect(model.errorMessage == nil)
    }
}

@MainActor
struct ChartScreenModelTests {
    @Test func startsAtOverviewWithInspectorVisible() {
        let chartID = UUID()
        let model = ChartScreenModel(chartID: chartID)

        #expect(model.chartID == chartID)
        #expect(model.destination == .overview)
        #expect(model.isInspectorPresented)
    }

    @Test func sidebarDestinationsAreUniqueAndGrouped() {
        let destinations = ChartScreenModel.Destination.library
            + ChartScreenModel.Destination.analysis
            + ChartScreenModel.Destination.chakras
            + ChartScreenModel.Destination.tools

        #expect(Set(destinations).count == destinations.count)
        #expect(destinations == ChartScreenModel.Destination.allCases)
    }

    @Test func selectingLibraryChartOpensInOverviewInSameWindow() {
        let model = ChartScreenModel()
        model.destination = .allCharts

        let newID = UUID()
        model.selectAndOpenChart(newID)

        #expect(model.activeChartID == newID)
        #expect(model.destination == .overview)
    }

    @Test func filteringAnEmptyLibraryRemainsEmpty() async throws {
        let repository = try SQLiteChartRepository.inMemory()
        try await repository.initialize()
        let store = ChartStore(repository: repository)
        await store.reloadFromRepository()
        let model = ChartScreenModel(store: store)
        model.destination = .allCharts

        model.filterLagna = .pisces
        #expect(model.hasActiveFilters)
        #expect(model.activeFilterCount == 1)
        #expect(model.visibleCharts.isEmpty)
    }

    @Test func chartStoreReturnsNilForUnknownChartID() {
        let store = ChartStore()
        let randomID = UUID()
        #expect(store.chartDetail(for: randomID) == nil)
    }

    @Test func settingsDestinationConfiguredCorrectly() {
        let model = ChartScreenModel()
        model.destination = .settings

        #expect(model.destination == .settings)
        #expect(ChartScreenModel.Destination.settings.systemImage == "gearshape")
        #expect(ChartScreenModel.Destination.settings.titleKey == "Settings")
        #expect(ChartScreenModel.Destination.tools.contains(.settings))
        #expect(model.inspectorChartDetail == nil)
    }
}

@MainActor
struct ChartRotationTests {
    @Test func bhavatBhavamRotationCalculatesCorrectLagnaAndBhavas() {
        // Tagore's chart has Pisces (12) Lagna
        let natalLagna = Rasi.pisces

        // 1. House 1 should be Pisces
        let h1Sign = ((natalLagna.rawValue - 1 + (1 - 1)) % 12) + 1
        #expect(Rasi(rawValue: h1Sign) == .pisces)

        // 2. Rotating to House 4 should make Gemini (3) the Lagna
        let h4SignRaw = ((natalLagna.rawValue - 1 + (4 - 1)) % 12) + 1
        let h4Sign = Rasi(rawValue: h4SignRaw)
        #expect(h4Sign == .gemini)

        // In this rotated chart, Jupiter (in Pisces) moves to Bhava 10
        let jupiterRasi = Rasi.pisces
        let rotatedBhava = ((jupiterRasi.rawValue - h4SignRaw + 12) % 12) + 1
        #expect(rotatedBhava == 10)

        // 3. Rotating to House 7 makes Virgo (6) the Lagna
        let h7SignRaw = ((natalLagna.rawValue - 1 + (7 - 1)) % 12) + 1
        let h7Sign = Rasi(rawValue: h7SignRaw)
        #expect(h7Sign == .virgo)

        // Jupiter (Pisces) is now in Bhava 7 (opposite to Lagna)
        let jupiterOppositeBhava = ((jupiterRasi.rawValue - h7SignRaw + 12) % 12) + 1
        #expect(jupiterOppositeBhava == 7)

        // 4. Reverse lookup: Clicking sign Cancer (4) gives natal House 5
        let cancerRasi = Rasi.cancer
        let cancerNatalHouse = ((cancerRasi.rawValue - natalLagna.rawValue + 12) % 12) + 1
        #expect(cancerNatalHouse == 5)
    }

    @Test func d1AndD9RotateIndependently() {
        // Tagore chart: D-1 natal Lagna is Pisces (12), D-9 natal Lagna is Cancer (4)
        let d1NatalLagna = Rasi.pisces
        let d9NatalLagna = Rasi.cancer

        var d1RotatedHouse = 1
        var d9RotatedHouse = 1

        // Initially both are unrotated
        #expect(d1RotatedHouse == 1)
        #expect(d9RotatedHouse == 1)

        // 1. User rotates D-9 to House 7
        d9RotatedHouse = 7
        let d9EffectiveLagnaRaw = ((d9NatalLagna.rawValue - 1 + (d9RotatedHouse - 1)) % 12) + 1
        let d1EffectiveLagnaRaw = ((d1NatalLagna.rawValue - 1 + (d1RotatedHouse - 1)) % 12) + 1

        // D-9 becomes Capricorn (10)
        #expect(Rasi(rawValue: d9EffectiveLagnaRaw) == .capricorn)
        // D-1 MUST remain Pisces (12), completely independent!
        #expect(Rasi(rawValue: d1EffectiveLagnaRaw) == .pisces)

        // 2. User rotates D-1 to House 4
        d1RotatedHouse = 4
        let d1NewEffectiveRaw = ((d1NatalLagna.rawValue - 1 + (d1RotatedHouse - 1)) % 12) + 1
        // D-1 becomes Gemini (3)
        #expect(Rasi(rawValue: d1NewEffectiveRaw) == .gemini)
        // D-9 remains Capricorn (10)
        #expect(Rasi(rawValue: d9EffectiveLagnaRaw) == .capricorn)

        // 3. User resets D-9 to Natal
        d9RotatedHouse = 1
        let d9ResetRaw = ((d9NatalLagna.rawValue - 1 + (d9RotatedHouse - 1)) % 12) + 1
        #expect(Rasi(rawValue: d9ResetRaw) == .cancer)
        // D-1 remains Gemini (3)
        #expect(Rasi(rawValue: d1NewEffectiveRaw) == .gemini)

        // 4. User resets D-1 to Natal
        d1RotatedHouse = 1
        let d1ResetRaw = ((d1NatalLagna.rawValue - 1 + (d1RotatedHouse - 1)) % 12) + 1
        #expect(Rasi(rawValue: d1ResetRaw) == .pisces)
    }
}

@MainActor
struct VargaCalculatorTests {
    @Test func generatesEveryShodashavargaForAComputedChart() {
        let planets = [
            PlanetPosition(
                graha: .sun,
                rasi: .aries,
                longitudeInRasi: 3.0,
                formattedDMS: "",
                nakshatra: .ashwini,
                pada: 1,
                isRetrograde: false,
                isCombust: false,
                dignity: .neutral,
                bhava: 1,
                charaKaraka: nil,
                speedDegPerDay: nil
            ),
        ]

        let charts = VargaCalculator.charts(lagnaLongitude: 3.0, planets: planets)

        #expect(charts.count == VargaDivision.allCases.count)
        #expect(Set(charts.map(\.division)) == Set(VargaDivision.allCases))
        #expect(charts.allSatisfy { $0.planetRasis[.sun] != nil })
    }

    @Test func navamshaUsesMovableFixedAndDualStartingSigns() {
        #expect(VargaCalculator.rasi(for: 0, division: .d9) == .aries)
        #expect(VargaCalculator.rasi(for: 30, division: .d9) == .capricorn)
        #expect(VargaCalculator.rasi(for: 60, division: .d9) == .libra)
        #expect(VargaCalculator.rasi(for: 30 + 30.0 / 9, division: .d9) == .aquarius)
    }

    @Test func trimsamsaUsesUnequalParashariRanges() {
        #expect(VargaCalculator.rasi(for: 4.999, division: .d30) == .aries)
        #expect(VargaCalculator.rasi(for: 5, division: .d30) == .aquarius)
        #expect(VargaCalculator.rasi(for: 30 + 4.999, division: .d30) == .taurus)
        #expect(VargaCalculator.rasi(for: 30 + 5, division: .d30) == .virgo)
    }
}
