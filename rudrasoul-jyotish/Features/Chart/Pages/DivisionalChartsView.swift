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
            toolbar

            if isRotated {
                rotationBanner
            }

            // Two-pane workbench
            HSplitView {
                canvasPane
                    .padding(DesignSpacing.medium)
                    .frame(minWidth: 320, maxWidth: .infinity)

                VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                    Text("Planet Placements in \(selectedDivision.rawValue)")
                        .designTextStyle(.section)

                    VargaPlacementsList(
                        rows: placementRows,
                        showsAmsa: selectedDivision == .d60,
                        isRotated: isRotated
                    )
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

    // MARK: - Toolbar and banner

    private var toolbar: some View {
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
    }

    private var rotationBanner: some View {
        HStack(spacing: DesignSpacing.small) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(DesignColor.accent)
            Text("Bhavat Bhavam: House \(rotatedLagnaHouse) (\(effectiveVargaLagnaRasi.sanskritName)) as Lagna in \(selectedDivision.rawValue)")
                .font(.caption.weight(.medium))
                .foregroundStyle(DesignColor.primaryText)
            Spacer()
            Button {
                resetRotation()
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

    // MARK: - Left pane

    private var canvasPane: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            canvasHeader

            if chartStyle == 0 {
                NorthIndianChartCanvas(
                    houseRasis: effectiveVargaHouseRasis,
                    housePlanets: effectiveVargaHousePlanets(varga: currentVarga),
                    extraHouseLabels: upagrahaHouseLabels,
                    isRotated: isRotated,
                    onShowChartFromHouse: { house in
                        if let selectedSign = effectiveVargaHouseRasis[house] {
                            rotate(toLagna: selectedSign)
                        }
                    },
                    onResetToNatalLagna: { resetRotation() }
                )
            } else {
                SouthIndianChartCanvas(
                    lagnaRasi: effectiveVargaLagnaRasi,
                    planetRasis: currentVarga.planetRasis,
                    extraRasiLabels: upagrahaRasiLabels,
                    isRotated: isRotated,
                    onShowChartFromRasi: { rasi in rotate(toLagna: rasi) },
                    onResetToNatalLagna: { resetRotation() }
                )
            }

            if selectedDivision == .d60 {
                Text("Shashtiamsa rules: sixty equal parts of 0°30' per sign; deities counted forward from Ghora in odd signs and backward from Chandrarekha in even signs (BPHS Ch. 6).")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    private var canvasHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDivision.title)
                    .designTextStyle(.section)
                Text(selectedDivision.domain)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                if selectedDivision == .d60 {
                    Text("Lagna amsa: \(lagnaAmsaCaption)")
                        .designTextStyle(.caption, monospacedDigits: true)
                        .foregroundStyle(DesignColor.secondaryText)
                }
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
    }

    private var lagnaAmsaCaption: String {
        guard let detail = currentVarga.lagnaAmsaDetail else { return "—" }
        return "\(detail.index) \(detail.deity)"
    }

    // MARK: - Rotation

    private func rotate(toLagna rasi: Rasi) {
        let natalSignRaw = currentVarga.lagnaRasi.rawValue
        let newRotatedHouse = ((rasi.rawValue - natalSignRaw + 12) % 12) + 1
        withAnimation(.easeInOut(duration: 0.2)) {
            rotatedLagnaHouse = newRotatedHouse
        }
    }

    private func resetRotation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            rotatedLagnaHouse = 1
        }
    }

    // MARK: - Derived state

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

    /// House number (1 ... 12) of a sign counted from the effective (possibly rotated) lagna.
    private func house(of rasi: Rasi) -> Int {
        ((rasi.rawValue - effectiveVargaLagnaRasi.rawValue + 12) % 12) + 1
    }

    /// Gulika and Maandi in this varga, in the fixed upagraha order; empty when unknown.
    private var upagrahaPlacements: [(kind: UpagrahaKind, rasi: Rasi)] {
        guard let rasis = currentVarga.upagrahaRasis else { return [] }
        return UpagrahaKind.allCases.compactMap { kind -> (kind: UpagrahaKind, rasi: Rasi)? in
            guard let rasi = rasis[kind] else { return nil }
            return (kind: kind, rasi: rasi)
        }
    }

    private var upagrahaHouseLabels: [Int: [String]] {
        var map: [Int: [String]] = [:]
        for placement in upagrahaPlacements {
            map[house(of: placement.rasi), default: []].append(placement.kind.shortAbbreviation)
        }
        return map
    }

    private var upagrahaRasiLabels: [Rasi: [String]] {
        var map: [Rasi: [String]] = [:]
        for placement in upagrahaPlacements {
            map[placement.rasi, default: []].append(placement.kind.shortAbbreviation)
        }
        return map
    }

    private var placementRows: [VargaPlacementRow] {
        let grahaRows = Graha.allCases.compactMap { graha -> VargaPlacementRow? in
            guard graha != .ascendant, let rasi = currentVarga.planetRasis[graha] else { return nil }
            return VargaPlacementRow(
                id: graha.rawValue,
                glyph: graha.astronomicalGlyph,
                name: graha.sanskritName,
                house: house(of: rasi),
                rasi: rasi,
                isVargottama: checkVargottama(graha: graha, vargaRasi: rasi),
                amsa: currentVarga.planetAmsaDetails?[graha]
            )
        }
        let upagrahaRows = upagrahaPlacements.map { placement in
            VargaPlacementRow(
                id: placement.kind.rawValue,
                glyph: placement.kind.shortAbbreviation,
                name: placement.kind.rawValue,
                house: house(of: placement.rasi),
                rasi: placement.rasi,
                isVargottama: false,
                amsa: nil
            )
        }
        return grahaRows + upagrahaRows
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
        for (graha, rasi) in varga.planetRasis {
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
                bhava: house(of: rasi),
                charaKaraka: nil,
                speedDegPerDay: nil
            )
            map[house(of: rasi), default: []].append(pos)
        }
        return map
    }
}

