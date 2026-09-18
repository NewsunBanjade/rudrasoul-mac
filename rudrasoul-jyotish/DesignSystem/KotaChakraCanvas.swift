import SwiftUI

extension Nakshatra {
    /// Three-letter label used inside chakra cells.
    var chakraAbbreviation: String {
        switch self {
        case .ashwini: "Asw"
        case .bharani: "Bha"
        case .krittika: "Kri"
        case .rohini: "Roh"
        case .mrigashira: "Mri"
        case .ardra: "Ard"
        case .punarvasu: "Pun"
        case .pushya: "Pus"
        case .ashlesha: "Asl"
        case .magha: "Mag"
        case .purvaPhalguni: "PPh"
        case .uttaraPhalguni: "UPh"
        case .hasta: "Has"
        case .chitra: "Chi"
        case .swati: "Swa"
        case .vishakha: "Vis"
        case .anuradha: "Anu"
        case .jyeshtha: "Jye"
        case .mula: "Mul"
        case .purvaAshadha: "PAs"
        case .uttaraAshadha: "UAs"
        case .shravana: "Shr"
        case .dhanishta: "Dha"
        case .shatabhisha: "Sha"
        case .purvaBhadrapada: "PBh"
        case .uttaraBhadrapada: "UBh"
        case .revati: "Rev"
        case .abhijit: "Abh"
        }
    }
}

extension Rasi {
    /// Three-letter label used inside chakra cells.
    var chakraAbbreviation: String {
        String(englishName.prefix(3))
    }
}

/// Draws the Kota Chakra: four nested squares (Bahya, Prakara, Madhya, Stambha)
/// joined by eight lines from the outer corners and mid-points to the centre, with
/// the 28 nakshatra cells threaded along those lines from the Janma nakshatra at
/// the north-east (top-right) corner, clockwise.
struct KotaChakraCanvas: View {
    let cells: [KotaCell]
    let janma: Nakshatra
    /// Transit grahas keyed by cell sequence, drawn under the natal grahas.
    var transitGrahas: [Int: [Graha]] = [:]

