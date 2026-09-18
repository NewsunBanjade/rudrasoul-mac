import SwiftUI

struct YogasAndDoshasView: View {
    let chart: ChartDetail
    @State private var filterCategory: String = "All"

    var body: some View {
        if chart.yogas.isEmpty {
            ContentUnavailableView(
                "Yoga detection is not available yet",
                systemImage: "checkmark.seal",
                description: Text("Automatic yoga and dosha detection is not part of this version, so nothing is listed rather than claiming an unverified combination.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignColor.background)
        } else {
            yogaList
        }
    }

    private var yogaList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                // Category Filter
                HStack {
                    Text("Classical Yogas & Doshas (\(filteredYogas.count) Formed)")
                        .designTextStyle(.section)
                    Spacer()
                    Picker("", selection: $filterCategory) {
                        Text("All").tag("All")
                        Text("Pancha Mahapurusha").tag("Pancha Mahapurusha")
                        Text("Raja Yoga").tag("Raja Yoga")
                        Text("Auspicious").tag("Auspicious")
                        Text("Viparita Raja Yoga").tag("Viparita Raja Yoga")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }

                // Yogas list
                ForEach(filteredYogas) { yoga in
                    VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                        HStack {
                            Text(yoga.name)
                                .designTextStyle(.section)
                                .foregroundStyle(DesignColor.primaryText)

                            Text(yoga.category)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignColor.accent.opacity(0.12))
                                .foregroundStyle(DesignColor.accent)
                                .clipShape(Capsule())

                            Spacer()

                            HStack(spacing: 4) {
                                ForEach(yoga.participatingGrahas) { g in
                                    Text("\(g.astronomicalGlyph) \(g.sanskritName)")
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(DesignColor.groupedBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                            }
                        }

                        Text(yoga.description)
                            .designTextStyle(.body)
                            .foregroundStyle(DesignColor.primaryText)
                            .padding(.vertical, 2)

                        HStack {
                            Text("Source: \(yoga.referenceSource)")
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                            Spacer()
                            if let cancel = yoga.cancellationNote {
                                Text("Bhanga Note: \(cancel)")
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.warning)
                            } else {
                                Text("Full Potency")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(DesignColor.benefic)
                            }
                        }
                    }
                    .padding(DesignSpacing.medium)
                    .background(DesignColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DesignColor.separator, lineWidth: 1)
                    )
                }
            }
            .padding(DesignSpacing.medium)
        }
        .background(DesignColor.background)
    }

    private var filteredYogas: [YogaRecord] {
        if filterCategory == "All" {
            return chart.yogas
        }
        return chart.yogas.filter { $0.category == filterCategory }
    }
}
