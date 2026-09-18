import EphemerisKit
import Foundation

/// Computes a complete `ChartDetail` from stored birth input through Swiss Ephemeris.
///
/// The ephemeris supplies longitudes, houses, sunrise and sunset. Everything
/// else (vargas, upagrahas, Jaimini data, dashas, chakras) is derived by the
/// pure calculators so that no quantity is computed in two places.
struct ChartCalculationService: Sendable {
    let ephemeris: SwissEphemeris

    init(ephemeris: SwissEphemeris = .shared) {
        self.ephemeris = ephemeris
    }

    func calculate(input: ChartCalculationInput) async throws -> ChartDetail {
        let coordinates = try input.coordinates
        let utcDate = try input.utcDate
        let julianDay = JulianDay(date: utcDate)
        let settings = EphemerisSettings(source: .swiss, ayanamsa: input.ayanamsa)
        let houses = try await ephemeris.houses(
            at: julianDay, coordinates: coordinates, system: input.houseSystem, ayanamsa: input.ayanamsa
        )

        var planets = try await planetPositions(
            julianDay: julianDay, settings: settings, nodeCalculation: input.nodeCalculation, cusps: houses.cusps
        )
        guard let moon = planets.first(where: { $0.graha == .moon }) else {
            throw ChartCalculationError.missingMoonPosition
        }
        let ascendant = houses.ascendant.normalizedLongitude360
        let lagna = makePosition(graha: .ascendant, longitude: ascendant, speed: nil, bhava: 1)

        // Day of birth: sunrise, sunset, vara, and everything that depends on them.
        let day = await dayContext(birth: utcDate, coordinates: coordinates, utcOffsetSeconds: input.utcOffsetSeconds)
        let upagrahas = await upagrahaPositions(
            context: day, coordinates: coordinates, houseSystem: input.houseSystem,
            ayanamsa: input.ayanamsa, cusps: houses.cusps
        )
        var sunriseContext: JaiminiCalculator.SunriseContext?
        if let day, let sunAtSunrise = try? await sunLongitude(at: day.sunrise, ayanamsa: input.ayanamsa) {
            sunriseContext = JaiminiCalculator.SunriseContext(
                birth: utcDate, sunrise: day.sunrise, sunLongitudeAtSunrise: sunAtSunrise
            )
        }

        // Jaimini: chara karakas are also written back onto the planet positions.
        let jaimini = JaiminiCalculator().calculate(
            lagnaLongitude: ascendant, planets: planets, sunriseContext: sunriseContext
        )
        planets = applyingCharaKarakas(jaimini.charaKarakas, to: planets)

        // Dashas.
        let vimshottari = VimshottariDashaCalculator().calculate(
            moonLongitude: moon.absoluteLongitude, birthDate: utcDate, maximumLevel: .pratyantardasha
        )
        let yogini = YoginiDashaCalculator().calculate(moonLongitude: moon.absoluteLongitude, birthDate: utcDate)
        let chara = CharaDashaCalculator().calculate(lagnaRasi: lagna.rasi, planets: planets, birthDate: utcDate)
        let lagnamsaRasi = VargaCalculator.rasi(for: ascendant, division: .d9)
        let lagnamsa = CharaDashaCalculator().calculateLagnamsa(
            lagnamsaRasi: lagnamsaRasi, planets: planets, birthDate: utcDate
        )

        let ayanamsaDegrees = await ephemeris.ayanamsaValue(at: julianDay, ayanamsa: input.ayanamsa ?? .lahiri)

        var detail = ChartDetail(
            id: input.id,
            name: input.name,
            gender: input.gender,
            birthDate: input.birthDate,
            birthTimeString: input.birthTimeString,
            calendarSystem: input.calendarSystem,
            bikramSambatDateString: input.bikramSambatDateString,
            locationName: input.locationName,
            latitude: input.latitude,
            longitude: input.longitude,
            timezoneString: input.timezoneString,
            ayanamsaName: input.ayanamsaName,
            ayanamsaValueDMS: dmsString(degrees: ayanamsaDegrees),
            nodeCalculation: input.nodeCalculation == .trueNode ? "True Node" : "Mean Node",
            sunriseString: day.map { localTimeString($0.sunrise, utcOffsetSeconds: input.utcOffsetSeconds) } ?? "",
            sunsetString: day.map { localTimeString($0.sunset, utcOffsetSeconds: input.utcOffsetSeconds) } ?? "",
            lagnaPosition: lagna,
            planets: planets,
            bhavas: bhavas(cusps: houses.cusps, planets: planets),
            vargas: VargaCalculator.charts(lagnaLongitude: ascendant, planets: planets, upagrahas: upagrahas),
            shadbala: [],
            ashtakavarga: AshtakavargaData(sarvashtakavarga: [:], bhinnashtakavarga: [:]),
            dashaNodes: vimshottari.nodes,
            currentDashaVector: vimshottari.currentDashaVector,
            yogas: [],
            sarvatobhadra: SarvatobhadraCalculator.calculate(planets: planets, lagna: lagna),
            kota: KotaChakraCalculator.calculate(planets: planets, lagna: lagna),
            notes: input.notes,
            predictions: []
        )
        detail.utcBirthDate = utcDate
        detail.sunriseDate = day?.sunrise
        detail.sunsetDate = day?.sunset
        detail.vara = day?.vara
        detail.upagrahas = upagrahas
        detail.jaimini = jaimini
        detail.yoginiDasha = yogini
        detail.charaDasha = chara
        detail.lagnamsaDasha = lagnamsa
        return detail
    }

