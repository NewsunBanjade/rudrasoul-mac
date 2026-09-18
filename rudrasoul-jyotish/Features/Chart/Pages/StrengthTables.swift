import SwiftUI

// Dense grids of the Strength page. Grids (not Tables) so that they take their natural
// height inside the page's scroll view and never scroll within themselves.

private func strengthHeader(_ title: String) -> some View {
    Text(title)
        .designTextStyle(.caption)
        .foregroundStyle(DesignColor.secondaryText)
}

private func strengthNumber(_ value: Double, decimals: Int = 1) -> some View {
    Text(String(format: "%.\(decimals)f", value))
        .designTextStyle(.body, monospacedDigits: true)
}

private func grahaCell(_ graha: Graha) -> some View {
    HStack(spacing: 4) {
        Text(graha.astronomicalGlyph)
        Text(graha.sanskritName)
            .fontWeight(.medium)
    }
    .designTextStyle(.body)
}

private struct StrengthGridBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSpacing.small)
            .background(DesignColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignColor.separator, lineWidth: 1)
            )
    }
}

// MARK: - Shadbala summary

struct ShadbalaSummaryTable: View {
    let rows: [ShadbalaBreakdown]

    var body: some View {
        Grid(alignment: .trailing, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
            GridRow {
                strengthHeader("Graha").gridColumnAlignment(.leading)
                strengthHeader("Sthana")
                strengthHeader("Dik")
                strengthHeader("Kala")
                strengthHeader("Cheshta")
                strengthHeader("Naisargika")
                strengthHeader("Drik")
                strengthHeader("Total (virupas)")
                strengthHeader("Rupas")
                strengthHeader("Required")
                strengthHeader("Rank")
            }
            ForEach(rows) { row in
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    grahaCell(row.graha)
                    strengthNumber(row.sthanaBala)
                    strengthNumber(row.dikBala)
                    strengthNumber(row.kalaBala)
                    strengthNumber(row.cheshtaBala)
                    strengthNumber(row.naisargikaBala)
                    strengthNumber(row.drikBala)
                    strengthNumber(row.totalVirupas)
                    Text(String(format: "%.2f", row.totalRupas))
                        .designTextStyle(.body, monospacedDigits: true)
                        .fontWeight(.semibold)
                        .foregroundStyle(row.isSufficient ? DesignColor.benefic : DesignColor.malefic)
                    strengthNumber(row.requiredRupas, decimals: 1)
                    Text("#\(row.rank)")
                        .designTextStyle(.body, monospacedDigits: true)
                        .foregroundStyle(row.rank == 1 ? DesignColor.accent : DesignColor.secondaryText)
                }
            }
        }
        .modifier(StrengthGridBox())
    }
}

// MARK: - Shadbala components

struct ShadbalaComponentsTable: View {
    let rows: [ShadbalaBreakdown]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .trailing, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
                GridRow {
                    strengthHeader("Graha").gridColumnAlignment(.leading)
                    strengthHeader("Uccha")
                    strengthHeader("Saptavargaja")
                    strengthHeader("Ojayugma")
                    strengthHeader("Kendradi")
                    strengthHeader("Drekkana")
                    strengthHeader("Nathonnatha")
                    strengthHeader("Paksha")
                    strengthHeader("Tribhaga")
                    strengthHeader("Abda")
                    strengthHeader("Masa")
                    strengthHeader("Vara")
                    strengthHeader("Hora")
                    strengthHeader("Ayana")
                    strengthHeader("Cheshta basis").gridColumnAlignment(.leading)
                }
                ForEach(rows) { row in
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        grahaCell(row.graha)
                        if let c = row.components {
                            strengthNumber(c.ucchaBala)
                            strengthNumber(c.saptavargajaBala)
                            strengthNumber(c.ojayugmaBala)
                            strengthNumber(c.kendradiBala)
                            strengthNumber(c.drekkanaBala)
                            strengthNumber(c.nathonnathaBala)
                            strengthNumber(c.pakshaBala)
                            strengthNumber(c.tribhagaBala)
                            strengthNumber(c.abdaBala)
                            strengthNumber(c.masaBala)
                            strengthNumber(c.varaBala)
                            strengthNumber(c.horaBala)
                            strengthNumber(c.ayanaBala)
                            Text(c.cheshtaNote)
                                .designTextStyle(.caption, monospacedDigits: true)
                                .foregroundStyle(DesignColor.secondaryText)
                        } else {
                            Text("Component detail is not stored for this chart; recalculate to add it.")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                                .gridCellColumns(14)
                        }
                    }
                }
            }
            .modifier(StrengthGridBox())
        }
    }
}

// MARK: - Bhava bala

struct BhavaBalaTable: View {
    let rows: [BhavaBala]

    var body: some View {
        Grid(alignment: .trailing, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
            GridRow {
                strengthHeader("House").gridColumnAlignment(.leading)
                strengthHeader("Rasi").gridColumnAlignment(.leading)
                strengthHeader("Lord").gridColumnAlignment(.leading)
                strengthHeader("Bhavadhipati")
                strengthHeader("Dig")
                strengthHeader("Drishti")
                strengthHeader("Total (virupas)")
                strengthHeader("Rupas")
                strengthHeader("Rank")
            }
            ForEach(rows) { row in
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    Text("\(row.house)")
                        .designTextStyle(.body, monospacedDigits: true)
                        .fontWeight(.medium)
                    Text(row.rasi.sanskritName)
                        .designTextStyle(.body)
                    grahaCell(row.lord)
                    strengthNumber(row.bhavadhipatiBala)
                    strengthNumber(row.bhavaDigBala)
                    strengthNumber(row.bhavaDrishtiBala)
                    strengthNumber(row.totalVirupas)
                    Text(String(format: "%.2f", row.totalRupas))
                        .designTextStyle(.body, monospacedDigits: true)
                        .fontWeight(.semibold)
                    Text("#\(row.rank)")
                        .designTextStyle(.body, monospacedDigits: true)
                        .foregroundStyle(row.rank == 1 ? DesignColor.accent : DesignColor.secondaryText)
                }
            }
        }
        .modifier(StrengthGridBox())
    }
}

// MARK: - Relationships

/// The 7 × 7 compound-relationship table: how the row planet regards the column planet.
struct RelationshipGrid: View {
    let relations: [Graha: [Graha: PlanetaryRelation]]

    private let grahas = GrahaDignityCalculator.sevenGrahas

    var body: some View {
        Grid(alignment: .center, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
            GridRow {
                strengthHeader("Regards →").gridColumnAlignment(.leading)
                ForEach(grahas) { graha in
                    strengthHeader(graha.shortAbbreviation)
                }
            }
            ForEach(grahas) { graha in
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    grahaCell(graha)
                    ForEach(grahas) { other in
                        relationCell(from: graha, to: other)
                    }
                }
            }
        }
        .modifier(StrengthGridBox())
    }

    @ViewBuilder
    private func relationCell(from graha: Graha, to other: Graha) -> some View {
        if graha == other {
            Text("—")
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.secondaryText)
        } else if let relation = relations[graha]?[other] {
            Text(relation.shortLabel)
                .designTextStyle(.body)
                .fontWeight(.medium)
                .foregroundStyle(relationColor(relation))
                .help("\(graha.sanskritName) regards \(other.sanskritName) as \(relation.rawValue)")
        } else {
            Text("·")
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private func relationColor(_ relation: PlanetaryRelation) -> Color {
        switch relation {
        case .adhiMitra, .mitra: DesignColor.benefic
        case .sama: DesignColor.primaryText
        case .shatru, .adhiShatru: DesignColor.malefic
        }
    }
}
