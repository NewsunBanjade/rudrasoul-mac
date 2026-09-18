import SwiftUI

/// Kota Chakra page: the fortress mandala counted from the Janma nakshatra, the
/// Kota Swami and Kota Pala, the zone occupants, and the entering/exiting planets.
///
/// Charts saved before the calculator existed carry no cells, so the chakra is
/// then derived on the fly from the D-1 positions with the pure calculator.
struct KotaView: View {
    let chart: ChartDetail

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                HStack {
                    Text("Kota Chakra")
                        .designTextStyle(.section)
                    Spacer()
                    Text("Janma nakshatra: \(janma.name)")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }

                KotaChakraCanvas(cells: cells, janma: janma)
                    .frame(maxWidth: 520, maxHeight: 520)

                Text("Nakshatras are counted from the Janma nakshatra along four legs; the 4th, 11th, 18th and 25th form the Stambha. Planets on a diagonal leg move inward (Pravesha), those on a cardinal leg move outward (Nirgama); retrograde motion reverses this.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)

                Spacer()
            }
            .padding(DesignSpacing.medium)
            .frame(minWidth: 400, maxWidth: .infinity)

            detailPane
                .padding(DesignSpacing.medium)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 380)
                .background(DesignColor.background)
        }
    }

    // MARK: - Data

    private var kota: KotaChakraData {
        if chart.kota.cells != nil {
            return chart.kota
        }
        return KotaChakraCalculator.calculate(planets: chart.planets, lagna: chart.lagnaPosition)
    }

    private var cells: [KotaCell] {
        kota.cells ?? []
    }

    private var janma: Nakshatra {
        kota.janmaNakshatra ?? chart.planets.first(where: { $0.graha == .moon })?.nakshatra ?? chart.lagnaPosition.nakshatra
    }

    private func natalPlacement(of graha: Graha) -> String {
        guard let position = chart.planets.first(where: { $0.graha == graha }) else { return "—" }
        return "\(position.rasi.sanskritName) \(position.formattedDMS) · Bhava \(position.bhava)"
    }

    // MARK: - Detail pane

    private var detailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                Text("Fortress dignitaries")
                    .designTextStyle(.section)

                MetricTile(
                    title: "Kota Swami (lord of the Moon sign)",
                    value: kota.kotaSwami.sanskritName,
                    subtitle: natalPlacement(of: kota.kotaSwami),
                    badge: "Swami"
                )
                MetricTile(
                    title: "Kota Pala (lord of the Janma nakshatra)",
                    value: kota.kotaPala.sanskritName,
                    subtitle: natalPlacement(of: kota.kotaPala),
                    badge: "Pala"
                )

                Divider()

                Text("Occupants by zone")
                    .designTextStyle(.section)
                Grid(alignment: .leading, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
                    ForEach(KotaChakraData.Zone.allCases) { zone in
                        GridRow(alignment: .firstTextBaseline) {
                            Text(zone.rawValue)
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Text(grahaList(kota.zoneAssignments[zone] ?? []))
                                .designTextStyle(.body)
                        }
                    }
                }

                Divider()

                Text("Direction of movement (Gati)")
                    .designTextStyle(.section)
                movementRow(title: "Pravesha (entering)", systemImage: "arrow.down.right", color: DesignColor.benefic, grahas: kota.praveshaGrahas)
                movementRow(title: "Nirgama (exiting)", systemImage: "arrow.up.right", color: DesignColor.malefic, grahas: kota.nirgamaGrahas)

                Divider()

                Text("Cells from Janma")
                    .designTextStyle(.section)
                Grid(alignment: .leading, horizontalSpacing: DesignSpacing.small, verticalSpacing: 2) {
                    ForEach(cells) { cell in
                        GridRow(alignment: .firstTextBaseline) {
                            Text("\(cell.sequence)")
                                .designTextStyle(.caption, monospacedDigits: true)
                                .foregroundStyle(DesignColor.secondaryText)
                            Text(cell.nakshatra.name)
                                .designTextStyle(.caption)
                            Text(KotaChakraCanvas.zoneShortName(cell.zone))
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Text(cell.grahas.isEmpty ? "" : grahaList(cell.grahas))
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.accent)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func movementRow(title: String, systemImage: String, color: Color, grahas: [Graha]) -> some View {
        HStack(alignment: .top, spacing: DesignSpacing.small) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                Text(grahaList(grahas))
                    .designTextStyle(.body)
            }
        }
    }

    private func grahaList(_ grahas: [Graha]) -> String {
        grahas.isEmpty ? "—" : grahas.map(\.sanskritName).joined(separator: ", ")
    }
}
