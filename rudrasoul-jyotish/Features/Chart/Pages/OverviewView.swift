import SwiftUI

struct OverviewView: View {
    let chart: ChartDetail
    @State private var chartStyle: Int = 0 // 0 = North Indian, 1 = South Indian
    @State private var d1RotatedHouse: Int = 1 // 1 = Natal D-1 Lagna, 2...12 = Rotated House
    @State private var d9RotatedHouse: Int = 1 // 1 = Natal D-9 Lagna, 2...12 = Rotated House

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                // Top Quick Metrics Strip
                HStack(spacing: DesignSpacing.small) {
                    MetricTile(
                        title: "Ascendant (Lagna)",
                        value: "\(chart.lagnaPosition.rasi.sanskritName) \(chart.lagnaPosition.formattedDMS)",
                        subtitle: "\(chart.lagnaPosition.nakshatra.name) Pada \(chart.lagnaPosition.pada)",
                        badge: "1st House"
                    )

                    MetricTile(
                        title: "Moon Nakshatra",
                        value: "\(moonPosition?.nakshatra.name ?? "—")",
                        subtitle: "\(moonPosition?.rasi.sanskritName ?? "") \(moonPosition?.formattedDMS ?? "")",
                        badge: "Pada \(moonPosition?.pada ?? 1)"
                    )

                    MetricTile(
                        title: "Current Dasha",
                        value: chart.currentDashaVector.components(separatedBy: "›").prefix(2).joined(separator: "› "),
                        subtitle: chart.currentDashaVector,
                        badge: "Active",
                        isAuspicious: true
                    )

                    MetricTile(
                        title: "Sunrise / Sunset",
                        value: "\(chart.sunriseString) – \(chart.sunsetString)",
                        subtitle: chart.timezoneString.components(separatedBy: " ").first ?? "LMT",
                        badge: "Vara"
                    )
                }

