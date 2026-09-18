import Foundation
import Observation

@MainActor
@Observable
final class ChartScreenModel {
    enum Destination: String, CaseIterable, Hashable {
        // Library
        case allCharts
        case recent

        // Analysis
        case overview
        case divisionalCharts
        case planetsAndHouses
        case strength
        case ashtakavarga
        case dasha
        case nakshatra
        case yogasAndDoshas

        // Chakras
        case sarvatobhadra
        case kota

        // Tools
        case progressionAndTransit
        case notesAndPredictions
        case settings

        var titleKey: String {
            switch self {
            case .allCharts: "library.sidebar.allCharts"
            case .recent: "library.sidebar.recent"
            case .settings: "Settings"
            default: "chart.sidebar.\(rawValue)"
            }
        }

        var systemImage: String {
            switch self {
            case .allCharts: "rectangle.stack"
            case .recent: "clock"
            case .overview: "square.grid.2x2"
            case .divisionalCharts: "square.grid.3x3"
            case .planetsAndHouses: "circle.hexagongrid"
            case .strength: "chart.bar"
            case .ashtakavarga: "arrow.up.and.down.text.horizontal"
            case .dasha: "timeline.selection"
            case .nakshatra: "sparkles"
            case .yogasAndDoshas: "checkmark.seal"
            case .sarvatobhadra: "grid"
            case .kota: "shield"
            case .progressionAndTransit: "arrow.triangle.swap"
            case .notesAndPredictions: "note.text"
            case .settings: "gearshape"
            }
        }

        static let library: [Destination] = [
            .allCharts,
            .recent,
        ]

        static let analysis: [Destination] = [
            .overview,
            .divisionalCharts,
            .planetsAndHouses,
            .strength,
            .ashtakavarga,
            .dasha,
            .nakshatra,
            .yogasAndDoshas,
        ]

        static let chakras: [Destination] = [
            .sarvatobhadra,
            .kota,
        ]

        static let tools: [Destination] = [
            .progressionAndTransit,
            .notesAndPredictions,
            .settings,
        ]
    }

    var chartID: UUID { activeChartID }
    var activeChartID: UUID
    var selectedLibraryChartID: UUID? {
        didSet {
            if let id = selectedLibraryChartID {
                Task {
                    await store.ensureChartLoaded(id: id)
                }
            }
        }
    }
    var destination: Destination? = .overview
    var isInspectorPresented = true
    var isPresentingNewChart = false
    var searchText = ""

    // Astrological Filters
    var filterLagna: Rasi? = nil
    var filterMoonRasi: Rasi? = nil
    var filterDashaLord: Graha? = nil
    var filterGender: String? = nil
    var isFilterPopoverPresented: Bool = false

    var isLibraryView: Bool {
        destination == .allCharts || destination == .recent
    }

    var hasActiveFilters: Bool {
        filterLagna != nil || filterMoonRasi != nil || filterDashaLord != nil || (filterGender != nil && filterGender != "All")
    }

    var activeFilterCount: Int {
        var count = 0
        if filterLagna != nil { count += 1 }
        if filterMoonRasi != nil { count += 1 }
        if filterDashaLord != nil { count += 1 }
        if filterGender != nil && filterGender != "All" { count += 1 }
        return count
    }

    func resetFilters() {
        filterLagna = nil
        filterMoonRasi = nil
        filterDashaLord = nil
        filterGender = nil
    }

    let store: ChartStore

    var chartDetail: ChartDetail? {
        store.chartDetail(for: activeChartID)
    }

    var selectedLibraryChartDetail: ChartDetail? {
        guard let id = selectedLibraryChartID else { return nil }
        guard visibleCharts.contains(where: { $0.id == id }) else { return nil }
        return store.chartDetail(for: id)
    }

    var inspectorChartDetail: ChartDetail? {
        if isLibraryView || destination == .settings {
            return destination == .settings ? nil : selectedLibraryChartDetail
        } else {
            return chartDetail
        }
    }

    var charts: [LibraryChartDisplayData] {
        store.chartsList
    }

    var visibleCharts: [LibraryChartDisplayData] {
        let baseList = destination == .recent ? Array(charts.prefix(10)) : charts
        return baseList.filter { chart in
            // Search text
            if !searchText.isEmpty {
                let matches = chart.name.localizedStandardContains(searchText)
                    || chart.location.localizedStandardContains(searchText)
                    || (chart.lagnaRasi?.localizedStandardContains(searchText) ?? false)
                    || (chart.moonNakshatra?.localizedStandardContains(searchText) ?? false)
                    || (chart.currentDasha?.localizedStandardContains(searchText) ?? false)
                if !matches { return false }
            }

            // Lagna filter
            if let filterLagna {
                guard let lagna = chart.lagnaRasi,
                      lagna.localizedCaseInsensitiveContains(filterLagna.sanskritName) ||
                      lagna.localizedCaseInsensitiveContains(filterLagna.englishName) else {
                    return false
                }
            }

            // Moon Sign filter
            if let filterMoonRasi {
                let matchesMoonRasi = chart.moonRasi.map {
                    $0.localizedCaseInsensitiveContains(filterMoonRasi.sanskritName) ||
                    $0.localizedCaseInsensitiveContains(filterMoonRasi.englishName)
                } ?? false

                if !matchesMoonRasi {
                    if let detail = store.chartDetail(for: chart.id),
                       let moon = detail.planets.first(where: { $0.graha == .moon }) {
                        if moon.rasi != filterMoonRasi { return false }
                    } else {
                        return false
                    }
                }
            }

            // Dasha Lord filter
            if let filterDashaLord {
                guard let dasha = chart.currentDasha,
                      dasha.localizedCaseInsensitiveContains(filterDashaLord.shortAbbreviation) ||
                      dasha.localizedCaseInsensitiveContains(filterDashaLord.sanskritName) ||
                      dasha.localizedCaseInsensitiveContains(filterDashaLord.rawValue) else {
                    return false
                }
            }

            // Gender filter
            if let filterGender, filterGender != "All" {
                guard let gender = chart.gender,
                      gender.localizedCaseInsensitiveCompare(filterGender) == .orderedSame else {
                    return false
                }
            }

            return true
        }
    }

    init(chartID: UUID = GoldenChartFixtures.tagoreID, store: ChartStore = .shared) {
        self.activeChartID = chartID
        self.selectedLibraryChartID = chartID
        self.store = store
    }

    func selectAndOpenChart(_ id: UUID) {
        self.activeChartID = id
        self.selectedLibraryChartID = id
        self.destination = .overview
        Task {
            await store.ensureChartLoaded(id: id)
        }
    }

    func deleteChart(id: UUID) {
        store.deleteChart(id: id)
        if selectedLibraryChartID == id {
            selectedLibraryChartID = visibleCharts.first(where: { $0.id != id })?.id
        }
        if activeChartID == id {
            if let nextID = store.chartsList.first(where: { $0.id != id })?.id {
                activeChartID = nextID
            }
        }
    }
}
