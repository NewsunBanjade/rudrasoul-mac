import Foundation

protocol ChartRepository: Sendable {
    func fetchAllCharts() async throws -> [LibraryChartDisplayData]
    func fetchChartDetail(id: UUID) async throws -> ChartDetail?
    func saveChart(detail: ChartDetail) async throws
    func deleteChart(id: UUID) async throws
    func searchCharts(query: String) async throws -> [LibraryChartDisplayData]
    func countCharts() async throws -> Int
    func exportDatabase(to destinationURL: URL) async throws
    func restoreDatabase(from sourceURL: URL) async throws
    func seedFixturesIfEmpty() async throws
}
