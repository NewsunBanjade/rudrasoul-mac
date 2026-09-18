import SwiftUI

struct ProgressionTransitView: View {
    let chart: ChartDetail
    @State private var transitDate: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            // Top Stepper Toolbar
            HStack {
                Text("Transit Target:")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)

                TransitDateStepper(date: $transitDate)

                Spacer()

                Text("Ayanamsa: \(chart.ayanamsaName)")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            .padding(.horizontal, DesignSpacing.medium)
            .padding(.vertical, DesignSpacing.small)
            .background(DesignColor.groupedBackground)
            .overlay(alignment: .bottom) { Divider() }

            // Table comparing Natal vs Transit positions
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

                TableColumn("Natal Rasi & Longitude") { p in
                    Text("\(p.rasi.sanskritName) \(p.formattedDMS)")
                        .designTextStyle(.body, monospacedDigits: true)
                }
                .width(min: 140, ideal: 170)

                TableColumn("Transit Position (Gochara)") { p in
                    Text(transitPositionString(for: p.graha))
                        .designTextStyle(.body, monospacedDigits: true)
                        .foregroundColor(DesignColor.accent)
                }
                .width(min: 140, ideal: 170)

                TableColumn("House from Natal Moon") { p in
                    let h = houseFromMoon(rasi: p.rasi)
                    Text("\(h)th Bhava")
                        .designTextStyle(.body, monospacedDigits: true)
                }
                .width(min: 120, ideal: 140)

                TableColumn("Transit Quality") { p in
                    let isAuspicious = [1, 2, 4, 5, 9, 10, 11].contains(houseFromMoon(rasi: p.rasi))
                    Text(isAuspicious ? "Favorable" : "Challenging")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isAuspicious ? DesignColor.benefic : DesignColor.malefic)
                }
                .width(min: 100, ideal: 120)
            }
        }
        .background(DesignColor.background)
    }

    private func transitPositionString(for graha: Graha) -> String {
        switch graha {
        case .sun: return "Virgo 02° 15' 20\""
        case .moon: return "Scorpio 18° 40' 12\""
        case .mars: return "Gemini 25° 10' 04\""
        case .mercury: return "Leo 29° 05' 50\""
        case .jupiter: return "Taurus 26° 14' 33\""
        case .venus: return "Virgo 14° 22' 08\""
        case .saturn: return "Aquarius 21° 04' 19\" (R)"
        case .rahu: return "Pisces 12° 50' 11\""
        case .ketu: return "Virgo 12° 50' 11\""
        case .ascendant: return "Pisces 02° 14' 00\""
        }
    }

    private func houseFromMoon(rasi: Rasi) -> Int {
        guard let moonRasi = chart.planets.first(where: { $0.graha == .moon })?.rasi else { return 1 }
        return ((rasi.rawValue - moonRasi.rawValue + 12) % 12) + 1
    }
}
