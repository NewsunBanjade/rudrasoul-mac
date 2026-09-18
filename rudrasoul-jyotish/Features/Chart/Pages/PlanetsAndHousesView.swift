import SwiftUI

struct PlanetsAndHousesView: View {
    let chart: ChartDetail
    @State private var viewMode: Int = 0 // 0 = Planets, 1 = Bhava Chalit

    var body: some View {
        VStack(spacing: 0) {
            // Segmented Header Switcher
            HStack {
                Picker("", selection: $viewMode) {
                    Text("Planetary Positions & Dignities").tag(0)
                    Text("Bhava Chalit & House Cusps").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
                Spacer()
            }
            .padding(.horizontal, DesignSpacing.medium)
            .padding(.vertical, DesignSpacing.small)
            .background(DesignColor.groupedBackground)
            .overlay(alignment: .bottom) { Divider() }

            if viewMode == 0 {
                planetsTable
                upagrahaSection
            } else {
                bhavasTable
            }
        }
        .background(DesignColor.background)
    }

    /// Hours and minutes of the rising instant, always shown in UTC because
    /// `UpagrahaPosition.risingDate` is a UTC instant.
    private var risingTimeStyle: Date.FormatStyle {
        Date.FormatStyle(timeZone: .gmt).hour().minute()
    }

    private var upagrahaSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            Text("Upagrahas")
                .designTextStyle(.section)

            if let upagrahas = chart.upagrahas, !upagrahas.isEmpty {
                upagrahaGrid(upagrahas)
            } else {
                Text("Gulika and Maandi are not available for this chart.")
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSpacing.medium)
        .overlay(alignment: .top) { Divider() }
    }

    private func upagrahaGrid(_ upagrahas: [UpagrahaPosition]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: DesignSpacing.medium, verticalSpacing: DesignSpacing.xSmall) {
            GridRow {
                upagrahaHeader("Point")
                upagrahaHeader("Rasi")
                upagrahaHeader("Longitude")
                upagrahaHeader("Nakshatra (Pada)")
                upagrahaHeader("Bhava")
                upagrahaHeader("Rises (UTC)")
            }

            ForEach(upagrahas) { u in
                GridRow {
                    Text(u.kind.rawValue)
                        .designTextStyle(.body)
                        .fontWeight(.medium)
                    Text("\(u.rasi.sanskritName) (\(u.rasi.englishName))")
                        .designTextStyle(.body)
                    Text(u.formattedDMS)
                        .designTextStyle(.body, monospacedDigits: true)
                    Text("\(u.nakshatra.name) - \(u.pada)")
                        .designTextStyle(.body, monospacedDigits: true)
                    Text("\(u.bhava)")
                        .designTextStyle(.body, monospacedDigits: true)
                    Text(u.risingDate, format: risingTimeStyle)
                        .designTextStyle(.body, monospacedDigits: true)
                }
            }
        }
    }

    private func upagrahaHeader(_ title: String) -> some View {
        Text(title)
            .designTextStyle(.caption)
            .foregroundStyle(DesignColor.secondaryText)
    }

    private var planetsTable: some View {
        Table(chart.planets) {
            TableColumn("Graha") { p in
                HStack(spacing: 4) {
                    Text(p.graha.astronomicalGlyph)
                    Text(p.graha.sanskritName)
                        .fontWeight(.medium)
                    if p.isRetrograde {
                        Text("R")
                            .font(.system(size: 10, weight: .bold).monospaced())
                            .foregroundColor(DesignColor.accent)
                    }
                }
                .designTextStyle(.body)
            }
            .width(min: 120, ideal: 140)

            TableColumn("Rasi") { p in
                Text("\(p.rasi.sanskritName) (\(p.rasi.englishName))")
                    .designTextStyle(.body)
            }
            .width(min: 130, ideal: 150)

            TableColumn("Longitude") { p in
                Text(p.formattedDMS)
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 95, ideal: 110)

            TableColumn("Nakshatra (Pada)") { p in
                Text("\(p.nakshatra.name) - \(p.pada)")
                    .designTextStyle(.body)
            }
            .width(min: 130, ideal: 150)

            TableColumn("Lord") { p in
                Text(p.nakshatra.lord.sanskritName)
                    .designTextStyle(.body)
            }
            .width(min: 80, ideal: 95)

            TableColumn("Bhava") { p in
                Text("\(p.bhava)")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(55)

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
            .width(min: 110, ideal: 125)

            TableColumn("Karaka") { p in
                Text(p.charaKaraka?.rawValue ?? "—")
                    .designTextStyle(.body, monospacedDigits: true)
                    .foregroundColor(p.charaKaraka == .atmakaraka ? DesignColor.accent : DesignColor.secondaryText)
            }
            .width(min: 60, ideal: 75)
        }
    }

    private var bhavasTable: some View {
        Table(chart.bhavas) {
            TableColumn("House") { b in
                Text("\(b.number)")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(50)

            TableColumn("Name") { b in
                Text(b.name)
                    .designTextStyle(.body)
                    .fontWeight(.medium)
            }
            .width(min: 110, ideal: 130)

            TableColumn("Rasi") { b in
                Text("\(b.rasi.sanskritName) (\(b.rasi.englishName))")
                    .designTextStyle(.body)
            }
            .width(min: 130, ideal: 150)

            TableColumn("Cusp Longitude") { b in
                Text(b.cuspLongitudeDMS)
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 95, ideal: 110)

            TableColumn("Lord") { b in
                Text(b.lord.sanskritName)
                    .designTextStyle(.body)
            }
            .width(min: 90, ideal: 105)

            TableColumn("Occupants") { b in
                if b.occupantGrahas.isEmpty {
                    Text("—")
                        .foregroundStyle(DesignColor.secondaryText)
                        .designTextStyle(.body)
                } else {
                    Text(b.occupantGrahas.map { $0.sanskritName }.joined(separator: ", "))
                        .designTextStyle(.body)
                        .fontWeight(.medium)
                }
            }
            .width(min: 130, ideal: 160)

            TableColumn("Significations") { b in
                Text(b.significance)
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            .width(min: 200, ideal: 300)
        }
    }
}
