import SwiftUI

struct ChartIdentityHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: DesignSpacing.small) {
            VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                Text(title)
                    .designTextStyle(.section)
                Text(subtitle)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, DesignSpacing.medium)
        .padding(.vertical, DesignSpacing.small)
        .background(DesignColor.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .accessibilityElement(children: .combine)
    }
}
