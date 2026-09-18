import Foundation

/// Everything the Shadbala calculator needs; supplied by the service layer so the
/// calculator itself never touches the ephemeris.
struct ShadbalaInput: Sendable {
    /// D-1 positions of every planet (Rahu and Ketu are ignored).
    let planets: [PlanetPosition]
    /// Sidereal ascendant in decimal degrees.
    let lagnaLongitude: Double
    /// Sidereal midheaven (10th bhava madhya) in decimal degrees.
    let midheavenLongitude: Double
    /// Ayanamsa at birth; recovers tropical longitudes for declinations and mean elements.
    let ayanamsaDegrees: Double
    /// Birth instant in UTC.
    let birth: Date
    /// Geographic longitude, east positive, for local mean time.
    let geographicLongitude: Double
    /// Sunrise, sunset and weekday of the birth; nil when the Sun neither rises nor sets.
    let day: UpagrahaCalculator.DayContext?
}

/// Shadbala, the six-fold strength of the seven planets.
///
/// Sources: Brihat Parashara Hora Shastra Ch. 27 (Santhanam) and B. V. Raman,
/// "Graha and Bhava Balas". Every function is pure.
///
/// Conventions chosen where the sources allow variants (each is also documented at its
/// function):
/// - Saptavargaja values are 45 / 30 / 20 / 15 / 10 / 4 / 2; moolatrikona is judged by degree
///   in D-1 and by sign in the other six vargas.
/// - Kendradi bala counts signs from the Lagna sign.
/// - Dig bala is measured from the Lagna and Midheaven degrees and their opposite points.
/// - Nathonnatha bala uses local mean time (4 minutes per degree of longitude) midnight.
/// - Cheshta bala uses the Chesta kendra of mean and true longitudes (Surya Siddhanta method);
///   the Sun's equals its Ayana bala and the Moon's its Paksha bala.
/// - Graha yuddha (planetary war) adjustments are not applied.
enum ShadbalaCalculator {
    static let grahas = GrahaDignityCalculator.sevenGrahas

    /// Minimum strength in rupas for a planet to be considered strong (BPHS 27.28).
    static func requiredRupas(for graha: Graha) -> Double {
        switch graha {
        case .sun: return 6.5
        case .moon: return 6.0
        case .mars: return 5.0
        case .mercury: return 7.0
        case .jupiter: return 6.5
        case .venus: return 5.5
        case .saturn: return 5.0
        default: return 0
        }
    }

    /// Naisargika bala (BPHS 27.25): 60 × 7/7, 6/7 … 1/7 for Sun, Moon, Venus, Jupiter,
    /// Mercury, Mars and Saturn.
    static func naisargikaBala(of graha: Graha) -> Double {
        switch graha {
        case .sun: return 60
        case .moon: return 60 * 6 / 7
        case .venus: return 60 * 5 / 7
        case .jupiter: return 60 * 4 / 7
        case .mercury: return 60 * 3 / 7
        case .mars: return 60 * 2 / 7
        case .saturn: return 60 / 7
        default: return 0
        }
    }

    // MARK: - Full computation

    static func calculate(_ input: ShadbalaInput) -> [ShadbalaBreakdown] {
        let positions = grahas.compactMap { graha in input.planets.first { $0.graha == graha } }
        guard positions.count == grahas.count else { return [] }
        let lagnaRasi = Rasi(absoluteLongitude: input.lagnaLongitude)
        let kalaContext = KalaContext(input: input)

        let entries = positions.map { planet in
            entry(for: planet, input: input, lagnaRasi: lagnaRasi, kalaContext: kalaContext)
        }
        let ranked = entries.sorted { $0.total > $1.total }

        return entries.map { entry in
            let rank = (ranked.firstIndex(where: { $0.planet.graha == entry.planet.graha }) ?? 0) + 1
            return ShadbalaBreakdown(
                graha: entry.planet.graha,
                sthanaBala: entry.sthana,
                dikBala: entry.dik,
                kalaBala: entry.kala,
                cheshtaBala: entry.cheshta,
                naisargikaBala: entry.naisargika,
                drikBala: entry.drik,
                totalVirupas: entry.total,
                totalRupas: entry.total / 60,
                requiredRupas: requiredRupas(for: entry.planet.graha),
                rank: rank,
                components: entry.components
            )
        }
    }

