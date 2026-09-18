import Foundation

/// Jaimini building blocks: chara karakas, arudha padas, karakamsa, and the
/// special lagnas. Every function is pure and deterministic; the only inputs
/// are sidereal longitudes and, for the time-based lagnas, the sunrise context.
///
/// Sources: Jaimini Upadesa Sutras (adhyaya 1, pada 1), Brihat Parashara Hora
/// Shastra (BPHS) chapters 5, 6, 29 and 32, and Uttara Kalamrita (Indu Lagna).
struct JaiminiCalculator: Sendable {
    /// Sunrise data the service supplies; nil when sunrise could not be computed.
    struct SunriseContext: Sendable {
        /// Birth instant in UTC.
        let birth: Date
        /// The last sunrise at or before `birth`, in UTC.
        let sunrise: Date
        /// Sidereal longitude of the Sun at that sunrise, in decimal degrees.
        let sunLongitudeAtSunrise: Double
    }

    var scheme: CharaKarakaScheme = .sevenKarakas
    /// Product decision: arudha exceptions are OFF by default ("use no exceptions").
    var applyArudhaExceptions: Bool = false

    /// The seven karakas in descending order of planetary degree (BPHS Ch. 32).
    static let karakaOrder: [CharaKaraka] = [
        .atmakaraka, .amatyakaraka, .bhratrukaraka, .matrukaraka,
        .putrakaraka, .gnatikaraka, .darakaraka,
    ]

    // MARK: - Full computation

    /// Fills `JaiminiData` from the D-1 positions. Bhava, Hora, Ghati and
    /// Varnada lagnas are produced only when `sunriseContext` is present;
    /// Indu and Sree lagnas need only the Moon and the Lagna.
    func calculate(
        lagnaLongitude: Double,
        planets: [PlanetPosition],
        sunriseContext: SunriseContext?
    ) -> JaiminiData {
        let lagnaRasi = Rasi(absoluteLongitude: lagnaLongitude)
        let karakas = Self.charaKarakas(planets: planets, scheme: scheme)
        let padas = Self.arudhaPadas(
            lagnaRasi: lagnaRasi,
            planets: planets,
            applyExceptions: applyArudhaExceptions
        )
        let karakamsa = Self.karakamsa(charaKarakas: karakas, planets: planets)
        let lagnamsa = VargaCalculator.rasi(for: lagnaLongitude, division: .d9)
        let lagnas = Self.specialLagnas(
            lagnaLongitude: lagnaLongitude,
            planets: planets,
            sunriseContext: sunriseContext
        )

        return JaiminiData(
            scheme: scheme,
            charaKarakas: karakas,
            arudhaPadas: padas,
            arudhaExceptionsApplied: applyArudhaExceptions,
            karakamsaRasi: karakamsa,
            lagnamsaRasi: lagnamsa,
            specialLagnas: lagnas
        )
    }

    // MARK: - Chara karakas

    /// Ranks the planets by their degree within the sign; the highest degree is
    /// the Atmakaraka, then Amatya, Bhratru, Matru, Putra, Gnati and Dara
    /// (BPHS Ch. 32; Jaimini Sutras 1.1.10–1.1.18).
    ///
    /// `.sevenKarakas` ranks Sun through Saturn only. `.eightKarakas` adds Rahu,
    /// whose degree is counted backwards from the end of its sign
    /// (30° − Rahu's longitude in sign) because the node moves in reverse.
    /// `CharaKaraka` has only seven cases, so in the eight-planet scheme the
    /// top seven planets are mapped and the eighth (lowest, where classical
    /// texts split Pitru/Gnati) is not represented in the result.
    ///
    /// Ties on the exact decimal degree are broken by the fixed order of
    /// `Graha.allCases` (Sun before Moon before Mars, and so on).
    static func charaKarakas(planets: [PlanetPosition], scheme: CharaKarakaScheme) -> [CharaKaraka: Graha] {
        let candidates = planets.compactMap { position -> (graha: Graha, degree: Double, order: Int)? in
            guard let order = Graha.allCases.firstIndex(of: position.graha) else { return nil }
            switch position.graha {
            case .sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn:
                return (position.graha, position.longitudeInRasi, order)
            case .rahu where scheme == .eightKarakas:
                return (position.graha, 30 - position.longitudeInRasi, order)
            default:
                return nil
            }
        }

        let ranked = candidates.sorted { lhs, rhs in
            if lhs.degree != rhs.degree {
                return lhs.degree > rhs.degree
            }
            return lhs.order < rhs.order
        }

        var result: [CharaKaraka: Graha] = [:]
        for (index, karaka) in karakaOrder.enumerated() where index < ranked.count {
            result[karaka] = ranked[index].graha
        }
        return result
    }

