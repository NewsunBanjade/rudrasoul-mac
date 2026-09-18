import SwiftUI

/// The chart's front page: the key placements, the D-1 and D-9 kundalis, every position
/// (Lagna, planets and upagrahas) in one table, the mahadasha timeline, and Shadbala at
/// a glance.
struct OverviewView: View {
    let chart: ChartDetail
    @State private var style: KundaliStyle = .northIndian
    @State private var d1Rotation = KundaliRotation()
    @State private var d9Rotation = KundaliRotation()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.large) {
                metricStrip
                kundaliSection
                positionsSection
                OverviewDashaStrip(nodes: chart.dashaNodes, activeVector: chart.currentDashaVector)
                OverviewStrengthStrip(shadbala: chart.shadbala)
            }
            .padding(DesignSpacing.medium)
        }
        .background(DesignColor.background)
    }

    // MARK: - Metrics

    private var moon: PlanetPosition? {
        chart.planets.first { $0.graha == .moon }
    }

    private var metricStrip: some View {
        HStack(spacing: DesignSpacing.small) {
            MetricTile(
                title: "Lagna (Ascendant)",
                value: "\(chart.lagnaPosition.rasi.sanskritName) \(chart.lagnaPosition.formattedDMS)",
                subtitle: "\(chart.lagnaPosition.nakshatra.name) pada \(chart.lagnaPosition.pada) · lord \(chart.lagnaPosition.rasi.lord.sanskritName)",
                badge: "1st bhava"
            )

            MetricTile(
                title: "Janma Nakshatra (Moon)",
                value: moon?.nakshatra.name ?? "—",
                subtitle: moon.map { "\($0.rasi.sanskritName) \($0.formattedDMS) · lord \($0.nakshatra.lord.sanskritName)" } ?? "",
                badge: moon.map { "Pada \($0.pada)" }
            )

            MetricTile(
                title: "Running Vimshottari Period",
                value: chart.currentDashaVector.components(separatedBy: "›").prefix(2).joined(separator: "› "),
                subtitle: chart.currentDashaVector,
                badge: "MD › AD",
                isAuspicious: true
            )

            MetricTile(
                title: "Sunrise – Sunset",
                value: sunriseSunsetValue,
                subtitle: [chart.vara?.name, timezoneAbbreviation].compactMap { $0 }.joined(separator: " · "),
                badge: chart.vara?.sanskritName
            )
        }
    }

    private var sunriseSunsetValue: String {
        let sunrise = chart.sunriseString.isEmpty ? "—" : chart.sunriseString
        let sunset = chart.sunsetString.isEmpty ? "—" : chart.sunsetString
        return "\(sunrise) – \(sunset)"
    }

    private var timezoneAbbreviation: String? {
        chart.timezoneString.components(separatedBy: " ").first
    }

    // MARK: - Kundalis

    private var d9: VargaChart? {
        chart.vargas.first { $0.division == .d9 }
    }

    private var kundaliSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("Kundali")
                    .designTextStyle(.section)
                Text("Right-click a house to view the chart from it (bhavat bhavam).")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                Spacer()
                Picker("Style", selection: $style) {
                    ForEach(KundaliStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .labelsHidden()
                .frame(width: 220)
            }

            if d1Rotation.isRotated || d9Rotation.isRotated {
                rotationBanner
            }

            HStack(alignment: .top, spacing: DesignSpacing.medium) {
                KundaliPanel(
                    title: "D-1 Rasi",
                    natalLagna: chart.lagnaPosition.rasi,
                    planetRasis: d1PlanetRasis,
                    retrogradeGrahas: retrogradeGrahas,
                    extraLabels: d1ExtraLabels,
                    style: style,
                    rotation: $d1Rotation
                )

                if let d9 {
                    KundaliPanel(
                        title: "D-9 Navamsha",
                        natalLagna: d9.lagnaRasi,
                        planetRasis: d9.planetRasis,
                        retrogradeGrahas: retrogradeGrahas,
                        extraLabels: extraLabels(from: d9.upagrahaRasis),
                        style: style,
                        rotation: $d9Rotation
                    )
                }
            }
        }
    }

    private var rotationBanner: some View {
        HStack(spacing: DesignSpacing.small) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(DesignColor.accent)
            Text(rotationDescription)
                .font(.caption.weight(.medium))
                .foregroundStyle(DesignColor.primaryText)
            Spacer()
            Button("Reset to natal") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    d1Rotation.reset()
                    d9Rotation.reset()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
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

    private var rotationDescription: String {
        var parts: [String] = []
        if d1Rotation.isRotated {
            parts.append("D-1 seen from natal house \(d1Rotation.house) (\(effectiveD1Lagna.sanskritName))")
        }
        if d9Rotation.isRotated, let d9 {
            parts.append("D-9 seen from house \(d9Rotation.house) (\(d9Rotation.effectiveLagna(natal: d9.lagnaRasi).sanskritName))")
        }
        return "Bhavat bhavam: " + parts.joined(separator: " · ")
    }

    private var d1PlanetRasis: [Graha: Rasi] {
        var map: [Graha: Rasi] = [:]
        for planet in chart.planets {
            map[planet.graha] = planet.rasi
        }
        return map
    }

    private var retrogradeGrahas: Set<Graha> {
        Set(chart.planets.filter(\.isRetrograde).map(\.graha))
    }

    private var d1ExtraLabels: [Rasi: [String]] {
        var map: [Rasi: [String]] = [:]
        for upagraha in chart.upagrahas ?? [] {
            map[upagraha.rasi, default: []].append(upagraha.kind.shortAbbreviation)
        }
        return map
    }

    private func extraLabels(from rasis: [UpagrahaKind: Rasi]?) -> [Rasi: [String]] {
        var map: [Rasi: [String]] = [:]
        for kind in UpagrahaKind.allCases {
            guard let rasi = rasis?[kind] else { continue }
            map[rasi, default: []].append(kind.shortAbbreviation)
        }
        return map
    }

    // MARK: - Positions

    private var effectiveD1Lagna: Rasi {
        d1Rotation.effectiveLagna(natal: chart.lagnaPosition.rasi)
    }

    private var positionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline) {
                Text("Positions")
                    .designTextStyle(.section)
                Spacer()
                Text(d1Rotation.isRotated
                    ? "Bhava counted from \(effectiveD1Lagna.sanskritName); natal bhava in brackets"
                    : "Bhava counted from the Lagna sign · R retrograde · C combust")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }

            OverviewPositionsGrid(rows: positionRows, isRotated: d1Rotation.isRotated)

            if chart.upagrahas == nil {
                Text("Gulika and Maandi are not stored for this chart. Use Recalculate (⇧⌘R) to add them.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
        }
    }

    private var positionRows: [OverviewPositionRow] {
        let natalLagna = chart.lagnaPosition.rasi
        let lagna = effectiveD1Lagna
        let rotated = d1Rotation.isRotated
        var rows: [OverviewPositionRow] = []

        let ascendant = chart.lagnaPosition
        rows.append(
            OverviewPositionRow(
                id: "lagna",
                glyph: "As",
                name: "Lagna",
                rasi: ascendant.rasi,
                formattedDMS: ascendant.formattedDMS,
                nakshatra: ascendant.nakshatra,
                pada: ascendant.pada,
                bhava: lagna.count(to: ascendant.rasi),
                natalBhava: rotated ? 1 : nil,
                dignity: nil,
                isRetrograde: false,
                isCombust: false,
                speedDegPerDay: nil,
                isLagna: true
            )
        )

        for planet in chart.planets {
            rows.append(
                OverviewPositionRow(
                    id: planet.graha.rawValue,
                    glyph: planet.graha.astronomicalGlyph,
                    name: planet.graha.sanskritName,
                    rasi: planet.rasi,
                    formattedDMS: planet.formattedDMS,
                    nakshatra: planet.nakshatra,
                    pada: planet.pada,
                    bhava: lagna.count(to: planet.rasi),
                    natalBhava: rotated ? natalLagna.count(to: planet.rasi) : nil,
                    dignity: planet.dignity,
                    isRetrograde: planet.isRetrograde,
                    isCombust: planet.isCombust,
                    speedDegPerDay: planet.speedDegPerDay,
                    isLagna: false
                )
            )
        }

        for upagraha in chart.upagrahas ?? [] {
            rows.append(
                OverviewPositionRow(
                    id: upagraha.kind.rawValue,
                    glyph: upagraha.kind.shortAbbreviation,
                    name: upagraha.kind.rawValue,
                    rasi: upagraha.rasi,
                    formattedDMS: upagraha.formattedDMS,
                    nakshatra: upagraha.nakshatra,
                    pada: upagraha.pada,
                    bhava: lagna.count(to: upagraha.rasi),
                    natalBhava: rotated ? natalLagna.count(to: upagraha.rasi) : nil,
                    dignity: nil,
                    isRetrograde: false,
                    isCombust: false,
                    speedDegPerDay: nil,
                    isLagna: false
                )
            )
        }

        return rows
    }
}
