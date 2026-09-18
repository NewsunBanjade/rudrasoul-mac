import SwiftUI

// The Overview's mahadasha timeline and Shadbala summary strips.

/// Every mahadasha as a bar whose length is proportional to its duration; the period
/// running today is highlighted.
struct OverviewDashaStrip: View {
    let nodes: [DashaNode]
    let activeVector: String

    var body: some View {
        let now = Date()
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline) {
                Text("Vimshottari mahadasha timeline")
                    .designTextStyle(.section)
                Spacer()
                Text("Running: \(activeVector)")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.accent)
                    .lineLimit(1)
            }

            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 2) {
                    ForEach(nodes) { node in
                        segment(
                            node,
                            isRunning: node.startDate <= now && now < node.endDate,
                            width: width(for: node, total: geometry.size.width)
                        )
                    }
                }
            }
            .frame(height: 46)
            .padding(DesignSpacing.small)
            .background(DesignColor.background)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignColor.separator, lineWidth: 1)
            )

            Text("Bar length is proportional to each mahadasha; the highlighted period is running today. Hover a bar for its dates.")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private var totalDuration: TimeInterval {
        nodes.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
    }

    private func width(for node: DashaNode, total: CGFloat) -> CGFloat {
        guard totalDuration > 0 else { return 0 }
        let spacing = CGFloat(max(nodes.count - 1, 0)) * 2
        let fraction = node.endDate.timeIntervalSince(node.startDate) / totalDuration
        return max(28, (total - spacing) * CGFloat(fraction))
    }

    private func segment(_ node: DashaNode, isRunning: Bool, width: CGFloat) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isRunning ? DesignColor.accent : DesignColor.groupedBackground)
                .frame(height: 24)
                .overlay(
                    Text(node.lord.shortAbbreviation)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isRunning ? Color.white : DesignColor.primaryText)
                )
            Text(node.startDate, format: .dateTime.year())
                .font(.system(size: 9).monospaced())
                .foregroundStyle(DesignColor.secondaryText)
        }
        .frame(width: width)
        .help("\(node.lord.sanskritName) mahadasha · \(node.formattedDuration) · \(node.startDate.formatted(date: .abbreviated, time: .omitted)) – \(node.endDate.formatted(date: .abbreviated, time: .omitted))")
    }
}

/// Rupas and rank of every planet in one row, or a pointer to Recalculate.
struct OverviewStrengthStrip: View {
    let shadbala: [ShadbalaBreakdown]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline) {
                Text("Shadbala at a glance")
                    .designTextStyle(.section)
                Spacer()
                Text("Rupas · rank · green meets the BPHS requirement")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            if shadbala.isEmpty {
                Text("Not computed for this chart. Use Recalculate (⇧⌘R) to add Shadbala, Bhava Bala and Ashtakavarga.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            } else {
                HStack(spacing: DesignSpacing.small) {
                    ForEach(shadbala.sorted { $0.rank < $1.rank }) { item in
                        VStack(spacing: 2) {
                            Text("\(item.graha.astronomicalGlyph) \(item.graha.sanskritName)")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text(String(format: "%.2f", item.totalRupas))
                                .designTextStyle(.body, monospacedDigits: true)
                                .foregroundStyle(item.isSufficient ? DesignColor.benefic : DesignColor.malefic)
                            Text("#\(item.rank)")
                                .font(.caption2)
                                .foregroundStyle(DesignColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(DesignColor.groupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
    }
}
