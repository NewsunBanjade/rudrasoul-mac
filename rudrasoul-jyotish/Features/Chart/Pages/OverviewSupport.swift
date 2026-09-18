import SwiftUI

// Building blocks of the Overview page: kundali rotation, the kundali panel, and the
// unified positions grid. The timeline and Shadbala strips live in OverviewStrips.swift.

/// Bhavat-bhavam rotation of one kundali: which natal house is treated as the Lagna.
struct KundaliRotation: Equatable {
    var house: Int = 1

    var isRotated: Bool { house != 1 }

    func effectiveLagna(natal: Rasi) -> Rasi {
        natal.advanced(by: house - 1)
    }

    mutating func rotate(toLagna rasi: Rasi, natal: Rasi) {
        house = natal.count(to: rasi)
    }

    mutating func reset() {
        house = 1
    }
}

enum KundaliStyle: Int, CaseIterable, Identifiable {
    case northIndian = 0
    case southIndian = 1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .northIndian: "North Indian"
        case .southIndian: "South Indian"
        }
    }
}

extension PlanetPosition {
    /// A sign-only placement for drawing charts whose degrees are not needed.
    static func signPlaceholder(graha: Graha, rasi: Rasi, bhava: Int, isRetrograde: Bool = false) -> PlanetPosition {
        PlanetPosition(
            graha: graha,
            rasi: rasi,
            longitudeInRasi: 0,
            formattedDMS: "",
            nakshatra: .ashwini,
            pada: 1,
            isRetrograde: isRetrograde,
            isCombust: false,
            dignity: .neutral,
            bhava: bhava,
            charaKaraka: nil,
            speedDegPerDay: nil
        )
    }
}

// MARK: - Kundali panel

