import Foundation

/// Bhinnashtakavarga and Sarvashtakavarga (BPHS Ch. 66, "Ashtakavarga").
///
/// For each of the seven planets a bindu is placed in the signs that lie in the listed
/// houses counted from each of eight references: the seven planets and the Lagna. The
/// tables are the Parashari benefic-house lists; their totals are Sun 48, Moon 49, Mars 39,
/// Mercury 54, Jupiter 56, Venus 52 and Saturn 39 bindus, 337 in all. The Sarvashtakavarga
/// of a sign is the sum of the seven planets' bindus in that sign (the Lagna's own
/// Ashtakavarga is not part of the sum).
enum AshtakavargaCalculator {
    /// The planets that own a Bhinnashtakavarga, in display order.
    static let contributingPlanets: [Graha] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]

    /// The seven planets and the Lagna, the reference points of every Bhinnashtakavarga.
    static let references: [Graha] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .ascendant]

    /// `beneficHouses[planet]?[reference]` lists the houses (1 = the reference's own sign)
    /// in which `planet` gains a bindu counted from `reference`.
    static let beneficHouses: [Graha: [Graha: [Int]]] = [
        .sun: [
            .sun: [1, 2, 4, 7, 8, 9, 10, 11],
            .moon: [3, 6, 10, 11],
            .mars: [1, 2, 4, 7, 8, 9, 10, 11],
            .mercury: [3, 5, 6, 9, 10, 11, 12],
            .jupiter: [5, 6, 9, 11],
            .venus: [6, 7, 12],
            .saturn: [1, 2, 4, 7, 8, 9, 10, 11],
            .ascendant: [3, 4, 6, 10, 11, 12],
        ],
        .moon: [
            .sun: [3, 6, 7, 8, 10, 11],
            .moon: [1, 3, 6, 7, 10, 11],
            .mars: [2, 3, 5, 6, 9, 10, 11],
            .mercury: [1, 3, 4, 5, 7, 8, 10, 11],
            .jupiter: [1, 4, 7, 8, 10, 11, 12],
            .venus: [3, 4, 5, 7, 9, 10, 11],
            .saturn: [3, 5, 6, 11],
            .ascendant: [3, 6, 10, 11],
        ],
        .mars: [
            .sun: [3, 5, 6, 10, 11],
            .moon: [3, 6, 11],
            .mars: [1, 2, 4, 7, 8, 10, 11],
            .mercury: [3, 5, 6, 11],
            .jupiter: [6, 10, 11, 12],
            .venus: [6, 8, 11, 12],
            .saturn: [1, 4, 7, 8, 9, 10, 11],
            .ascendant: [1, 3, 6, 10, 11],
        ],
        .mercury: [
            .sun: [5, 6, 9, 11, 12],
            .moon: [2, 4, 6, 8, 10, 11],
            .mars: [1, 2, 4, 7, 8, 9, 10, 11],
            .mercury: [1, 3, 5, 6, 9, 10, 11, 12],
            .jupiter: [6, 8, 11, 12],
            .venus: [1, 2, 3, 4, 5, 8, 9, 11],
            .saturn: [1, 2, 4, 7, 8, 9, 10, 11],
            .ascendant: [1, 2, 4, 6, 8, 10, 11],
        ],
        .jupiter: [
            .sun: [1, 2, 3, 4, 7, 8, 9, 10, 11],
            .moon: [2, 5, 7, 9, 11],
            .mars: [1, 2, 4, 7, 8, 10, 11],
            .mercury: [1, 2, 4, 5, 6, 9, 10, 11],
            .jupiter: [1, 2, 3, 4, 7, 8, 10, 11],
            .venus: [2, 5, 6, 9, 10, 11],
            .saturn: [3, 5, 6, 12],
            .ascendant: [1, 2, 4, 5, 6, 7, 9, 10, 11],
        ],
        .venus: [
            .sun: [8, 11, 12],
            .moon: [1, 2, 3, 4, 5, 8, 9, 11, 12],
            .mars: [3, 5, 6, 9, 11, 12],
            .mercury: [3, 5, 6, 9, 11],
            .jupiter: [5, 8, 9, 10, 11],
            .venus: [1, 2, 3, 4, 5, 8, 9, 10, 11],
            .saturn: [3, 4, 5, 8, 9, 10, 11],
            .ascendant: [1, 2, 3, 4, 5, 8, 9, 11],
        ],
        .saturn: [
            .sun: [1, 2, 4, 7, 8, 10, 11],
            .moon: [3, 6, 11],
            .mars: [3, 5, 6, 10, 11, 12],
            .mercury: [6, 8, 9, 10, 11, 12],
            .jupiter: [5, 6, 11, 12],
            .venus: [6, 11, 12],
            .saturn: [3, 5, 6, 11],
            .ascendant: [1, 3, 4, 6, 10, 11],
        ],
    ]

    /// The total number of bindus a planet's Bhinnashtakavarga always holds.
    static func expectedTotal(of planet: Graha) -> Int {
        beneficHouses[planet]?.values.reduce(0) { $0 + $1.count } ?? 0
    }

    /// Bhinnashtakavarga of the seven planets and the resulting Sarvashtakavarga.
    static func calculate(lagnaRasi: Rasi, planets positions: [PlanetPosition]) -> AshtakavargaData {
        var referenceSigns: [Graha: Rasi] = [.ascendant: lagnaRasi]
        for position in positions where references.contains(position.graha) {
            referenceSigns[position.graha] = position.rasi
        }

        var bhinna: [Graha: [Rasi: Int]] = [:]
        for planet in contributingPlanets {
            bhinna[planet] = bhinnashtakavarga(of: planet, referenceSigns: referenceSigns)
        }

        var sarva: [Rasi: Int] = [:]
        for rasi in Rasi.allCases {
            sarva[rasi] = contributingPlanets.reduce(0) { $0 + (bhinna[$1]?[rasi] ?? 0) }
        }
        return AshtakavargaData(sarvashtakavarga: sarva, bhinnashtakavarga: bhinna)
    }

    /// Bindus of one planet in each of the twelve signs. References whose sign is unknown
    /// contribute nothing.
    static func bhinnashtakavarga(of planet: Graha, referenceSigns: [Graha: Rasi]) -> [Rasi: Int] {
        var bindus: [Rasi: Int] = [:]
        for rasi in Rasi.allCases {
            bindus[rasi] = 0
        }
        guard let table = beneficHouses[planet] else { return bindus }
        for reference in references {
            guard let referenceSign = referenceSigns[reference], let houses = table[reference] else { continue }
            for house in houses {
                let sign = referenceSign.advanced(by: house - 1)
                bindus[sign, default: 0] += 1
            }
        }
        return bindus
    }
}