                // Kundali section with style picker
                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    HStack {
                        Text("Kundali Visuals")
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

                    // Independent rotation active banner
                    if isD1Rotated || isD9Rotated {
                        HStack(spacing: DesignSpacing.small) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(DesignColor.accent)

                            if isD1Rotated && isD9Rotated {
                                Text("Bhavat Bhavam: D-1 (H\(d1RotatedHouse) · \(effectiveD1LagnaRasi.sanskritName)), D-9 (H\(d9RotatedHouse) · \(effectiveD9LagnaRasi.sanskritName))")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(DesignColor.primaryText)
                            } else if isD1Rotated {
                                Text("Bhavat Bhavam: D-1 viewed from House \(d1RotatedHouse) (\(effectiveD1LagnaRasi.sanskritName))")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(DesignColor.primaryText)
                            } else {
                                Text("Bhavat Bhavam: D-9 Navamsha viewed from House \(d9RotatedHouse) (\(effectiveD9LagnaRasi.sanskritName))")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(DesignColor.primaryText)
                            }

                            Spacer()

                            if isD1Rotated {
                                Button("Reset D-1") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        d1RotatedHouse = 1
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }

                            if isD9Rotated {
                                Button("Reset D-9") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        d9RotatedHouse = 1
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }

                            if isD1Rotated && isD9Rotated {
                                Button("Reset Both") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        d1RotatedHouse = 1
                                        d9RotatedHouse = 1
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.mini)
                            }
                        }
                        .padding(.horizontal, DesignSpacing.small)
                        .padding(.vertical, 6)
                        .background(DesignColor.accent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DesignColor.accent.opacity(0.25), lineWidth: 1)
                        )
                    }

                    HStack(spacing: DesignSpacing.medium) {
                        // D-1 Rasi Kundali (Rotates independently)
                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            HStack {
                                Text("D-1 Rasi Kundali")
                                    .designTextStyle(.caption)
                                    .foregroundStyle(DesignColor.secondaryText)
                                Spacer()
                                if isD1Rotated {
                                    HStack(spacing: 4) {
                                        Text("\(effectiveD1LagnaRasi.sanskritName) (H\(d1RotatedHouse) As)")
                                            .designTextStyle(.caption, monospacedDigits: true)
                                            .foregroundStyle(DesignColor.accent)
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                d1RotatedHouse = 1
                                            }
                                        } label: {
                                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                                .foregroundColor(DesignColor.secondaryText)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Reset D-1 to Natal Lagna")
                                    }
                                } else {
                                    Text("\(chart.lagnaPosition.rasi.sanskritName) Lagna")
                                        .designTextStyle(.caption, monospacedDigits: true)
                                        .foregroundStyle(DesignColor.accent)
                                }
                            }

                            if chartStyle == 0 {
                                NorthIndianChartCanvas(
                                    houseRasis: effectiveD1HouseRasis,
                                    housePlanets: effectiveD1HousePlanets,
                                    isRotated: isD1Rotated,
                                    onShowChartFromHouse: { house in
                                        if let selectedSign = effectiveD1HouseRasis[house] {
                                            let natalSignRaw = chart.lagnaPosition.rasi.rawValue
                                            let newRotatedHouse = ((selectedSign.rawValue - natalSignRaw + 12) % 12) + 1
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                d1RotatedHouse = newRotatedHouse
                                            }
                                        }
                                    },
                                    onResetToNatalLagna: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            d1RotatedHouse = 1
                                        }
                                    }
                                )
                            } else {
                                SouthIndianChartCanvas(
                                    lagnaRasi: effectiveD1LagnaRasi,
                                    planetRasis: Dictionary(uniqueKeysWithValues: chart.planets.map { ($0.graha, $0.rasi) }),
                                    isRotated: isD1Rotated,
                                    onShowChartFromRasi: { rasi in
                                        let natalSignRaw = chart.lagnaPosition.rasi.rawValue
                                        let newRotatedHouse = ((rasi.rawValue - natalSignRaw + 12) % 12) + 1
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            d1RotatedHouse = newRotatedHouse
                                        }
                                    },
                                    onResetToNatalLagna: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            d1RotatedHouse = 1
                                        }
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // D-9 Navamsha Kundali (Rotates independently)
                        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                            if let d9 = chart.vargas.first(where: { $0.division == .d9 }) {
                                let effD9Lagna = effectiveD9LagnaRasi
                                let effD9Houses = effectiveD9HouseRasis(d9: d9)

                                HStack {
                                    Text("D-9 Navamsha Kundali")
                                        .designTextStyle(.caption)
                                        .foregroundStyle(DesignColor.secondaryText)
                                    Spacer()
                                    if isD9Rotated {
                                        HStack(spacing: 4) {
                                            Text("\(effD9Lagna.sanskritName) (H\(d9RotatedHouse) As)")
                                                .designTextStyle(.caption, monospacedDigits: true)
                                                .foregroundStyle(DesignColor.accent)
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    d9RotatedHouse = 1
                                                }
                                            } label: {
                                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                                    .foregroundColor(DesignColor.secondaryText)
                                            }
                                            .buttonStyle(.plain)
                                            .help("Reset D-9 to Natal Lagna")
                                        }
                                    } else {
                                        Text("\(d9.lagnaRasi.sanskritName) Lagna")
                                            .designTextStyle(.caption, monospacedDigits: true)
                                            .foregroundStyle(DesignColor.secondaryText)
                                    }
                                }

                                if chartStyle == 0 {
                                    NorthIndianChartCanvas(
                                        houseRasis: effD9Houses,
                                        housePlanets: effectiveD9HousePlanets(d9: d9),
                                        isRotated: isD9Rotated,
                                        onShowChartFromHouse: { house in
                                            if let selectedSign = effD9Houses[house] {
                                                let natalD9SignRaw = d9.lagnaRasi.rawValue
                                                let newRotatedHouse = ((selectedSign.rawValue - natalD9SignRaw + 12) % 12) + 1
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    d9RotatedHouse = newRotatedHouse
                                                }
                                            }
                                        },
                                        onResetToNatalLagna: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                d9RotatedHouse = 1
                                            }
                                        }
                                    )
                                } else {
                                    SouthIndianChartCanvas(
                                        lagnaRasi: effD9Lagna,
                                        planetRasis: d9.planetRasis,
                                        isRotated: isD9Rotated,
                                        onShowChartFromRasi: { rasi in
                                            let natalD9SignRaw = d9.lagnaRasi.rawValue
                                            let newRotatedHouse = ((rasi.rawValue - natalD9SignRaw + 12) % 12) + 1
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                d9RotatedHouse = newRotatedHouse
                                            }
                                        },
                                        onResetToNatalLagna: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                d9RotatedHouse = 1
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Lifespan Mahadasha Timeline Bar
                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                    HStack {
                        Text("Vimshottari Mahadasha Timeline")
                            .designTextStyle(.section)
                        Spacer()
                        Text("Focus: \(chart.currentDashaVector)")
                            .designTextStyle(.caption, monospacedDigits: true)
                            .foregroundStyle(DesignColor.accent)
                    }

                    // Continuous horizontal timeline strip
                    HStack(spacing: 2) {
                        ForEach(chart.dashaNodes) { node in
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(node.statusText == "Focused" ? DesignColor.accent : DesignColor.groupedBackground)
                                    .frame(height: 24)
                                    .overlay(
                                        Text("\(node.lord.shortAbbreviation) (\(node.formattedDuration.prefix(3)))")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(node.statusText == "Focused" ? .white : DesignColor.primaryText)
                                    )
                                Text(node.startDate, format: .dateTime.year())
                                    .font(.system(size: 9).monospaced())
                                    .foregroundColor(DesignColor.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(DesignSpacing.small)
                    .background(DesignColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DesignColor.separator, lineWidth: 1)
                    )
                }

                // Planetary Positions Table
                VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
                    Text("Planetary Positions & Dignities")
                        .designTextStyle(.section)

                    Table(chart.planets) {
                        TableColumn("Graha") { p in
                            HStack(spacing: 4) {
                                Text(p.graha.astronomicalGlyph)
                                Text(p.graha.sanskritName)
                                    .fontWeight(.medium)
                            }
                            .designTextStyle(.body)
                        }
                        .width(min: 110, ideal: 130)

                        TableColumn("Rasi") { p in
                            Text("\(p.rasi.sanskritName) (\(p.rasi.englishName))")
                                .designTextStyle(.body)
                        }
                        .width(min: 120, ideal: 140)

                        TableColumn("Longitude") { p in
                            Text(p.formattedDMS)
                                .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 90, ideal: 105)

                        TableColumn("Nakshatra & Pada") { p in
                            Text("\(p.nakshatra.name) - \(p.pada)")
                                .designTextStyle(.body)
                        }
                        .width(min: 120, ideal: 140)

                        TableColumn(isD1Rotated ? "Bhava (Nat)" : "Bhava") { p in
                            let currentBhava = ((p.rasi.rawValue - effectiveD1LagnaRasi.rawValue + 12) % 12) + 1
                            HStack(spacing: 4) {
                                Text("\(currentBhava)")
                                    .fontWeight(isD1Rotated ? .semibold : .regular)
                                    .foregroundColor(isD1Rotated ? DesignColor.accent : DesignColor.primaryText)
                                if isD1Rotated {
                                    Text("(\(p.bhava))")
                                        .font(.caption2)
                                        .foregroundColor(DesignColor.secondaryText)
                                }
                            }
                            .designTextStyle(.body, monospacedDigits: true)
                        }
                        .width(min: 50, ideal: isD1Rotated ? 75 : 50)

                        TableColumn("Dignity") { p in
                            HStack(spacing: 4) {
                                Text(p.dignity.rawValue)
                                if !p.dignity.glyph.isEmpty {
                                    Text(p.dignity.glyph)
                                        .fontWeight(.bold)
                                        .foregroundColor(p.dignity == .exalted ? DesignColor.accent : DesignColor.secondaryText)
                                }
                            }
                            .designTextStyle(.body)
                        }
                        .width(min: 100, ideal: 110)

                        TableColumn("Speed (°/day)") { p in
                            Text(p.speedDegPerDay.map { String(format: "%.2f", $0) } ?? "—")
                                .designTextStyle(.body, monospacedDigits: true)
                                .foregroundColor(p.isRetrograde ? DesignColor.accent : DesignColor.primaryText)
                        }
                        .width(min: 80, ideal: 95)
                    }
                    .frame(height: 260)
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

    private var moonPosition: PlanetPosition? {
        chart.planets.first(where: { $0.graha == .moon })
    }

    private var isD1Rotated: Bool {
        d1RotatedHouse != 1
    }

    private var isD9Rotated: Bool {
        d9RotatedHouse != 1
    }

    private var effectiveD1LagnaRasi: Rasi {
        let raw = ((chart.lagnaPosition.rasi.rawValue - 1 + (d1RotatedHouse - 1)) % 12) + 1
        return Rasi(rawValue: raw) ?? chart.lagnaPosition.rasi
    }

    private var effectiveD1HouseRasis: [Int: Rasi] {
        houseRasis(lagna: effectiveD1LagnaRasi)
    }

    private var effectiveD1HousePlanets: [Int: [PlanetPosition]] {
        var map: [Int: [PlanetPosition]] = [:]
        let effLagnaRaw = effectiveD1LagnaRasi.rawValue
        for p in chart.planets {
            let rotatedBhava = ((p.rasi.rawValue - effLagnaRaw + 12) % 12) + 1
            let rotatedP = PlanetPosition(
                graha: p.graha,
                rasi: p.rasi,
                longitudeInRasi: p.longitudeInRasi,
                formattedDMS: p.formattedDMS,
                nakshatra: p.nakshatra,
                pada: p.pada,
                isRetrograde: p.isRetrograde,
                isCombust: p.isCombust,
                dignity: p.dignity,
                bhava: rotatedBhava,
                charaKaraka: p.charaKaraka,
                speedDegPerDay: p.speedDegPerDay
            )
            map[rotatedBhava, default: []].append(rotatedP)
        }
        return map
    }

    private var effectiveD9LagnaRasi: Rasi {
        guard let d9 = chart.vargas.first(where: { $0.division == .d9 }) else {
            return chart.lagnaPosition.rasi
        }
        let raw = ((d9.lagnaRasi.rawValue - 1 + (d9RotatedHouse - 1)) % 12) + 1
        return Rasi(rawValue: raw) ?? d9.lagnaRasi
    }

    private func effectiveD9HouseRasis(d9: VargaChart) -> [Int: Rasi] {
        houseRasis(lagna: effectiveD9LagnaRasi)
    }

    private func effectiveD9HousePlanets(d9: VargaChart) -> [Int: [PlanetPosition]] {
        var map: [Int: [PlanetPosition]] = [:]
        let effLagnaRaw = effectiveD9LagnaRasi.rawValue
        for (graha, rasi) in d9.planetRasis {
            let house = ((rasi.rawValue - effLagnaRaw + 12) % 12) + 1
            let fakePos = PlanetPosition(
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
            map[house, default: []].append(fakePos)
        }
        return map
    }

    private func houseRasis(lagna: Rasi) -> [Int: Rasi] {
        var map: [Int: Rasi] = [:]
        for h in 1...12 {
            let rasiIndex = ((lagna.rawValue - 1 + (h - 1)) % 12) + 1
            map[h] = Rasi(rawValue: rasiIndex)
        }
        return map
    }
}
