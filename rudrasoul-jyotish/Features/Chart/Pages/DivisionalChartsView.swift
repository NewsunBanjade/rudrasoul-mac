import SwiftUI

struct DivisionalChartsView: View {
    let chart: ChartDetail
    var model: ChartScreenModel = ChartScreenModel()
    @State private var selectedDivision: VargaDivision = .d9
    @State private var chartStyle: Int = 0 // 0 = North Indian, 1 = South Indian
    @State private var rotatedLagnaHouse: Int = 1 // 1 = Natal Varga Lagna, 2...12 = Rotated House

    private var isRotated: Bool {
        rotatedLagnaHouse != 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar / Division Picker
            HStack {
                Picker("Divisional Chart", selection: $selectedDivision) {
                    ForEach(VargaDivision.allCases) { division in
                        Text(division.title).tag(division)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 240)

                Spacer()

                Picker("Style", selection: $chartStyle) {
                    Text("North Indian").tag(0)
                    Text("South Indian").tag(1)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 200)
            }
            .padding(.horizontal, DesignSpacing.medium)
            .padding(.vertical, DesignSpacing.small)
            .background(DesignColor.groupedBackground)
            .overlay(alignment: .bottom) { Divider() }

            // Active Bhavat Bhavam Rotation Banner
            if isRotated {
                HStack(spacing: DesignSpacing.small) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(DesignColor.accent)
                    Text("Bhavat Bhavam: House \(rotatedLagnaHouse) (\(effectiveVargaLagnaRasi.sanskritName)) as Lagna in \(selectedDivision.rawValue)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DesignColor.primaryText)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            rotatedLagnaHouse = 1
                        }
                    } label: {
                        Label("Reset to Natal Lagna", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(.horizontal, DesignSpacing.medium)
                .padding(.vertical, 6)
                .background(DesignColor.accent.opacity(0.08))
                .overlay(alignment: .bottom) { Divider() }
            }

            // Two-pane workbench
            HSplitView {
                // Left pane: Kundali canvas
                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedDivision.title)
                                .designTextStyle(.section)
                            Text(selectedDivision.domain)
                                .designTextStyle(.caption)
                                .foregroundStyle(DesignColor.secondaryText)
                        }
                        Spacer()
                        if isRotated {
                            Text("\(effectiveVargaLagnaRasi.sanskritName) (H\(rotatedLagnaHouse) As)")
                                .designTextStyle(.caption, monospacedDigits: true)
                                .foregroundStyle(DesignColor.accent)
                        } else {
                            Text("\(currentVarga.lagnaRasi.sanskritName) Lagna")
                                .designTextStyle(.caption, monospacedDigits: true)
                                .foregroundStyle(DesignColor.accent)
                        }
                    }

                    if chartStyle == 0 {
                        NorthIndianChartCanvas(
                            houseRasis: effectiveVargaHouseRasis,
                            housePlanets: effectiveVargaHousePlanets(varga: currentVarga),
                            isRotated: isRotated,
                            onShowChartFromHouse: { house in
                                if let selectedSign = effectiveVargaHouseRasis[house] {
                                    let natalSignRaw = currentVarga.lagnaRasi.rawValue
                                    let newRotatedHouse = ((selectedSign.rawValue - natalSignRaw + 12) % 12) + 1
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        rotatedLagnaHouse = newRotatedHouse
                                    }
                                }
                            },
                            onResetToNatalLagna: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    rotatedLagnaHouse = 1
                                }
                            }
                        )
                    } else {
                        SouthIndianChartCanvas(
                            lagnaRasi: effectiveVargaLagnaRasi,
                            planetRasis: currentVarga.planetRasis,
                            isRotated: isRotated,
                            onShowChartFromRasi: { rasi in
                                let natalSignRaw = currentVarga.lagnaRasi.rawValue
                                let newRotatedHouse = ((rasi.rawValue - natalSignRaw + 12) % 12) + 1
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    rotatedLagnaHouse = newRotatedHouse
                                }
                            },
                            onResetToNatalLagna: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    rotatedLagnaHouse = 1
                                }
                            }
                        )
                    }

                    Spacer()
                }
                .padding(DesignSpacing.medium)
                .frame(minWidth: 320, maxWidth: .infinity)

                // Right pane: Planetary placements and varga analysis
                VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                    Text("Planet Placements in \(selectedDivision.rawValue)")
                        .designTextStyle(.section)

                    List(Graha.allCases.filter { $0 != .ascendant }) { graha in
                        let rasi = currentVarga.planetRasis[graha] ?? .aries
                        let isVargottama = checkVargottama(graha: graha, vargaRasi: rasi)
                        let vargaBhava = ((rasi.rawValue - effectiveVargaLagnaRasi.rawValue + 12) % 12) + 1

                        HStack {
                            Text(graha.astronomicalGlyph)
                                .frame(width: 20)
                            Text(graha.sanskritName)
                                .designTextStyle(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Text("H\(vargaBhava) · \(rasi.sanskritName)")
                                .designTextStyle(.body, monospacedDigits: true)
                                .foregroundColor(isRotated ? DesignColor.accent : DesignColor.primaryText)
                            if isVargottama {
                                Text("Vargottama")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(DesignColor.accent.opacity(0.15))
                                    .foregroundStyle(DesignColor.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.inset)
                }
                .padding(DesignSpacing.medium)
                .frame(minWidth: 280, maxWidth: .infinity)
            }
        }
        .onChange(of: selectedDivision) { _, _ in
            rotatedLagnaHouse = 1
        }
        .background(DesignColor.background)
    }

    private var currentVarga: VargaChart {
        chart.vargas.first(where: { $0.division == selectedDivision })
            ?? VargaChart(
                division: selectedDivision,
                lagnaRasi: chart.lagnaPosition.rasi,
                planetRasis: Dictionary(uniqueKeysWithValues: chart.planets.map { ($0.graha, $0.rasi) })
            )
    }

    private var effectiveVargaLagnaRasi: Rasi {
        let raw = ((currentVarga.lagnaRasi.rawValue - 1 + (rotatedLagnaHouse - 1)) % 12) + 1
        return Rasi(rawValue: raw) ?? currentVarga.lagnaRasi
    }

    private var effectiveVargaHouseRasis: [Int: Rasi] {
        houseRasis(lagna: effectiveVargaLagnaRasi)
    }

    private func checkVargottama(graha: Graha, vargaRasi: Rasi) -> Bool {
        guard selectedDivision == .d9 else { return false }
        let d1Rasi = chart.planets.first(where: { $0.graha == graha })?.rasi
        return d1Rasi == vargaRasi
    }

    private func houseRasis(lagna: Rasi) -> [Int: Rasi] {
        var map: [Int: Rasi] = [:]
        for h in 1...12 {
            let rasiIndex = ((lagna.rawValue - 1 + (h - 1)) % 12) + 1
            map[h] = Rasi(rawValue: rasiIndex)
        }
        return map
    }

    private func effectiveVargaHousePlanets(varga: VargaChart) -> [Int: [PlanetPosition]] {
        var map: [Int: [PlanetPosition]] = [:]
        let effLagnaRaw = effectiveVargaLagnaRasi.rawValue
        for (graha, rasi) in varga.planetRasis {
            let house = ((rasi.rawValue - effLagnaRaw + 12) % 12) + 1
            let pos = PlanetPosition(
                graha: graha,
                rasi: rasi,
                longitudeInRasi: 0,
                formattedDMS: "",
                nakshatra: .ashwini,
                pada: 1,
                isRetrograde: false,
                isCombust: false,
                dignity: .neutral,
                bhava: house,
                charaKaraka: nil,
                speedDegPerDay: nil
            )
            map[house, default: []].append(pos)
        }
        return map
    }
}