    /// Half side length of each square as a fraction of the drawing side, outermost first.
    private static let squareRadii: [CGFloat] = [0.44, 0.325, 0.215, 0.105]
    /// Size of a cell box as a fraction of the drawing side.
    private static let cellBoxSize = CGSize(width: 0.11, height: 0.085)
    private static let zonesOutermostFirst: [KotaChakraData.Zone] = [.bahya, .prakara, .madhya, .stambha]
    private static let cornerVectors: [CGPoint] = [
        CGPoint(x: 1, y: -1), CGPoint(x: 1, y: 1), CGPoint(x: -1, y: 1), CGPoint(x: -1, y: -1),
    ]
    private static let cardinalVectors: [CGPoint] = [
        CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: -1, y: 0), CGPoint(x: 0, y: -1),
    ]

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            Self.drawFrame(in: &context, centre: centre, side: side)
            Self.drawZoneNames(in: &context, centre: centre, side: side)
            for cell in cells {
                drawCell(cell, in: &context, centre: centre, side: side)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(DesignColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignColor.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Centre point of the cell at `sequence` (1 ... 28).
    ///
    /// Each seven-cell leg starts at a corner of the outer square, runs along the
    /// diagonal to the Stambha corner, then back out along the following cardinal
    /// line to the mid-point of the outer square: NE→E, SE→S, SW→W, NW→N.
    static func cellCentre(sequence: Int, centre: CGPoint, side: CGFloat) -> CGPoint {
        let index = max(0, min(KotaChakraCalculator.cellCount - 1, sequence - 1))
        let leg = index / 7
        let position = index % 7
        let vector = position <= 3 ? cornerVectors[leg] : cardinalVectors[leg]
        let radiusIndex = position <= 3 ? position : 6 - position
        let radius = squareRadii[radiusIndex] * side
        return CGPoint(x: centre.x + vector.x * radius, y: centre.y + vector.y * radius)
    }

    static func zoneShortName(_ zone: KotaChakraData.Zone) -> String {
        switch zone {
        case .stambha: "Stambha"
        case .madhya: "Madhya"
        case .prakara: "Prakara"
        case .bahya: "Bahya"
        }
    }

    private static func drawFrame(in context: inout GraphicsContext, centre: CGPoint, side: CGFloat) {
        for radius in squareRadii {
            let half = radius * side
            let rect = CGRect(x: centre.x - half, y: centre.y - half, width: half * 2, height: half * 2)
            context.stroke(Path(rect), with: .color(DesignColor.separator), lineWidth: 1)
        }
        let outer = (squareRadii.first ?? 0) * side
        var rays = Path()
        for anchor in cornerVectors + cardinalVectors {
            rays.move(to: CGPoint(x: centre.x + anchor.x * outer, y: centre.y + anchor.y * outer))
            rays.addLine(to: centre)
        }
        context.stroke(rays, with: .color(DesignColor.separator), lineWidth: 1)
    }

    private static func drawZoneNames(in context: inout GraphicsContext, centre: CGPoint, side: CGFloat) {
        for (index, zone) in zonesOutermostFirst.enumerated() {
            let radius = squareRadii[index] * side
            let point = zone == .stambha
                ? centre
                : CGPoint(x: centre.x - radius / 2, y: centre.y - radius)
            let text = Text(zoneShortName(zone))
                .font(.caption2)
                .foregroundStyle(DesignColor.secondaryText)
            let resolved = context.resolve(text)
            let measured = resolved.measure(in: CGSize(width: side, height: side))
            let backdrop = CGRect(
                x: point.x - measured.width / 2 - 2,
                y: point.y - measured.height / 2,
                width: measured.width + 4,
                height: measured.height
            )
            context.fill(Path(backdrop), with: .color(DesignColor.background))
            context.draw(resolved, at: point, anchor: .center)
        }
    }

    private func drawCell(_ cell: KotaCell, in context: inout GraphicsContext, centre: CGPoint, side: CGFloat) {
        let point = Self.cellCentre(sequence: cell.sequence, centre: centre, side: side)
        let boxWidth = Self.cellBoxSize.width * side
        let boxHeight = Self.cellBoxSize.height * side
        let box = CGRect(x: point.x - boxWidth / 2, y: point.y - boxHeight / 2, width: boxWidth, height: boxHeight)
        let isJanma = cell.nakshatra == janma
        let boxPath = Path(roundedRect: box, cornerRadius: 3)
        context.fill(boxPath, with: .color(isJanma ? DesignColor.accent.opacity(0.15) : DesignColor.background))
        context.stroke(boxPath, with: .color(isJanma ? DesignColor.accent : DesignColor.separator), lineWidth: 1)

        let label = Text(cell.nakshatra.chakraAbbreviation)
            .font(.caption2.weight(isJanma ? .bold : .medium))
            .foregroundStyle(isJanma ? DesignColor.accent : DesignColor.primaryText)
        context.draw(context.resolve(label), at: CGPoint(x: point.x, y: box.minY + boxHeight * 0.28), anchor: .center)

        if !cell.grahas.isEmpty {
            let grahaText = Self.grahaText(cell.grahas)
            context.draw(context.resolve(grahaText), at: CGPoint(x: point.x, y: box.minY + boxHeight * 0.62), anchor: .center)
        }
        if let transit = transitGrahas[cell.sequence], !transit.isEmpty {
            let transitText = Text(transit.map(\.shortAbbreviation).joined(separator: " "))
                .font(.caption2)
                .foregroundStyle(DesignColor.transit)
            context.draw(context.resolve(transitText), at: CGPoint(x: point.x, y: box.minY + boxHeight * 0.88), anchor: .center)
        }
    }

    private static func grahaText(_ grahas: [Graha]) -> Text {
        var result = Text(verbatim: "")
        for (index, graha) in grahas.enumerated() {
            let piece = Text(graha.shortAbbreviation)
                .foregroundStyle(graha.isNaturalBenefic ? DesignColor.benefic : DesignColor.malefic)
            result = index == 0 ? piece : result + Text(verbatim: " ") + piece
        }
        return result.font(.caption2.weight(.semibold))
    }

    private var accessibilityDescription: String {
        var parts = ["Kota Chakra counted from Janma nakshatra \(janma.name)."]
        for zone in Self.zonesOutermostFirst.reversed() {
            let occupied = cells.filter { $0.zone == zone && !$0.grahas.isEmpty }
            guard !occupied.isEmpty else { continue }
            let entries = occupied.flatMap { cell in
                cell.grahas.map { "\($0.rawValue) in \(cell.nakshatra.name)" }
            }
            parts.append("\(Self.zoneShortName(zone)) zone: \(entries.joined(separator: ", ")).")
        }
        let transitEntries = cells.flatMap { cell in
            (transitGrahas[cell.sequence] ?? []).map { "\($0.rawValue) in \(cell.nakshatra.name)" }
        }
        if !transitEntries.isEmpty {
            parts.append("Transits: \(transitEntries.joined(separator: ", ")).")
        }
        return parts.joined(separator: " ")
    }
}
