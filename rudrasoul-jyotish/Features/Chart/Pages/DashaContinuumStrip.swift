import SwiftUI

/// The lifespan strip of mahadashas. Block widths are proportional to each
/// period's duration, the block containing the target date is filled with the
/// accent colour, and a thin marker shows where the target date falls.
struct DashaContinuumStrip: View {
    let rows: [DashaRowItem]
    let targetDate: Date
    @Binding var selectedRowID: UUID?

    private let blockHeight: CGFloat = 28
    private let stripHeight: CGFloat = 48
    private let minimumBlockWidth: Double = 40
    private let blockSpacing: Double = 2

    var body: some View {
        GeometryReader { proxy in
            let layout = DashaContinuumLayout(
                rows: rows,
                availableWidth: Double(proxy.size.width),
                minimumWidth: minimumBlockWidth,
                spacing: blockSpacing
            )
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    ForEach(layout.blocks) { block in
                        blockView(block)
                            .frame(width: CGFloat(block.width))
                            .offset(x: CGFloat(block.x))
                    }
                    if let markerX = layout.markerX(for: targetDate) {
                        Rectangle()
                            .fill(DesignColor.accent)
                            .frame(width: 2, height: stripHeight)
                            .offset(x: CGFloat(markerX) - 1)
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: CGFloat(layout.totalWidth), height: stripHeight, alignment: .topLeading)
            }
        }
        .frame(height: stripHeight)
        .padding(DesignSpacing.small)
        .background(DesignColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
    }

    private func blockView(_ block: DashaContinuumBlock) -> some View {
        let row = block.row
        let isSelected = selectedRowID == row.id
        return VStack(spacing: DesignSpacing.xSmall) {
            RoundedRectangle(cornerRadius: 3)
                .fill(row.isActive ? DesignColor.accent : DesignColor.groupedBackground)
                .frame(height: blockHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isSelected ? DesignColor.accent : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Text(row.shortLabel)
                        .designTextStyle(.caption, monospacedDigits: true)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundStyle(row.isActive ? Color.white : DesignColor.primaryText)
                        .padding(.horizontal, DesignSpacing.xSmall)
                )
            Text(row.startDate, format: .dateTime.year())
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(DesignColor.secondaryText)
        }
        .contentShape(Rectangle())
        .onTapGesture { selectedRowID = row.id }
        .help(Text("\(row.name) · \(row.formattedDuration)"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(row.name) \(row.levelTag), \(row.formattedDuration), from age \(row.ageAtStart, format: .number.precision(.fractionLength(1)))"))
        .accessibilityAddTraits(row.isActive ? .isSelected : [])
    }
}
