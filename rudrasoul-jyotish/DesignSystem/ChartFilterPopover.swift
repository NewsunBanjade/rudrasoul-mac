import SwiftUI

/// A popover view for filtering the chart library by astrological criteria.
struct ChartFilterPopover: View {
    @Binding var selectedLagna: Rasi?
    @Binding var selectedMoonRasi: Rasi?
    @Binding var selectedDashaLord: Graha?
    @Binding var selectedGender: String?
    let onReset: () -> Void

    private let dashaLords: [Graha] = [
        .sun, .moon, .mars, .rahu, .jupiter, .saturn, .mercury, .ketu, .venus
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text("Filter Charts")
                        .designTextStyle(.section)
                    Text("Advanced")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(DesignColor.accent.opacity(0.12))
                        .foregroundStyle(DesignColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

                Button("Reset") {
                    onReset()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(hasAnyActiveFilter ? DesignColor.accent : DesignColor.secondaryText)
                .disabled(!hasAnyActiveFilter)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                    // Lagna (Ascendant)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lagna (Ascendant)")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 4) {
                            filterChip(
                                title: "All Signs",
                                isSelected: selectedLagna == nil
                            ) {
                                selectedLagna = nil
                            }

                            ForEach(Rasi.allCases) { rasi in
                                filterChip(
                                    title: "\(rasi.sanskritName)",
                                    isSelected: selectedLagna == rasi
                                ) {
                                    selectedLagna = (selectedLagna == rasi ? nil : rasi)
                                }
                            }
                        }
                    }

                    Divider()

                    // Moon Sign
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Moon Sign (Chandra Rasi)")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)

                        Picker("Moon Sign", selection: $selectedMoonRasi) {
                            Text("All Signs").tag(Optional<Rasi>.none)
                            ForEach(Rasi.allCases) { rasi in
                                Text("\(rasi.sanskritName) (\(rasi.englishName))").tag(Optional(rasi))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    Divider()

                    // Running Mahadasha Lord
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Running Mahadasha")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)

                        HStack(spacing: 4) {
                            filterChip(
                                title: "Any",
                                isSelected: selectedDashaLord == nil
                            ) {
                                selectedDashaLord = nil
                            }

                            ForEach(dashaLords) { lord in
                                filterChip(
                                    title: lord.shortAbbreviation,
                                    isSelected: selectedDashaLord == lord
                                ) {
                                    selectedDashaLord = (selectedDashaLord == lord ? nil : lord)
                                }
                            }
                        }
                    }

                    Divider()

                    // Gender
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gender")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)

                        Picker("Gender", selection: Binding(
                            get: { selectedGender ?? "All" },
                            set: { selectedGender = ($0 == "All" ? nil : $0) }
                        )) {
                            Text("All").tag("All")
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 360)
        }
        .padding(DesignSpacing.medium)
        .frame(width: 320)
        .background(DesignColor.background)
    }

    private var hasAnyActiveFilter: Bool {
        selectedLagna != nil || selectedMoonRasi != nil || selectedDashaLord != nil || (selectedGender != nil && selectedGender != "All")
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(isSelected ? DesignColor.accent : DesignColor.groupedBackground)
                .foregroundStyle(isSelected ? Color.white : DesignColor.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? DesignColor.accent : DesignColor.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// An active filter token strip showing removable filter chips.
struct ActiveFilterTokenBar: View {
    let lagna: Rasi?
    let moonRasi: Rasi?
    let dashaLord: Graha?
    let gender: String?
    let onRemoveLagna: () -> Void
    let onRemoveMoonRasi: () -> Void
    let onRemoveDashaLord: () -> Void
    let onRemoveGender: () -> Void
    let onClearAll: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text("Filters:")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)

                if let lagna {
                    tokenChip(title: "Lagna: \(lagna.sanskritName)", onRemove: onRemoveLagna)
                }

                if let moonRasi {
                    tokenChip(title: "Moon: \(moonRasi.sanskritName)", onRemove: onRemoveMoonRasi)
                }

                if let dashaLord {
                    tokenChip(title: "Dasha: \(dashaLord.sanskritName)", onRemove: onRemoveDashaLord)
                }

                if let gender, gender != "All" {
                    tokenChip(title: "Gender: \(gender)", onRemove: onRemoveGender)
                }

                Button("Clear All") {
                    onClearAll()
                }
                .font(.caption2)
                .foregroundStyle(DesignColor.secondaryText)
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
            .padding(.horizontal, DesignSpacing.small)
            .padding(.vertical, 4)
        }
        .background(DesignColor.groupedBackground.opacity(0.5))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func tokenChip(title: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DesignColor.accent)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DesignColor.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(DesignColor.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(DesignColor.accent.opacity(0.25), lineWidth: 1)
        )
    }
}
