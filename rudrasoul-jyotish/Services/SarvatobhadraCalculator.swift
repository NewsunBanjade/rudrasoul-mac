import Foundation

/// Builds the Sarvatobhadra Chakra (SBC): the 9 × 9 grid of 81 cells that holds
/// the 28 nakshatras, the 16 Sanskrit vowels, the 20 Avakahada letters, the 12
/// rasis and the five tithi groups, and computes the vedhas (piercing rays) that
/// the planets cast across it.
///
/// Layout source: the chakra as tabulated in the English Wikipedia article
/// "Sarvatobhadra Chakra" (after Narapatijayacharya / Muhurta Chintamani), cross-
/// checked against the cage numbering in "Sarvato Bhadra Chakra – Preparation of
/// the Chart" (Prof. Anthony Writer, archive.org "astrology-book-collection").
/// Both agree on:
///
/// * Outer ring: the 28 nakshatras, seven per side, clockwise from the east side
///   starting with Krittika; Abhijit has its own cell between Uttara Ashadha and
///   Shravana. The four outer corners hold the vowels अ आ इ ई.
/// * The 16 vowels sit on the two diagonals: four per ring, clockwise from the
///   north-east corner of each ring (अ आ इ ई | उ ऊ ऋ ॠ | ऌ ॡ ए ऐ | ओ औ अं अः).
/// * Second ring: the 20 letters of the Avakahada sequence, five per side
///   clockwise from the east: अ व क ह ड | म ट प र त | न य भ ज ख | ग स द च ल.
/// * Third ring: the 12 rasis three per side, Taurus first on the east side
///   (Taurus–Cancer inside Krittika–Ashlesha, and so on round to Aries).
/// * Fourth ring: the tithi groups Nanda (east), Bhadra (south), Jaya (west),
///   Rikta (north); Purna in the centre. Weekdays share those cells:
///   Nanda Sunday/Tuesday, Bhadra Monday/Wednesday, Jaya Thursday, Rikta Friday,
///   Purna Saturday (Wikipedia table). Prof. Writer's cage list instead starts the
///   weekdays with Friday in the east cell; the Wikipedia pairing is used here
///   because it is the complete, self-consistent table.
///
/// Orientation on screen: east is at the top, so the chakra reads clockwise as
/// top row left→right (Krittika…Ashlesha), right column top→bottom
/// (Magha…Vishakha), bottom row right→left (Anuradha…Shravana) and left column
/// bottom→top (Dhanishta…Bharani). The north-east corner is therefore top-left.
///
/// Vedha source: Wikipedia, ibid.: "When a planet occupies a nakshatra, it causes
/// vedha on the contents of the squares along 3 lines: one vertical or horizontal
/// line and two crossward lines starting at the nakshatra." All three lines are
/// always applied (the "all three vedhas" school). A second school keys a single
/// line to the planet's speed (fast → left, retrograde → right, mean → front;
/// Prof. Writer, op. cit.); retrograde motion is therefore only noted in the
/// descriptive strings, never used to drop a line.
enum SarvatobhadraCalculator {
    typealias Cell = SarvatobhadraData.Cell

    /// What a cell holds; derived from its position and contents.
    enum CellKind: Sendable {
        case nakshatra
        case vowel
        case consonant
        case rasi
        case tithi
    }

    /// Cells per row and per column.
    static let gridSize = 9
    /// Number of concentric rings that carry content (the centre is separate).
    static let ringCount = 4
    /// Label of the centre cell.
    static let centreLabel = "Purna"

    private static let vowels: [String] = [
        "अ", "आ", "इ", "ई", "उ", "ऊ", "ऋ", "ॠ", "ऌ", "ॡ", "ए", "ऐ", "ओ", "औ", "अं", "अः",
    ]
    private static let avakahadaLetters: [String] = [
        "अ", "व", "क", "ह", "ड", "म", "ट", "प", "र", "त", "न", "य", "भ", "ज", "ख", "ग", "स", "द", "च", "ल",
    ]
    private static let ringRasis: [Rasi] = [
        .taurus, .gemini, .cancer, .leo, .virgo, .libra,
        .scorpio, .sagittarius, .capricorn, .aquarius, .pisces, .aries,
    ]
    private static let tithiGroups: [String] = ["Nanda", "Bhadra", "Jaya", "Rikta"]
    private static let directions: [SarvatobhadraVedha.Direction] = [.front, .left, .right]

    // MARK: Layout

