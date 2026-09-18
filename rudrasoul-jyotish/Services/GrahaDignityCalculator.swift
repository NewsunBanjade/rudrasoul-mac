import Foundation

/// Sign dignities, the five-fold (panchadha) planetary relationships, and combustion.
///
/// Sources: exaltation signs and their deepest points, BPHS Ch. 3, vv. 49–50; moolatrikona
/// portions, BPHS Ch. 3, vv. 51–54; natural friendship, BPHS Ch. 3, vv. 55–56; temporary
/// friendship (a planet in the 2nd, 3rd, 4th, 10th, 11th or 12th sign from another is its
/// temporary friend), BPHS Ch. 3, v. 57; compound relationship, BPHS Ch. 3, vv. 58–59.
/// Combustion distances follow Surya Siddhanta Ch. 9 as quoted by the BPHS commentators:
/// Moon 12°, Mars 17°, Mercury 14° (12° retrograde), Jupiter 11°, Venus 10° (8° retrograde),
/// Saturn 15°.
///
/// Rahu and Ketu have no classical friendship table. They are scored exalted in Taurus and
/// Scorpio respectively and debilitated in the opposite sign (a common convention), and
/// neutral everywhere else.
enum GrahaDignityCalculator {
    enum NaturalRelation: Sendable {
        case friend
        case neutral
        case enemy
    }