/// One kundali (D-1, D-9, ...) with its own rotation, in either drawing style.
struct KundaliPanel: View {
    let title: String
    let natalLagna: Rasi
    let planetRasis: [Graha: Rasi]
    let retrogradeGrahas: Set<Graha>
    /// Short labels (upagrahas, padas) keyed by sign.
    let extraLabels: [Rasi: [String]]
    let style: KundaliStyle
    @Binding var rotation: KundaliRotation

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xSmall) {
            header
            switch style {
            case .northIndian:
                NorthIndianChartCanvas(
                    houseRasis: houseRasis,
                    housePlanets: housePlanets,
                    extraHouseLabels: extraHouseLabels,
                    isRotated: rotation.isRotated,
                    onShowChartFromHouse: { house in
                        if let sign = houseRasis[house] {
                            rotate(to: sign)
                        }
                    },
                    onResetToNatalLagna: { reset() }
                )
            case .southIndian:
                SouthIndianChartCanvas(
                    lagnaRasi: lagna,
                    planetRasis: planetRasis,
                    extraRasiLabels: extraLabels,
                    isRotated: rotation.isRotated,
                    onShowChartFromRasi: { rotate(to: $0) },
                    onResetToNatalLagna: { reset() }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    var lagna: Rasi {
        rotation.effectiveLagna(natal: natalLagna)
    }

    private var header: some View {
        HStack {
            Text(title)
                .designTextStyle(.caption)
                .foregroundStyle(DesignColor.secondaryText)
            Spacer()
            if rotation.isRotated {
                HStack(spacing: 4) {
                    Text("\(lagna.sanskritName) as Lagna (natal house \(rotation.house))")
                        .designTextStyle(.caption, monospacedDigits: true)
                        .foregroundStyle(DesignColor.accent)
                    Button {
                        reset()
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundStyle(DesignColor.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .help("Reset to the natal Lagna")
                }
            } else {
                Text("\(natalLagna.sanskritName) Lagna")
                    .designTextStyle(.caption, monospacedDigits: true)
                    .foregroundStyle(DesignColor.accent)
            }
        }
    }

    private var houseRasis: [Int: Rasi] {
        var map: [Int: Rasi] = [:]
        for house in 1 ... 12 {
            map[house] = lagna.advanced(by: house - 1)
        }
        return map
    }

    /// Planets per house in the canonical graha order, so labels never reorder between draws.
    private var housePlanets: [Int: [PlanetPosition]] {
        var map: [Int: [PlanetPosition]] = [:]
        for graha in Graha.allCases {
            guard let rasi = planetRasis[graha] else { continue }
            let house = lagna.count(to: rasi)
            map[house, default: []].append(
                .signPlaceholder(graha: graha, rasi: rasi, bhava: house, isRetrograde: retrogradeGrahas.contains(graha))
            )
        }
        return map
    }

    private var extraHouseLabels: [Int: [String]] {
        var map: [Int: [String]] = [:]
        for (rasi, labels) in extraLabels {
            map[lagna.count(to: rasi), default: []].append(contentsOf: labels)
        }
        return map
    }

    private func rotate(to rasi: Rasi) {
        withAnimation(.easeInOut(duration: 0.2)) {
            rotation.rotate(toLagna: rasi, natal: natalLagna)
        }
    }

    private func reset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            rotation.reset()
        }
    }
}

// MARK: - Positions grid

/// One row of the Overview positions grid: the Lagna, a planet, or an upagraha.
struct OverviewPositionRow: Identifiable {
    let id: String
    let glyph: String
    let name: String
    let rasi: Rasi
    let formattedDMS: String
    let nakshatra: Nakshatra
    let pada: Int
    /// House counted from the effective (possibly rotated) Lagna.
    let bhava: Int
    /// House counted from the natal Lagna; only set while the chart is rotated.
    let natalBhava: Int?
    /// Nil for the Lagna and the upagrahas, which have no dignity.
    let dignity: Dignity?
    let isRetrograde: Bool
    let isCombust: Bool
    let speedDegPerDay: Double?
    let isLagna: Bool
}

struct OverviewPositionsGrid: View {
    let rows: [OverviewPositionRow]
    let isRotated: Bool

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
            GridRow {
                header("Body")
                header("Rasi")
                header("Longitude")
                header("Nakshatra · Pada")
                header(isRotated ? "Bhava (natal)" : "Bhava")
                header("Dignity")
                header("Motion")
            }
            ForEach(rows) { row in
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    HStack(spacing: 4) {
                        Text(row.glyph)
                            .frame(minWidth: 22, alignment: .leading)
                        Text(row.name)
                            .fontWeight(row.isLagna ? .semibold : .medium)
                    }
                    .designTextStyle(.body)
                    .foregroundStyle(row.isLagna ? DesignColor.accent : DesignColor.primaryText)

                    Text("\(row.rasi.sanskritName) (\(row.rasi.englishName))")
                        .designTextStyle(.body)

                    Text(row.formattedDMS)
                        .designTextStyle(.body, monospacedDigits: true)

                    Text("\(row.nakshatra.name) · \(row.pada)")
                        .designTextStyle(.body, monospacedDigits: true)

                    bhavaCell(row)

                    dignityCell(row)

                    motionCell(row)
                }
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

    private func header(_ title: String) -> some View {
        Text(title)
            .designTextStyle(.caption)
            .foregroundStyle(DesignColor.secondaryText)
    }

    private func bhavaCell(_ row: OverviewPositionRow) -> some View {
        HStack(spacing: 4) {
            Text("\(row.bhava)")
                .fontWeight(row.natalBhava != nil ? .semibold : .regular)
                .foregroundStyle(row.natalBhava != nil ? DesignColor.accent : DesignColor.primaryText)
            if let natalBhava = row.natalBhava {
                Text("(\(natalBhava))")
                    .font(.caption2)
                    .foregroundStyle(DesignColor.secondaryText)
            }
        }
        .designTextStyle(.body, monospacedDigits: true)
    }

    @ViewBuilder
    private func dignityCell(_ row: OverviewPositionRow) -> some View {
        if let dignity = row.dignity {
            HStack(spacing: 4) {
                Text(dignity.rawValue)
                if !dignity.glyph.isEmpty {
                    Text(dignity.glyph)
                        .fontWeight(.bold)
                        .foregroundStyle(dignityColor(dignity))
                }
            }
            .designTextStyle(.body)
        } else {
            Text("—")
                .designTextStyle(.body)
                .foregroundStyle(DesignColor.secondaryText)
        }
    }

    private func dignityColor(_ dignity: Dignity) -> Color {
        switch dignity {
        case .exalted, .moolatrikona, .ownSign: DesignColor.benefic
        case .debilitated: DesignColor.malefic
        default: DesignColor.secondaryText
        }
    }

    private func motionCell(_ row: OverviewPositionRow) -> some View {
        HStack(spacing: 4) {
            if let speed = row.speedDegPerDay {
                Text(String(format: "%+.2f°/d", speed))
                    .designTextStyle(.body, monospacedDigits: true)
            } else {
                Text("—")
                    .designTextStyle(.body)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            if row.isRetrograde {
                flag("R", color: DesignColor.accent, help: "Retrograde")
            }
            if row.isCombust {
                flag("C", color: DesignColor.malefic, help: "Combust (within the Sun's orb)")
            }
        }
    }

    private func flag(_ text: String, color: Color, help: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .help(help)
    }
}
