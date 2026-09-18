import SwiftUI

struct NakshatraView: View {
    let chart: ChartDetail

    var body: some View {
        Table(Nakshatra.allCases.filter { $0 != .abhijit }) {
            TableColumn("#") { n in
                Text("\(n.rawValue)")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(40)

            TableColumn("Nakshatra") { n in
                HStack(spacing: 4) {
                    Text(n.name)
                        .fontWeight(.medium)
                    if n == chart.lagnaPosition.nakshatra {
                        Text("Lagna")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DesignColor.accent.opacity(0.15))
                            .foregroundStyle(DesignColor.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    if n == moonNakshatra {
                        Text("Moon")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DesignColor.benefic.opacity(0.15))
                            .foregroundStyle(DesignColor.benefic)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                .designTextStyle(.body)
            }
            .width(min: 140, ideal: 160)

            TableColumn("Ruler Graha") { n in
                HStack(spacing: 4) {
                    Text(n.lord.astronomicalGlyph)
                    Text(n.lord.sanskritName)
                }
                .designTextStyle(.body)
            }
            .width(min: 110, ideal: 130)

            TableColumn("Presiding Deity") { n in
                Text(n.deity)
                    .designTextStyle(.body)
            }
            .width(min: 130, ideal: 160)

            TableColumn("Gana") { n in
                Text(n.gana)
                    .designTextStyle(.body)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Resident Planets") { n in
                let occupants = chart.planets.filter { $0.nakshatra == n }
                if occupants.isEmpty {
                    Text("—")
                        .foregroundStyle(DesignColor.secondaryText)
                        .designTextStyle(.body)
                } else {
                    Text(occupants.map { "\($0.graha.sanskritName) (Pada \($0.pada))" }.joined(separator: ", "))
                        .designTextStyle(.body)
                        .fontWeight(.medium)
                }
            }
            .width(min: 160, ideal: 220)
        }
        .background(DesignColor.background)
    }

    private var moonNakshatra: Nakshatra? {
        chart.planets.first(where: { $0.graha == .moon })?.nakshatra
    }
}
