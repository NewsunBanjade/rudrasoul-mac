import SwiftUI

struct StrengthView: View {
    let chart: ChartDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.large) {
                // Shadbala Overview Cards
                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    HStack {
                        Text("Shadbala (Sixfold Planetary Strength)")
                            .designTextStyle(.section)
                        Spacer()
                        Text("Required Threshold: 1.00 Rupa (60 Virupas = 1 Rupa)")
                            .designTextStyle(.caption, monospacedDigits: true)
                            .foregroundStyle(DesignColor.secondaryText)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: DesignSpacing.small) {
                        ForEach(chart.shadbala) { sb in
                            ShadbalaMeterCard(data: sb)
                        }
                    }
                }

                Divider()

                // Detailed Breakdown Table
                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    Text("Detailed Bala Components (Virupas)")
                        .designTextStyle(.section)

                    Table(chart.shadbala) {
                        TableColumn("Graha") { sb in
                            HStack(spacing: 4) {
                                Text(sb.graha.astronomicalGlyph)
                                Text(sb.graha.sanskritName)
                                    .fontWeight(.medium)
                            }
                            .designTextStyle(.body)
                        }
                        .width(min: 100, ideal: 120)

                        TableColumn("Sthana") { sb in
                            Text(String(format: "%.1f", sb.sthanaBala))
                                .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 65, ideal: 80)

                        TableColumn("Dik") { sb in
                            Text(String(format: "%.1f", sb.dikBala))
                                .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 55, ideal: 70)

                        TableColumn("Kala") { sb in
                            Text(String(format: "%.1f", sb.kalaBala))
                                .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 65, ideal: 80)

                        TableColumn("Cheshta") { sb in
                            Text(String(format: "%.1f", sb.cheshtaBala))
                                .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 65, ideal: 80)

                        TableColumn("Naisargika") { sb in
                            Text(String(format: "%.1f", sb.naisargikaBala))
                                .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 75, ideal: 90)

                        TableColumn("Drik") { sb in
                            Text(String(format: "%.1f", sb.drikBala))
                                .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 55, ideal: 70)

                        TableColumn("Total (Rupas)") { sb in
                            Text(String(format: "%.2f", sb.totalRupas))
                                .designTextStyle(.body, monospacedDigits: true)
                                .fontWeight(.bold)
                                .foregroundColor(sb.isSufficient ? DesignColor.primaryText : DesignColor.secondaryText)
                        }
                        .width(min: 90, ideal: 105)

                        TableColumn("Rank") { sb in
                            Text("#\(sb.rank)")
                                .designTextStyle(.body, monospacedDigits: true)
                                .foregroundColor(sb.rank == 1 ? DesignColor.accent : DesignColor.secondaryText)
                        }
                        .width(50)
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DesignColor.separator, lineWidth: 1)
                    )
                }
            }
            .padding(DesignSpacing.medium)
        }
        .background(DesignColor.background)
    }
}

private struct ShadbalaMeterCard: View {
    let data: ShadbalaBreakdown

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
                    .foregroundColor(data.rank == 1 ? DesignColor.accent : DesignColor.secondaryText)
            }

            HStack {
                Text(String(format: "%.2f Rupas", data.totalRupas))
                    .designTextStyle(.section, monospacedDigits: true)
                Spacer()
                Text(String(format: "%.0f%%", data.percentageOfRequired))
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(data.isSufficient ? DesignColor.benefic : DesignColor.malefic)
            }

            // Visual Progress Meter
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignColor.groupedBackground)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(data.isSufficient ? DesignColor.accent : DesignColor.secondaryText)
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(data.totalRupas / 1.6)), height: 6)

                    // 1.00 Rupa Threshold Line
                    Rectangle()
                        .fill(DesignColor.primaryText)
                        .frame(width: 1.5, height: 10)
                        .offset(x: min(geo.size.width - 2, geo.size.width * CGFloat(1.00 / 1.6)))
                }
            }
            .frame(height: 10)
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
