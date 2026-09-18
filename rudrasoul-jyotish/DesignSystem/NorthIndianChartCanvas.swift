import SwiftUI

/// A native SwiftUI Canvas rendering the classical North Indian diamond Kundali,
/// with interactive house hit-testing and context menu support.
struct NorthIndianChartCanvas: View {
    let houseRasis: [Int: Rasi]
    let housePlanets: [Int: [PlanetPosition]]
    /// Short labels drawn under the planets of a house, e.g. upagrahas ("Gk", "Md") or arudha padas ("AL").
    var extraHouseLabels: [Int: [String]] = [:]
    var isRotated: Bool = false
    var onShowChartFromHouse: ((Int) -> Void)? = nil
    var onResetToNatalLagna: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Drawing Canvas
                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // Outer border
                    let outerRect = CGRect(x: 1, y: 1, width: w - 2, height: h - 2)
                    context.stroke(Path(outerRect), with: .color(DesignColor.separator), lineWidth: 1)

                    // Diagonal lines
                    var diag1 = Path()
                    diag1.move(to: CGPoint(x: 1, y: 1))
                    diag1.addLine(to: CGPoint(x: w - 1, y: h - 1))
                    context.stroke(diag1, with: .color(DesignColor.separator), lineWidth: 1)

                    var diag2 = Path()
                    diag2.move(to: CGPoint(x: w - 1, y: 1))
                    diag2.addLine(to: CGPoint(x: 1, y: h - 1))
                    context.stroke(diag2, with: .color(DesignColor.separator), lineWidth: 1)

                    // Inner diamond
                    var diamond = Path()
                    diamond.move(to: CGPoint(x: w / 2, y: 1))
                    diamond.addLine(to: CGPoint(x: w - 1, y: h / 2))
                    diamond.addLine(to: CGPoint(x: w / 2, y: h - 1))
                    diamond.addLine(to: CGPoint(x: 1, y: h / 2))
                    diamond.closeSubpath()
                    context.stroke(diamond, with: .color(DesignColor.separator), lineWidth: 1)

                    // Text labels for each house
                    let centers = Self.houseCenters(width: w, height: h)
                    for house in 1...12 {
                        guard let center = centers[house] else { continue }

                        // Sign number
                        if let rasi = houseRasis[house] {
                            let rasiText = Text("\(rasi.rawValue)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(DesignColor.secondaryText)
                            context.draw(
                                context.resolve(rasiText),
                                at: CGPoint(x: center.x, y: center.y - 14),
                                anchor: .center
                            )
                        }

                        // Planets
                        if let planets = housePlanets[house], !planets.isEmpty {
                            let planetNames = planets.map { pos -> String in
                                var str = pos.graha.shortAbbreviation
                                if pos.isRetrograde { str += "(R)" }
                                return str
                            }.joined(separator: " ")

                            let planetText = Text(planetNames)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(house == 1 ? DesignColor.accent : DesignColor.primaryText)
                            context.draw(
                                context.resolve(planetText),
                                at: CGPoint(x: center.x, y: center.y + 4),
                                anchor: .center
                            )
                        }

                        // Secondary points (upagrahas, padas) below the planets
                        if let labels = extraHouseLabels[house], !labels.isEmpty {
                            let extraText = Text(labels.joined(separator: " "))
                                .font(.caption2.weight(.medium))
                                .foregroundColor(DesignColor.secondaryText)
                            context.draw(
                                context.resolve(extraText),
                                at: CGPoint(x: center.x, y: center.y + 18),
                                anchor: .center
                            )
                        }
                    }
                }

                // Interactive House Overlays for Right-Click Context Menu
                ForEach(1...12, id: \.self) { house in
                    NorthIndianHouseShape(house: house)
                        .fill(Color.white.opacity(0.001)) // Invisible but hit-testable
                        .contentShape(NorthIndianHouseShape(house: house))
                        .contextMenu {
                            Button {
                                onShowChartFromHouse?(house)
                            } label: {
                                let signStr = houseRasis[house]?.sanskritName ?? ""
                                Label("Show chart from this house (House \(house)\(signStr.isEmpty ? "" : " - " + signStr))", systemImage: "arrow.triangle.2.circlepath")
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
        .aspectRatio(1, contentMode: .fit)
        .background(DesignColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
    }

    static func houseCenters(width w: CGFloat, height h: CGFloat) -> [Int: CGPoint] {
        [
            1: CGPoint(x: w * 0.50, y: h * 0.25),
            2: CGPoint(x: w * 0.25, y: h * 0.12),
            3: CGPoint(x: w * 0.12, y: h * 0.25),
            4: CGPoint(x: w * 0.25, y: h * 0.50),
            5: CGPoint(x: w * 0.12, y: h * 0.75),
            6: CGPoint(x: w * 0.25, y: h * 0.88),
            7: CGPoint(x: w * 0.50, y: h * 0.75),
            8: CGPoint(x: w * 0.75, y: h * 0.88),
            9: CGPoint(x: w * 0.88, y: h * 0.75),
            10: CGPoint(x: w * 0.75, y: h * 0.50),
            11: CGPoint(x: w * 0.88, y: h * 0.25),
            12: CGPoint(x: w * 0.75, y: h * 0.12)
        ]
    }

    static func housePath(for house: Int, in size: CGSize) -> Path {
        let w = size.width
        let h = size.height
        var path = Path()

        switch house {
        case 1: // Top Center Diamond
            path.move(to: CGPoint(x: w * 0.50, y: 0))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.25))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.25))
            path.closeSubpath()

        case 2: // Top Left Triangle
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: w * 0.50, y: 0))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.25))
            path.closeSubpath()

        case 3: // Upper Left Triangle
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.25))
            path.addLine(to: CGPoint(x: 0, y: h * 0.50))
            path.closeSubpath()

        case 4: // Left Center Diamond
            path.move(to: CGPoint(x: 0, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.25))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.75))
            path.closeSubpath()

        case 5: // Lower Left Triangle
            path.move(to: CGPoint(x: 0, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.75))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.closeSubpath()

        case 6: // Bottom Left Triangle
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.75))
            path.addLine(to: CGPoint(x: w * 0.50, y: h))
            path.closeSubpath()

        case 7: // Bottom Center Diamond
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.75))
            path.addLine(to: CGPoint(x: w * 0.50, y: h))
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.75))
            path.closeSubpath()

        case 8: // Bottom Right Triangle
            path.move(to: CGPoint(x: w * 0.50, y: h))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.75))
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()

        case 9: // Lower Right Triangle
            path.move(to: CGPoint(x: w * 0.75, y: h * 0.75))
            path.addLine(to: CGPoint(x: w, y: h * 0.50))
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()

        case 10: // Right Center Diamond
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.25))
            path.addLine(to: CGPoint(x: w, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.75))
            path.closeSubpath()

        case 11: // Upper Right Triangle
            path.move(to: CGPoint(x: w * 0.75, y: h * 0.25))
            path.addLine(to: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w, y: h * 0.50))
            path.closeSubpath()

        case 12: // Top Right Triangle
            path.move(to: CGPoint(x: w * 0.50, y: 0))
            path.addLine(to: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.25))
            path.closeSubpath()

        default:
            break
        }

        return path
    }
}

private struct NorthIndianHouseShape: Shape {
    let house: Int

    func path(in rect: CGRect) -> Path {
        NorthIndianChartCanvas.housePath(for: house, in: rect.size)
    }
}
