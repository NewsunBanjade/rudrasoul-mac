import SwiftUI

struct AshtakavargaView: View {
    let chart: ChartDetail
    @State private var selectedGraha: Graha = .jupiter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.large) {
                // SAV Summary Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sarvashtakavarga (SAV)")
                            .designTextStyle(.section)
                        Text("Total Samudaya Bindus: \(chart.ashtakavarga.totalBindus) (Standard 337) · Standard Sign Threshold: ≥ 28 Bindus")
                            .designTextStyle(.caption, monospacedDigits: true)
                            .foregroundStyle(DesignColor.secondaryText)
                    }
                    Spacer()
                }

                // 12 Signs SAV Card Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(Rasi.allCases) { rasi in
                        let bindus = chart.ashtakavarga.sarvashtakavarga[rasi] ?? 28
                        let isStrong = bindus >= 28

                        VStack(spacing: 4) {
                            Text(rasi.sanskritName)
                                .font(.caption.weight(.medium))
                                .foregroundColor(DesignColor.secondaryText)

                            Text("\(bindus)")
                                .designTextStyle(.title, monospacedDigits: true)
                                .foregroundColor(isStrong ? DesignColor.primaryText : DesignColor.secondaryText)

                            Text(isStrong ? "Strong" : "Weak")
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(isStrong ? DesignColor.benefic.opacity(0.15) : DesignColor.malefic.opacity(0.15))
                                .foregroundStyle(isStrong ? DesignColor.benefic : DesignColor.malefic)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .padding(.vertical, DesignSpacing.small)
                        .frame(maxWidth: .infinity)
                        .background(DesignColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isStrong ? DesignColor.separator : DesignColor.malefic.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                Divider()

                // Bhinnashtakavarga (BAV) Section
                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    HStack {
                        Text("Bhinnashtakavarga (Individual Planet BAV)")
                            .designTextStyle(.section)
                        Spacer()
                        Picker("", selection: $selectedGraha) {
                            ForEach([Graha.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]) { g in
                                Text(g.sanskritName).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }

                    // Planet's BAV Row
                    if let bav = chart.ashtakavarga.bhinnashtakavarga[selectedGraha] {
                        HStack(spacing: 8) {
                            ForEach(Rasi.allCases) { rasi in
                                let count = bav[rasi] ?? 4
                                VStack(spacing: 2) {
                                    Text(rasi.sanskritName.prefix(3))
                                        .font(.caption2)
                                        .foregroundColor(DesignColor.secondaryText)
                                    Text("\(count)")
                                        .designTextStyle(.section, monospacedDigits: true)
                                        .foregroundColor(count >= 4 ? DesignColor.accent : DesignColor.primaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(DesignColor.groupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    } else {
                        Text("Individual BAV bindu breakdown available in classical ephemeris mode.")
                            .designTextStyle(.caption)
                            .foregroundStyle(DesignColor.secondaryText)
                    }
                }
            }
            .padding(DesignSpacing.medium)
        }
        .background(DesignColor.background)
    }
}