// MARK: - Placements list

/// One row of the right-hand placements list: a graha or an upagraha in the selected varga.
private struct VargaPlacementRow: Identifiable {
    let id: String
    let glyph: String
    let name: String
    let house: Int
    let rasi: Rasi
    let isVargottama: Bool
    /// Shashtiamsa index and deity; only present for grahas in D-60.
    let amsa: ShashtiamsaDetail?
}

private struct VargaPlacementsList: View {
    let rows: [VargaPlacementRow]
    /// True for D-60, where the amsa column is shown for every graha row.
    let showsAmsa: Bool
    let isRotated: Bool

    var body: some View {
        List(rows) { row in
            HStack(spacing: DesignSpacing.small) {
                Text(row.glyph)
                    .designTextStyle(.body)
                    .frame(width: 24)
                Text(row.name)
                    .designTextStyle(.body)
                    .fontWeight(.medium)
                Spacer()
                if showsAmsa {
                    amsaText(for: row.amsa)
                }
                Text("H\(row.house) · \(row.rasi.sanskritName)")
                    .designTextStyle(.body, monospacedDigits: true)
                    .foregroundStyle(isRotated ? DesignColor.accent : DesignColor.primaryText)
                if row.isVargottama {
                    badge("Vargottama", background: DesignColor.accent.opacity(0.15), foreground: DesignColor.accent)
                }
                if showsAmsa, let amsa = row.amsa {
                    natureBadge(isBenefic: amsa.isBenefic)
                }
            }
            .padding(.vertical, 2)
        }
        .listStyle(.inset)
    }

    @ViewBuilder
    private func amsaText(for amsa: ShashtiamsaDetail?) -> some View {
        if let amsa {
            Text("\(amsa.index) \(amsa.deity)")
                .designTextStyle(.body, monospacedDigits: true)
                .foregroundStyle(DesignColor.secondaryText)
        } else {
            Text("—")
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private func natureBadge(isBenefic: Bool) -> some View {
        badge(
            isBenefic ? "Benefic" : "Malefic",
            background: (isBenefic ? DesignColor.benefic : DesignColor.malefic).opacity(0.15),
            foreground: isBenefic ? DesignColor.benefic : DesignColor.malefic
        )
    }

    private func badge(_ title: String, background: Color, foreground: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
