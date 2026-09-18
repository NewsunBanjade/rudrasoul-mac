import SwiftUI

/// The 9 × 9 Sarvatobhadra Chakra grid. Cells are laid out row-major from
/// `SarvatobhadraData.Cell.row` / `.col`; the selected cell and the cells struck
/// by the current vedha lines are tinted.
struct SarvatobhadraGrid: View {
    let cells: [SarvatobhadraData.Cell]
    @Binding var selectedCellID: Int?
    var highlightedCellIDs: Set<Int> = []

    private static let gridSize = 9

    var body: some View {
        VStack(spacing: 1) {
            ForEach(0 ..< Self.gridSize, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0 ..< Self.gridSize, id: \.self) { col in
                        let id = row * Self.gridSize + col
                        if let cell = cellsByID[id] {
                            SarvatobhadraCellView(
                                cell: cell,
                                isSelected: selectedCellID == id,
                                isHighlighted: highlightedCellIDs.contains(id)
                            ) {
                                selectedCellID = selectedCellID == id ? nil : id
                            }
                        } else {
                            Rectangle().fill(DesignColor.background)
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(DesignColor.separator)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }

    private var cellsByID: [Int: SarvatobhadraData.Cell] {
        Dictionary(cells.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var accessibilityDescription: String {
        let occupied = cells.filter { !$0.occupyingGrahas.isEmpty }
        guard !occupied.isEmpty else { return "Sarvatobhadra Chakra with no placements." }
        let entries = occupied.flatMap { cell in
            cell.occupyingGrahas.map { "\($0.rawValue) in \(cell.label)" }
        }
        return "Sarvatobhadra Chakra. " + entries.joined(separator: ", ") + "."
    }
}

private struct SarvatobhadraCellView: View {
    let cell: SarvatobhadraData.Cell
    let isSelected: Bool
    let isHighlighted: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Rectangle().fill(fillColor)

                VStack(spacing: 1) {
                    if !cell.occupyingGrahas.isEmpty {
                        Text(cell.occupyingGrahas.map(\.shortAbbreviation).joined(separator: " "))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DesignColor.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Text(label)
                        .font(.caption2.weight(cell.nakshatra != nil ? .medium : .regular))
                        .foregroundStyle(cell.nakshatra != nil ? DesignColor.primaryText : DesignColor.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var label: String {
        if let nakshatra = cell.nakshatra { return nakshatra.chakraAbbreviation }
        if let rasi = cell.rasi { return rasi.chakraAbbreviation }
        return cell.label
    }

    private var fillColor: Color {
        if isSelected { return DesignColor.accent.opacity(0.22) }
        if isHighlighted { return DesignColor.transit.opacity(0.18) }
        return cell.nakshatra != nil ? DesignColor.groupedBackground : DesignColor.background
    }

    private var accessibilityText: String {
        let occupants = cell.occupyingGrahas.map(\.rawValue).joined(separator: ", ")
        return occupants.isEmpty ? cell.label : "\(cell.label), \(occupants)"
    }
}
