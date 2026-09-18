import SwiftUI

/// Sarvatobhadra Chakra page: the 9 × 9 grid with the natal placements, the
/// vedha lines of a chosen planet or cell, and the details of the selected cell.
///
/// Charts saved before the calculator existed carry no cells, so the chakra is
/// then derived on the fly from the D-1 positions with the pure calculator.
struct SarvatobhadraView: View {
    let chart: ChartDetail
    @State private var selectedCellID: Int? = nil
    @State private var selectedGraha: Graha? = nil

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: DesignSpacing.small) {
                HStack {
                    Text("Sarvatobhadra Chakra")
                        .designTextStyle(.section)
                    Spacer()
                    Picker("Vedhas of", selection: $selectedGraha) {
                        Text("Selected cell").tag(Graha?.none)
                        ForEach(placedGrahas) { graha in
                            Text(graha.sanskritName).tag(Graha?.some(graha))
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .fixedSize()
                }

                SarvatobhadraGrid(
                    cells: data.cells,
                    selectedCellID: $selectedCellID,
                    highlightedCellIDs: highlightedCellIDs
                )
                .frame(maxWidth: 560, maxHeight: 560)

                Text("Outer ring: 28 nakshatras from Krittika, clockwise. Corners and the second ring: vowels and Avakahada letters. Third ring: rasis. Fourth ring: tithi groups with Purna at the centre. A planet strikes the cells on the straight line and both diagonals through its nakshatra.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)

                Spacer()
            }
            .padding(DesignSpacing.medium)
            .frame(minWidth: 420, maxWidth: .infinity)

            detailPane
                .padding(DesignSpacing.medium)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 380)
                .background(DesignColor.background)
        }
    }

    // MARK: - Data

    private var data: SarvatobhadraData {
        if chart.sarvatobhadra.cells.count == SarvatobhadraCalculator.gridSize * SarvatobhadraCalculator.gridSize {
            return chart.sarvatobhadra
        }
        return SarvatobhadraCalculator.calculate(planets: chart.planets, lagna: chart.lagnaPosition)
    }

    private var placedGrahas: [Graha] {
        Graha.allCases.filter { graha in
            graha != .ascendant && data.cells.contains { $0.occupyingGrahas.contains(graha) }
        }
    }

    private var selectedCell: SarvatobhadraData.Cell? {
        guard let selectedCellID else { return nil }
        return data.cells.first { $0.id == selectedCellID }
    }

    /// Cells struck by the chosen planet, or by the selected cell when no planet is chosen.
    private var highlightedCellIDs: Set<Int> {
        let source: SarvatobhadraData.Cell?
        if let selectedGraha {
            source = data.cells.first { $0.occupyingGrahas.contains(selectedGraha) }
        } else {
            source = selectedCell
        }
        guard let source else { return [] }
        return Set(SarvatobhadraCalculator.vedhas(from: source, in: data.cells).map(\.id))
    }

    private var vedhaDetails: [SarvatobhadraVedha] {
        let all = data.vedhaDetails ?? []
        guard let selectedGraha else { return all }
        return all.filter { $0.graha == selectedGraha }
    }

    // MARK: - Detail pane

    private var detailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                Text("Selected cell")
                    .designTextStyle(.section)
                if let cell = selectedCell {
                    cellFacts(cell)
                } else {
                    Text("Click a cell to see its contents and the lines through it.")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }

                Divider()

                Text(selectedGraha.map { "Vedhas of \($0.sanskritName)" } ?? "All vedhas")
                    .designTextStyle(.section)
                if vedhaDetails.isEmpty {
                    Text("No vedhas recorded.")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: DesignSpacing.small, verticalSpacing: 2) {
                        ForEach(vedhaDetails) { vedha in
                            GridRow(alignment: .firstTextBaseline) {
                                Text(vedha.graha.shortAbbreviation)
                                    .designTextStyle(.caption)
                                    .foregroundStyle(vedha.isBenefic ? DesignColor.benefic : DesignColor.malefic)
                                Text(vedha.direction.rawValue)
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.secondaryText)
                                Text(vedha.targetLabel)
                                    .designTextStyle(.caption)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cellFacts(_ cell: SarvatobhadraData.Cell) -> some View {
        Grid(alignment: .leading, horizontalSpacing: DesignSpacing.small, verticalSpacing: DesignSpacing.xSmall) {
            GridRow(alignment: .firstTextBaseline) {
                Text("Contents").designTextStyle(.caption).foregroundStyle(DesignColor.secondaryText)
                Text(cell.label).designTextStyle(.body)
            }
            GridRow(alignment: .firstTextBaseline) {
                Text("Kind").designTextStyle(.caption).foregroundStyle(DesignColor.secondaryText)
                Text(kindName(of: cell)).designTextStyle(.body)
            }
            GridRow(alignment: .firstTextBaseline) {
                Text("Occupants").designTextStyle(.caption).foregroundStyle(DesignColor.secondaryText)
                Text(cell.occupyingGrahas.isEmpty ? "—" : cell.occupyingGrahas.map(\.sanskritName).joined(separator: ", "))
                    .designTextStyle(.body)
            }
            GridRow(alignment: .firstTextBaseline) {
                Text("Struck cells").designTextStyle(.caption).foregroundStyle(DesignColor.secondaryText)
                Text("\(highlightedCellIDs.count)").designTextStyle(.body, monospacedDigits: true)
            }
        }
    }

    private func kindName(of cell: SarvatobhadraData.Cell) -> String {
        switch SarvatobhadraCalculator.kind(of: cell) {
        case .nakshatra: "Nakshatra"
        case .vowel: "Vowel"
        case .consonant: "Avakahada letter"
        case .rasi: "Rasi"
        case .tithi: "Tithi group"
        }
    }
}
