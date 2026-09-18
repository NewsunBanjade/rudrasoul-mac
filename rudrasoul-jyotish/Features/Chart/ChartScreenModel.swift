import Foundation
import Observation

/// One open chart in the workspace tab strip.
struct ChartTab: Identifiable, Hashable, Sendable {
    let id: UUID
    let chartID: UUID
    /// The analysis page this tab was last showing.
    var destination: ChartScreenModel.Destination

    init(id: UUID = UUID(), chartID: UUID, destination: ChartScreenModel.Destination = .overview) {
        self.id = id
        self.chartID = chartID
        self.destination = destination
    }
}

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
        case jaimini

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
            case .jaimini: "point.3.connected.trianglepath.dotted"
            case .sarvatobhadra: "grid"
            case .kota: "shield"
            case .progressionAndTransit: "arrow.triangle.swap"
            case .notesAndPredictions: "note.text"
            case .settings: "gearshape"
            }
        }

        /// The library list pages.
        var isLibrary: Bool {
            self == .allCharts || self == .recent
        }

        /// Pages that show one chart and therefore belong to a chart tab.
        var isChartPage: Bool {
            !isLibrary && self != .settings
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
            .jaimini,
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

    // MARK: - Open charts (tabs)

    /// Every open chart, in strip order.
    private(set) var tabs: [ChartTab] = []

    /// The tab whose chart the analysis pages show. It stays set while the library or the
    /// settings are visible so that returning to an analysis page restores the same chart.
    private(set) var selectedTabID: UUID?

    var selectedTab: ChartTab? {
        tabs.first { $0.id == selectedTabID }
    }

    /// The chart shown on the analysis pages; nil when no chart is open.
    var activeChartID: UUID? {
        selectedTab?.chartID
    }

    var chartID: UUID? { activeChartID }

    /// The tab to highlight in the strip: only while an analysis page is showing.
    var highlightedTabID: UUID? {
        (destination?.isChartPage ?? false) ? selectedTabID : nil
    }

    var selectedLibraryChartID: UUID? {
        didSet {
            if let id = selectedLibraryChartID {
                Task {
                    await store.ensureChartLoaded(id: id)
                }
            }
        }
    }

    /// The sidebar selection. Changing it to an analysis page keeps the open tab in step.
    var destination: Destination? = .allCharts {
        didSet {
            syncTabs(to: destination)
        }
    }

    var isInspectorPresented = true
    var isPresentingNewChart = false
    var searchText = ""

    // MARK: - Recalculation

    private(set) var isRecalculating = false
    var recalculationError: String?

    // MARK: - Astrological filters

    var filterLagna: Rasi? = nil
    var filterMoonRasi: Rasi? = nil
    var filterDashaLord: Graha? = nil
    var filterGender: String? = nil
    var isFilterPopoverPresented: Bool = false

    var isLibraryView: Bool {
        destination?.isLibrary ?? false
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
        guard let activeChartID else { return nil }
        return store.chartDetail(for: activeChartID)
    }

    var selectedLibraryChartDetail: ChartDetail? {
        guard let id = selectedLibraryChartID else { return nil }
        guard visibleCharts.contains(where: { $0.id == id }) else { return nil }
        return store.chartDetail(for: id)
    }

    var inspectorChartDetail: ChartDetail? {
        guard let destination else { return nil }
        if destination.isLibrary {
            return selectedLibraryChartDetail
        }
        if destination == .settings {
            return nil
        }
        return chartDetail
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

    /// Starts in the library; with a `chartID` the chart is opened in a tab on its Overview.
    init(chartID: UUID? = nil, store: ChartStore = .shared) {
        self.store = store
        if let chartID {
            let tab = ChartTab(chartID: chartID)
            tabs = [tab]
            selectedTabID = tab.id
            selectedLibraryChartID = chartID
            destination = .overview
        }
    }

    // MARK: - Tab actions

    /// Opens a chart in a new tab, or brings its existing tab forward, on `destination`.
    func openChart(_ id: UUID, destination: Destination = .overview) {
        selectedLibraryChartID = id
        if let existing = tabs.first(where: { $0.chartID == id }) {
            selectedTabID = existing.id
        } else {
            appendTab(chartID: id, destination: destination)
        }
        self.destination = destination
    }

    func selectAndOpenChart(_ id: UUID) {
        openChart(id)
    }

    func selectTab(_ tabID: UUID) {
        guard let tab = tabs.first(where: { $0.id == tabID }) else { return }
        selectedTabID = tabID
        selectedLibraryChartID = tab.chartID
        destination = tab.destination
    }

    func closeTab(_ tabID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        tabs.remove(at: index)
        guard selectedTabID == tabID else { return }
        let showingChart = destination?.isChartPage ?? false
        if tabs.isEmpty {
            selectedTabID = nil
            if showingChart {
                destination = .allCharts
            }
        } else {
            let next = tabs[min(index, tabs.count - 1)]
            selectedTabID = next.id
            if showingChart {
                destination = next.destination
            }
        }
    }

    /// Closes the tab shown by the current analysis page; does nothing elsewhere.
    func closeSelectedTab() {
        guard let highlightedTabID else { return }
        closeTab(highlightedTabID)
    }

    func closeOtherTabs(keeping tabID: UUID) {
        for tab in tabs where tab.id != tabID {
            closeTab(tab.id)
        }
    }

    func closeAllTabs() {
        for tab in tabs {
            closeTab(tab.id)
        }
    }

    /// Moves to the next (`offset` 1) or previous (`offset` -1) tab, wrapping around.
    func selectAdjacentTab(offset: Int) {
        guard !tabs.isEmpty else { return }
        let currentIndex = tabs.firstIndex(where: { $0.id == selectedTabID }) ?? (offset > 0 ? tabs.count - 1 : 0)
        let count = tabs.count
        let nextIndex = ((currentIndex + offset) % count + count) % count
        selectTab(tabs[nextIndex].id)
    }

    func showLibrary() {
        destination = .allCharts
    }

    /// The tab title: the chart name once loaded, else its library name, else a placeholder.
    func title(for tab: ChartTab) -> String {
        if let detail = store.chartDetail(for: tab.chartID) {
            return detail.name
        }
        if let item = store.chartsList.first(where: { $0.id == tab.chartID }) {
            return item.name
        }
        return "Chart"
    }

    private func appendTab(chartID: UUID, destination: Destination) {
        let tab = ChartTab(chartID: chartID, destination: destination)
        tabs.append(tab)
        selectedTabID = tab.id
        Task {
            await store.ensureChartLoaded(id: chartID)
        }
    }

    /// Keeps the tabs consistent with a sidebar choice: an analysis page is remembered on the
    /// selected tab; if no tab is selected the most recent one is used; if none is open the
    /// highlighted library chart (or the first chart) is opened.
    private func syncTabs(to destination: Destination?) {
        guard let destination, destination.isChartPage else { return }
        if let index = tabs.firstIndex(where: { $0.id == selectedTabID }) {
            tabs[index].destination = destination
        } else if let last = tabs.last {
            selectedTabID = last.id
            tabs[tabs.count - 1].destination = destination
        } else if let chartID = selectedLibraryChartID ?? store.chartsList.first?.id {
            appendTab(chartID: chartID, destination: destination)
        }
    }

    // MARK: - Chart actions

    func recalculateChart(id: UUID) {
        guard !isRecalculating else { return }
        isRecalculating = true
        recalculationError = nil
        Task {
            do {
                try await store.recalculateChart(id: id)
            } catch {
                recalculationError = error.localizedDescription
            }
            isRecalculating = false
        }
    }

    func recalculateActiveChart() {
        guard let activeChartID else { return }
        recalculateChart(id: activeChartID)
    }

    func deleteChart(id: UUID) {
        for tab in tabs where tab.chartID == id {
            closeTab(tab.id)
        }
        store.deleteChart(id: id)
        if selectedLibraryChartID == id {
            selectedLibraryChartID = visibleCharts.first(where: { $0.id != id })?.id
        }
    }
}
