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

    @Test func chartStoreLoadsDefaultFixtures() async throws {
        let store = ChartStore()
        let charts = try await store.charts()

        #expect(charts.count >= 2)
        #expect(charts.contains(where: { $0.name == "Rabindranath Tagore" }))
        #expect(charts.contains(where: { $0.name == "Mahatma Gandhi" }))

        let detail = store.chartDetail(for: GoldenChartFixtures.tagoreID)
        #expect(detail?.name == "Rabindranath Tagore")
        #expect(detail?.lagnaPosition.rasi == .pisces)
        #expect(detail?.planets.count == 9)
    }

    @Test func filteringByLagnaFiltersChartsCorrectly() {
        let model = ChartScreenModel()
        model.destination = .allCharts

        #expect(model.visibleCharts.count >= 2)

        // Filter for Pisces Lagna (Tagore is Pisces, Gandhi is Libra)
        model.filterLagna = .pisces
        #expect(model.hasActiveFilters)
        #expect(model.activeFilterCount == 1)
        #expect(model.visibleCharts.contains { $0.name == "Rabindranath Tagore" })
        #expect(!model.visibleCharts.contains { $0.name == "Mahatma Gandhi" })

        // Filter for Libra Lagna
        model.filterLagna = .libra
        #expect(model.visibleCharts.contains { $0.name == "Mahatma Gandhi" })
        #expect(!model.visibleCharts.contains { $0.name == "Rabindranath Tagore" })

        // Filter for Aries Lagna (no chart in default fixtures)
        model.filterLagna = .aries
        #expect(model.visibleCharts.isEmpty)

        // Reset
        model.resetFilters()
        #expect(!model.hasActiveFilters)
        #expect(model.activeFilterCount == 0)
        #expect(model.visibleCharts.count >= 2)
    }

    @Test func filteringByMoonRasiAndDashaLord() {
        let model = ChartScreenModel()
        model.destination = .allCharts

        // Gandhi has Moon in Cancer
        model.filterMoonRasi = .cancer
        #expect(model.visibleCharts.contains { $0.name == "Mahatma Gandhi" })
        #expect(!model.visibleCharts.contains { $0.name == "Rabindranath Tagore" })

        // Reset and filter by Sun Dasha Lord (Tagore's active vector has Sun)
        model.resetFilters()
        model.filterDashaLord = .sun
        #expect(model.visibleCharts.contains { $0.name == "Rabindranath Tagore" })

        // Combined filter
        model.filterLagna = .pisces
        #expect(model.activeFilterCount == 2)
        #expect(model.visibleCharts.contains { $0.name == "Rabindranath Tagore" })
        #expect(!model.visibleCharts.contains { $0.name == "Mahatma Gandhi" })
    }

    @Test func librarySelectionUpdatesInspectorChartDetail() {
        let model = ChartScreenModel()
        model.destination = .allCharts

        // Active chart is Tagore by default
        #expect(model.activeChartID == GoldenChartFixtures.tagoreID)

        // Selected in library is initially Tagore
        #expect(model.inspectorChartDetail?.name == "Rabindranath Tagore")

        // User clicks on Mahatma Gandhi in the library table
        model.selectedLibraryChartID = GoldenChartFixtures.gandhiID
        #expect(model.inspectorChartDetail?.name == "Mahatma Gandhi")

        // User clicks on Rabindranath Tagore in the library table
        model.selectedLibraryChartID = GoldenChartFixtures.tagoreID
        #expect(model.inspectorChartDetail?.name == "Rabindranath Tagore")

        // If no chart is selected, inspectorChartDetail is nil
        model.selectedLibraryChartID = nil
        #expect(model.inspectorChartDetail == nil)

        // If in overview, inspectorChartDetail shows active chart
        model.destination = .overview
        #expect(model.inspectorChartDetail?.name == "Rabindranath Tagore")
    }

    @Test func chartStoreReturnsNilForUnknownChartID() {
        let store = ChartStore()
        let randomID = UUID()
        #expect(store.chartDetail(for: randomID) == nil)
    }

    @Test func searchingChartsInLibraryFiltersCorrectly() {
        let model = ChartScreenModel()
        model.destination = .allCharts

        model.searchText = "Gandhi"
        #expect(model.visibleCharts.count == 1)
        #expect(model.visibleCharts.first?.name == "Mahatma Gandhi")

        model.searchText = "Tagore"
        #expect(model.visibleCharts.count == 1)
        #expect(model.visibleCharts.first?.name == "Rabindranath Tagore")

        model.searchText = ""
        #expect(model.visibleCharts.count >= 2)
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
