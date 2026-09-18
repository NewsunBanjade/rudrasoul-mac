import SwiftUI

/// A native SwiftUI Canvas rendering the classical South Indian 4x4 fixed-zodiac box Kundali,
/// with interactive house hit-testing and context menu support.
struct SouthIndianChartCanvas: View {
    let lagnaRasi: Rasi
    let planetRasis: [Graha: Rasi]
    var isRotated: Bool = false
    var onShowChartFromRasi: ((Rasi) -> Void)? = nil
    var onResetToNatalLagna: (() -> Void)? = nil

    // Fixed South Indian sign layout: 4x4 grid where center 2x2 is merged/empty
    // Row 0: Pisces(12), Aries(1), Taurus(2), Gemini(3)
    // Row 1: Aquarius(11), [Center], [Center], Cancer(4)
    // Row 2: Capricorn(10), [Center], [Center], Leo(5)
    // Row 3: Sagittarius(9), Scorpio(8), Libra(7), Virgo(6)
    private static let gridRasis: [[Rasi?]] = [
        [.pisces, .aries, .taurus, .gemini],
        [.aquarius, nil, nil, .cancer],
        [.capricorn, nil, nil, .leo],
        [.sagittarius, .scorpio, .libra, .virgo]
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    let w = size.width
                    let h = size.height
                    let cellW = w / 4.0
                    let cellH = h / 4.0

                    // Grid outer border
                    let outerRect = CGRect(x: 0.5, y: 0.5, width: w - 1, height: h - 1)
                    context.stroke(Path(outerRect), with: .color(DesignColor.separator), lineWidth: 1)

                    // Cell dividers
                    for col in 1..<4 {
                        let x = CGFloat(col) * cellW
                        var line = Path()
                        line.move(to: CGPoint(x: x, y: 0))
                        line.addLine(to: CGPoint(x: x, y: h))
                        context.stroke(line, with: .color(DesignColor.separator), lineWidth: 1)
                    }
                    for row in 1..<4 {
                        let y = CGFloat(row) * cellH
                        var line = Path()
                        line.move(to: CGPoint(x: 0, y: y))
                        line.addLine(to: CGPoint(x: w, y: y))
                        context.stroke(line, with: .color(DesignColor.separator), lineWidth: 1)
                    }

                    // Draw center fill to cover center 2x2 lines
                    let centerRect = CGRect(x: cellW, y: cellH, width: cellW * 2, height: cellH * 2)
                    context.fill(Path(centerRect), with: .color(DesignColor.groupedBackground))
                    context.stroke(Path(centerRect), with: .color(DesignColor.separator), lineWidth: 1)

                    // Center watermark / label
                    let centerText = Text("South Indian\nFixed Zodiac")
                        .font(.caption.weight(.medium))
                        .foregroundColor(DesignColor.secondaryText)
                    context.draw(context.resolve(centerText), at: CGPoint(x: w / 2, y: h / 2), anchor: .center)

                    // Fill each zodiac cell
                    for (rowIndex, row) in Self.gridRasis.enumerated() {
                        for (colIndex, rasiOpt) in row.enumerated() {
                            guard let rasi = rasiOpt else { continue }
                            let cellX = CGFloat(colIndex) * cellW
                            let cellY = CGFloat(rowIndex) * cellH

                            // Rasi abbreviation top-left
                            let isLagna = (rasi == lagnaRasi)
                            var headerStr = rasi.sanskritName.prefix(3).uppercased()
                            if isLagna { headerStr += " (As)" }

                            let signText = Text(headerStr)
                                .font(.caption2.weight(isLagna ? .bold : .medium))
                                .foregroundColor(isLagna ? DesignColor.accent : DesignColor.secondaryText)
                            context.draw(
                                context.resolve(signText),
                                at: CGPoint(x: cellX + 4, y: cellY + 8),
                                anchor: .leading
                            )

                            // Planets located in this sign
                            let planetsInSign = planetRasis.filter { $0.value == rasi }.map { $0.key }
                            if !planetsInSign.isEmpty {
                                let text = planetsInSign.map { $0.shortAbbreviation }.joined(separator: " ")
                                let pText = Text(text)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(DesignColor.primaryText)
                                context.draw(
                                    context.resolve(pText),
                                    at: CGPoint(x: cellX + cellW / 2, y: cellY + cellH / 2 + 4),
                                    anchor: .center
                                )
                            }
                        }
                    }
                }

                // Interactive Overlays for Right-Click Context Menu
                let cellW = geometry.size.width / 4.0
                let cellH = geometry.size.height / 4.0

                ForEach(0..<4, id: \.self) { row in
                    ForEach(0..<4, id: \.self) { col in
                        if let rasi = Self.gridRasis[row][col] {
                            let houseNum = ((rasi.rawValue - lagnaRasi.rawValue + 12) % 12) + 1
                            Rectangle()
                                .fill(Color.white.opacity(0.001))
                                .contentShape(Rectangle())
                                .frame(width: cellW, height: cellH)
                                .position(x: CGFloat(col) * cellW + cellW / 2, y: CGFloat(row) * cellH + cellH / 2)
                                .contextMenu {
                                    Button {
                                        onShowChartFromRasi?(rasi)
                                    } label: {
                                        Label("Show chart from this house (House \(houseNum) - \(rasi.sanskritName))", systemImage: "arrow.triangle.2.circlepath")
                                    }

                                    if isRotated {
                                        Divider()
                                        Button {
                                            onResetToNatalLagna?()
                                        } label: {
                                            Label("Reset to Natal Lagna", systemImage: "arrow.uturn.backward")
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(DesignColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
    }
}
