import SwiftUI

// Table helpers for the Jaimini page. Each table is a plain native `Table`
// with a fixed height so that it sits inside the page's scroll view.

/// One row of the chara karaka table.
struct JaiminiKarakaRow: Identifiable {
    let karaka: CharaKaraka
    let graha: Graha
    /// D-1 position of the graha; nil when the chart lacks it.
    let position: PlanetPosition?

    var id: String { karaka.rawValue }
}

struct JaiminiKarakaTable: View {
    let rows: [JaiminiKarakaRow]

    var body: some View {
        Table(rows) {
            TableColumn("Karaka") { row in
                HStack(spacing: DesignSpacing.xSmall) {
                    Text(row.karaka.rawValue)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignColor.accent)
                    Text(row.karaka.title)
                }
                .designTextStyle(.body)
            }
            .width(min: 170, ideal: 230)

            TableColumn("Graha") { row in
                HStack(spacing: DesignSpacing.xSmall) {
                    Text(row.graha.astronomicalGlyph)
                    Text(row.graha.sanskritName)
                        .fontWeight(.medium)
                }
                .designTextStyle(.body)
            }
            .width(min: 90, ideal: 110)

            TableColumn("Degree") { row in
                Text(row.position?.formattedDMS ?? "—")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 90, ideal: 105)

            TableColumn("Rasi") { row in
                Text(row.position?.rasi.sanskritName ?? "—")
                    .designTextStyle(.body)
            }
            .width(min: 90, ideal: 110)
        }
        .frame(height: 240)
        .jaiminiTableFrame()
    }
}

struct JaiminiArudhaTable: View {
    let padas: [ArudhaPada]
    let lagnaRasi: Rasi

    var body: some View {
        Table(padas) {
            TableColumn("Pada") { pada in
                Text(pada.name)
                    .fontWeight(.semibold)
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 50, ideal: 60)

            TableColumn("Bhava") { pada in
                Text("\(pada.house)")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 50, ideal: 60)

            TableColumn("Bhava sign") { pada in
                Text(lagnaRasi.advanced(by: pada.house - 1).sanskritName)
                    .designTextStyle(.body)
            }
            .width(min: 100, ideal: 120)

            TableColumn("Lord") { pada in
                HStack(spacing: DesignSpacing.xSmall) {
                    Text(pada.lord.astronomicalGlyph)
                    Text(pada.lord.sanskritName)
                }
                .designTextStyle(.body)
            }
            .width(min: 90, ideal: 110)

            TableColumn("Pada sign") { pada in
                Text("\(pada.rasi.sanskritName) (\(pada.rasi.englishName))")
                    .designTextStyle(.body)
            }
            .width(min: 140, ideal: 170)

            TableColumn("Exception") { pada in
                Text(pada.exceptionApplied ? "✓" : "—")
                    .designTextStyle(.body)
                    .foregroundStyle(pada.exceptionApplied ? DesignColor.accent : DesignColor.secondaryText)
            }
            .width(min: 70, ideal: 80)
        }
        .frame(height: 340)
        .jaiminiTableFrame()
    }
}

struct JaiminiSpecialLagnaTable: View {
    let lagnas: [SpecialLagnaPosition]

    var body: some View {
        Table(SpecialLagnaKind.allCases) {
            TableColumn("Lagna") { kind in
                HStack(spacing: DesignSpacing.xSmall) {
                    Text(kind.shortAbbreviation)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignColor.accent)
                    Text(kind.rawValue)
                }
                .designTextStyle(.body)
            }
            .width(min: 130, ideal: 150)

            TableColumn("Sign") { kind in
                Text(lagna(for: kind)?.rasi.sanskritName ?? "—")
                    .designTextStyle(.body)
            }
            .width(min: 100, ideal: 120)

            TableColumn("Longitude") { kind in
                Text(lagna(for: kind)?.formattedDMS ?? "—")
                    .designTextStyle(.body, monospacedDigits: true)
            }
            .width(min: 90, ideal: 105)

            TableColumn("Basis") { kind in
                Text(Self.basis(for: kind))
                    .designTextStyle(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
            }
            .width(min: 220, ideal: 300)
        }
        .frame(height: 210)
        .jaiminiTableFrame()
    }

    private func lagna(for kind: SpecialLagnaKind) -> SpecialLagnaPosition? {
        lagnas.first(where: { $0.kind == kind })
    }

    /// Short statement of each rule with its classical source.
    private static func basis(for kind: SpecialLagnaKind) -> String {
        switch kind {
        case .bhavaLagna: "Sun at sunrise + 15° per hour (BPHS Ch. 5)"
        case .horaLagna: "Sun at sunrise + 30° per hour (BPHS Ch. 5)"
        case .ghatiLagna: "Sun at sunrise + 75° per hour (BPHS Ch. 5)"
        case .induLagna: "Kalas of the 9th lords from Lagna and Moon (Uttara Kalamrita)"
        case .sreeLagna: "Lagna + Moon's nakshatra fraction × 360° (BPHS Ch. 5)"
        case .varnadaLagna: "Varnas of Lagna and Hora Lagna (BPHS Ch. 6)"
        }
    }
}

private struct JaiminiTableFrame: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignColor.separator, lineWidth: 1)
            )
    }
}

private extension View {
    func jaiminiTableFrame() -> some View {
        modifier(JaiminiTableFrame())
    }
}
