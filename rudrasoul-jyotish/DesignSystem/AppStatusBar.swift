import SwiftUI

struct AppStatusBar: View {
    let leadingText: LocalizedStringKey
    let trailingText: LocalizedStringKey

    var body: some View {
        HStack(spacing: DesignSpacing.medium) {
            Text(leadingText)
            Spacer()
            Text(trailingText)
        }
        .designTextStyle(.caption, monospacedDigits: true)
        .foregroundStyle(DesignColor.secondaryText)
        .padding(.horizontal, DesignSpacing.small)
        .padding(.vertical, DesignSpacing.xSmall)
        .background(DesignColor.background)
        .overlay(alignment: .top) {
            Divider()
        }
        .accessibilityElement(children: .combine)
    }
}
