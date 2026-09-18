import Foundation
import Observation

@MainActor
@Observable
final class LibraryScreenModel {
    enum Destination: Hashable {
        case allCharts
        case recent
    }

    private(set) var charts: [LibraryChartDisplayData] = []
    private(set) var errorMessage: String?
    var destination: Destination? = .allCharts
    var selectedChartID: LibraryChartDisplayData.ID?
    var searchText = ""

    // Astrological Filters
    var filterLagna: Rasi? = nil
    var filterMoonRasi: Rasi? = nil
    var filterDashaLord: Graha? = nil
    var filterGender: String? = nil
    var isFilterPopoverPresented: Bool = false

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

    private let library: any LibraryProviding

    init(library: any LibraryProviding) {
        self.library = library
    }

    var visibleCharts: [LibraryChartDisplayData] {
        let destinationCharts = switch destination {
        case .allCharts, .none:
            charts
        case .recent:
            Array(charts.prefix(10))
        }

        return destinationCharts.filter { chart in
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
                guard let moonRasi = chart.moonRasi,
                      moonRasi.localizedCaseInsensitiveContains(filterMoonRasi.sanskritName) ||
                      moonRasi.localizedCaseInsensitiveContains(filterMoonRasi.englishName) else {
                    return false
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

    var chartCount: Int {
        visibleCharts.count
    }

    func load() async {
        do {
            charts = try await library.charts()
            errorMessage = nil
        } catch {
            charts = []
            errorMessage = String(localized: "library.error.load")
        }
    }
}