    // MARK: - Positions

    private func planetPositions(
        julianDay: JulianDay,
        settings: EphemerisSettings,
        nodeCalculation: ChartCalculationInput.NodeCalculation,
        cusps: [Double]
    ) async throws -> [PlanetPosition] {
        let rawPositions = try await withThrowingTaskGroup(of: (Graha, EclipticPosition).self) { group in
            for graha in Graha.ephemerisGrahas {
                group.addTask {
                    (graha, try await ephemeris.position(
                        of: graha.ephemerisGraha(nodeCalculation: nodeCalculation), at: julianDay, settings: settings
                    ))
                }
            }
            var positions: [(Graha, EclipticPosition)] = []
            for try await position in group {
                positions.append(position)
            }
            return positions
        }

        var planets = rawPositions.map { graha, position in
            makePosition(
                graha: graha,
                longitude: position.longitude,
                speed: position.longitudeSpeed,
                bhava: houseNumber(for: position.longitude, cusps: cusps)
            )
        }
        if let rahu = planets.first(where: { $0.graha == .rahu }) {
            // Ketu is always diametrically opposite Rahu and shares its motion.
            let ketuLongitude = (rahu.absoluteLongitude + 180).normalizedLongitude360
            planets.append(
                makePosition(
                    graha: .ketu,
                    longitude: ketuLongitude,
                    speed: rahu.speedDegPerDay,
                    bhava: houseNumber(for: ketuLongitude, cusps: cusps)
                )
            )
        }
        let order = Graha.allCases
        planets.sort { (order.firstIndex(of: $0.graha) ?? 0) < (order.firstIndex(of: $1.graha) ?? 0) }
        return planets
    }

    private func makePosition(graha: Graha, longitude: Double, speed: Double?, bhava: Int) -> PlanetPosition {
        let normalized = longitude.normalizedLongitude360
        return PlanetPosition(
            graha: graha,
            rasi: Rasi(absoluteLongitude: normalized),
            longitudeInRasi: normalized.longitudeWithinRasi,
            formattedDMS: normalized.dmsStringInRasi,
            nakshatra: Nakshatra(absoluteLongitude: normalized),
            pada: Nakshatra.pada(absoluteLongitude: normalized),
            isRetrograde: (speed ?? 0) < 0,
            isCombust: false,
            dignity: .neutral,
            bhava: bhava,
            charaKaraka: nil,
            speedDegPerDay: speed
        )
    }

