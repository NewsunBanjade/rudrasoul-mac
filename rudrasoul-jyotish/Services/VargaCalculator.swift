import Foundation

/// Produces the Parashari Shodashavarga sign placements from sidereal longitudes.
///
/// The sign starts and exceptional Trimsamsa ranges follow Brihat Parashara Hora
/// Shastra, chapters 6–7. Longitudes remain unrounded; only the resulting sign is
/// retained because `VargaChart` is a sign-placement model.
enum VargaCalculator {
    /// All sixteen Shodashavarga charts for a lagna, its planets, and (optionally) the
    /// upagrahas Gulika and Maandi.
    ///
    /// Upagrahas are shadow points with a sidereal longitude, so they take a divisional
    /// sign by exactly the same rule as a planet. `upagrahaRasis` is always populated
    /// (empty when no upagrahas are given) so that views can distinguish "computed,
    /// none present" from charts saved before upagrahas existed (`nil`).
    /// For D-60 the Shashtiamsa deity of the lagna and of every planet is attached
    /// (BPHS Ch. 6, vv. 33–41; see `ShashtiamsaTable`).
    static func charts(
        lagnaLongitude: Double,
        planets: [PlanetPosition],
        upagrahas: [UpagrahaPosition] = []
    ) -> [VargaChart] {
        VargaDivision.allCases.map { division in
            chart(for: division, lagnaLongitude: lagnaLongitude, planets: planets, upagrahas: upagrahas)
        }
    }

    private static func chart(
        for division: VargaDivision,
        lagnaLongitude: Double,
        planets: [PlanetPosition],
        upagrahas: [UpagrahaPosition]
    ) -> VargaChart {
        let planetRasis: [Graha: Rasi] = Dictionary(
            planets.map { planet -> (Graha, Rasi) in
                (planet.graha, rasi(for: planet.absoluteLongitude, division: division))
            },
            uniquingKeysWith: { _, last in last }
        )
        let upagrahaRasis: [UpagrahaKind: Rasi] = Dictionary(
            upagrahas.map { upagraha -> (UpagrahaKind, Rasi) in
                (upagraha.kind, rasi(for: upagraha.longitude, division: division))
            },
            uniquingKeysWith: { _, last in last }
        )
        var chart = VargaChart(
            division: division,
            lagnaRasi: rasi(for: lagnaLongitude, division: division),
            planetRasis: planetRasis
        )
        chart.upagrahaRasis = upagrahaRasis
        if division == .d60 {
            chart.lagnaAmsaDetail = ShashtiamsaTable.detail(absoluteLongitude: lagnaLongitude)
            let amsaDetails: [Graha: ShashtiamsaDetail] = Dictionary(
                planets.map { planet -> (Graha, ShashtiamsaDetail) in
                    (planet.graha, ShashtiamsaTable.detail(absoluteLongitude: planet.absoluteLongitude))
                },
                uniquingKeysWith: { _, last in last }
            )
            chart.planetAmsaDetails = amsaDetails
        }
        return chart
    }

