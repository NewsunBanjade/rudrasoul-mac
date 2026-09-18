import SwiftUI

/// The Vimshottari chain running at the target date, followed by the two levels
/// below the deepest stored node (normally Sookshma and Prana), computed on
/// demand with `VimshottariDashaCalculator.subPeriods` instead of being stored.
struct DashaDrilldownView: View {
    let chart: ChartDetail
    let birthDate: Date
    let targetDate: Date

    private let calculator = VimshottariDashaCalculator()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.small) {
                Text("Active period at target date")
                    .designTextStyle(.section)

                let storedPath = VimshottariDashaCalculator.activePath(in: chart.dashaNodes, at: targetDate)
                if let deepest = storedPath.last {
                    chainText(storedPath)
                    let firstLevel = calculator.subPeriods(of: deepest, birthDate: birthDate, referenceDate: targetDate)
                    periodGrid(firstLevel)
                    if let active = firstLevel.first(where: { contains(targetDate, $0) }) {
                        periodGrid(calculator.subPeriods(of: active, birthDate: birthDate, referenceDate: targetDate))
                    }
                } else {
                    Text("No Vimshottari period covers the target date.")
                        .designTextStyle(.body)
                        .foregroundStyle(DesignColor.secondaryText)
                }
            }
            .padding(DesignSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignColor.background)
    }

    private func chainText(_ path: [DashaNode]) -> some View {
        let chain = path.map { "\($0.lord.sanskritName) \($0.level.rawValue)" }.joined(separator: " › ")
        return Text(chain)
            .designTextStyle(.body)
            .foregroundStyle(DesignColor.accent)
    }

    @ViewBuilder
    private func periodGrid(_ nodes: [DashaNode]) -> some View {
        if let level = nodes.first?.level {
            VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                Text(levelTitle(level))
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                Grid(alignment: .leading, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
                    ForEach(nodes) { node in
                        periodRow(node)
                    }
                }
            }
        }
    }

    private func periodRow(_ node: DashaNode) -> some View {
        let isActive = contains(targetDate, node)
        return GridRow {
            HStack(spacing: DesignSpacing.xSmall) {
                Text(node.lord.astronomicalGlyph)
                Text(node.lord.sanskritName)
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .designTextStyle(.body)
            Text(node.startDate, format: .dateTime.year().month().day().hour().minute())
                .designTextStyle(.body, monospacedDigits: true)
            Text(node.endDate, format: .dateTime.year().month().day().hour().minute())
                .designTextStyle(.body, monospacedDigits: true)
            Text(node.formattedDuration)
                .designTextStyle(.body, monospacedDigits: true)
        }
        .foregroundStyle(isActive ? DesignColor.accent : DesignColor.primaryText)
        .padding(.vertical, 2)
        .padding(.horizontal, DesignSpacing.xSmall)
        .background(isActive ? DesignColor.accent.opacity(0.10) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func levelTitle(_ level: DashaLevel) -> LocalizedStringKey {
        switch level {
        case .mahadasha: "Mahadasha periods"
        case .antardasha: "Antardasha periods"
        case .pratyantardasha: "Pratyantardasha periods"
        case .sookshma: "Sookshma periods"
        case .prana: "Prana periods"
        }
    }

    private func contains(_ date: Date, _ node: DashaNode) -> Bool {
        date >= node.startDate && date < node.endDate
    }
}
