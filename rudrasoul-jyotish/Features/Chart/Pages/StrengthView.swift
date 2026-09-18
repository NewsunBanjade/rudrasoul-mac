import SwiftUI

/// Shadbala of the seven planets, Bhava Bala of the twelve houses, and the compound
/// (panchadha) relationships that the dignities and Saptavargaja bala rest on.
struct StrengthView: View {
    let chart: ChartDetail
    @State private var showsComponents = false

    var body: some View {
        if chart.shadbala.isEmpty {
            StrengthUnavailableView(
                title: "Shadbala not computed",
                systemImage: "chart.bar",
                description: "This chart was saved before strengths were calculated. Recalculate it to add Shadbala, Bhava Bala and Ashtakavarga."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignColor.background)
        } else {
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.large) {
                shadbalaSection
                Divider()
                bhavaBalaSection
                Divider()
                relationshipSection
            }
            .padding(DesignSpacing.medium)
        }
        .background(DesignColor.background)
    }

    private var sortedShadbala: [ShadbalaBreakdown] {
        chart.shadbala.sorted { $0.rank < $1.rank }
    }

    // MARK: - Shadbala

    private var shadbalaSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("Shadbala (six-fold strength)")
                    .designTextStyle(.section)
                Spacer()
                Text("Required (BPHS 27): Su 6.5 · Mo 6.0 · Ma 5.0 · Me 7.0 · Ju 6.5 · Ve 5.5 · Sa 5.0 rupas")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.secondaryText)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: DesignSpacing.small) {
                ForEach(sortedShadbala) { item in
                    ShadbalaMeterCard(data: item)
                }
            }

            ShadbalaSummaryTable(rows: sortedShadbala)

            DisclosureGroup("Component details (virupas)", isExpanded: $showsComponents) {
                ShadbalaComponentsTable(rows: sortedShadbala)
                    .padding(.top, DesignSpacing.small)
            }

            Text("Conventions: Saptavargaja 45/30/20/15/10/4/2 with moolatrikona by degree in D-1 and by sign in the other vargas; Kendradi counted from the Lagna sign; Dig bala from the Lagna and Midheaven; Nathonnatha by local mean time; Cheshta from the Chesta kendra (Sun = Ayana bala, Moon = Paksha bala). Graha yuddha is not applied.")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Bhava bala

    private var bhavaBalaSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            Text("Bhava Bala (house strength)")
                .designTextStyle(.section)

            if let bhavaBala = chart.bhavaBala, !bhavaBala.isEmpty {
                BhavaBalaTable(rows: bhavaBala)
                Text("Bhavadhipati = Shadbala of the house lord · Dig = the sign's strength in this house (BPHS 28.4) · Drishti = net benefic aspect on the cusp ÷ 4.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Bhava Bala is not stored for this chart. Recalculate to add it.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
        }
    }

    // MARK: - Relationships

    private var relationshipSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("Panchadha Maitri (compound relationships)")
                    .designTextStyle(.section)
                Spacer()
                Text("AM Adhi Mitra · M Mitra · S Sama · E Shatru · AE Adhi Shatru")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }

            if let relations = chart.planetaryRelations, !relations.isEmpty {
                RelationshipGrid(relations: relations)
                Text("Natural friendship (BPHS 3.55–56) combined with temporary friendship, which planets in the 2nd, 3rd, 4th, 10th, 11th and 12th signs from a planet enjoy (BPHS 3.57–59). The row planet regards the column planet.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Relationships are not stored for this chart. Recalculate to add them.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
        }
    }
}

/// One planet's total against its required strength.
private struct ShadbalaMeterCard: View {
    let data: ShadbalaBreakdown

    /// The meter spans 0 … 150 % of the requirement; the mark sits at 100 %.
    private let meterSpan = 1.5

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            HStack {
                Text(data.graha.astronomicalGlyph)
                Text(data.graha.sanskritName)
                    .designTextStyle(.body)
                    .fontWeight(.medium)
                Spacer()
                Text("Rank #\(data.rank)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(data.rank == 1 ? DesignColor.accent : DesignColor.secondaryText)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.2f rupas", data.totalRupas))
                    .designTextStyle(.section, monospacedDigits: true)
                Spacer()
                Text(String(format: "%.0f%% of %.1f", data.percentageOfRequired, data.requiredRupas))
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(data.isSufficient ? DesignColor.benefic : DesignColor.malefic)
            }

            GeometryReader { geometry in
                let ratio = data.requiredRupas > 0 ? data.totalRupas / data.requiredRupas : 0
                let fill = min(1, max(0, ratio / meterSpan))
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignColor.groupedBackground)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(data.isSufficient ? DesignColor.benefic : DesignColor.malefic)
                        .frame(width: geometry.size.width * CGFloat(fill), height: 6)

                    Rectangle()
                        .fill(DesignColor.primaryText)
                        .frame(width: 1.5, height: 10)
                        .offset(x: geometry.size.width * CGFloat(1 / meterSpan))
                }
            }
            .frame(height: 10)
            .accessibilityLabel("\(data.graha.sanskritName) \(String(format: "%.2f", data.totalRupas)) of \(String(format: "%.1f", data.requiredRupas)) rupas")
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
