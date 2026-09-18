import SwiftUI

/// The trailing inspector: identity, Lagna, ayanamsa, the running period, coordinates,
/// and a Shadbala summary of the chart in focus.
struct ChartInspector: View {
    let chart: ChartDetail?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
            Text("chart.inspector.title")
                .designTextStyle(.section)

            if let chart {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSpacing.small) {
                        MetricTile(
                            title: "Native Subject",
                            value: chart.name,
                            subtitle: "\(chart.gender) · \(chart.calendarSystem)",
                            badge: "Natal"
                        )

                        MetricTile(
                            title: "Ascendant (Lagna)",
                            value: "\(chart.lagnaPosition.rasi.sanskritName) \(chart.lagnaPosition.formattedDMS)",
                            subtitle: "\(chart.lagnaPosition.nakshatra.name) Pada \(chart.lagnaPosition.pada)",
                            badge: "1st House"
                        )

                        MetricTile(
                            title: "Ayanamsa Offset",
                            value: chart.ayanamsaValueDMS.isEmpty ? "—" : chart.ayanamsaValueDMS,
                            subtitle: chart.ayanamsaName,
                            badge: "Sidereal"
                        )

                        MetricTile(
                            title: "Running Vimshottari Period",
                            value: chart.currentDashaVector.components(separatedBy: "›").prefix(2).joined(separator: "› "),
                            subtitle: chart.currentDashaVector,
                            badge: "Running",
                            isAuspicious: true
                        )

                        Divider().padding(.vertical, DesignSpacing.xSmall)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Birth Coordinates")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Text("\(chart.latitude), \(chart.longitude)")
                                .designTextStyle(.body, monospacedDigits: true)
                            Text(chart.timezoneString)
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                        }

                        Divider().padding(.vertical, DesignSpacing.xSmall)

                        strengthSummary(for: chart)
                    }
                }
            } else {
                ContentUnavailableView(
                    "chart.inspector.unavailable.title",
                    systemImage: "info.circle",
                    description: Text("chart.inspector.unavailable.description")
                )
                Spacer()
            }
        }
        .padding(DesignSpacing.medium)
        .background(DesignColor.groupedBackground)
    }

    @ViewBuilder
    private func strengthSummary(for chart: ChartDetail) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Shadbala")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
            if let strongest = chart.shadbala.min(by: { $0.rank < $1.rank }),
               let weakest = chart.shadbala.max(by: { $0.rank < $1.rank }) {
                Text("Strongest: \(strongest.graha.sanskritName) · \(String(format: "%.2f", strongest.totalRupas)) rupas")
                    .designTextStyle(.body, monospacedDigits: true)
                    .fontWeight(.medium)
                Text("Weakest: \(weakest.graha.sanskritName) · \(String(format: "%.2f", weakest.totalRupas)) rupas")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.secondaryText)
            } else {
                Text("Not computed for this chart. Use Recalculate to add Shadbala, Bhava Bala and Ashtakavarga.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
        }
    }
}
