import EphemerisKit
import Foundation

/// Computes the D-1 positions from stored birth input through Swiss Ephemeris.
struct ChartCalculationService: Sendable {
    private let ephemeris: SwissEphemeris

    init(ephemeris: SwissEphemeris = .shared) {
        self.ephemeris = ephemeris
    }

    func calculate(input: ChartCalculationInput) async throws -> ChartDetail {
        let coordinates = try input.coordinates
        let utcDate = try input.utcDate
        let utcComponents = Calendar.utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: utcDate)
        guard let year = utcComponents.year, let month = utcComponents.month, let day = utcComponents.day else {
            throw ChartCalculationError.invalidBirthDate
        }

        let utcHour = Double(utcComponents.hour ?? 0)
            + Double(utcComponents.minute ?? 0) / 60
            + Double(utcComponents.second ?? 0) / 3_600
        let julianDay = await ephemeris.julianDay(
            year: Int32(year), month: Int32(month), day: Int32(day), utcHour: utcHour
        )
        let settings = EphemerisSettings(source: .swiss, ayanamsa: input.ayanamsa)
        let houses = try await ephemeris.houses(
            at: julianDay, coordinates: coordinates, system: input.houseSystem, ayanamsa: input.ayanamsa
        )

        let rawPositions = try await withThrowingTaskGroup(of: (Graha, EclipticPosition).self) { group in
            for graha in Graha.calculatedGrahas(nodeCalculation: input.nodeCalculation) {
                group.addTask {
                    (graha, try await ephemeris.position(of: graha.ephemerisGraha(nodeCalculation: input.nodeCalculation), at: julianDay, settings: settings))
                }
            }
            var positions: [(Graha, EclipticPosition)] = []
            for try await position in group {
                positions.append(position)
            }
            return positions
        }

        var planets = rawPositions.map { graha, position in
            PlanetPosition(
                graha: graha,
                rasi: Rasi(longitude: position.longitude),
                longitudeInRasi: position.longitude.truncatingRemainder(dividingBy: 30),
                formattedDMS: position.longitude.dmsInRasi,
                nakshatra: Nakshatra(longitude: position.longitude),
                pada: Nakshatra.pada(longitude: position.longitude),
                isRetrograde: position.longitudeSpeed < 0,
                isCombust: false,
                dignity: .neutral,
                bhava: houseNumber(for: position.longitude, cusps: houses.cusps),
                charaKaraka: nil,
                speedDegPerDay: position.longitudeSpeed
            )
        }
        if let rahu = planets.first(where: { $0.graha == .rahu }) {
            let rahuLongitude = Double(rahu.rasi.rawValue - 1) * 30 + rahu.longitudeInRasi
            let ketuLongitude = rahuLongitude + 180
            let ketu = PlanetPosition(
                graha: .ketu,
                rasi: Rasi(longitude: ketuLongitude),
                longitudeInRasi: ketuLongitude.normalizedLongitude.truncatingRemainder(dividingBy: 30),
                formattedDMS: ketuLongitude.dmsInRasi,
                nakshatra: Nakshatra(longitude: ketuLongitude),
                pada: Nakshatra.pada(longitude: ketuLongitude),
                isRetrograde: rahu.isRetrograde,
                isCombust: false,
                dignity: .neutral,
                bhava: houseNumber(for: ketuLongitude, cusps: houses.cusps),
                charaKaraka: nil,
                speedDegPerDay: rahu.speedDegPerDay
            )
            planets.append(ketu)
        }
        planets.sort { $0.graha.rawValue < $1.graha.rawValue }

        guard let moon = planets.first(where: { $0.graha == .moon }) else {
            throw ChartCalculationError.missingMoonPosition
        }
        let moonLongitude = Double(moon.rasi.rawValue - 1) * 30 + moon.longitudeInRasi
        let dashaResult = VimshottariDashaCalculator().calculate(
            moonLongitude: moonLongitude,
            birthDate: utcDate,
            maximumLevel: .pratyantardasha
        )