    /// The divisional sign of an absolute sidereal longitude.
    ///
    /// D-60 (BPHS Ch. 6, v. 33): "ignore the sign position of a planet and take the
    /// degrees it traversed in that sign; multiply by 2, divide by 12, add 1 to the
    /// remainder" and count that many signs from the sign itself. `natalSign +
    /// Int(longitudeInSign / 0.5)` taken modulo 12 is the same count.
    static func rasi(for longitude: Double, division: VargaDivision) -> Rasi {
        let normalized = longitude.normalizedVargaLongitude
        let natalSign = Int(normalized / 30)
        let longitudeInSign = normalized - Double(natalSign) * 30

        switch division {
        case .d1:
            return rasi(at: natalSign)
        case .d2:
            return rasi(at: horaSignIndex(natalSign: natalSign, longitudeInSign: longitudeInSign))
        case .d3:
            return rasi(at: natalSign + Int(longitudeInSign / 10) * 4)
        case .d4:
            return rasi(at: natalSign + Int(longitudeInSign / 7.5) * 3)
        case .d7:
            return rasi(at: (natalSign.isEven ? natalSign + 6 : natalSign) + Int(longitudeInSign / (30.0 / 7)))
        case .d9:
            return rasi(at: navamshaStart(for: natalSign) + Int(longitudeInSign / (30.0 / 9)))
        case .d10:
            return rasi(at: (natalSign.isEven ? natalSign + 8 : natalSign) + Int(longitudeInSign / 3))
        case .d12:
            return rasi(at: natalSign + Int(longitudeInSign / 2.5))
        case .d16:
            return rasi(at: shodasamshaStart(for: natalSign) + Int(longitudeInSign / (30.0 / 16)))
        case .d20:
            return rasi(at: vimshamshaStart(for: natalSign) + Int(longitudeInSign / 1.5))
        case .d24:
            return rasi(at: natalSign.isEven ? 3 + Int(longitudeInSign / 1.25) : 4 + Int(longitudeInSign / 1.25))
        case .d27:
            return rasi(at: bhamsaStart(for: natalSign) + Int(longitudeInSign / (30.0 / 27)))
        case .d30:
            return rasi(at: trimsamsaSignIndex(natalSign: natalSign, longitudeInSign: longitudeInSign))
        case .d40:
            return rasi(at: (natalSign.isEven ? 6 : 0) + Int(longitudeInSign / 0.75))
        case .d45:
            return rasi(at: akshavedamshaStart(for: natalSign) + Int(longitudeInSign / (30.0 / 45)))
        case .d60:
            return rasi(at: natalSign + Int(longitudeInSign / 0.5))
        }
    }

    private static func rasi(at zeroBasedIndex: Int) -> Rasi {
        Rasi(rawValue: ((zeroBasedIndex % 12) + 12) % 12 + 1)!
    }

    private static func horaSignIndex(natalSign: Int, longitudeInSign: Double) -> Int {
        let firstHoraIsSun = !natalSign.isEven
        let isFirstHora = longitudeInSign < 15
        let sunHora = firstHoraIsSun == isFirstHora
        return sunHora ? 4 : 3 // Leo / Cancer
    }

    private static func navamshaStart(for natalSign: Int) -> Int {
        switch natalSign % 3 {
        case 0: natalSign // movable
        case 1: natalSign + 8 // fixed: ninth from the sign
        default: natalSign + 4 // dual: fifth from the sign
        }
    }

    private static func shodasamshaStart(for natalSign: Int) -> Int {
        switch natalSign % 3 {
        case 0: 0 // movable: Aries
        case 1: 4 // fixed: Leo
        default: 8 // dual: Sagittarius
        }
    }

    private static func vimshamshaStart(for natalSign: Int) -> Int {
        switch natalSign % 3 {
        case 0: 0 // movable: Aries
        case 1: 8 // fixed: Sagittarius
        default: 4 // dual: Leo
        }
    }

    private static func bhamsaStart(for natalSign: Int) -> Int {
        switch natalSign % 3 {
        case 0: 0 // movable: Aries
        case 1: 3 // fixed: Cancer
        default: 6 // dual: Libra
        }
    }

    private static func akshavedamshaStart(for natalSign: Int) -> Int {
        switch natalSign % 3 {
        case 0: 0 // movable: Aries
        case 1: 4 // fixed: Leo
        default: 8 // dual: Sagittarius
        }
    }

    private static func trimsamsaSignIndex(natalSign: Int, longitudeInSign: Double) -> Int {
        let ranges: [(upperBound: Double, sign: Int)] = natalSign.isEven
            ? [(5, 1), (12, 5), (20, 11), (25, 9), (30, 7)] // Ve, Me, Ju, Sa, Ma
            : [(5, 0), (10, 10), (18, 8), (25, 2), (30, 6)] // Ma, Sa, Ju, Me, Ve
        return ranges.first(where: { longitudeInSign < $0.upperBound })?.sign ?? ranges[4].sign
    }
}

private extension Double {
    var normalizedVargaLongitude: Double {
        let remainder = truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }
}

private extension Int {
    var isEven: Bool { self % 2 != 0 }
}
