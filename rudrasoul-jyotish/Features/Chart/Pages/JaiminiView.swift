import SwiftUI

/// Jaimini page: chara karakas, arudha padas, karakamsa and the special lagnas.
///
/// Stored `chart.jaimini` data is preferred. Charts saved before the Jaimini
/// module existed have none, so karakas, padas, Indu and Sree lagnas are then
/// derived on the fly from the D-1 positions with the pure calculator; the
/// sunrise-based lagnas show "—" until the chart is recomputed.
struct JaiminiView: View {
    let chart: ChartDetail
    @State private var chartStyle: Int = 0 // 0 = North Indian, 1 = South Indian
    @State private var applyExceptions: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                headerTiles

                HStack(alignment: .top, spacing: DesignSpacing.medium) {
                    kundaliSection
                        .frame(maxWidth: .infinity)
                    karakaSection
                        .frame(maxWidth: .infinity)
                }

                arudhaSection
                specialLagnaSection
            }
            .padding(DesignSpacing.medium)
        }
        .background(DesignColor.background)
    }

    // MARK: - Sections

    private var headerTiles: some View {
        HStack(spacing: DesignSpacing.small) {
            MetricTile(
                title: "Atmakaraka",
                value: atmakarakaPosition?.graha.sanskritName ?? "—",
                subtitle: atmakarakaSubtitle,
                badge: "AK"
            )
            MetricTile(
                title: "Karakamsa",
                value: karakamsaRasi?.sanskritName ?? "—",
                subtitle: "Navamsa of the Atmakaraka"
            )
            MetricTile(
                title: "Lagnamsa",
                value: lagnamsaRasi.sanskritName,
                subtitle: "Navamsa of the Lagna"
            )
            MetricTile(
                title: "Indu Lagna",
                value: specialLagna(.induLagna)?.rasi.sanskritName ?? "—",
                badge: "IL"
            )
            MetricTile(
                title: "Arudha Lagna",
                value: pada(house: 1)?.rasi.sanskritName ?? "—",
                badge: "AL"
            )
            MetricTile(
                title: "Upapada",
                value: pada(house: 12)?.rasi.sanskritName ?? "—",
                badge: "UL"
            )
        }
    }

    private var kundaliSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack {
                Text("Rasi Kundali with padas")
                    .designTextStyle(.section)
                Spacer()
                Picker("", selection: $chartStyle) {
                    Text("North Indian").tag(0)
                    Text("South Indian").tag(1)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 220)
            }

            if chartStyle == 0 {
                NorthIndianChartCanvas(
                    houseRasis: houseRasis,
                    housePlanets: housePlanets,
                    extraHouseLabels: houseLabels
                )
            } else {
                SouthIndianChartCanvas(
                    lagnaRasi: lagnaRasi,
                    planetRasis: planetRasis,
                    extraRasiLabels: rasiLabels
                )
            }

            Text("Secondary labels: arudha padas (AL, A2 … A11, UL) and special lagnas (BL, HL, GL, IL, SL, VL).")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private var karakaSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack {
                Text("Chara karakas")
                    .designTextStyle(.section)
                Spacer()
                Text(schemeName)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }

            JaiminiKarakaTable(rows: karakaRows)

            Text("Ranked by degree within the sign, highest first (BPHS Ch. 32).")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private var arudhaSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack {
                Text("Arudha padas")
                    .designTextStyle(.section)
                Spacer()
                Toggle("Apply classical exceptions", isOn: $applyExceptions)
                    .controlSize(.small)
            }

            JaiminiArudhaTable(padas: arudhaPadas, lagnaRasi: lagnaRasi)

            Text("The pada is as far from the bhava lord as the lord is from the bhava (Jaimini Sutras 1.1.29). Exceptions: a pada falling in the bhava itself moves to the 10th from it; a pada in the 7th from the bhava moves to the 4th from it (1.1.30).")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private var specialLagnaSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            Text("Special lagnas")
                .designTextStyle(.section)

            JaiminiSpecialLagnaTable(lagnas: specialLagnas)

            if hasMissingLagnas {
                Text("Requires sunrise; recompute the chart to fill the missing lagnas.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.warning)
            }
            Text("Indu and Varnada lagnas are sign-based, so they are shown at 0° of their sign.")
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    // MARK: - Derived Jaimini data

    private var lagnaRasi: Rasi {
        chart.lagnaPosition.rasi
    }

    private var schemeName: String {
        (chart.jaimini?.scheme ?? .sevenKarakas).rawValue
    }

    private var charaKarakas: [CharaKaraka: Graha] {
        chart.jaimini?.charaKarakas
            ?? JaiminiCalculator.charaKarakas(planets: chart.planets, scheme: .sevenKarakas)
    }

    private var arudhaPadas: [ArudhaPada] {
        if let stored = chart.jaimini, stored.arudhaExceptionsApplied == applyExceptions {
            return stored.arudhaPadas
        }
        return JaiminiCalculator.arudhaPadas(
            lagnaRasi: lagnaRasi,
            planets: chart.planets,
            applyExceptions: applyExceptions
        )
    }

    private var karakamsaRasi: Rasi? {
        chart.jaimini?.karakamsaRasi
            ?? JaiminiCalculator.karakamsa(charaKarakas: charaKarakas, planets: chart.planets)
    }

    private var lagnamsaRasi: Rasi {
        chart.jaimini?.lagnamsaRasi
            ?? VargaCalculator.rasi(for: chart.lagnaPosition.absoluteLongitude, division: .d9)
    }

    private var specialLagnas: [SpecialLagnaPosition] {
        chart.jaimini?.specialLagnas
            ?? JaiminiCalculator.specialLagnas(
                lagnaLongitude: chart.lagnaPosition.absoluteLongitude,
                planets: chart.planets,
                sunriseContext: nil
            )
    }

    private var hasMissingLagnas: Bool {
        specialLagnas.count < SpecialLagnaKind.allCases.count
    }

    private var atmakarakaPosition: PlanetPosition? {
        charaKarakas[.atmakaraka].flatMap { graha in
            chart.planets.first(where: { $0.graha == graha })
        }
    }

    private var atmakarakaSubtitle: String? {
        guard let position = atmakarakaPosition else { return nil }
        return "\(position.rasi.sanskritName) \(position.formattedDMS)"
    }

    private var karakaRows: [JaiminiKarakaRow] {
        JaiminiCalculator.karakaOrder.compactMap { karaka -> JaiminiKarakaRow? in
            guard let graha = charaKarakas[karaka] else { return nil }
            return JaiminiKarakaRow(
                karaka: karaka,
                graha: graha,
                position: chart.planets.first(where: { $0.graha == graha })
            )
        }
    }

    private func specialLagna(_ kind: SpecialLagnaKind) -> SpecialLagnaPosition? {
        specialLagnas.first(where: { $0.kind == kind })
    }

    private func pada(house: Int) -> ArudhaPada? {
        arudhaPadas.first(where: { $0.house == house })
    }

    // MARK: - Kundali placement

    /// Whole-sign house of a sign counted from the natal Lagna (1 … 12).
    private func house(of rasi: Rasi) -> Int {
        lagnaRasi.count(to: rasi)
    }

    private var houseRasis: [Int: Rasi] {
        var map: [Int: Rasi] = [:]
        for house in 1...12 {
            map[house] = lagnaRasi.advanced(by: house - 1)
        }
        return map
    }

    private var housePlanets: [Int: [PlanetPosition]] {
        var map: [Int: [PlanetPosition]] = [:]
        for planet in chart.planets {
            map[house(of: planet.rasi), default: []].append(planet)
        }
        return map
    }

    private var planetRasis: [Graha: Rasi] {
        Dictionary(uniqueKeysWithValues: chart.planets.map { ($0.graha, $0.rasi) })
    }

    /// Pada names first (in house order), then special lagna abbreviations.
    private var rasiLabels: [Rasi: [String]] {
        var map: [Rasi: [String]] = [:]
        for pada in arudhaPadas {
            map[pada.rasi, default: []].append(pada.name)
        }
        for lagna in specialLagnas {
            map[lagna.rasi, default: []].append(lagna.kind.shortAbbreviation)
        }
        return map
    }

    private var houseLabels: [Int: [String]] {
        var map: [Int: [String]] = [:]
        for (rasi, labels) in rasiLabels {
            map[house(of: rasi)] = labels
        }
        return map
    }
}
