import SwiftUI

struct KotaView: View {
    let chart: ChartDetail

    var body: some View {
        HSplitView {
            // Left: Concentric Fortress Visuals
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                HStack {
                    Text("Kota Chakra (Fortress Mandala)")
                        .designTextStyle(.section)
                    Spacer()
                    Text("Defense & Protection Analysis")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                }

                // Concentric Zone Fortress Box
                ZStack {
                    // Zone 4: Bahya (Outer)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignColor.separator, lineWidth: 1.5)
                        .background(DesignColor.background)

                    // Zone 3: Prakara (Ramparts)
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignColor.separator, lineWidth: 1.5)
                        .background(DesignColor.groupedBackground.opacity(0.4))
                        .padding(40)

                    // Zone 2: Madhya (Inner Hall)
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DesignColor.separator, lineWidth: 1.5)
                        .background(DesignColor.groupedBackground.opacity(0.7))
                        .padding(80)

                    // Zone 1: Stambha (Center Pillar)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignColor.accent.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DesignColor.accent, lineWidth: 2)
                        )
                        .padding(120)
                        .overlay(
                            VStack(spacing: 2) {
                                Text("STAMBHA")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(DesignColor.accent)
                                ForEach(chart.kota.zoneAssignments[.stambha] ?? []) { g in
                                    Text("\(g.astronomicalGlyph) \(g.sanskritName)")
                                        .font(.caption.weight(.bold))
                                }
                            }
                        )

                    // Overlay labels on zones
                    VStack {
                        HStack {
                            Text("Bahya (Outer)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DesignColor.secondaryText)
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }

                    VStack {
                        HStack {
                            Text("Prakara (Wall)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DesignColor.secondaryText)
                                .padding(48)
                            Spacer()
                        }
                        Spacer()
                    }

                    VStack {
                        HStack {
                            Text("Madhya")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(DesignColor.secondaryText)
                                .padding(88)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxHeight: 440)

                Spacer()
            }
            .padding(DesignSpacing.medium)
            .frame(minWidth: 400, maxWidth: .infinity)

            // Right: Kota Swami, Kota Pala & Movement Summary
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                Text("Fortress Dignitaries")
                    .designTextStyle(.section)

                HStack(spacing: DesignSpacing.small) {
                    MetricTile(
                        title: "Kota Swami (Fortress King)",
                        value: chart.kota.kotaSwami.sanskritName,
                        subtitle: "Protector of vital core",
                        badge: "Auspicious",
                        isAuspicious: true
                    )

                    MetricTile(
                        title: "Kota Pala (Guardian)",
                        value: chart.kota.kotaPala.sanskritName,
                        subtitle: "Commander at ramparts",
                        badge: "Guard",
                        isAuspicious: true
                    )
                }

                Divider()

                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                    Text("Direction of Movement (Gati)")
                        .designTextStyle(.section)

                    HStack(alignment: .top, spacing: DesignSpacing.medium) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "arrow.down.right")
                                    .foregroundColor(DesignColor.benefic)
                                Text("Pravesha (Entering)")
                                    .fontWeight(.medium)
                            }
                            .designTextStyle(.caption)

                            ForEach(chart.kota.praveshaGrahas) { g in
                                Text("• \(g.sanskritName) (\(g.rawValue))")
                                    .designTextStyle(.caption)
                            }
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(DesignColor.malefic)
                                Text("Nirgama (Exiting)")
                                    .fontWeight(.medium)
                            }
                            .designTextStyle(.caption)

                            ForEach(chart.kota.nirgamaGrahas) { g in
                                Text("• \(g.sanskritName) (\(g.rawValue))")
                                    .designTextStyle(.caption)
                            }
                        }
                    }
                    .padding(DesignSpacing.small)
                    .background(DesignColor.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Divider()

                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                    Text("Classical Interpretation")
                        .designTextStyle(.caption)
                        .foregroundStyle(DesignColor.secondaryText)
                    Text("When benefics like Jupiter and Moon reside in the Stambha (core) during Pravesha, the native's position remains unassailable and health remains robust against adversity.")
                        .designTextStyle(.body)
                        .foregroundStyle(DesignColor.primaryText)
                }

                Spacer()
            }
            .padding(DesignSpacing.medium)
            .frame(minWidth: 280, maxWidth: 360)
            .background(DesignColor.background)
        }
    }
}