    /// The 81 empty cells, row-major, `id == row * 9 + col`.
    static func layout() -> [Cell] {
        var cells: [Int: Cell] = [:]
        for ring in 0..<ringCount {
            let low = ring
            let high = gridSize - 1 - ring
            let corners = [(low, low), (low, high), (high, high), (high, low)]
            for (offset, corner) in corners.enumerated() {
                let cell = makeCell(row: corner.0, col: corner.1, label: vowels[ring * 4 + offset], isVowel: true)
                cells[cell.id] = cell
            }
            for (offset, coordinate) in sideCoordinates(low: low, high: high).enumerated() {
                let cell = sideCell(ring: ring, offset: offset, row: coordinate.row, col: coordinate.col)
                cells[cell.id] = cell
            }
        }
        let centre = gridSize / 2
        let centreCell = makeCell(row: centre, col: centre, label: centreLabel)
        cells[centreCell.id] = centreCell
        return (0..<(gridSize * gridSize)).compactMap { cells[$0] }
    }

    /// Weekdays written in a tithi-group cell, or empty for any other label.
    static func weekdays(forTithiGroup label: String) -> [Vara] {
        switch label {
        case "Nanda": [.sunday, .tuesday]
        case "Bhadra": [.monday, .wednesday]
        case "Jaya": [.thursday]
        case "Rikta": [.friday]
        case centreLabel: [.saturday]
        default: []
        }
    }

    static func kind(of cell: Cell) -> CellKind {
        if cell.nakshatra != nil { return .nakshatra }
        if cell.rasi != nil { return .rasi }
        if cell.isSpecialSound { return .vowel }
        return ringIndex(row: cell.row, col: cell.col) == 1 ? .consonant : .tithi
    }

    /// 0 for the outer ring, 4 for the centre.
    static func ringIndex(row: Int, col: Int) -> Int {
        min(row, col, gridSize - 1 - row, gridSize - 1 - col)
    }

    /// Non-corner cells of one ring, clockwise from the top-left corner.
    private static func sideCoordinates(low: Int, high: Int) -> [(row: Int, col: Int)] {
        guard low + 1 <= high else { return [] }
        let inner = Array((low + 1)..<high)
        var result: [(row: Int, col: Int)] = []
        result += inner.map { (row: low, col: $0) }
        result += inner.map { (row: $0, col: high) }
        result += inner.reversed().map { (row: high, col: $0) }
        result += inner.reversed().map { (row: $0, col: low) }
        return result
    }

    private static func sideCell(ring: Int, offset: Int, row: Int, col: Int) -> Cell {
        switch ring {
        case 0:
            let start = Nakshatra28.index(of: .krittika)
            let nakshatra = Nakshatra28.sequence[(start + offset) % Nakshatra28.sequence.count]
            return makeCell(row: row, col: col, label: nakshatra.name, nakshatra: nakshatra)
        case 1:
            return makeCell(row: row, col: col, label: avakahadaLetters[offset % avakahadaLetters.count])
        case 2:
            let rasi = ringRasis[offset % ringRasis.count]
            return makeCell(row: row, col: col, label: rasi.englishName, rasi: rasi)
        default:
            return makeCell(row: row, col: col, label: tithiGroups[offset % tithiGroups.count])
        }
    }

    private static func makeCell(
        row: Int,
        col: Int,
        label: String,
        nakshatra: Nakshatra? = nil,
        rasi: Rasi? = nil,
        isVowel: Bool = false
    ) -> Cell {
        Cell(
            id: row * gridSize + col,
            row: row,
            col: col,
            label: label,
            nakshatra: nakshatra,
            rasi: rasi,
            occupyingGrahas: [],
            isSpecialSound: isVowel
        )
    }

    // MARK: Vedhas

    /// Unit step pointing from a perimeter cell into the grid; nil for corners and
    /// interior cells.
    static func inwardStep(of cell: Cell) -> (row: Int, col: Int)? {
        let last = gridSize - 1
        let onRowEdge = cell.row == 0 || cell.row == last
        let onColEdge = cell.col == 0 || cell.col == last
        guard onRowEdge != onColEdge else { return nil }
        if cell.row == 0 { return (1, 0) }
        if cell.row == last { return (-1, 0) }
        if cell.col == 0 { return (0, 1) }
        return (0, -1)
    }

