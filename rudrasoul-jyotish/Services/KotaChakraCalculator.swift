import Foundation

// MARK: - 28-nakshatra scheme

/// The 28-fold nakshatra scheme used by the transit chakras (Kota and Sarvatobhadra).
///
/// Abhijit is intercalated between Uttara Ashadha and Shravana. By the standard
/// convention its span is the last quarter of Uttara Ashadha plus the first
/// fifteenth of Shravana: 276°40' to 280°53'20" sidereal (Wikipedia, "Abhijit
/// (nakshatra)"; the same bounds are used by Jagannatha Hora and by the
/// PanchangBodh Sarvatobhadra calculator). Every other longitude keeps its usual
/// 27-fold nakshatra.
enum Nakshatra28 {
    /// Start of Abhijit: 276°40'.
    static let abhijitStart: Double = 276.0 + 40.0 / 60.0
    /// End of Abhijit (exclusive): 280°53'20".
    static let abhijitEnd: Double = 280.0 + 53.0 / 60.0 + 20.0 / 3_600.0

    /// The 28 nakshatras in zodiacal order, Abhijit after Uttara Ashadha.
    static let sequence: [Nakshatra] = [
        .ashwini, .bharani, .krittika, .rohini, .mrigashira, .ardra, .punarvasu, .pushya, .ashlesha,
        .magha, .purvaPhalguni, .uttaraPhalguni, .hasta, .chitra, .swati, .vishakha, .anuradha, .jyeshtha,
        .mula, .purvaAshadha, .uttaraAshadha, .abhijit, .shravana, .dhanishta, .shatabhisha,
        .purvaBhadrapada, .uttaraBhadrapada, .revati,
    ]

    /// The 28-fold nakshatra containing an absolute sidereal longitude.
    static func nakshatra(absoluteLongitude: Double) -> Nakshatra {
        let longitude = absoluteLongitude.normalizedLongitude360
        if longitude >= abhijitStart && longitude < abhijitEnd {
            return .abhijit
        }
        return Nakshatra(absoluteLongitude: longitude)
    }

    /// Position of a nakshatra in the 28-fold sequence, 0 ... 27.
    static func index(of nakshatra: Nakshatra) -> Int {
        sequence.firstIndex(of: nakshatra) ?? 0
    }

    /// Count from `origin` to `target`, both inclusive, 1 ... 28.
    static func count(from origin: Nakshatra, to target: Nakshatra) -> Int {
        let difference = index(of: target) - index(of: origin)
        return ((difference % sequence.count) + sequence.count) % sequence.count + 1
    }
}

// MARK: - Kota Chakra

/// Builds the Kota (Durga) Chakra: the fortress diagram of four nested squares
/// through which the 28 nakshatras are threaded, counted from the Janma nakshatra.
///
/// Rules, as given in the classical chakra literature (the Kota Chakra chapter
/// of Prasna Marga and the transit chakras of Jataka Parijata) and summarised by
/// Vijayalur, "Kota Chakra", JYOTHISHI (2011) and the Scribd article
/// "Understanding Kota Chakra in Astrology":
///
/// * The Janma nakshatra is the Moon's nakshatra in the 28-fold scheme (Abhijit
///   included). It is sequence 1 and sits at the north-east corner of the outer
///   square.
/// * Counting from Janma, the Stambha (innermost square) holds the 4th, 11th,
///   18th and 25th nakshatras; the Madhya holds the 3rd, 5th, 10th, 12th, 17th,
///   19th, 24th and 26th; the Prakara holds the 2nd, 6th, 9th, 13th, 16th, 20th,
///   23rd and 27th; the Bahya holds the 1st, 7th, 8th, 14th, 15th, 21st, 22nd
///   and 28th. The pattern repeats every seven nakshatras.
/// * Kota Swami is the lord of the rasi occupied by the natal Moon.
/// * Kota Pala is the lord of the Janma nakshatra. (Some authors instead take the
///   lord of the name's first syllable from the Avakahada chakra; that variant is
///   not implemented because the app does not store a Sanskrit name.)
/// * Planets enter the fort along the four diagonal legs (north-east, south-east,
///   south-west, north-west corners inward) and leave along the four cardinal
///   legs (east, south, west, north outward). A retrograde planet, and Rahu and
///   Ketu which are always retrograde, move the opposite way, so entry becomes
///   exit and vice versa.
enum KotaChakraCalculator {
    /// Number of nakshatra cells in the chakra.
    static let cellCount = 28

