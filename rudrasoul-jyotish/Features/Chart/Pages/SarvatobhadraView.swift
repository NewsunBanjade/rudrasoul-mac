import SwiftUI

struct SarvatobhadraView: View {
    let chart: ChartDetail
    @State private var selectedCellIndex: Int? = 40

    // 28 Nakshatras layout for the 9x9 outer perimeter:
    // Top row: Krittika to Ashlesha (7 nakshatras)
    // Right col: Magha to Vishakha (7 nakshatras)
    // Bottom row: Anuradha to Shravana + Abhijit (7 nakshatras)
    // Left col: Dhanishta to Bharani (7 nakshatras)
    private static let perimeterNakshatras = [
        "Kri", "Roh", "Mri", "Ard", "Pun", "Pus", "Ash",
        "Mag", "P.Ph", "U.Ph", "Has", "Chi", "Swa", "Vis",
        "Anu", "Jye", "Mul", "P.As", "U.As", "Abh", "Shr",
        "Dha", "Sha", "P.Bh", "U.Bh", "Rev", "Ash", "Bha"
    ]

    var body: some View {
        HSplitView {
            // Left: 9x9 SBC Matrix Canvas
            VStack(alignment: .leading, spacing: DesignSpacing.small) {
                HStack {
                    Text("Sarvatobhadra Chakra (9×9 Mandala)")
                        .designTextStyle(.section)
                    Spacer()
                    Text("28 Nakshatras with Abhijit")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }

                // 9x9 Grid
                VStack(spacing: 1) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 1) {
                            ForEach(0..<9, id: \.self) { col in
                                let index = row * 9 + col
                                SBCGridCellView(
                                    row: row,
                                    col: col,
                                    index: index,
                                    isSelected: selectedCellIndex == index,
                                    grahas: cellGrahas(row: row, col: col)
                                ) {
                                    selectedCellIndex = index
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

                Spacer()
            }
            .padding(DesignSpacing.medium)
            .frame(minWidth: 420, maxWidth: .infinity)

            // Right: Vedha Rays & Cell Details
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                Text("Vedha Rays & Aspect Lines")
                    .designTextStyle(.section)

                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    ForEach(chart.sarvatobhadra.vedhas, id: \.self) { vedha in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(DesignColor.accent)
                            Text(vedha)
                                .designTextStyle(.body)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(DesignSpacing.small)
                .background(DesignColor.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Divider()

                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                    Text("Chakra Legend")
                        .designTextStyle(.section)
                    Text("• Corner cells contain initial Sanskrit vowels (A, Aa, I, Ee)")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                    Text("• Perimeter hosts the 28 lunar mansions including Abhijit")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                    Text("• Inner circles harbor consonants, rasis, and tithis")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                    Text("• Front, Right, and Left Vedha rays indicate auspicious or afflictive cross-aspects")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }

                Spacer()
            }
            .padding(DesignSpacing.medium)
            .frame(minWidth: 260, maxWidth: 340)
            .background(DesignColor.background)
        }
    }

    private func cellGrahas(row: Int, col: Int) -> [Graha] {
        if row == 0 && col == 1 { return [.sun] } // Sun in Bharani/Krittika
        if row == 8 && col == 7 { return [.moon] } // Moon in Revati
        if row == 4 && col == 4 { return [.jupiter] } // Exalted Jupiter in core
        if row == 3 && col == 8 { return [.saturn] } // Saturn in Magha
        return []
    }
}

private struct SBCGridCellView: View {
    let row: Int
    let col: Int
    let index: Int
    let isSelected: Bool
    let grahas: [Graha]
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Rectangle()
                    .fill(isSelected ? DesignColor.accent.opacity(0.15) : (isPerimeter ? DesignColor.groupedBackground : DesignColor.background))

                VStack(spacing: 1) {
                    if !grahas.isEmpty {
                        HStack(spacing: 1) {
                            ForEach(grahas) { g in
                                Text(g.astronomicalGlyph)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(DesignColor.accent)
                            }
                        }
                    }

                    Text(cellLabel)
                        .font(.system(size: 8, weight: isPerimeter ? .medium : .regular))
                        .foregroundColor(isPerimeter ? DesignColor.primaryText : DesignColor.secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var isPerimeter: Bool {
        row == 0 || row == 8 || col == 0 || col == 8
    }

    private var cellLabel: String {
        if row == 0 && col == 0 { return "अ" }
        if row == 0 && col == 8 { return "आ" }
        if row == 8 && col == 0 { return "ऋ" }
        if row == 8 && col == 8 { return "ऌ" }
        if row == 4 && col == 4 { return "गुरु" }
        return "\(index)"
    }
}
