import SwiftUI

/// Gochara: the transiting positions at a chosen instant, computed from the ephemeris
/// with the chart's own ayanamsa and node setting, against the natal positions.
struct ProgressionTransitView: View {
    let chart: ChartDetail

    @State private var transitDate = Date()
    @State private var transitPositions: [PlanetPosition] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            if let errorMessage {
                ContentUnavailableView(
                    "Transit positions unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                transitTable
                    .overlay {
                        if isLoading && transitPositions.isEmpty {
                            ProgressView("Calculating transits…")
                                .controlSize(.small)
                        }
                    }
                footer
            }
        }
        .background(DesignColor.background)
        .task(id: transitDate) {
            await loadTransits()
        }
    }

    // MARK: - Loading

    private func loadTransits() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let positions = try await ChartCalculationService().transitPositions(
                at: transitDate,
                ayanamsa: chart.ephemerisAyanamsa,
                nodeCalculation: chart.ephemerisNodeCalculation
            )
            transitPositions = positions
            errorMessage = nil
        } catch is CancellationError {
            // A newer date superseded this request.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Rows

    private struct TransitRow: Identifiable {
        var id: String { transit.graha.rawValue }
        let natal: PlanetPosition?
        let transit: PlanetPosition
    }

    private var rows: [TransitRow] {
        transitPositions.map { transit in
            TransitRow(natal: chart.planets.first { $0.graha == transit.graha }, transit: transit)
        }
    }

    private var natalMoonRasi: Rasi? {
        chart.planets.first { $0.graha == .moon }?.rasi
    }

    private func houseFromMoon(_ rasi: Rasi) -> Int? {
        natalMoonRasi.map { $0.count(to: rasi) }
    }

    private func houseFromLagna(_ rasi: Rasi) -> Int {
        chart.lagnaPosition.rasi.count(to: rasi)
    }

    /// Houses from the natal Moon in which each planet's transit is favourable
    /// (Phaladeepika Ch. 26, vv. 1–2; Rahu and Ketu by the common 3, 6, 11 rule).
    private func favourableHousesFromMoon(_ graha: Graha) -> [Int] {
        switch graha {
        case .sun: [3, 6, 10, 11]
        case .moon: [1, 3, 6, 7, 10, 11]
        case .mars: [3, 6, 11]
        case .mercury: [2, 4, 6, 8, 10, 11]
        case .jupiter: [2, 5, 7, 9, 11]
        case .venus: [1, 2, 3, 4, 5, 8, 9, 11, 12]
        case .saturn: [3, 6, 11]
        case .rahu, .ketu: [3, 6, 11]
        case .ascendant: []
        }
    }

    // MARK: - Subviews

    private var toolbar: some View {
        HStack {
            Text("Transit instant:")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)

            TransitDateStepper(date: $transitDate)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer()

            Text("Ayanamsa: \(chart.ayanamsaName) · \(chart.nodeCalculation)")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
        }
        .padding(.horizontal, DesignSpacing.medium)
        .padding(.vertical, DesignSpacing.small)
        .background(DesignColor.groupedBackground)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var transitTable: some View {
        Table(rows) {
            TableColumn("Graha") { row in
                HStack(spacing: 4) {
                    Text(row.transit.graha.astronomicalGlyph)
                    Text(row.transit.graha.sanskritName)
                        .fontWeight(.medium)
                }
                .designTextStyle(.body)
            }
            .width(min: 110, ideal: 130)

            TableColumn("Natal") { row in
                if let natal = row.natal {
                    Text("\(natal.rasi.sanskritName) \(natal.formattedDMS)")
                        .designTextStyle(.body, monospacedDigits: true)
                } else {
                    Text("—")
                        .designTextStyle(.body)
                        .foregroundStyle(DesignColor.secondaryText)
                }
            }
            .width(min: 150, ideal: 180)

            TableColumn("Transit (gochara)") { row in
                HStack(spacing: 4) {
                    Text("\(row.transit.rasi.sanskritName) \(row.transit.formattedDMS)")
                        .designTextStyle(.body, monospacedDigits: true)
                        .foregroundStyle(DesignColor.transit)
                    if row.transit.isRetrograde {
                        Text("R")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignColor.accent)
                    }
                    if row.transit.isCombust {
                        Text("C")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignColor.malefic)
                    }
                }
            }
            .width(min: 170, ideal: 200)

            TableColumn("Nakshatra") { row in
                Text("\(row.transit.nakshatra.name) · \(row.transit.pada)")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 130, ideal: 150)

            TableColumn("From natal Moon") { row in
                Text(houseFromMoon(row.transit.rasi).map { "\($0)" } ?? "—")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 90, ideal: 110)

            TableColumn("From Lagna") { row in
                Text("\(houseFromLagna(row.transit.rasi))")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Gochara (from Moon)") { row in
                if let house = houseFromMoon(row.transit.rasi) {
                    let favourable = favourableHousesFromMoon(row.transit.graha).contains(house)
                    Text(favourable ? "Favourable" : "Unfavourable")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(favourable ? DesignColor.benefic : DesignColor.malefic)
                } else {
                    Text("—")
                        .designTextStyle(.body)
                        .foregroundStyle(DesignColor.secondaryText)
                }
            }
            .width(min: 120, ideal: 140)
        }
    }

    private var footer: some View {
        HStack {
            Text("Positions are sidereal, computed by Swiss Ephemeris for the chosen instant (UTC \(transitDate.formatted(.dateTime.year().month().day().hour().minute()))). Favourable houses follow Phaladeepika Ch. 26 without vedha.")
                .designTextStyle(.caption, monospacedDigits: true)
                .foregroundStyle(DesignColor.secondaryText)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, DesignSpacing.medium)
        .padding(.vertical, DesignSpacing.xSmall)
        .overlay(alignment: .top) { Divider() }
    }
}
