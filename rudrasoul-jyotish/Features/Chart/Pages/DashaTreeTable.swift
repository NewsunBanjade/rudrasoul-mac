import SwiftUI

/// Hierarchical table of dasha periods. Rows on the active path for the target
/// date are drawn in the accent colour; the selection drives the inspector.
struct DashaTreeTable: View {
    let rows: [DashaRowItem]
    @Binding var selectedRowID: UUID?

    var body: some View {
        Table(rows, children: \.children, selection: $selectedRowID) {
            TableColumn("Period") { row in
                HStack(spacing: DesignSpacing.xSmall) {
                    Text(row.glyph)
                    Text(row.name)
                        .fontWeight(row.depth == 0 ? .semibold : .regular)
                    Text(row.levelTag)
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(DesignColor.secondaryText)
                }
                .designTextStyle(.body)
                .foregroundStyle(row.isActive ? DesignColor.accent : DesignColor.primaryText)
            }
            .width(min: 170, ideal: 210)

            TableColumn("Start") { row in
                Text(row.startDate, format: .dateTime.year().month().day())
                    .designTextStyle(.body, monospacedDigits: true)
                    .foregroundStyle(row.isActive ? DesignColor.accent : DesignColor.primaryText)
            }
            .width(min: 100, ideal: 115)

            TableColumn("End") { row in
                Text(row.endDate, format: .dateTime.year().month().day())
                    .designTextStyle(.body, monospacedDigits: true)
                    .foregroundStyle(row.isActive ? DesignColor.accent : DesignColor.primaryText)
            }
            .width(min: 100, ideal: 115)

            TableColumn("Duration") { row in
                Text(row.formattedDuration)
                    .designTextStyle(.body, monospacedDigits: true)
                    .foregroundStyle(row.isActive ? DesignColor.accent : DesignColor.primaryText)
            }
            .width(min: 90, ideal: 110)

            TableColumn("Age") { row in
                Text(String(format: "%.1f", row.ageAtStart))
                    .designTextStyle(.body, monospacedDigits: true)
                    .foregroundStyle(row.isActive ? DesignColor.accent : DesignColor.primaryText)
            }
            .width(min: 50, ideal: 60)
        }
        .accessibilityLabel(Text("Dasha hierarchy"))
    }
}