    /// A leg is one corner-to-centre-to-midpoint run: seven cells.
    private static let legLength = 7

    /// Zone of the nakshatra at `sequence` (1 ... 28) counted from Janma.
    static func zone(forSequence sequence: Int) -> KotaChakraData.Zone {
        switch legPosition(of: sequence) {
        case 0, 6:
            .bahya
        case 1, 5:
            .prakara
        case 2, 4:
            .madhya
        default:
            .stambha
        }
    }

    /// Whether a planet standing at `sequence` is moving into the fort (Pravesha)
    /// rather than out of it (Nirgama).
    ///
    /// Positions 1–3 of each leg (Bahya corner, Prakara, Madhya on a diagonal) are
    /// the entry path for direct motion and positions 5–7 (Madhya, Prakara, Bahya
    /// on a cardinal line) the exit path; retrograde motion reverses them. The
    /// Stambha cell (position 4) is the innermost point, so a planet there has
    /// completed its entry whichever way it came; it is always counted as
    /// Pravesha. This treatment of the Stambha is a convention of this app.
    static func isEntering(sequence: Int, isRetrograde: Bool) -> Bool {
        let position = legPosition(of: sequence)
        return isRetrograde ? position >= 3 : position <= 3
    }

    /// Position inside the seven-cell leg, 0 ... 6 (0 = Bahya corner, 3 = Stambha).
    private static func legPosition(of sequence: Int) -> Int {
        let zeroBased = ((sequence - 1) % cellCount + cellCount) % cellCount
        return zeroBased % legLength
    }

    /// The full chakra for a set of natal (or transit) positions.
    ///
    /// The ascendant is never placed in the chakra; `lagna` only stands in for the
    /// Moon when no Moon position is supplied.
    static func calculate(planets: [PlanetPosition], lagna: PlanetPosition) -> KotaChakraData {
        let moon = planets.first { $0.graha == .moon } ?? lagna
        let janma = Nakshatra28.nakshatra(absoluteLongitude: moon.absoluteLongitude)
        let grahas = planets.filter { $0.graha != .ascendant }

        var grahasBySequence: [Int: [Graha]] = [:]
        var zoneAssignments: [KotaChakraData.Zone: [Graha]] = [:]
        var pravesha: [Graha] = []
        var nirgama: [Graha] = []
        for zone in KotaChakraData.Zone.allCases {
            zoneAssignments[zone] = []
        }

        for position in grahas {
            let nakshatra = Nakshatra28.nakshatra(absoluteLongitude: position.absoluteLongitude)
            let sequence = Nakshatra28.count(from: janma, to: nakshatra)
            grahasBySequence[sequence, default: []].append(position.graha)
            zoneAssignments[zone(forSequence: sequence), default: []].append(position.graha)
            if isEntering(sequence: sequence, isRetrograde: position.isRetrograde) {
                pravesha.append(position.graha)
            } else {
                nirgama.append(position.graha)
            }
        }

        let cells = makeCells(janma: janma, grahasBySequence: grahasBySequence)
        return KotaChakraData(
            kotaSwami: moon.rasi.lord,
            kotaPala: janma.lord,
            zoneAssignments: zoneAssignments,
            praveshaGrahas: pravesha,
            nirgamaGrahas: nirgama,
            janmaNakshatra: janma,
            cells: cells
        )
    }

    /// The 28 cells in sequence order starting from the Janma nakshatra.
    static func makeCells(janma: Nakshatra, grahasBySequence: [Int: [Graha]]) -> [KotaCell] {
        let start = Nakshatra28.index(of: janma)
        return (1...cellCount).map { sequence in
            let nakshatra = Nakshatra28.sequence[(start + sequence - 1) % cellCount]
            return KotaCell(
                sequence: sequence,
                nakshatra: nakshatra,
                zone: zone(forSequence: sequence),
                grahas: grahasBySequence[sequence] ?? []
            )
        }
    }
}