    /// Cells struck along one ray from a perimeter nakshatra cell, in travel order.
    ///
    /// Front runs straight across the grid. Left and right run at 45° and are named
    /// from the planet's own viewpoint facing inward: left is the diagonal in the
    /// zodiacal direction of the ring, right the one against it. Every ray ends at
    /// the far perimeter cell it reaches.
    static func struckCells(
        from cell: Cell,
        direction: SarvatobhadraVedha.Direction,
        in cells: [Cell]
    ) -> [Cell] {
        guard let inward = inwardStep(of: cell) else { return [] }
        let step: (row: Int, col: Int)
        switch direction {
        case .front:
            step = inward
        case .left:
            step = (row: inward.row - inward.col, col: inward.col + inward.row)
        case .right:
            step = (row: inward.row + inward.col, col: inward.col - inward.row)
        }
        return walk(from: cell, step: step, in: cells)
    }

    /// Every cell that shares a vedha line with `cell`.
    ///
    /// For a perimeter nakshatra cell these are its three rays. For any other cell
    /// they are the full row, column and both diagonals, which is what the cell
    /// would be struck through.
    static func vedhas(from cell: Cell, in cells: [Cell]) -> [Cell] {
        if inwardStep(of: cell) != nil {
            return directions.flatMap { struckCells(from: cell, direction: $0, in: cells) }
        }
        let steps: [(row: Int, col: Int)] = [
            (1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1),
        ]
        return steps.flatMap { walk(from: cell, step: $0, in: cells) }
    }

    private static func walk(from cell: Cell, step: (row: Int, col: Int), in cells: [Cell]) -> [Cell] {
        let lookup = Dictionary(cells.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var row = cell.row + step.row
        var col = cell.col + step.col
        var result: [Cell] = []
        while (0..<gridSize).contains(row), (0..<gridSize).contains(col) {
            if let next = lookup[row * gridSize + col] {
                result.append(next)
            }
            row += step.row
            col += step.col
        }
        return result
    }

    // MARK: Calculation

    /// Places the planets and the lagna in their 28-fold nakshatra cells and lists
    /// every vedha the planets cast. The lagna is shown but casts no vedha.
    static func calculate(planets: [PlanetPosition], lagna: PlanetPosition) -> SarvatobhadraData {
        let base = layout()
        let positions = planets.filter { $0.graha != .ascendant } + [lagna]
        var occupants: [Int: [Graha]] = [:]
        var placements: [(position: PlanetPosition, cellID: Int)] = []

        for position in positions {
            let nakshatra = Nakshatra28.nakshatra(absoluteLongitude: position.absoluteLongitude)
            guard let cell = base.first(where: { $0.nakshatra == nakshatra }) else { continue }
            occupants[cell.id, default: []].append(position.graha)
            if position.graha != .ascendant {
                placements.append((position: position, cellID: cell.id))
            }
        }

        let cells = base.map { cell in
            Cell(
                id: cell.id,
                row: cell.row,
                col: cell.col,
                label: cell.label,
                nakshatra: cell.nakshatra,
                rasi: cell.rasi,
                occupyingGrahas: occupants[cell.id] ?? [],
                isSpecialSound: cell.isSpecialSound
            )
        }

        var details: [SarvatobhadraVedha] = []
        var summaries: [String] = []
        for placement in placements {
            guard let source = cells.first(where: { $0.id == placement.cellID }),
                  let nakshatra = source.nakshatra else { continue }
            for direction in directions {
                let struck = struckCells(from: source, direction: direction, in: cells)
                    .filter { !$0.label.isEmpty }
                guard !struck.isEmpty else { continue }
                details += struck.map { target in
                    SarvatobhadraVedha(
                        graha: placement.position.graha,
                        sourceNakshatra: nakshatra,
                        direction: direction,
                        targetLabel: target.label,
                        isBenefic: placement.position.graha.isNaturalBenefic
                    )
                }
                summaries.append(summary(for: placement.position, nakshatra: nakshatra, direction: direction, struck: struck))
            }
        }
        return SarvatobhadraData(cells: cells, vedhas: summaries, vedhaDetails: details)
    }

    private static func summary(
        for position: PlanetPosition,
        nakshatra: Nakshatra,
        direction: SarvatobhadraVedha.Direction,
        struck: [Cell]
    ) -> String {
        let motion = position.isRetrograde ? " (R)" : ""
        let targets = struck.map(\.label).joined(separator: ", ")
        return "\(position.graha.rawValue)\(motion) in \(nakshatra.name) → \(direction.rawValue.lowercased()) vedha on \(targets)"
    }
}
