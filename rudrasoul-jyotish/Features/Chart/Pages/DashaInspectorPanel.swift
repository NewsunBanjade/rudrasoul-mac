import SwiftUI

/// Facts about one dasha period that follow directly from the chart: the
/// period's dates and ages, and the natal placement of its lord (or, for a sign
/// period, the sign's lord and occupants). Nothing interpretive is shown.
struct DashaInspectorPanel: View {
    let chart: ChartDetail
    let item: DashaRowItem?
    /// True when `item` is the period at the target date rather than a user selection.
    let showsActivePeriod: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                header
                if let item {
                    periodFacts(item)
                    Divider()
                    if let graha = item.graha, item.rasi == nil {
                        grahaFacts(graha)
                    } else if let rasi = item.rasi {
                        rasiFacts(rasi)
                    }
                } else {
                    Text("No period covers the target date.")
                        .designTextStyle(.body)
                        .foregroundStyle(DesignColor.secondaryText)
                }
            }
            .padding(DesignSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignColor.background)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Dasha inspector")
                .designTextStyle(.section)
            Spacer()
            Text(showsActivePeriod ? "At target date" : "Selected")
                .font(.caption2)
                .padding(.horizontal, DesignSpacing.xSmall)
                .padding(.vertical, 1)
                .background(DesignColor.accent.opacity(0.15))
                .foregroundStyle(DesignColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    private func periodFacts(_ item: DashaRowItem) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack(spacing: DesignSpacing.small) {
                Text(item.glyph)
                    .designTextStyle(.title)
                    .frame(width: 36, height: 36)
                    .background(DesignColor.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .designTextStyle(.section)
                    Text(item.levelTag)
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }
            }
            Grid(alignment: .leading, horizontalSpacing: DesignSpacing.small, verticalSpacing: DesignSpacing.xSmall) {
                factRow("Start", item.startDate.formatted(.dateTime.year().month().day().hour().minute()))
                factRow("End", item.endDate.formatted(.dateTime.year().month().day().hour().minute()))
                factRow("Duration", item.formattedDuration)
                factRow("Age span", String(format: "%.1f – %.1f", item.ageAtStart, item.ageAtEnd))
            }
        }
    }

    @ViewBuilder
    private func grahaFacts(_ graha: Graha) -> some View {
        if let position = chart.planets.first(where: { $0.graha == graha }) {
            VStack(alignment: .leading, spacing: DesignSpacing.small) {
                Text("Natal placement of \(graha.sanskritName)")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                Grid(alignment: .leading, horizontalSpacing: DesignSpacing.small, verticalSpacing: DesignSpacing.xSmall) {
                    factRow("Rasi", "\(position.rasi.sanskritName) (\(position.rasi.englishName))")
                    factRow("Longitude", position.formattedDMS)
                    factRow("Nakshatra", "\(position.nakshatra.name) \(position.pada)")
                    factRow("Bhava", "\(position.bhava)")
                    factRow("Dignity", position.dignity.rawValue)
                    factRow("Motion", position.isRetrograde ? "Retrograde" : "Direct")
                }
            }
        } else {
            Text("\(graha.sanskritName) has no natal position in this chart.")
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private func rasiFacts(_ rasi: Rasi) -> some View {
        let lords = CharaDashaCalculator.lords(of: rasi).map(\.sanskritName).joined(separator: " · ")
        let occupants = chart.planets.filter { $0.rasi == rasi }
        let bhava = chart.lagnaPosition.rasi.count(to: rasi)
        return VStack(alignment: .leading, spacing: DesignSpacing.small) {
            Text("Sign in the natal chart")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
            Grid(alignment: .leading, horizontalSpacing: DesignSpacing.small, verticalSpacing: DesignSpacing.xSmall) {
                factRow("Rasi", "\(rasi.sanskritName) (\(rasi.englishName))")
                factRow("Lord", lords)
                factRow("Bhava from lagna", "\(bhava)")
                factRow("Occupants", occupants.isEmpty ? "None" : occupants.map(\.displayLabel).joined(separator: ", "))
            }
        }
    }

    private func factRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        GridRow(alignment: .firstTextBaseline) {
            Text(label)
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
            Text(value)
                .designTextStyle(.body, monospacedDigits: true)
                .foregroundStyle(DesignColor.primaryText)
                .textSelection(.enabled)
        }
    }
}
