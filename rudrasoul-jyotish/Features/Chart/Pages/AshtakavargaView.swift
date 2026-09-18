import SwiftUI

/// Bhinnashtakavarga of the seven planets and the Sarvashtakavarga, sign by sign from
/// the Lagna. Nothing is shown for charts that carry no Ashtakavarga instead of a default.
struct AshtakavargaView: View {
    let chart: ChartDetail

    private let planets = AshtakavargaCalculator.contributingPlanets

    var body: some View {
        if data.sarvashtakavarga.isEmpty || data.bhinnashtakavarga.isEmpty {
            StrengthUnavailableView(
                title: "Ashtakavarga not computed",
                systemImage: "arrow.up.and.down.text.horizontal",
                description: "This chart was saved before Ashtakavarga was calculated. Recalculate it to add the bindus."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignColor.background)
        } else {
            content
        }
    }

    private var data: AshtakavargaData {
        chart.ashtakavarga
    }

    /// The twelve signs in house order from the Lagna.
    private var orderedRasis: [Rasi] {
        (0 ..< 12).map { chart.lagnaPosition.rasi.advanced(by: $0) }
    }

    private func sign(of graha: Graha) -> Rasi? {
        chart.planets.first { $0.graha == graha }?.rasi
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.large) {
                header
                bindusGrid
                houseStrip
                Text("BPHS Ch. 66–67: a sign with 28 or more Sarvashtakavarga bindus, or 4 or more bindus in a planet's own Bhinnashtakavarga, supports that planet's transit through it; fewer bindus point to obstruction. ● marks the sign the planet occupies at birth.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignSpacing.medium)
        }
        .background(DesignColor.background)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ashtakavarga")
                    .designTextStyle(.section)
                Text("Sarvashtakavarga total \(data.totalBindus) bindus (337 expected) · signs in house order from \(chart.lagnaPosition.rasi.sanskritName) Lagna")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            Spacer()
        }
    }

    // MARK: - BAV / SAV grid

    private var bindusGrid: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .center, horizontalSpacing: DesignSpacing.small, verticalSpacing: DesignSpacing.xSmall) {
                GridRow {
                    headerCell("Graha").gridColumnAlignment(.leading)
                    ForEach(Array(orderedRasis.enumerated()), id: \.offset) { index, rasi in
                        VStack(spacing: 1) {
                            Text("H\(index + 1)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(DesignColor.accent)
                            Text(rasi.sanskritName)
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                        }
                    }
                    headerCell("Total")
                }

                ForEach(planets) { planet in
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        HStack(spacing: 4) {
                            Text(planet.astronomicalGlyph)
                            Text(planet.sanskritName)
                                .fontWeight(.medium)
                        }
                        .designTextStyle(.body)

                        ForEach(orderedRasis) { rasi in
                            bavCell(planet: planet, rasi: rasi)
                        }

                        Text("\(data.bhinnashtakavarga[planet]?.values.reduce(0, +) ?? 0)")
                            .designTextStyle(.body, monospacedDigits: true)
                            .foregroundStyle(DesignColor.secondaryText)
                    }
                }

                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    Text("Sarvashtakavarga")
                        .designTextStyle(.body)
                        .fontWeight(.semibold)
                    ForEach(orderedRasis) { rasi in
                        savCell(rasi: rasi)
                    }
                    Text("\(data.totalBindus)")
                        .designTextStyle(.body, monospacedDigits: true)
                        .fontWeight(.semibold)
                }
            }
            .padding(DesignSpacing.small)
            .background(DesignColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignColor.separator, lineWidth: 1)
            )
        }
    }

    private func headerCell(_ title: String) -> some View {
        Text(title)
            .designTextStyle(.caption)
            .foregroundStyle(DesignColor.secondaryText)
    }

    @ViewBuilder
    private func bavCell(planet: Graha, rasi: Rasi) -> some View {
        if let bindus = data.bhinnashtakavarga[planet]?[rasi] {
            let occupied = sign(of: planet) == rasi
            HStack(spacing: 2) {
                Text("\(bindus)")
                    .designTextStyle(.body, monospacedDigits: true)
                    .fontWeight(occupied ? .semibold : .regular)
                    .foregroundStyle(bavColor(bindus))
                if occupied {
                    Text("●")
                        .font(.system(size: 7))
                        .foregroundStyle(DesignColor.accent)
                }
            }
            .frame(minWidth: 40)
            .help(occupied ? "\(planet.sanskritName) is placed in \(rasi.sanskritName) at birth" : "")
        } else {
            Text("—")
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.secondaryText)
                .frame(minWidth: 40)
        }
    }

    @ViewBuilder
    private func savCell(rasi: Rasi) -> some View {
        if let bindus = data.sarvashtakavarga[rasi] {
            Text("\(bindus)")
                .designTextStyle(.body, monospacedDigits: true)
                .fontWeight(.semibold)
                .foregroundStyle(savColor(bindus))
                .frame(minWidth: 40)
                .padding(.vertical, 2)
                .background(savColor(bindus).opacity(bindus >= 28 || bindus < 25 ? 0.12 : 0))
                .clipShape(RoundedRectangle(cornerRadius: 3))
        } else {
            Text("—")
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.secondaryText)
                .frame(minWidth: 40)
        }
    }

    private func bavColor(_ bindus: Int) -> Color {
        if bindus >= 5 { return DesignColor.benefic }
        if bindus <= 2 { return DesignColor.malefic }
        return DesignColor.primaryText
    }

    private func savColor(_ bindus: Int) -> Color {
        if bindus >= 28 { return DesignColor.benefic }
        if bindus < 25 { return DesignColor.malefic }
        return DesignColor.primaryText
    }

    // MARK: - SAV by house

    private var houseStrip: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            Text("Sarvashtakavarga by house")
                .designTextStyle(.section)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSpacing.small), count: 6), spacing: DesignSpacing.small) {
                ForEach(Array(orderedRasis.enumerated()), id: \.offset) { index, rasi in
                    let bindus = data.sarvashtakavarga[rasi]
                    VStack(spacing: 2) {
                        Text("House \(index + 1)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(DesignColor.accent)
                        Text(rasi.sanskritName)
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)
                        Text(bindus.map { "\($0)" } ?? "—")
                            .designTextStyle(.title, monospacedDigits: true)
                            .foregroundStyle(bindus.map(savColor) ?? DesignColor.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSpacing.small)
                    .background(DesignColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DesignColor.separator, lineWidth: 1)
                    )
                }
            }
        }
    }
}
