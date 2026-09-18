import Foundation

// Special lagnas: Bhava, Hora, Ghati (BPHS Ch. 5), Sree (BPHS Ch. 5),
// Varnada (BPHS Ch. 6) and Indu (Uttara Kalamrita, khanda 4).

extension JaiminiCalculator {
    /// Seconds per hour, used to convert the sunrise-to-birth interval.
    private static let secondsPerHour: Double = 3_600

    // MARK: - Assembly

    /// Builds every special lagna that the inputs allow, in `SpecialLagnaKind`
    /// order. Indu and Sree lagnas need only the Lagna and the Moon; Bhava,
    /// Hora, Ghati and Varnada lagnas need the sunrise context.
    ///
    /// Indu and Varnada are sign-only lagnas, so their longitude is the start
    /// of the sign (0° within the sign).
    static func specialLagnas(
        lagnaLongitude: Double,
        planets: [PlanetPosition],
        sunriseContext: SunriseContext?
    ) -> [SpecialLagnaPosition] {
        let lagnaRasi = Rasi(absoluteLongitude: lagnaLongitude)
        var byKind: [SpecialLagnaKind: Double] = [:]

        if let moon = planets.first(where: { $0.graha == .moon }) {
            byKind[.induLagna] = signStartLongitude(of: induLagna(lagnaRasi: lagnaRasi, moonRasi: moon.rasi))
            byKind[.sreeLagna] = sreeLagna(lagnaLongitude: lagnaLongitude, moonLongitude: moon.absoluteLongitude)
        }

        if let context = sunriseContext {
            let hora = horaLagna(context: context)
            byKind[.bhavaLagna] = bhavaLagna(context: context)
            byKind[.horaLagna] = hora
            byKind[.ghatiLagna] = ghatiLagna(context: context)
            let varnada = varnadaLagna(lagnaRasi: lagnaRasi, horaLagnaRasi: Rasi(absoluteLongitude: hora))
            byKind[.varnadaLagna] = signStartLongitude(of: varnada)
        }

        return SpecialLagnaKind.allCases.compactMap { kind in
            byKind[kind].map { position(kind: kind, longitude: $0) }
        }
    }

    /// Wraps an absolute longitude into a `SpecialLagnaPosition` using the shared helpers.
    static func position(kind: SpecialLagnaKind, longitude: Double) -> SpecialLagnaPosition {
        let normalized = longitude.normalizedLongitude360
        return SpecialLagnaPosition(
            kind: kind,
            longitude: normalized,
            rasi: Rasi(absoluteLongitude: normalized),
            longitudeInRasi: normalized.longitudeWithinRasi,
            formattedDMS: normalized.dmsStringInRasi
        )
    }

    /// Absolute longitude of the first point of a sign.
    static func signStartLongitude(of rasi: Rasi) -> Double {
        Double(rasi.rawValue - 1) * 30
    }

    // MARK: - Indu Lagna

    /// Kalas of each planet for the Indu Lagna (Uttara Kalamrita, khanda 4):
    /// Sun 30, Moon 16, Mars 6, Mercury 8, Jupiter 10, Venus 12, Saturn 1.
    /// Nodes never rule a sign in this scheme, so they carry no kalas.
    static func induKalas(of graha: Graha) -> Int {
        switch graha {
        case .sun: 30
        case .moon: 16
        case .mars: 6
        case .mercury: 8
        case .jupiter: 10
        case .venus: 12
        case .saturn: 1
        case .rahu, .ketu, .ascendant: 0
        }
    }

    /// Indu Lagna (Uttara Kalamrita, khanda 4): add the kalas of the lord of
    /// the 9th from the Lagna and of the lord of the 9th from the Moon, divide
    /// by 12 and keep the remainder (0 counts as 12), then count that many
    /// signs from the Moon's sign with the Moon's sign as 1.
    static func induLagna(lagnaRasi: Rasi, moonRasi: Rasi) -> Rasi {
        let ninthFromLagnaLord = lagnaRasi.advanced(by: 8).lord
        let ninthFromMoonLord = moonRasi.advanced(by: 8).lord
        let total = induKalas(of: ninthFromLagnaLord) + induKalas(of: ninthFromMoonLord)
        var remainder = total % 12
        if remainder == 0 {
            remainder = 12
        }
        return moonRasi.advanced(by: remainder - 1)
    }

    // MARK: - Sree Lagna

    /// Sree Lagna (BPHS Ch. 5): the fraction of the Moon's nakshatra already
    /// traversed, multiplied by 360°, is added to the Lagna's longitude.
    static func sreeLagna(lagnaLongitude: Double, moonLongitude: Double) -> Double {
        let fraction = Nakshatra.fractionTraversed(absoluteLongitude: moonLongitude)
        return (lagnaLongitude + fraction * 360).normalizedLongitude360
    }

    // MARK: - Varnada Lagna

    /// Varnada Lagna (BPHS Ch. 6). Count the Lagna sign from Aries forward if
    /// it is odd, from Pisces backward if it is even; do the same for the Hora
    /// Lagna. If both signs are odd or both are even, add the two counts;
    /// otherwise subtract the smaller from the larger. Reduce modulo 12
    /// (0 counts as 12). The result is counted forward from Aries when the
    /// Lagna sign is odd and backward from Pisces when it is even.
    static func varnadaLagna(lagnaRasi: Rasi, horaLagnaRasi: Rasi) -> Rasi {
        let lagnaCount = varnadaCount(of: lagnaRasi)
        let horaCount = varnadaCount(of: horaLagnaRasi)
        let sameKind = lagnaRasi.isOdd == horaLagnaRasi.isOdd
        var result = sameKind ? lagnaCount + horaCount : abs(lagnaCount - horaCount)
        result %= 12
        if result == 0 {
            result = 12
        }
        return lagnaRasi.isOdd
            ? Rasi.aries.advanced(by: result - 1)
            : Rasi.pisces.advanced(by: -(result - 1))
    }

    /// Odd signs count forward from Aries (Aries = 1); even signs count
    /// backward from Pisces (Pisces = 1, Aquarius = 2, … Taurus = 11).
    private static func varnadaCount(of rasi: Rasi) -> Int {
        rasi.isOdd ? rasi.rawValue : 13 - rasi.rawValue
    }

    // MARK: - Bhava, Hora and Ghati lagnas

    /// Bhava Lagna (BPHS Ch. 5): starts at the Sun's longitude at sunrise and
    /// advances one sign every 5 ghatis (2 hours), i.e. 15° per hour.
    static func bhavaLagna(context: SunriseContext) -> Double {
        (context.sunLongitudeAtSunrise + hoursSinceSunrise(context) * 15).normalizedLongitude360
    }

    /// Hora Lagna (BPHS Ch. 5): starts at the Sun's longitude at sunrise and
    /// advances one sign every 2.5 ghatis (1 hour), i.e. 30° per hour.
    static func horaLagna(context: SunriseContext) -> Double {
        (context.sunLongitudeAtSunrise + hoursSinceSunrise(context) * 30).normalizedLongitude360
    }

    /// Ghati Lagna (BPHS Ch. 5): starts at the Sun's longitude at sunrise and
    /// advances one sign every ghati (24 minutes), i.e. 75° per hour.
    static func ghatiLagna(context: SunriseContext) -> Double {
        (context.sunLongitudeAtSunrise + hoursSinceSunrise(context) * 75).normalizedLongitude360
    }

    /// Decimal hours elapsed from the reference sunrise to the birth instant.
    private static func hoursSinceSunrise(_ context: SunriseContext) -> Double {
        context.birth.timeIntervalSince(context.sunrise) / secondsPerHour
    }
}