    private struct Entry {
        let planet: PlanetPosition
        let components: ShadbalaComponents
        let sthana: Double
        let dik: Double
        let kala: Double
        let cheshta: Double
        let naisargika: Double
        let drik: Double

        var total: Double { sthana + dik + kala + cheshta + naisargika + drik }
    }

    private static func entry(
        for planet: PlanetPosition,
        input: ShadbalaInput,
        lagnaRasi: Rasi,
        kalaContext: KalaContext
    ) -> Entry {
        let uccha = ucchaBala(of: planet.graha, longitude: planet.absoluteLongitude)
        let saptavargaja = saptavargajaBala(of: planet, planets: input.planets)
        let ojayugma = ojayugmaBala(of: planet)
        let kendradi = kendradiBala(of: planet, lagnaRasi: lagnaRasi)
        let drekkana = drekkanaBala(of: planet)
        let sthana = uccha + saptavargaja + ojayugma + kendradi + drekkana

        let dik = digBala(
            of: planet, lagnaLongitude: input.lagnaLongitude, midheavenLongitude: input.midheavenLongitude
        )

        let nathonnatha = nathonnathaBala(
            of: planet.graha, birth: input.birth, geographicLongitude: input.geographicLongitude
        )
        let paksha = pakshaBala(of: planet, planets: input.planets)
        let tribhaga = tribhagaBala(of: planet.graha, day: input.day, birth: input.birth)
        let abda = kalaContext.yearLord == planet.graha ? 15.0 : 0.0
        let masa = kalaContext.monthLord == planet.graha ? 30.0 : 0.0
        let vara = kalaContext.varaLord == planet.graha ? 45.0 : 0.0
        let hora = kalaContext.horaLord == planet.graha ? 60.0 : 0.0
        let ayana = ayanaBala(of: planet, ayanamsaDegrees: input.ayanamsaDegrees, birth: input.birth)
        let kala = nathonnatha + paksha + tribhaga + abda + masa + vara + hora + ayana

        let cheshta = cheshtaBala(
            of: planet, ayanaBala: ayana, pakshaBala: paksha, ayanamsaDegrees: input.ayanamsaDegrees, birth: input.birth
        )
        let components = ShadbalaComponents(
            ucchaBala: uccha,
            saptavargajaBala: saptavargaja,
            ojayugmaBala: ojayugma,
            kendradiBala: kendradi,
            drekkanaBala: drekkana,
            nathonnathaBala: nathonnatha,
            pakshaBala: paksha,
            tribhagaBala: tribhaga,
            abdaBala: abda,
            masaBala: masa,
            varaBala: vara,
            horaBala: hora,
            ayanaBala: ayana,
            cheshtaNote: cheshta.note
        )
        return Entry(
            planet: planet,
            components: components,
            sthana: sthana,
            dik: dik,
            kala: kala,
            cheshta: cheshta.value,
            naisargika: naisargikaBala(of: planet.graha),
            drik: drikBala(of: planet, planets: input.planets)
        )
    }

    // MARK: - Sthana bala

    /// Uccha bala (BPHS 27.3–4): 60 virupas at the deepest exaltation point falling to 0 at
    /// the deepest debilitation point, one virupa per 3°.
    static func ucchaBala(of graha: Graha, longitude: Double) -> Double {
        guard let exaltation = GrahaDignityCalculator.exaltationPoint(of: graha) else { return 0 }
        let debilitation = (exaltation + 180).normalizedLongitude360
        return GrahaDignityCalculator.angularDistance(longitude, debilitation) / 3
    }

    /// The seven vargas of Saptavargaja bala.
    static let saptavargaDivisions: [VargaDivision] = [.d1, .d2, .d3, .d7, .d9, .d12, .d30]

