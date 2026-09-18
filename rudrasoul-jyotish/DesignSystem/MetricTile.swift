import SwiftUI

/// A reusable analytical metric tile displaying title, monospaced primary value, and optional secondary badge.
struct MetricTile: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var badge: String? = nil
    var isAuspicious: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            HStack {
                Text(title)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(badgeBackground)
                        .foregroundStyle(badgeForeground)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }

            Text(value)
                .designTextStyle(.section, monospacedDigits: true)
                .foregroundStyle(DesignColor.primaryText)

            if let subtitle {
                Text(subtitle)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(DesignSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
    }

    private var badgeBackground: Color {
        if let isAuspicious {
            return isAuspicious ? DesignColor.benefic.opacity(0.15) : DesignColor.malefic.opacity(0.15)
        }
        return DesignColor.groupedBackground
    }

    private var badgeForeground: Color {
        if let isAuspicious {
            return isAuspicious ? DesignColor.benefic : DesignColor.malefic
        }
        return DesignColor.secondaryText
    }
}