    private func applyingCharaKarakas(_ karakas: [CharaKaraka: Graha], to planets: [PlanetPosition]) -> [PlanetPosition] {
        planets.map { planet in
            guard let karaka = karakas.first(where: { $0.value == planet.graha })?.key else { return planet }
            return PlanetPosition(
                graha: planet.graha,
                rasi: planet.rasi,
                longitudeInRasi: planet.longitudeInRasi,
                formattedDMS: planet.formattedDMS,
                nakshatra: planet.nakshatra,
                pada: planet.pada,
                isRetrograde: planet.isRetrograde,
                isCombust: planet.isCombust,
                dignity: planet.dignity,
                bhava: planet.bhava,
                charaKaraka: karaka,
                speedDegPerDay: planet.speedDegPerDay
            )
        }
    }

    private func bhavas(cusps: [Double], planets: [PlanetPosition]) -> [BhavaData] {
        (0 ..< 12).map { index in
            let cusp = cusps[index].normalizedLongitude360
            let rasi = Rasi(absoluteLongitude: cusp)
            return BhavaData(
                number: index + 1,
                rasi: rasi,
                cuspLongitudeDMS: cusp.dmsStringInRasi,
                lord: rasi.lord,
                occupantGrahas: planets.filter { $0.bhava == index + 1 }.map(\.graha),
                name: "Bhava \(index + 1)",
                significance: ""
            )
        }
    }
}

struct ChartCalculationInput: Sendable {
    enum NodeCalculation: Sendable { case trueNode, meanNode }

    let id: UUID
    let name: String
    let gender: String
    let birthDate: Date
    let birthTimeString: String
    let calendarSystem: String
    let bikramSambatDateString: String
    let locationName: String
    let latitude: String
    let longitude: String
    let timezoneString: String
    let utcOffsetSeconds: TimeInterval
    let ayanamsaName: String
    let ayanamsa: Ayanamsa?
    let nodeCalculation: NodeCalculation
    let houseSystem: HouseSystem
    let notes: [ChartNote]

    var coordinates: GeographicCoordinates {
        get throws { GeographicCoordinates(latitude: try latitude.decimalDegrees, longitude: try longitude.decimalDegrees) }
    }

    /// The single place where local civil time becomes a UTC instant.
    var utcDate: Date {
        get throws {
            let local = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: birthDate)
            guard let date = Calendar.utc.date(from: local) else { throw ChartCalculationError.invalidBirthDate }
            return date.addingTimeInterval(-utcOffsetSeconds)
        }
    }
}

enum ChartCalculationError: LocalizedError {
    case invalidBirthDate, invalidCoordinates, missingMoonPosition

    var errorDescription: String? {
        switch self {
        case .invalidBirthDate: "The birth date and time are invalid."
        case .invalidCoordinates: "Coordinates must be decimal degrees or DMS values."
        case .missingMoonPosition: "The Moon position is required to calculate Vimshottari dasha."
        }
    }
}

private extension Calendar {
    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }
}

private extension String {
    var decimalDegrees: Double {
        get throws {
            let negative = contains("S") || contains("W") || trimmingCharacters(in: .whitespaces).hasPrefix("-")
            let values = split { !$0.isNumber && $0 != "." }.compactMap { Double($0) }
            guard let degrees = values.first else { throw ChartCalculationError.invalidCoordinates }
            let result = degrees + (values.count > 1 ? values[1] / 60 : 0) + (values.count > 2 ? values[2] / 3_600 : 0)
            return negative ? -result : result
        }
    }
}

private extension Graha {
    /// Bodies requested from the ephemeris; Ketu is derived from Rahu and the lagna from the houses.
    static let ephemerisGrahas: [Graha] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu]

    func ephemerisGraha(nodeCalculation: ChartCalculationInput.NodeCalculation) -> EphemerisKit.Graha {
        switch self {
        case .sun: .sun
        case .moon: .moon
        case .mars: .mars
        case .mercury: .mercury
        case .jupiter: .jupiter
        case .venus: .venus
        case .saturn: .saturn
        case .rahu: nodeCalculation == .trueNode ? .trueNode : .meanNode
        case .ascendant, .ketu: .sun // never requested; see `ephemerisGrahas`
        }
    }
}
