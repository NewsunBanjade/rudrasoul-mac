import Foundation

/// Bhava Bala, the strength of the twelve houses.
///
/// Sources: Brihat Parashara Hora Shastra Ch. 28 and B. V. Raman, "Graha and Bhava Balas".
/// Three components are summed for every house: the Shadbala of the lord of the house sign
/// (Bhavadhipati bala), the directional strength of that sign in that house (Bhava Dig bala),
/// and a quarter of the net benefic aspect on the house cusp (Bhava Drishti bala). The
/// day-birth / night-birth additions some commentators include are not applied.
enum BhavaBalaCalculator {
    static func calculate(cusps: [Double], shadbala: [ShadbalaBreakdown], planets: [PlanetPosition]) -> [BhavaBala] {
        guard cusps.count == 12, !shadbala.isEmpty else { return [] }

        var houses: [Int] = []
        var rasis: [Rasi] = []
        var lords: [Graha] = []
        var adhipatiBalas: [Double] = []
        var digBalas: [Double] = []
        var drishtiBalas: [Double] = []
        var totals: [Double] = []

        for index in 0 ..< 12 {
            let cusp = cusps[index].normalizedLongitude360
            let rasi = Rasi(absoluteLongitude: cusp)
            let lord = rasi.lord
            let adhipati = shadbala.first(where: { $0.graha == lord })?.totalVirupas ?? 0
            let dig = bhavaDigBala(house: index + 1, cuspLongitude: cusp)
            let drishti = ShadbalaCalculator.netAspect(
                onLongitude: cusp, in: rasi, excluding: nil, planets: planets
            ) / 4
            houses.append(index + 1)
            rasis.append(rasi)
            lords.append(lord)
            adhipatiBalas.append(adhipati)
            digBalas.append(dig)
            drishtiBalas.append(drishti)
            totals.append(adhipati + dig + drishti)
        }

        let ranking = totals.indices.sorted { totals[$0] > totals[$1] }
        return totals.indices.map { index in
            BhavaBala(
                house: houses[index],
                rasi: rasis[index],
                lord: lords[index],
                bhavadhipatiBala: adhipatiBalas[index],
                bhavaDigBala: digBalas[index],
                bhavaDrishtiBala: drishtiBalas[index],
                totalVirupas: totals[index],
                rank: (ranking.firstIndex(of: index) ?? 0) + 1
            )
        }
    }

    /// The house in which a sign of this kind is strongest (BPHS 28.4–5): human signs
    /// (Gemini, Virgo, Libra, Aquarius, first half of Sagittarius) in the 1st; quadrupeds
    /// (Aries, Taurus, Leo, second half of Sagittarius, first half of Capricorn) in the 10th;
    /// watery signs (Cancer, Pisces, second half of Capricorn) in the 4th; Scorpio in the 7th.
    static func strongestHouse(forCuspLongitude longitude: Double) -> Int {
        let rasi = Rasi(absoluteLongitude: longitude)
        let firstHalf = longitude.longitudeWithinRasi < 15
        switch rasi {
        case .gemini, .virgo, .libra, .aquarius: return 1
        case .sagittarius: return firstHalf ? 1 : 10
        case .aries, .taurus, .leo: return 10
        case .capricorn: return firstHalf ? 10 : 4
        case .cancer, .pisces: return 4
        case .scorpio: return 7
        }
    }

    /// 60 virupas when the sign sits in its strongest house, 10 fewer for every house away
    /// from it (counting the shorter way round), down to 0 in the opposite house.
    static func bhavaDigBala(house: Int, cuspLongitude: Double) -> Double {
        let strongest = strongestHouse(forCuspLongitude: cuspLongitude)
        let difference = abs(house - strongest)
        let distance = min(difference, 12 - difference)
        return Double(60 - 10 * distance)
    }
}
