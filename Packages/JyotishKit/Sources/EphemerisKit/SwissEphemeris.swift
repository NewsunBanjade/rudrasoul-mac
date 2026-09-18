import CSwissEph
import Foundation

/// Serializes all calls into Swiss Ephemeris, whose C runtime owns global mutable state.
public actor SwissEphemeris: EphemerisProviding {
    public static let shared = SwissEphemeris()

    private enum Flag {
        static let swiss: Int32 = 2
        static let moshier: Int32 = 4
        static let speed: Int32 = 256
        static let sidereal: Int32 = 65_536
    }

    private init() {
        if let dataDirectory = Self.bundledEphemerisDataDirectory() {
            dataDirectory.path.withCString(jp_swe_set_ephemeris_path)
        }
    }

    /// Configures bundled Swiss data for dates from 1800 through 2399.
    /// The data must be present before requesting `.swiss` positions.
    public func configureBundledEphemerisData() {
        guard let dataDirectory = Self.bundledEphemerisDataDirectory() else {
            return
        }
        configure(ephemerisPath: dataDirectory)
    }

    public func configure(ephemerisPath: URL) {
        ephemerisPath.path.withCString(jp_swe_set_ephemeris_path)
    }

    public func julianDay(
        year: Int32,
        month: Int32,
        day: Int32,
        utcHour: Double,
        gregorian: Bool = true
    ) -> JulianDay {
        JulianDay(jp_swe_julian_day(year, month, day, utcHour, gregorian ? 1 : 0))
    }

    public func position(
        of graha: Graha,
        at julianDay: JulianDay,
        settings: EphemerisSettings
    ) throws -> EclipticPosition {
        if let ayanamsa = settings.ayanamsa {
            jp_swe_set_sidereal_mode(ayanamsa.rawValue)
        }

        let requestedSource = sourceFlag(for: settings.source)
        var flags = requestedSource | Flag.speed
        if settings.ayanamsa != nil {
            flags |= Flag.sidereal
        }

        var result = jp_swe_position_result()
        var error = [CChar](repeating: 0, count: 256)
        let returnedFlags = error.withUnsafeMutableBufferPointer { buffer in
            jp_swe_calculate_ut(
                julianDay.value,
                graha.rawValue,
                flags,
                &result,
                buffer.baseAddress,
                buffer.count
            )
        }

        guard returnedFlags >= 0 else {
            let message = String(
                decoding: error.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) },
                as: UTF8.self
            )
            throw EphemerisError.calculationFailed(message)
        }
        guard settings.source != .swiss || returnedFlags & Flag.swiss != 0 else {
            throw EphemerisError.missingSwissEphemerisData
        }

        return EclipticPosition(
            longitude: result.values.0,
            latitude: result.values.1,
            distanceAU: result.values.2,
            longitudeSpeed: result.values.3,
            latitudeSpeed: result.values.4,
            distanceSpeed: result.values.5,
            source: settings.source
        )
    }

    public func houses(
        at julianDay: JulianDay,
        coordinates: GeographicCoordinates,
        system: HouseSystem,
        ayanamsa: Ayanamsa?
    ) throws -> Houses {
        guard (-90 ... 90).contains(coordinates.latitude),
              (-180 ... 180).contains(coordinates.longitude)
        else {
            throw EphemerisError.invalidCoordinates
        }

        if let ayanamsa {
            jp_swe_set_sidereal_mode(ayanamsa.rawValue)
        }
        var result = jp_swe_houses_result()
        let returnCode = jp_swe_houses_ut(
            julianDay.value,
            ayanamsa == nil ? 0 : Flag.sidereal,
            coordinates.latitude,
            coordinates.longitude,
            system.rawValue,
            &result
        )
        guard returnCode == 0 else {
            throw EphemerisError.houseCalculationFailed
        }

        let cusps = withUnsafeBytes(of: result.cusps) { bytes in
            Array(bytes.bindMemory(to: Double.self).dropFirst().prefix(12))
        }
        return Houses(
            cusps: cusps,
            ascendant: result.angles.0,
            midheaven: result.angles.1,
            vertex: result.angles.3
        )
    }

    private func sourceFlag(for source: EphemerisSource) -> Int32 {
        switch source {
        case .swiss: Flag.swiss
        case .moshier: Flag.moshier
        }
    }

    private nonisolated static func bundledEphemerisDataDirectory() -> URL? {
        Bundle.module.url(forResource: "ephe", withExtension: nil)
    }
}
