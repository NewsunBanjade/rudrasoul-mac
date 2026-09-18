import SwiftUI

/// Browser-style strip of the open charts, with a fixed Library tab in front and a
/// New Chart button at the end.
struct ChartTabStrip: View {
    struct Item: Identifiable, Hashable {
        let id: UUID
        let title: String
    }

    let items: [Item]
    /// The highlighted chart tab; nil while the library or the settings are showing.
    let selectedID: UUID?
    let isLibrarySelected: Bool
    let onSelectLibrary: () -> Void
    let onSelect: (UUID) -> Void
    let onClose: (UUID) -> Void
    let onCloseOthers: (UUID) -> Void
    let onNewChart: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ChartTabButton(
                        title: "Library",
                        systemImage: "rectangle.stack",
                        isSelected: isLibrarySelected,
                        showsClose: false,
                        onSelect: onSelectLibrary,
                        onClose: nil
                    )
                    .help("Show the chart library (⇧⌘L)")

                    ForEach(items) { item in
                        ChartTabButton(
                            title: item.title,
                            systemImage: nil,
                            isSelected: item.id == selectedID,
                            showsClose: true,
                            onSelect: { onSelect(item.id) },
                            onClose: { onClose(item.id) }
                        )
                        .contextMenu {
                            Button("Close Tab") { onClose(item.id) }
                            Button("Close Other Tabs") { onCloseOthers(item.id) }
                                .disabled(items.count < 2)
                        }
                    }
                }
                .padding(.horizontal, DesignSpacing.small)
                .padding(.vertical, DesignSpacing.xSmall)
            }

            Spacer(minLength: 0)

            Button(action: onNewChart) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignColor.secondaryText)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DesignSpacing.xSmall)
            .help("New chart (⌘N)")
        }
        .frame(height: 34)
        .background(DesignColor.groupedBackground)
        .overlay(alignment: .bottom) { Divider() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Open charts")
    }
}

private struct ChartTabButton: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let showsClose: Bool
    let onSelect: () -> Void
    let onClose: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: DesignSpacing.xSmall) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .medium))
            }
            Text(title)
                .designTextStyle(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(1)
                .truncationMode(.tail)
            if showsClose {
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 14, height: 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(DesignColor.secondaryText)
                .opacity(isHovering || isSelected ? 1 : 0)
                .help("Close tab (⌘W)")
            }
        }
        .padding(.horizontal, DesignSpacing.small)
        .frame(height: 26)
        .frame(minWidth: 72, maxWidth: 200)
        .background(isSelected ? DesignColor.background : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? DesignColor.separator : Color.clear, lineWidth: 1)
        )
        .foregroundStyle(isSelected ? DesignColor.primaryText : DesignColor.secondaryText)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}