        let lagna = PlanetPosition(
            graha: .ascendant,
            rasi: Rasi(longitude: houses.ascendant),
            longitudeInRasi: houses.ascendant.truncatingRemainder(dividingBy: 30),
            formattedDMS: houses.ascendant.dmsInRasi,
            nakshatra: Nakshatra(longitude: houses.ascendant),
            pada: Nakshatra.pada(longitude: houses.ascendant),
            isRetrograde: false,
            isCombust: false,
            dignity: .neutral,
            bhava: 1,
            charaKaraka: nil,
            speedDegPerDay: nil
        )
        let bhavas = (0 ..< 12).map { index in
            let cusp = houses.cusps[index]
            let rasi = Rasi(longitude: cusp)
            return BhavaData(
                number: index + 1,
                rasi: rasi,
                cuspLongitudeDMS: cusp.dmsInRasi,
                lord: rasi.lord,
                occupantGrahas: planets.filter { $0.bhava == index + 1 }.map(\.graha),
                name: "Bhava \(index + 1)",
                significance: ""
            )
        }

        return ChartDetail(
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
            ayanamsaValueDMS: "",
            nodeCalculation: input.nodeCalculation == .trueNode ? "True Node" : "Mean Node",
            sunriseString: "",
            sunsetString: "",
            lagnaPosition: lagna,
            planets: planets,
            bhavas: bhavas,
            vargas: VargaCalculator.charts(lagnaLongitude: houses.ascendant, planets: planets),
            shadbala: [], ashtakavarga: AshtakavargaData(sarvashtakavarga: [:], bhinnashtakavarga: [:]),
            dashaNodes: dashaResult.nodes, currentDashaVector: dashaResult.currentDashaVector, yogas: [], sarvatobhadra: SarvatobhadraData(cells: [], vedhas: []),
            kota: KotaChakraData(kotaSwami: .sun, kotaPala: .sun, zoneAssignments: [:], praveshaGrahas: [], nirgamaGrahas: []),
            notes: input.notes, predictions: []
        )
    }

    private func houseNumber(for longitude: Double, cusps: [Double]) -> Int {
        let normalized = longitude.normalizedLongitude
        for index in 0 ..< 12 {
            let start = cusps[index].normalizedLongitude
            let end = cusps[(index + 1) % 12].normalizedLongitude
            let span = (end - start + 360).truncatingRemainder(dividingBy: 360)
            let distance = (normalized - start + 360).truncatingRemainder(dividingBy: 360)
            if distance < span { return index + 1 }
        }
        return 12
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
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
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

private extension Double {
    var normalizedLongitude: Double { truncatingRemainder(dividingBy: 360) < 0 ? truncatingRemainder(dividingBy: 360) + 360 : truncatingRemainder(dividingBy: 360) }
    var dmsInRasi: String {
        let totalSeconds = Int((truncatingRemainder(dividingBy: 30) * 3_600).rounded())
        return String(format: "%02d° %02d' %02d\\\"", totalSeconds / 3_600, (totalSeconds / 60) % 60, totalSeconds % 60)
    }
}

private extension Rasi {
    init(longitude: Double) { self = Rasi(rawValue: Int(longitude.normalizedLongitude / 30) + 1)! }
}

private extension Nakshatra {
    init(longitude: Double) { self = Nakshatra(rawValue: Int(longitude.normalizedLongitude / (360.0 / 27.0)) + 1)! }
    static func pada(longitude: Double) -> Int { Int(longitude.normalizedLongitude.truncatingRemainder(dividingBy: 360.0 / 27.0) / (360.0 / 108.0)) + 1 }
}

private extension Graha {
    static func calculatedGrahas(nodeCalculation: ChartCalculationInput.NodeCalculation) -> [Graha] {
        [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu]
    }

    func ephemerisGraha(nodeCalculation: ChartCalculationInput.NodeCalculation) -> EphemerisKit.Graha {
        switch self {
        case .sun: .sun; case .moon: .moon; case .mars: .mars; case .mercury: .mercury
        case .jupiter: .jupiter; case .venus: .venus; case .saturn: .saturn
        case .rahu: nodeCalculation == .trueNode ? .trueNode : .meanNode
        case .ascendant, .ketu: fatalError("Not an ephemeris body")
        }
    }
}