    /// Navamsa sign of the Atmakaraka (Karakamsa / Swamsa), Jaimini Sutras 1.2.
    /// Nil when the Atmakaraka's D-1 position is not among `planets`.
    static func karakamsa(charaKarakas: [CharaKaraka: Graha], planets: [PlanetPosition]) -> Rasi? {
        guard let atmakaraka = charaKarakas[.atmakaraka],
              let position = planets.first(where: { $0.graha == atmakaraka })
        else {
            return nil
        }
        return VargaCalculator.rasi(for: position.absoluteLongitude, division: .d9)
    }

    // MARK: - Arudha padas

    /// Arudha pada of every whole-sign bhava from the Lagna, in house order
    /// (Jaimini Sutras 1.1.29–30; BPHS Ch. 29).
    ///
    /// For bhava n take its sign lord L, count the signs from the bhava sign to
    /// L's sign inclusive (k, 1…12), and the pada is the k-th sign counted from
    /// L's sign. Sign lords come from `Rasi.lord` (Mars for Scorpio, Saturn for
    /// Aquarius); the Ketu/Rahu co-lordship variant is not used.
    ///
    /// When `applyExceptions` is true the classical exceptions are applied:
    /// a pada falling in the bhava sign itself moves to the 10th from that
    /// pada, and a pada falling in the 7th from the bhava sign moves to the 4th
    /// from that pada. Bhavas whose lord has no position in `planets` are left out.
    static func arudhaPadas(lagnaRasi: Rasi, planets: [PlanetPosition], applyExceptions: Bool) -> [ArudhaPada] {
        (1...12).compactMap { house in
            arudhaPada(house: house, lagnaRasi: lagnaRasi, planets: planets, applyExceptions: applyExceptions)
        }
    }

    private static func arudhaPada(
        house: Int,
        lagnaRasi: Rasi,
        planets: [PlanetPosition],
        applyExceptions: Bool
    ) -> ArudhaPada? {
        let bhavaRasi = lagnaRasi.advanced(by: house - 1)
        let lord = bhavaRasi.lord
        guard let lordRasi = planets.first(where: { $0.graha == lord })?.rasi else {
            return nil
        }

        let count = bhavaRasi.count(to: lordRasi)
        var pada = lordRasi.advanced(by: count - 1)
        var exceptionApplied = false

        if applyExceptions {
            if pada == bhavaRasi {
                pada = pada.advanced(by: 9) // 10th from the pada
                exceptionApplied = true
            } else if pada == bhavaRasi.advanced(by: 6) {
                pada = pada.advanced(by: 3) // 4th from the pada
                exceptionApplied = true
            }
        }

        return ArudhaPada(
            house: house,
            name: arudhaName(house: house),
            rasi: pada,
            lord: lord,
            exceptionApplied: exceptionApplied
        )
    }

    /// "AL" for the Lagna pada, "UL" (Upapada) for the 12th, "A7" (Darapada)
    /// for the 7th and "A2"…"A11" for the rest.
    static func arudhaName(house: Int) -> String {
        switch house {
        case 1: "AL"
        case 12: "UL"
        default: "A\(house)"
        }
    }
}