    /// Saptavargaja bala (BPHS 27.6–7): in each of the seven vargas the planet gets 45 in its
    /// moolatrikona, 30 in its own sign, 20 in an Adhi Mitra's sign, 15 in a Mitra's, 10 in a
    /// Sama's, 4 in a Shatru's and 2 in an Adhi Shatru's. Moolatrikona is judged by degree in
    /// D-1 and by sign in the other vargas, where degrees have no meaning.
    static func saptavargajaBala(of planet: PlanetPosition, planets: [PlanetPosition]) -> Double {
        saptavargaDivisions.reduce(0.0) { total, division in
            total + vargaBala(of: planet, in: division, planets: planets)
        }
    }

    static func vargaBala(of planet: PlanetPosition, in division: VargaDivision, planets: [PlanetPosition]) -> Double {
        let sign = VargaCalculator.rasi(for: planet.absoluteLongitude, division: division)
        if let moolatrikona = GrahaDignityCalculator.moolatrikona(of: planet.graha), sign == moolatrikona.rasi {
            let inPortion = division == .d1 ? moolatrikona.range.contains(planet.longitudeInRasi) : true
            if inPortion { return 45 }
        }
        if sign.lord == planet.graha { return 30 }
        guard let relation = GrahaDignityCalculator.compoundRelation(of: planet.graha, to: sign.lord, planets: planets)
        else {
            return 10
        }
        switch relation {
        case .adhiMitra: return 20
        case .mitra: return 15
        case .sama: return 10
        case .shatru: return 4
        case .adhiShatru: return 2
        }
    }

    /// Ojayugma bala (BPHS 27.8): the Moon and Venus gain 15 virupas in an even sign, the
    /// other planets 15 in an odd sign, in each of D-1 and D-9.
    static func ojayugmaBala(of planet: PlanetPosition) -> Double {
        let prefersEven = planet.graha == .moon || planet.graha == .venus
        let signs = [planet.rasi, VargaCalculator.rasi(for: planet.absoluteLongitude, division: .d9)]
        return signs.reduce(0.0) { total, sign in
            total + (sign.isOdd != prefersEven ? 15.0 : 0.0)
        }
    }

    /// Kendradi bala (BPHS 27.9): 60 in a kendra, 30 in a panapara, 15 in an apoklima,
    /// counting signs from the Lagna sign.
    static func kendradiBala(of planet: PlanetPosition, lagnaRasi: Rasi) -> Double {
        switch lagnaRasi.count(to: planet.rasi) {
        case 1, 4, 7, 10: return 60
        case 2, 5, 8, 11: return 30
        default: return 15
        }
    }

    /// Drekkana bala (BPHS 27.10): male planets (Sun, Mars, Jupiter) gain 15 in the first
    /// drekkana, hermaphrodite planets (Mercury, Saturn) in the second, female planets
    /// (Moon, Venus) in the third.
    static func drekkanaBala(of planet: PlanetPosition) -> Double {
        let drekkana = min(Int(planet.longitudeInRasi / 10), 2) + 1
        switch planet.graha {
        case .sun, .mars, .jupiter: return drekkana == 1 ? 15 : 0
        case .mercury, .saturn: return drekkana == 2 ? 15 : 0
        case .moon, .venus: return drekkana == 3 ? 15 : 0
        default: return 0
        }
    }

    // MARK: - Dig bala

    /// Dig bala (BPHS 27.11): Jupiter and Mercury are strongest at the Lagna, the Sun and
    /// Mars at the Midheaven, Saturn at the 7th (Lagna + 180°), the Moon and Venus at the 4th
    /// (Midheaven + 180°). The strength is the distance from the opposite point divided by 3.
    static func digBala(of planet: PlanetPosition, lagnaLongitude: Double, midheavenLongitude: Double) -> Double {
        let strongPoint: Double
        switch planet.graha {
        case .jupiter, .mercury: strongPoint = lagnaLongitude
        case .sun, .mars: strongPoint = midheavenLongitude
        case .saturn: strongPoint = lagnaLongitude + 180
        case .moon, .venus: strongPoint = midheavenLongitude + 180
        default: return 0
        }
        let weakPoint = (strongPoint + 180).normalizedLongitude360
        return GrahaDignityCalculator.angularDistance(planet.absoluteLongitude, weakPoint) / 3
    }

    // MARK: - Cheshta bala

    struct CheshtaResult: Sendable {
        let value: Double
        let note: String
    }