    /// The seven planets that take part in dignities, relationships and Shadbala.
    static let sevenGrahas: [Graha] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]

    // MARK: - Exaltation, debilitation, moolatrikona

    /// Deepest exaltation point as an absolute sidereal longitude.
    static func exaltationPoint(of graha: Graha) -> Double? {
        switch graha {
        case .sun: return 10 // Aries 10°
        case .moon: return 33 // Taurus 3°
        case .mars: return 298 // Capricorn 28°
        case .mercury: return 165 // Virgo 15°
        case .jupiter: return 95 // Cancer 5°
        case .venus: return 357 // Pisces 27°
        case .saturn: return 200 // Libra 20°
        case .rahu: return 50 // Taurus 20° (convention)
        case .ketu: return 230 // Scorpio 20° (convention)
        case .ascendant: return nil
        }
    }

    static func exaltationRasi(of graha: Graha) -> Rasi? {
        exaltationPoint(of: graha).map { Rasi(absoluteLongitude: $0) }
    }

    static func debilitationRasi(of graha: Graha) -> Rasi? {
        exaltationPoint(of: graha).map { Rasi(absoluteLongitude: $0 + 180) }
    }

    /// The degrees of the exaltation sign that count as exalted (inclusive, so the deepest
    /// point itself is exalted). Mercury is exalted only up to 15° Virgo and the Moon only up
    /// to 3° Taurus; the rest of those signs is moolatrikona.
    private static func exaltationUpperDegree(of graha: Graha) -> Double {
        switch graha {
        case .mercury: return 15
        case .moon: return 3
        default: return 30
        }
    }

    /// Moolatrikona sign and the degree range inside it (BPHS Ch. 3, vv. 51–54).
    static func moolatrikona(of graha: Graha) -> (rasi: Rasi, range: ClosedRange<Double>)? {
        switch graha {
        case .sun: return (rasi: .leo, range: 0 ... 20)
        case .moon: return (rasi: .taurus, range: 3 ... 30)
        case .mars: return (rasi: .aries, range: 0 ... 12)
        case .mercury: return (rasi: .virgo, range: 15 ... 20)
        case .jupiter: return (rasi: .sagittarius, range: 0 ... 10)
        case .venus: return (rasi: .libra, range: 0 ... 15)
        case .saturn: return (rasi: .aquarius, range: 0 ... 20)
        default: return nil
        }
    }

    /// The sign dignity of a planet from its sign, its degrees inside that sign, and the D-1
    /// positions of every planet (temporary friendships depend on them).
    ///
    /// Order of precedence: exaltation, debilitation, moolatrikona, own sign, then the
    /// compound relationship with the sign lord.
    static func dignity(of graha: Graha, rasi: Rasi, degreeInRasi: Double, planets: [PlanetPosition]) -> Dignity {
        if let exaltation = exaltationRasi(of: graha), rasi == exaltation,
           degreeInRasi <= exaltationUpperDegree(of: graha) {
            return .exalted
        }
        if let debilitation = debilitationRasi(of: graha), rasi == debilitation {
            return .debilitated
        }
        guard sevenGrahas.contains(graha) else { return .neutral }
        if let moolatrikona = moolatrikona(of: graha), rasi == moolatrikona.rasi,
           moolatrikona.range.contains(degreeInRasi) {
            return .moolatrikona
        }
        if rasi.lord == graha {
            return .ownSign
        }
        return compoundRelation(of: graha, to: rasi.lord, planets: planets)?.dignity ?? .neutral
    }

    // MARK: - Relationships

    /// Natural (naisargika) relationship of `graha` towards `other` (BPHS Ch. 3, vv. 55–56).
    static func naturalRelation(of graha: Graha, to other: Graha) -> NaturalRelation {
        guard graha != other else { return .friend }
        let friends: [Graha]
        let enemies: [Graha]
        switch graha {
        case .sun:
            friends = [.moon, .mars, .jupiter]
            enemies = [.venus, .saturn]
        case .moon:
            friends = [.sun, .mercury]
            enemies = []
        case .mars:
            friends = [.sun, .moon, .jupiter]
            enemies = [.mercury]
        case .mercury:
            friends = [.sun, .venus]
            enemies = [.moon]
        case .jupiter:
            friends = [.sun, .moon, .mars]
            enemies = [.mercury, .venus]
        case .venus:
            friends = [.mercury, .saturn]
            enemies = [.sun, .moon]
        case .saturn:
            friends = [.mercury, .venus]
            enemies = [.sun, .moon, .mars]
        default:
            return .neutral
        }
        if friends.contains(other) { return .friend }
        if enemies.contains(other) { return .enemy }
        return .neutral
    }

    /// Whether `other` is a temporary (tatkalika) friend of `graha`: it occupies the 2nd, 3rd,
    /// 4th, 10th, 11th or 12th sign counted from `graha` (BPHS Ch. 3, v. 57).
    /// Nil when either planet has no position.
    static func isTemporaryFriend(_ graha: Graha, of other: Graha, planets: [PlanetPosition]) -> Bool? {
        guard let from = planets.first(where: { $0.graha == graha })?.rasi,
              let to = planets.first(where: { $0.graha == other })?.rasi
        else {
            return nil
        }
        return [2, 3, 4, 10, 11, 12].contains(from.count(to: to))
    }

    /// Compound (panchadha) relationship of `graha` towards `other` (BPHS Ch. 3, vv. 58–59):
    /// natural friend + temporary friend = Adhi Mitra; natural neutral + temporary friend =
    /// Mitra; friend + enemy or enemy + friend = Sama; natural neutral + temporary enemy =
    /// Shatru; natural enemy + temporary enemy = Adhi Shatru.
    static func compoundRelation(of graha: Graha, to other: Graha, planets: [PlanetPosition]) -> PlanetaryRelation? {
        guard graha != other, sevenGrahas.contains(graha), sevenGrahas.contains(other),
              let temporaryFriend = isTemporaryFriend(graha, of: other, planets: planets)
        else {
            return nil
        }
        switch (naturalRelation(of: graha, to: other), temporaryFriend) {
        case (.friend, true): return .adhiMitra
        case (.friend, false): return .sama
        case (.neutral, true): return .mitra
        case (.neutral, false): return .shatru
        case (.enemy, true): return .sama
        case (.enemy, false): return .adhiShatru
        }
    }

    /// The full 7 × 7 compound relationship table, `table[graha]?[other]`.
    static func compoundRelations(planets: [PlanetPosition]) -> [Graha: [Graha: PlanetaryRelation]] {
        var table: [Graha: [Graha: PlanetaryRelation]] = [:]
        for graha in sevenGrahas {
            var row: [Graha: PlanetaryRelation] = [:]
            for other in sevenGrahas where other != graha {
                if let relation = compoundRelation(of: graha, to: other, planets: planets) {
                    row[other] = relation
                }
            }
            table[graha] = row
        }
        return table
    }

    // MARK: - Combustion

    /// Maximum distance from the Sun at which a planet is combust, in degrees.
    static func combustionOrb(of graha: Graha, isRetrograde: Bool) -> Double? {
        switch graha {
        case .moon: return 12
        case .mars: return 17
        case .mercury: return isRetrograde ? 12 : 14
        case .jupiter: return 11
        case .venus: return isRetrograde ? 8 : 10
        case .saturn: return 15
        default: return nil
        }
    }

    static func isCombust(_ planet: PlanetPosition, sunLongitude: Double) -> Bool {
        guard let orb = combustionOrb(of: planet.graha, isRetrograde: planet.isRetrograde) else { return false }
        return angularDistance(planet.absoluteLongitude, sunLongitude) <= orb
    }

    /// The shorter arc between two longitudes, 0 ... 180.
    static func angularDistance(_ first: Double, _ second: Double) -> Double {
        let difference = abs(first - second).truncatingRemainder(dividingBy: 360)
        return min(difference, 360 - difference)
    }

    // MARK: - Application

    /// The same positions with `dignity` and `isCombust` filled in.
    static func applyingDignities(to planets: [PlanetPosition]) -> [PlanetPosition] {
        let sunLongitude = planets.first(where: { $0.graha == .sun })?.absoluteLongitude
        return planets.map { planet in
            PlanetPosition(
                graha: planet.graha,
                rasi: planet.rasi,
                longitudeInRasi: planet.longitudeInRasi,
                formattedDMS: planet.formattedDMS,
                nakshatra: planet.nakshatra,
                pada: planet.pada,
                isRetrograde: planet.isRetrograde,
                isCombust: sunLongitude.map { isCombust(planet, sunLongitude: $0) } ?? false,
                dignity: dignity(
                    of: planet.graha,
                    rasi: planet.rasi,
                    degreeInRasi: planet.longitudeInRasi,
                    planets: planets
                ),
                bhava: planet.bhava,
                charaKaraka: planet.charaKaraka,
                speedDegPerDay: planet.speedDegPerDay
            )
        }
    }
}
