import Foundation

struct LibraryChartDisplayData: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let location: String
    let localDate: Date
    let calendar: Calendar.Identifier
    var lagnaRasi: String? = nil
    var moonNakshatra: String? = nil
    var moonRasi: String? = nil
    var currentDasha: String? = nil
    var gender: String? = nil
}

protocol LibraryProviding: Sendable {
    func charts() async throws -> [LibraryChartDisplayData]
}

/// The first Library fixture intentionally contains no chart records. Verified
/// birth data will replace it when the project's golden fixtures are available.
struct EmptyLibraryFixture: LibraryProviding {
    func charts() async throws -> [LibraryChartDisplayData] {
        []
    }
}