    /// Cheshta bala (BPHS 27.21–24): the Sun's equals its Ayana bala, the Moon's its Paksha
    /// bala, and the five other planets get their Chesta kendra divided by 3.
    static func cheshtaBala(
        of planet: PlanetPosition,
        ayanaBala: Double,
        pakshaBala: Double,
        ayanamsaDegrees: Double,
        birth: Date
    ) -> CheshtaResult {
        switch planet.graha {
        case .sun:
            return CheshtaResult(value: ayanaBala, note: "Equals Ayana bala")
        case .moon:
            return CheshtaResult(value: pakshaBala, note: "Equals Paksha bala")
        case .mars, .mercury, .jupiter, .venus, .saturn:
            let kendra = cheshtaKendra(of: planet, ayanamsaDegrees: ayanamsaDegrees, birth: birth)
            return CheshtaResult(value: kendra / 3, note: String(format: "Chesta kendra %.1f°", kendra))
        default:
            return CheshtaResult(value: 0, note: "")
        }
    }

    /// Chesta kendra = Seeghrochcha − (mean planet + true planet) / 2, reduced to 0 … 180
    /// (Surya Siddhanta; Raman, "Graha and Bhava Balas", Cheshta bala).
    ///
    /// For Mars, Jupiter and Saturn the Seeghrochcha is the mean Sun and the mean planet the
    /// planet's own heliocentric mean longitude; for Mercury and Venus the mean planet is the
    /// mean Sun and the Seeghrochcha the planet's heliocentric mean longitude. Mean longitudes
    /// are tropical of date (Meeus, Astronomical Algorithms, Table 31.A) and the sidereal true
    /// longitude is made tropical by adding the ayanamsa, so the two frames cancel.
    static func cheshtaKendra(of planet: PlanetPosition, ayanamsaDegrees: Double, birth: Date) -> Double {
        let centuries = julianCenturiesSinceJ2000(birth)
        guard let heliocentric = meanHeliocentricLongitude(of: planet.graha, centuries: centuries) else { return 0 }
        let meanSun = meanSunLongitude(centuries: centuries)
        let trueLongitude = (planet.absoluteLongitude + ayanamsaDegrees).normalizedLongitude360

        let seeghrochcha: Double
        let meanPlanet: Double
        switch planet.graha {
        case .mercury, .venus:
            seeghrochcha = heliocentric
            meanPlanet = meanSun
        default:
            seeghrochcha = meanSun
            meanPlanet = heliocentric
        }

        // Circular mean of the mean and true longitudes.
        var halfDifference = (trueLongitude - meanPlanet).normalizedLongitude360
        if halfDifference > 180 { halfDifference -= 360 }
        let average = (meanPlanet + halfDifference / 2).normalizedLongitude360

        let kendra = (seeghrochcha - average).normalizedLongitude360
        return kendra > 180 ? 360 - kendra : kendra
    }

    /// Julian centuries from J2000.0 (JD 2 451 545.0) to a UTC instant.
    static func julianCenturiesSinceJ2000(_ date: Date) -> Double {
        let julianDay = 2_440_587.5 + date.timeIntervalSince1970 / 86_400
        return (julianDay - 2_451_545.0) / 36_525
    }

    /// Geocentric mean longitude of the Sun, tropical of date (Meeus 25.2).
    static func meanSunLongitude(centuries: Double) -> Double {
        (280.466457 + 36_000.7698278 * centuries).normalizedLongitude360
    }

    /// Heliocentric mean longitude of a planet, tropical of date (Meeus, Table 31.A).
    static func meanHeliocentricLongitude(of graha: Graha, centuries: Double) -> Double? {
        let value: Double
        switch graha {
        case .mercury: value = 252.250906 + 149_474.0722491 * centuries
        case .venus: value = 181.979801 + 58_519.2130302 * centuries
        case .mars: value = 355.433000 + 19_141.6964471 * centuries
        case .jupiter: value = 34.351519 + 3_036.3027748 * centuries
        case .saturn: value = 50.077444 + 1_223.5110686 * centuries
        default: return nil
        }
        return value.normalizedLongitude360
    }
}
