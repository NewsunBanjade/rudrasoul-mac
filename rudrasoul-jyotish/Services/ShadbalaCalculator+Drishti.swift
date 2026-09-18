import Foundation

/// Graduated planetary aspects (Sripati's drishti) and the Drik bala built on them.
extension ShadbalaCalculator {
    /// The virupas of aspect a planet casts on a point `distance` degrees ahead of it
    /// (BPHS Ch. 26, vv. 2–5): rising from 0 at 30° to 15 at 60°, 45 at 90°, 30 at 120°,
    /// 0 at 150°, 60 at 180°, then falling to 0 at 300°.
    static func aspectValue(distance: Double) -> Double {
        let d = distance.normalizedLongitude360
        switch d {
        case ..<30: return 0
        case ..<60: return (d - 30) / 2
        case ..<90: return d - 45
        case ..<120: return (120 - d) / 2 + 30
        case ..<150: return 150 - d
        case ..<180: return (d - 150) * 2
        case ..<300: return (300 - d) / 2
        default: return 0
        }
    }

    /// Extra virupas of the special aspects (BPHS Ch. 26, v. 6): Mars on the 4th and 8th
    /// signs (+15), Jupiter on the 5th and 9th (+30), Saturn on the 3rd and 10th (+45).
    static func specialAspectValue(of graha: Graha, signDistance: Int) -> Double {
        switch (graha, signDistance) {
        case (.mars, 4), (.mars, 8): return 15
        case (.jupiter, 5), (.jupiter, 9): return 30
        case (.saturn, 3), (.saturn, 10): return 45
        default: return 0
        }
    }

    /// Total aspect, in virupas, of `aspecting` on a point at `longitude` inside `rasi`.
    static func aspect(from aspecting: PlanetPosition, toLongitude longitude: Double, in rasi: Rasi) -> Double {
        aspectValue(distance: longitude - aspecting.absoluteLongitude)
            + specialAspectValue(of: aspecting.graha, signDistance: aspecting.rasi.count(to: rasi))
    }

    /// Signed sum of the aspects of the seven planets on a point: benefic aspects add,
    /// malefic aspects subtract. `excluded` (the aspected planet itself) casts none.
    static func netAspect(
        onLongitude longitude: Double,
        in rasi: Rasi,
        excluding excluded: Graha?,
        planets: [PlanetPosition]
    ) -> Double {
        planets.reduce(0.0) { sum, aspecting in
            guard grahas.contains(aspecting.graha), aspecting.graha != excluded else { return sum }
            let value = aspect(from: aspecting, toLongitude: longitude, in: rasi)
            return sum + (isBenefic(aspecting, planets: planets) ? value : -value)
        }
    }

    /// Drik bala (BPHS 27.26): a quarter of the benefic aspects received minus a quarter of
    /// the malefic aspects received.
    static func drikBala(of planet: PlanetPosition, planets: [PlanetPosition]) -> Double {
        netAspect(
            onLongitude: planet.absoluteLongitude, in: planet.rasi, excluding: planet.graha, planets: planets
        ) / 4
    }
}
