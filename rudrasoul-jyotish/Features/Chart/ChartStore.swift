import Foundation
import Observation
import os


@MainActor
@Observable
final class ChartStore: LibraryProviding {
    static let shared = ChartStore()

    private(set) var chartsList: [LibraryChartDisplayData] = []
    private var chartDetails: [UUID: ChartDetail] = [:]
    let repository: any ChartRepository

    init(repository: any ChartRepository = SQLiteChartRepository.shared) {
        self.repository = repository
        loadDefaultFixtures()
        Task {
            await reloadFromRepository()
        }
    }

    private func loadDefaultFixtures() {
        let tagore = GoldenChartFixtures.tagore
        let gandhi = GoldenChartFixtures.gandhi

        chartDetails[tagore.id] = tagore
        chartDetails[gandhi.id] = gandhi

        let tagoreMoon = tagore.planets.first(where: { $0.graha == .moon })
        let gandhiMoon = gandhi.planets.first(where: { $0.graha == .moon })

        chartsList = [
            LibraryChartDisplayData(
                id: tagore.id,
                name: tagore.name,
                location: tagore.locationName,
                localDate: tagore.birthDate,
                calendar: .gregorian,
                lagnaRasi: tagore.lagnaPosition.rasi.sanskritName,
                moonNakshatra: tagoreMoon?.nakshatra.name,
                moonRasi: tagoreMoon?.rasi.sanskritName,
                currentDasha: tagore.currentDashaVector,
                gender: tagore.gender
            ),
            LibraryChartDisplayData(
                id: gandhi.id,
                name: gandhi.name,
                location: gandhi.locationName,
                localDate: gandhi.birthDate,
                calendar: .gregorian,
                lagnaRasi: gandhi.lagnaPosition.rasi.sanskritName,
                moonNakshatra: gandhiMoon?.nakshatra.name,
                moonRasi: gandhiMoon?.rasi.sanskritName,
                currentDasha: gandhi.currentDashaVector,
                gender: gandhi.gender
            )
        ]
    }

    func reloadFromRepository() async {
        do {
            let repoCharts = try await repository.fetchAllCharts()
            if !repoCharts.isEmpty {
                self.chartsList = repoCharts
                for chart in repoCharts {
                    if chartDetails[chart.id] == nil {
                        if let detail = try? await repository.fetchChartDetail(id: chart.id) {
                            self.chartDetails[chart.id] = detail
                        }
                    }
                }
            }
        } catch {
            PersistenceLogger.store.error("Failed to reload charts from SQLite: \(error.localizedDescription)")
        }
    }

    func charts() async throws -> [LibraryChartDisplayData] {
        chartsList
    }

    func chartDetail(for id: UUID) -> ChartDetail? {
        chartDetails[id]
    }

    func ensureChartLoaded(id: UUID) async {
        guard chartDetails[id] == nil else { return }
        if let detail = try? await repository.fetchChartDetail(id: id) {
            chartDetails[id] = detail
        }
    }

    func saveChart(detail: ChartDetail) {
        chartDetails[detail.id] = detail
        let moon = detail.planets.first(where: { $0.graha == .moon })
        let item = LibraryChartDisplayData(
            id: detail.id,
            name: detail.name,
            location: detail.locationName,
            localDate: detail.birthDate,
            calendar: .gregorian,
            lagnaRasi: detail.lagnaPosition.rasi.sanskritName,
            moonNakshatra: moon?.nakshatra.name,
            moonRasi: moon?.rasi.sanskritName,
            currentDasha: detail.currentDashaVector,
            gender: detail.gender
        )
        chartsList.removeAll { $0.id == detail.id }
        chartsList.insert(item, at: 0)

        Task {
            do {
                try await repository.saveChart(detail: detail)
            } catch {
                PersistenceLogger.store.error("Failed to persist chart to SQLite: \(error.localizedDescription)")
            }
        }
    }

    func deleteChart(id: UUID) {
        chartDetails.removeValue(forKey: id)
        chartsList.removeAll { $0.id == id }

        Task {
            do {
                try await repository.deleteChart(id: id)
            } catch {
                PersistenceLogger.store.error("Failed to delete chart from SQLite: \(error.localizedDescription)")
            }
        }
    }
}
